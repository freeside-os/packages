build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/sbin" ]; then find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} +; fi
