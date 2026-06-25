build:
    tar -xf v$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && python3 setup.py build

package:
    cd $PKG_NAME-$PKG_VERSION && python3 setup.py install --prefix=/usr --root="$DESTDIR" --skip-build
    mkdir -p "$DESTDIR/usr/share/licenses/$PKG_NAME"
    install -vDm 644 $PKG_NAME-$PKG_VERSION/LICENSE "$DESTDIR/usr/share/licenses/$PKG_NAME/LICENSE"
    mkdir -p "$DESTDIR/usr/share/doc/$PKG_NAME"
    install -vDm 644 $PKG_NAME-$PKG_VERSION/README.md "$DESTDIR/usr/share/doc/$PKG_NAME/README.md"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
