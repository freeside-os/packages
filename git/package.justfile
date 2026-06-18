build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --with-openssl --without-tcltk --without-gettext && make -j$(nproc) NO_GETTEXT=YesPlease

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make NO_GETTEXT=YesPlease DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
