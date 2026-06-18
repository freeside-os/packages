build:
    tar -xf pkgconf-2.2.0.tar.xz
    cd pkgconf-2.2.0 && ./configure --prefix=/usr --with-pkg-config-dir=/usr/lib/pkgconfig:/usr/share/pkgconfig && make -j$(nproc)

package destdir:
    cd pkgconf-2.2.0 && make DESTDIR="{{destdir}}" install
    ln -sf pkgconf "{{destdir}}/usr/bin/pkg-config"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
