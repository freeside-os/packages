build:
    tar -xf Python-3.12.3.tar.xz
    cd Python-3.12.3 && ./configure --prefix=/usr --enable-shared --with-ensurepip=yes --with-openssl=/usr && make -j$(nproc)

package:
    cd Python-3.12.3 && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
