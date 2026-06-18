build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --with-curses --enable-static-link=no && make -j$(nproc)

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    ln -sf bash "{{destdir}}/usr/bin/sh"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
