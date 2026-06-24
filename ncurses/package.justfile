build:
    tar -xf "$PKG_NAME-$PKG_VERSION.tar.gz"
    cd "$PKG_NAME-$PKG_VERSION" && ./configure $CONFIGURE_ARGS && make -j$(nproc)

package:
    cd "$PKG_NAME-$PKG_VERSION" && make DESTDIR="$DESTDIR" install
    # Link libncurses to libncursesw for compatibility
    for lib in ncurses form panel menu; do \
        ln -sf lib${lib}w.so "$DESTDIR/usr/lib/lib${lib}.so"; \
    done
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
