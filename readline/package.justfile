build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-curses
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) SHLIB_LIBS="-lncursesw"

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}" -name "*.so*" -exec chmod 755 {} +
    find "{{destdir}}" -name "*.a" -exec chmod 644 {} +
    find "{{destdir}}" -name "*.h" -exec chmod 644 {} +
