build:
    tar -xf curl-8.8.0.tar.xz
    cd curl-8.8.0 && ./configure --prefix=/usr --with-openssl --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt && make -j$(nproc)

package destdir:
    cd curl-8.8.0 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
