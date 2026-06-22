build:
    tar -xf btrfs-progs-v$PKG_VERSION.tar.xz
    cd btrfs-progs-v$PKG_VERSION && ./configure \
        --prefix=/usr \
        --sbindir=/usr/bin \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-documentation \
        --disable-backtrace \
        --disable-lzo \
        --disable-convert \
        --with-crypto=openssl
    cd btrfs-progs-v$PKG_VERSION && make

package:
    cd btrfs-progs-v$PKG_VERSION && make DESTDIR="$DESTDIR" install

    # Enforce strict permissions
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -type f -name "*.so*" -exec chmod 755 {} +; fi
