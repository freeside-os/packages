build:
    tar -xf meson-1.4.0.tar.gz

package destdir:
    cd meson-1.4.0 && python3 setup.py install --prefix=/usr --root="{{destdir}}"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
