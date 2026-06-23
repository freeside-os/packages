build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) PREFIX=/usr

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" PREFIX=/usr install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
