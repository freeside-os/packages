build:
    tar -xf flex-2.6.4.tar.gz
    cd flex-2.6.4 && ./configure --prefix=/usr --disable-static && make -j$(nproc)

package destdir:
    cd flex-2.6.4 && make DESTDIR="{{destdir}}" install
    ln -sf flex "{{destdir}}/usr/bin/lex"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
