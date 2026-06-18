build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) CFLAGS="-O2 -pipe -fPIC" PREFIX=/usr && make -f Makefile-libbz2_so

package:
    cd $PKG_NAME-$PKG_VERSION && make PREFIX="$DESTDIR/usr" install
    cp -a $PKG_NAME-$PKG_VERSION/libbz2.so.1.0.8 "$DESTDIR/usr/lib/"
    ln -sf libbz2.so.1.0.8 "$DESTDIR/usr/lib/libbz2.so.1.0"
    ln -sf libbz2.so.1.0.8 "$DESTDIR/usr/lib/libbz2.so"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
