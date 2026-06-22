build:
    tar -xf MarkupSafe-$PKG_VERSION.tar.gz

package:
    cd MarkupSafe-$PKG_VERSION && python3 setup.py install --prefix=/usr --root="$DESTDIR"
    find "$DESTDIR" -type d -exec chmod 755 {} +
