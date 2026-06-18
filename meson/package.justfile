build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz

package destdir:
    cd $PKG_NAME-$PKG_VERSION && python3 setup.py install --prefix=/usr --root="{{destdir}}"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
