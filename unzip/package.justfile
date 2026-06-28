#pkg_version := env_var_or_default("PKG_VERSION")
pkg_version := "60"

build:
    tar -xf unzip{{pkg_version}}.tar.gz
    cd unzip{{pkg_version}} && make -f unix/Makefile linux_noasm CC="clang" LD="clang" CFLAGS="-O3 -Wall"

package:
    cd unzip{{pkg_version}} && make -f unix/Makefile prefix="$DESTDIR/usr" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
