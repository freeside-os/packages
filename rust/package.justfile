build:
    tar -xf $PKG_NAME-$PKG_VERSION-x86_64-unknown-linux-musl.tar.gz

package destdir:
    cd $PKG_NAME-$PKG_VERSION-x86_64-unknown-linux-musl && ./install.sh --prefix="{{destdir}}/usr" --components=rustc,cargo,rust-std-x86_64-unknown-linux-musl
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
