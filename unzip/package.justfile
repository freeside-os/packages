build:
    tar -xf unzip60.tar.gz
    cd unzip60 && make -f unix/Makefile linux_noasm CC="clang" LD="clang" CFLAGS="-O3 -Wall"

package destdir:
    cd unzip60 && make -f unix/Makefile prefix="{{destdir}}/usr" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
