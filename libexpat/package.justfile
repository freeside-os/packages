build:
    tar -xf expat-2.6.2.tar.xz
    cd expat-2.6.2 && ./configure \
        --prefix=/usr \
        --enable-shared \
        --enable-static
    cd expat-2.6.2 && make -j$(nproc)

package destdir:
    cd expat-2.6.2 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    find "{{destdir}}" -name "*.so*" -exec chmod 755 {} +
    find "{{destdir}}" -name "*.a" -exec chmod 644 {} +
    find "{{destdir}}" -name "*.h" -exec chmod 644 {} +
