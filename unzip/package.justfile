build:
    tar -xf unzip${PKG_VERSION//./}.tar.gz
    cd unzip${PKG_VERSION//./} && make -f unix/Makefile linux_noasm CC="clang" LD="clang" CFLAGS="-O3 -Wall"

package destdir:
    cd unzip${PKG_VERSION//./} && make -f unix/Makefile prefix="{{destdir}}/usr" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
