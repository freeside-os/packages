build:
    tar -xf "$PKG_NAME-$PKG_VERSION.tar.gz"
    cd "$PKG_NAME" && cargo build --release

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp "$PKG_NAME"/target/release/"$PKG_NAME" "$DESTDIR/usr/bin/$PKG_NAME"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
