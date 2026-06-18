build:
    tar -xf 1.36.0.tar.gz
    cd $PKG_NAME-$PKG_VERSION && cargo build --release

package destdir:
    mkdir -p "{{destdir}}/usr/bin"
    cp $PKG_NAME-$PKG_VERSION/target/release/just "{{destdir}}/usr/bin/just"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
