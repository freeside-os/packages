pkg_name := env_var_or_default("PKG_NAME", "linux-kernel")
pkg_version := env_var_or_default("PKG_VERSION", "7.1.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

build:
    # Nothing to compile, it's already compiled by linux-mainline.

package:
    # Copy the kernel vmlinuz (bzImage) from the linux-mainline build tree
    mkdir -p "{{destdir}}"/usr/lib/freeside/kernel
    cp /usr/lib/freeside/linux/linux-mainline/arch/x86/boot/bzImage "{{destdir}}"/usr/lib/freeside/kernel/vmlinuz
    
    # Enforce strict permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
