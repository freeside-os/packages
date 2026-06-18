build:
    tar -xf perl-5.38.2.tar.xz
    cd perl-5.38.2 && ./Configure \
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
        -Dusethreads
    cd perl-5.38.2 && make -j$(nproc)

package destdir:
    cd perl-5.38.2 && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    find "{{destdir}}" -name "*.so" -exec chmod 755 {} +
