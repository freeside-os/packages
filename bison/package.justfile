build:
    tar -xf bison-3.8.2.tar.xz
    cd bison-3.8.2 && ./configure --prefix=/usr && make -j$(nproc)

package destdir:
    cd bison-3.8.2 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
