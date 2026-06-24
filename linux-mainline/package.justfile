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
    # Copy the kernel build output/tree to the destination directory
    mkdir -p "{{destdir}}"/usr/lib/freeside/linux/linux-mainline
    cp -a . "{{destdir}}"/usr/lib/freeside/linux/linux-mainline

    # Strict permissions: Enforce chmod 755 on directories and binaries at the end of the package step
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
