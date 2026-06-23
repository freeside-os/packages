build:
    tar -xf v$PKG_VERSION.tar.gz

package:
    (cd pyelftools-0.33 && python3 -m pip install . --root="$DESTDIR" --prefix=/usr --no-deps)
    mkdir -p "$DESTDIR/usr/share/licenses/$PKG_NAME"
    install -vDm 644 pyelftools-0.33/LICENSE "$DESTDIR/usr/share/licenses/$PKG_NAME/LICENSE"
    mkdir -p "$DESTDIR/usr/share/doc/$PKG_NAME"
    install -vDm 644 pyelftools-0.33/README.md "$DESTDIR/usr/share/doc/$PKG_NAME/README.md"
    install -vDm 644 pyelftools-0.33/CHANGES "$DESTDIR/usr/share/doc/$PKG_NAME/CHANGES"
    cp -vr pyelftools-0.33/examples "$DESTDIR/usr/share/doc/$PKG_NAME/"
    find "$DESTDIR" -type d -exec chmod 755 {} +
