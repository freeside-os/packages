build:
    mkdir -p build-dir
    cd build-dir && tar -xf ../tzcode$PKG_VERSION.tar.gz
    cd build-dir && tar -xf ../$PKG_NAME$PKG_VERSION.tar.gz
    cd build-dir && make -j$(nproc) CFLAGS="${CFLAGS:--O2 -pipe}" CC="${CC:-gcc}" TOPDIR=/usr TZDIR=/usr/share/zoneinfo BINDIR=/usr/bin SBINDIR=/usr/bin MANDIR=/usr/share/man LIBDIR=/usr/lib

package:
    cd build-dir && make DESTDIR="$DESTDIR" TOPDIR=/usr TZDIR=/usr/share/zoneinfo BINDIR=/usr/bin SBINDIR=/usr/bin MANDIR=/usr/share/man LIBDIR=/usr/lib install
    rm -f "$DESTDIR/etc/localtime" "$DESTDIR/usr/etc/localtime"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/sbin" ]; then find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} +; fi
