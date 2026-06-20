build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS && make -j$(nproc) NO_GETTEXT=YesPlease

package:
    cd $PKG_NAME-$PKG_VERSION && make NO_GETTEXT=YesPlease DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
