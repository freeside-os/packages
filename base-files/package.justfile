# Base Files Installation rules
build:
    @echo "Preparing base-files layout..."

package:
    # 1. Unpack default lowerdir configurations (/usr/share/freeside/etc/passwd, etc.)
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz -C "$DESTDIR"
    
    # 2. Assert read-only userspace structures are initialized
    mkdir -p "$DESTDIR/usr/bin"
    mkdir -p "$DESTDIR/usr/lib"
    mkdir -p "$DESTDIR/usr/share"
    mkdir -p "$DESTDIR/usr/include"
    mkdir -p "$DESTDIR/var"
    mkdir -p "$DESTDIR/boot"
    mkdir -p "$DESTDIR/usr/share/freeside/etc"
    
    # 3. Install the declarative tmpfiles configuration
    mkdir -p "$DESTDIR/usr/lib/tmpfiles.d"
    cp base-files.conf "$DESTDIR/usr/lib/tmpfiles.d/base-files.conf"
    
    # 4. Install the systemd etc.mount unit file
    mkdir -p "$DESTDIR/usr/lib/systemd/system"
    cp etc.mount "$DESTDIR/usr/lib/systemd/system/etc.mount"
    
    # 5. Enforce permissions
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib/tmpfiles.d" -type f -exec chmod 644 {} +
    find "$DESTDIR/usr/lib/systemd/system" -type f -exec chmod 644 {} +
    find "$DESTDIR/usr/share/freeside/etc" -type f -exec chmod 644 {} +
    
    @echo "Base files layout and declarative systemd configs staged successfully."
