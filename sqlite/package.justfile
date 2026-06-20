build:
    tar -xf sqlite-autoconf-$SQLITE_CODE.tar.gz
    cd sqlite-autoconf-$SQLITE_CODE && ./configure $CONFIGURE_ARGS && make -j$(nproc)

package:
    cd sqlite-autoconf-$SQLITE_CODE && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
