build:
    tar -xf file-5.45.tar.gz
    cd file-5.45 && ./configure --prefix=/usr --disable-static && make -j$(nproc)

package destdir:
    cd file-5.45 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
