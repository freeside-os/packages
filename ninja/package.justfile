build:
    tar -xf v1.12.1.tar.gz
    cd ninja-1.12.1 && ./configure.py --bootstrap

package destdir:
    mkdir -p "{{destdir}}/usr/bin"
    cp ninja-1.12.1/ninja "{{destdir}}/usr/bin/ninja"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
