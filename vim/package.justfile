build:
    tar -xf v9.1.1000.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure \
        --prefix=/usr \
        --with-features=huge \
        --enable-multibyte \
        --disable-gui \
        --without-x \
        --disable-nls \
        --enable-terminal
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
