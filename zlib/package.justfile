build:
    tar -xf zlib-1.3.1.tar.gz
    cd zlib-1.3.1 && ./configure --prefix=/usr --shared && make -j$(nproc)

package destdir:
    cd zlib-1.3.1 && make DESTDIR="{{destdir}}" install
    # Enforce strict permissions compliance
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    find "{{destdir}}/usr/lib" -name "*.a" -exec chmod 644 {} + || true
    find "{{destdir}}/usr/include" -type f -exec chmod 644 {} + || true
