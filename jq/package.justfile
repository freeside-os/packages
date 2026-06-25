build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS --with-oniguruma=builtin && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -exec chmod 644 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/sbin" ]; then find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -name "*.so*" -type f -exec chmod 755 {} +; fi
