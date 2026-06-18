build:
    tar -xf v1.12.1.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure.py --bootstrap

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp $PKG_NAME-$PKG_VERSION/ninja "$DESTDIR/usr/bin/ninja"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
