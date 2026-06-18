build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --with-shared --without-debug --enable-widec --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    # Link libncurses to libncursesw for compatibility
    for lib in ncurses form panel menu; do \
        ln -sf lib${lib}w.so "$DESTDIR/usr/lib/lib${lib}.so"; \
    done
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
