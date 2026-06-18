build:
    tar -xf sqlite-autoconf-$SQLITE_CODE.tar.gz
    cd sqlite-autoconf-$SQLITE_CODE && ./configure --prefix=/usr && make -j$(nproc)

package destdir:
    cd sqlite-autoconf-$SQLITE_CODE && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
