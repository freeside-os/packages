build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --shared && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    # Enforce strict permissions compliance
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    find "$DESTDIR/usr/lib" -name "*.a" -exec chmod 644 {} + || true
    find "$DESTDIR/usr/include" -type f -exec chmod 644 {} + || true
