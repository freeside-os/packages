pkg_name := env_var_or_default("PKG_NAME", "UNDEFINED")
pkg_version := env_var_or_default("PKG_VERSION", "UNDEFINED")
destdir := env_var_or_default("DESTDIR", "UNDEFINED")

build:
    # Nothing to compile, it's already compiled by linux-mainline.

package:
    # Copy the kernel vmlinuz (bzImage) from the linux-mainline build tree
    mkdir -p "{{destdir}}"/usr/lib/freeside/linux/kernel
    cp /usr/lib/freeside/linux/mainline/vmlinuz "{{destdir}}"/usr/lib/freeside/linux/kernel/vmlinuz
    cp /usr/lib/freeside/linux/mainline/System.map "{{destdir}}"/usr/lib/freeside/linux/kernel/System.map
    
    # Enforce strict permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
