build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./config --prefix=/usr --openssldir=/etc/ssl shared zlib-dynamic && make -j$(nproc)

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install_sw
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
