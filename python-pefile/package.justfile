build:
    tar -xf pefile-$PKG_VERSION.tar.gz

package:
    (cd pefile-$PKG_VERSION && python3 -m pip install . --root="$DESTDIR" --prefix=/usr --no-deps)
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -name "*.so" -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
