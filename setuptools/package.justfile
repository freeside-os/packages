build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz

package:
    cd $PKG_NAME-$PKG_VERSION && python3 setup.py install --prefix=/usr --root="$DESTDIR"
    find "$DESTDIR" -type d -exec chmod 755 {} +
