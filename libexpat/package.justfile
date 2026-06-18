build:
    tar -xf expat-$PKG_VERSION.tar.xz
    cd expat-$PKG_VERSION && ./configure \
        --prefix=/usr \
        --enable-shared \
        --enable-static
    cd expat-$PKG_VERSION && make -j$(nproc)

package:
    cd expat-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    find "$DESTDIR" -name "*.so*" -exec chmod 755 {} +
    find "$DESTDIR" -name "*.a" -exec chmod 644 {} +
    find "$DESTDIR" -name "*.h" -exec chmod 644 {} +
