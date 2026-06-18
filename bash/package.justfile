build:
    tar -xf bash-5.2.21.tar.gz
    cd bash-5.2.21 && ./configure --prefix=/usr --with-curses --enable-static-link=no && make -j$(nproc)

package destdir:
    cd bash-5.2.21 && make DESTDIR="{{destdir}}" install
    ln -sf bash "{{destdir}}/usr/bin/sh"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
