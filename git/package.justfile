build:
    tar -xf git-2.45.1.tar.xz
    cd git-2.45.1 && ./configure --prefix=/usr --with-openssl --without-tcltk --without-gettext && make -j$(nproc) NO_GETTEXT=YesPlease

package destdir:
    cd git-2.45.1 && make NO_GETTEXT=YesPlease DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
