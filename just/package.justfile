build:
    tar -xf 1.36.0.tar.gz
    cd $PKG_NAME-$PKG_VERSION && cargo build --release

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp $PKG_NAME-$PKG_VERSION/target/release/just "$DESTDIR/usr/bin/just"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
