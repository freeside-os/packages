# live-initramfs overlay build recipe
pkg_name := env_var_or_default("PKG_NAME", "live-initramfs")
pkg_version := env_var_or_default("PKG_VERSION", "1.0.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

build:
    python3 generate_cpio.py

package:
    mkdir -p "{{destdir}}"/usr/lib/freeside
    cp initramfs-live.cpio.gz "{{destdir}}"/usr/lib/freeside/initramfs-live.cpio.gz
    find "{{destdir}}" -type d -exec chmod 755 {} +
    chmod 644 "{{destdir}}"/usr/lib/freeside/initramfs-live.cpio.gz
