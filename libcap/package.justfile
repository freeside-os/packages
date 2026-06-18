build:
    tar -xf libcap-2.70.tar.xz
    cd libcap-2.70 && make -j$(nproc) GOLANG=no PAM=no lib=lib

package destdir:
    cd libcap-2.70 && make prefix=/usr lib=lib GOLANG=no PAM=no DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
