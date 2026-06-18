build:
    tar -xf make-4.4.1.tar.gz
    cd make-4.4.1 && ./configure --prefix=/usr && make -j$(nproc)

package destdir:
    cd make-4.4.1 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
