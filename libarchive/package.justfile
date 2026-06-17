build:
    tar -xf libarchive-3.7.4.tar.gz
    cd libarchive-3.7.4 && ./configure --prefix=/usr --disable-static && make -j$(nproc)

package destdir:
    cd libarchive-3.7.4 && make DESTDIR="{{destdir}}" install
    # Enforce strict permissions compliance
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    find "{{destdir}}/usr/include" -type f -exec chmod 644 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
