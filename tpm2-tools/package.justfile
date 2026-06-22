build:
    tar xzf tpm2-tools-5.6.tar.gz
    cd "$PKG_NAME-5.6" && ./configure \
                --prefix=/usr \
                --sbindir=/usr/bin \
                --libdir=/usr/lib \
                --sysconfdir=/etc \
                --localstatedir=/var \
                --disable-static
    cd "$PKG_NAME-5.6" && make

package:
    cd "$PKG_NAME-5.6" && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    [ -d "$DESTDIR/usr/bin" ] && find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
    [ -d "$DESTDIR/usr/sbin" ] && find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} + || true
    [ -d "$DESTDIR/usr/libexec" ] && find "$DESTDIR/usr/libexec" -type f -exec chmod 755 {} + || true
    find "$DESTDIR" -type f -name "*.so*" -exec chmod 755 {} + || true
