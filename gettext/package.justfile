build:
    tar -xf gettext-0.22.5.tar.xz
    cd gettext-0.22.5 && ./configure --prefix=/usr --disable-static && make -j$(nproc)

package destdir:
    cd gettext-0.22.5 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
