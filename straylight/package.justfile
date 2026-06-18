build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd straylight && cargo build --release

package destdir:
    mkdir -p "{{destdir}}/usr/bin"
    cp straylight/target/release/straylight "{{destdir}}/usr/bin/straylight"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
