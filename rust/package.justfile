build:
    tar -xf $PKG_NAME-$PKG_VERSION-x86_64-unknown-linux-musl.tar.gz

package:
    cd $PKG_NAME-$PKG_VERSION-x86_64-unknown-linux-musl && ./install.sh --prefix="$DESTDIR/usr" --components=rustc,cargo,rust-std-x86_64-unknown-linux-musl
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
