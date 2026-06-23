# base-initramfs build recipe
pkg_name := env_var_or_default("PKG_NAME", "base-initramfs")
pkg_version := env_var_or_default("PKG_VERSION", "1.0.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

build:
    python3 fsinitrd.py --packages-dir /workspace/packages_output --output initramfs.cpio

package:
    mkdir -p "{{destdir}}"/usr/lib/freeside
    cp initramfs.cpio "{{destdir}}"/usr/lib/freeside/initramfs.cpio

    # Strict permissions: Enforce chmod 755 on directories and binaries at the end of the package step
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
