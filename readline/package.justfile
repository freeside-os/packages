build:
    tar -xf readline-8.2.tar.gz
    cd readline-8.2 && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-curses
    cd readline-8.2 && make -j$(nproc) SHLIB_LIBS="-lncursesw"

package destdir:
    cd readline-8.2 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}" -name "*.so*" -exec chmod 755 {} +
    find "{{destdir}}" -name "*.a" -exec chmod 644 {} +
    find "{{destdir}}" -name "*.h" -exec chmod 644 {} +
