build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure \
        --prefix=/usr \
        --enable-shared \
        --disable-static
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -name "*.so*" -exec chmod 755 {} +
    find "$DESTDIR" -name "*.h" -exec chmod 644 {} +
