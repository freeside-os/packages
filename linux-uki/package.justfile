pkg_name := env_var_or_default("PKG_NAME", "linux-uki")
pkg_version := env_var_or_default("PKG_VERSION", "7.1.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

build:
    # Nothing to compile

package:
    # 1. Stage boot command-line parameters
    mkdir -p "{{destdir}}"/usr/lib/kernel
    cp cmdline "{{destdir}}"/usr/lib/kernel/cmdline

    # 2. Assemble the Unified Kernel Image (UKI) PE executable using systemd-ukify
    /usr/lib/systemd/ukify build \
        --os-release=@/etc/os-release \
        --cmdline=@cmdline \
        --initrd=/usr/lib/freeside/initramfs.cpio \
        --linux=/usr/lib/freeside/kernel/vmlinuz \
        --stub=/usr/lib/systemd/boot/efi/linuxx64.efi.stub \
        --output="{{destdir}}"/usr/lib/kernel/uki-{{pkg_version}}.efi

    # 3. Strict permissions: Enforce chmod 755 on directories and binaries at the end of the package step
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
