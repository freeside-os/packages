build:
    tar -xf libffi-3.4.6.tar.gz
    cd libffi-3.4.6 && ./configure \
        --prefix=/usr \
        --enable-shared \
        --disable-static
    cd libffi-3.4.6 && make -j$(nproc)

package destdir:
    cd libffi-3.4.6 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}" -name "*.so*" -exec chmod 755 {} +
    find "{{destdir}}" -name "*.h" -exec chmod 644 {} +
