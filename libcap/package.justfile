build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) GOLANG=no PAM=no lib=lib

package:
    cd $PKG_NAME-$PKG_VERSION && make prefix=/usr lib=lib GOLANG=no PAM=no DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
