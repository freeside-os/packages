build:
    tar -xf expat-$PKG_VERSION.tar.xz
    cd expat-$PKG_VERSION && ./configure \
        --prefix=/usr \
        --enable-shared \
        --enable-static
    cd expat-$PKG_VERSION && make -j$(nproc)

package destdir:
    cd expat-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    find "{{destdir}}" -name "*.so*" -exec chmod 755 {} +
    find "{{destdir}}" -name "*.a" -exec chmod 644 {} +
    find "{{destdir}}" -name "*.h" -exec chmod 644 {} +
