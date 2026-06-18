build:
    tar -xf zstd-1.5.6.tar.gz
    cd zstd-1.5.6 && make -j$(nproc) PREFIX=/usr

package destdir:
    cd zstd-1.5.6 && make DESTDIR="{{destdir}}" PREFIX=/usr install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
