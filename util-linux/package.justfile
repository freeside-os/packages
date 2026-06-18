build:
    tar -xf util-linux-2.40.1.tar.xz
    cd util-linux-2.40.1 && ./configure --prefix=/usr --disable-static --disable-bash-completion --disable-use-tty-group --disable-makeinstall-chown --disable-makeinstall-setuid --disable-liblastlog2 && make -j$(nproc)

package destdir:
    cd util-linux-2.40.1 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/sbin" ]; then find "{{destdir}}/usr/sbin" -type f -exec chmod 755 {} +; fi
