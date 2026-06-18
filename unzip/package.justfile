build:
    tar -xf unzip${PKG_VERSION//./}.tar.gz
    cd unzip${PKG_VERSION//./} && make -f unix/Makefile linux_noasm CC="clang" LD="clang" CFLAGS="-O3 -Wall"

package:
    cd unzip${PKG_VERSION//./} && make -f unix/Makefile prefix="$DESTDIR/usr" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
