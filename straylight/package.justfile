build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd straylight && cargo build --release

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp straylight/target/release/straylight "$DESTDIR/usr/bin/straylight"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
