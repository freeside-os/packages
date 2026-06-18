build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) CFLAGS="-O2 -pipe -fPIC" PREFIX=/usr && make -f Makefile-libbz2_so

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make PREFIX="{{destdir}}/usr" install
    cp -a $PKG_NAME-$PKG_VERSION/libbz2.so.1.0.8 "{{destdir}}/usr/lib/"
    ln -sf libbz2.so.1.0.8 "{{destdir}}/usr/lib/libbz2.so.1.0"
    ln -sf libbz2.so.1.0.8 "{{destdir}}/usr/lib/libbz2.so"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
