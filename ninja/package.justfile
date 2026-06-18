build:
    tar -xf v1.12.1.tar.gz
    cd $PKG_NAME-$PKG_VERSION && ./configure.py --bootstrap

package destdir:
    mkdir -p "{{destdir}}/usr/bin"
    cp $PKG_NAME-$PKG_VERSION/ninja "{{destdir}}/usr/bin/ninja"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
