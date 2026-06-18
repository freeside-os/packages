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
        -Dusethreads
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    find "{{destdir}}" -name "*.so" -exec chmod 755 {} +
