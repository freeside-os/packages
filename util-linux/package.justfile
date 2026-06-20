build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/sbin" ]; then find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} +; fi
