build:
    tar -xf patchelf-0.18.0.tar.gz
    cd patchelf-0.18.0 && ./configure --prefix=/usr && make -j$(nproc)

package destdir:
    cd patchelf-0.18.0 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
