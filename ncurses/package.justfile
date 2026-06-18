build:
    tar -xf ncurses-6.4.tar.gz
    cd ncurses-6.4 && ./configure --prefix=/usr --with-shared --without-debug --enable-widec --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig && make -j$(nproc)

package destdir:
    cd ncurses-6.4 && make DESTDIR="{{destdir}}" install
    # Link libncurses to libncursesw for compatibility
    for lib in ncurses form panel menu; do \
        ln -sf lib${lib}w.so "{{destdir}}/usr/lib/lib${lib}.so"; \
    done
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
