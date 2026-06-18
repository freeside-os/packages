build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --shared && make -j$(nproc)

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    # Enforce strict permissions compliance
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    find "{{destdir}}/usr/lib" -name "*.a" -exec chmod 644 {} + || true
    find "{{destdir}}/usr/include" -type f -exec chmod 644 {} + || true
