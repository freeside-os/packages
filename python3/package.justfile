build:
    tar -xf Python-3.12.3.tar.xz
    cd Python-3.12.3 && ./configure --prefix=/usr --enable-shared --with-ensurepip=yes && make -j$(nproc)

package destdir:
    cd Python-3.12.3 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
