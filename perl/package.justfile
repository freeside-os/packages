build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && ./Configure \
        -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/core_perl \
        -Darchlib=/usr/lib/perl5/core_perl \
        -Dvendorlib=/usr/lib/perl5/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/vendor_perl \
        -Dsitelib=/usr/lib/perl5/site_perl \
        -Dsitearch=/usr/lib/perl5/site_perl \
        -Duseshrplib \
        -Dusethreads \
        -Ud_getpwent_r \
        -Ud_getgrent_r \
        -Ud_getprotoent_r \
        -Ud_getprotobynumber_r \
        -Ud_getprotobyname_r \
        -Ud_getservent_r \
        -Ud_getservbyname_r \
        -Ud_getservbyport_r \
        -Ud_getspnam_r \
        -Ud_getnetbyname_r \
        -Ud_getnetbyaddr_r \
        -Ud_getnetent_r \
        -Ud_gethostbyname_r \
        -Ud_gethostbyaddr_r \
        -Ud_gethostent_r
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    find "$DESTDIR" -name "*.so" -exec chmod 755 {} +
