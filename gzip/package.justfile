build:
    tar -xf gzip-1.13.tar.xz
    cd gzip-1.13 && ./configure --prefix=/usr && make -j$(nproc)

package destdir:
    cd gzip-1.13 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
