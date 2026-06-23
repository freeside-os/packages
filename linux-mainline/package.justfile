# linux-mainline compile and UKI stitching recipe
pkg_name := env_var_or_default("PKG_NAME", "linux-mainline")
pkg_version := env_var_or_default("PKG_VERSION", "7.1.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

cc := "clang"
ld := "ld.lld"
llvm_flags := "CC=clang LD=ld.lld LLVM=1 LLVM_IAS=1"

prepare:
    # Tarball is likely downloaded to the current directory (src).
    tar -xf linux-7.1.tar.xz --strip-components=1
    sed -i 's|#include <linux/types.h>|#include <linux/types.h>\n#ifndef __attribute_const__\n#define __attribute_const__ __attribute__((__const__))\n#endif|' include/uapi/linux/swab.h
    
    # Inject our minimal, musl-friendly, vendor-neutral hardware configuration
    cp /workspace/packages/linux-mainline/files/freeside_defconfig .config
    make ARCH=x86_64 olddefconfig

build: prepare
    # Compile raw kernel image (bzImage on x86_64) using Clang
    make -j$(nproc) ARCH=x86_64 {{llvm_flags}} bzImage
    # Compile driver modules
    make -j$(nproc) ARCH=x86_64 {{llvm_flags}} modules

package:
    # 1. Map driver modules directly to un-merged /usr location
    mkdir -p "{{destdir}}"/usr/lib/modules
    make ARCH=x86_64 {{llvm_flags}} INSTALL_MOD_PATH="{{destdir}}"/usr modules_install
    
    # Strip debugging symbols and remove transient development symlinks
    find "{{destdir}}"/usr/lib/modules/ -name "*.ko" -exec llvm-objcopy --strip-debug {} \;
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}/build || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}/source || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}-freeside/build || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}-freeside/source || true

    # 2. Stage boot command-line parameters
    mkdir -p "{{destdir}}"/usr/lib/kernel
    cp /workspace/packages/linux-mainline/files/cmdline "{{destdir}}"/usr/lib/kernel/cmdline

    # 3. Assemble the Unified Kernel Image (UKI) PE executable using llvm-objcopy (letting it auto-assign VMAs)
    llvm-objcopy \
        --add-section .osrel=/etc/os-release \
        --set-section-flags .osrel=alloc,readonly,code \
        --add-section .cmdline="{{destdir}}"/usr/lib/kernel/cmdline \
        --set-section-flags .cmdline=alloc,readonly,code \
        --add-section .initrd=/usr/lib/freeside/initramfs.cpio \
        --set-section-flags .initrd=alloc,readonly,code \
        --add-section .linux=arch/x86/boot/bzImage \
        --set-section-flags .linux=alloc,readonly,code \
        /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
        "{{destdir}}"/usr/lib/kernel/uki-{{pkg_version}}.efi

    # 4. Strict permissions: Enforce chmod 755 on directories and binaries at the end of the package step
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
