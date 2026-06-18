build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && ./configure --prefix=/usr --disable-nls && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    ln -sf gawk "$DESTDIR/usr/bin/awk"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
