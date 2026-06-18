build:
    tar -xf openssl-3.3.0.tar.gz
    cd openssl-3.3.0 && ./config --prefix=/usr --openssldir=/etc/ssl shared zlib-dynamic && make -j$(nproc)

package destdir:
    cd openssl-3.3.0 && make DESTDIR="{{destdir}}" install_sw
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
