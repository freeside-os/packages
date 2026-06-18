build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) GOLANG=no PAM=no lib=lib

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make prefix=/usr lib=lib GOLANG=no PAM=no DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
