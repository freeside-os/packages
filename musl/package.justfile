build:
    tar -xf musl-1.2.5.tar.gz
    cd musl-1.2.5 && ./configure --prefix=/usr --syslibdir=/usr/lib && make -j$(nproc)

package destdir:
    cd musl-1.2.5 && make DESTDIR="{{destdir}}" install
    # Enforce strict permissions compliance
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    find "{{destdir}}/usr/lib" -name "*.a" -exec chmod 644 {} + || true
    find "{{destdir}}/usr/include" -type f -exec chmod 644 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
