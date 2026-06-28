build:
    @echo "Preparing base-files layout..."

package:
    mkdir -p "$DESTDIR"
    tar -xf "$PKG_NAME"-*.tar.gz -C "$DESTDIR"
    mkdir -p "$DESTDIR/usr/bin"
    mkdir -p "$DESTDIR/usr/lib"
    mkdir -p "$DESTDIR/usr/share"
    mkdir -p "$DESTDIR/usr/include"
    mkdir -p "$DESTDIR/var"
    mkdir -p "$DESTDIR/boot"
    mkdir -p "$DESTDIR/usr/share/freeside/etc"
    mkdir -p "$DESTDIR/usr/lib/tmpfiles.d"
    cp base-files.conf "$DESTDIR/usr/lib/tmpfiles.d/base-files.conf"
    mkdir -p "$DESTDIR/usr/lib/systemd/system"
    cp etc.mount "$DESTDIR/usr/lib/systemd/system/etc.mount"
    mkdir -p "$DESTDIR/usr/lib"
    cp os-release "$DESTDIR/usr/lib/os-release"
    sed -i "s/__VERSION__/$FREESIDE_VERSION/g" "$DESTDIR/usr/lib/os-release"
    mkdir -p "$DESTDIR/etc"
    ln -sf ../usr/lib/os-release "$DESTDIR/etc/os-release"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib/tmpfiles.d" -type f -exec chmod 644 {} +
    find "$DESTDIR/usr/lib/systemd/system" -type f -exec chmod 644 {} +
    find "$DESTDIR/usr/share/freeside/etc" -type f -exec chmod 644 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
    chmod 644 "$DESTDIR/usr/lib/os-release"
    @echo "Base files layout and declarative systemd configs staged successfully."
