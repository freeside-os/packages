build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    ln -sf flex "$DESTDIR/usr/bin/lex"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
