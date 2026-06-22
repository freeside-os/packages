build:
    clang -O2 -Wall getent.c -o getent
    clang -O2 -Wall getconf.c -o getconf
    clang -O2 -Wall iconv.c -o iconv
    clang -O2 -Wall ldconfig.c -o ldconfig

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp getent getconf iconv ldconfig ldd "$DESTDIR/usr/bin/"
    chmod 755 "$DESTDIR/usr/bin/getent" "$DESTDIR/usr/bin/getconf" "$DESTDIR/usr/bin/iconv" "$DESTDIR/usr/bin/ldconfig" "$DESTDIR/usr/bin/ldd"
