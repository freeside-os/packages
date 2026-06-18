build:
    tar -xf v9.1.1000.tar.gz
    cd vim-9.1.1000 && ./configure \
        --prefix=/usr \
        --with-features=huge \
        --enable-multibyte \
        --disable-gui \
        --without-x \
        --disable-nls \
        --enable-terminal
    cd vim-9.1.1000 && make -j$(nproc)

package destdir:
    cd vim-9.1.1000 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
