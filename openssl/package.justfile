build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./config --prefix=/usr --openssldir=/etc/ssl shared no-comp && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install_sw
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
