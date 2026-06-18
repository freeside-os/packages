build:
    tar -xf xz-5.6.2.tar.gz
    cd xz-5.6.2 && ./configure --prefix=/usr --disable-static && make -j$(nproc)

package destdir:
    cd xz-5.6.2 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
