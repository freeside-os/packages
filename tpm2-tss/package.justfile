build:
    tar xzf tpm2-tss-4.1.3.tar.gz
    mkdir -p dummy-bin
    echo '#!/bin/sh' > dummy-bin/groupadd
    echo 'exit 0' >> dummy-bin/groupadd
    echo '#!/bin/sh' > dummy-bin/useradd
    echo 'exit 0' >> dummy-bin/useradd
    chmod +x dummy-bin/*
    
    cd "$PKG_NAME-4.1.3" && PATH="$PWD/../dummy-bin:$PATH" ./configure \
                --prefix=/usr \
                --sbindir=/usr/bin \
                --libdir=/usr/lib \
                --sysconfdir=/etc \
                --localstatedir=/var \
                --with-runstatedir=/run \
                --with-sysusersdir=/usr/lib/sysusers.d \
                --with-tmpfilesdir=/usr/lib/tmpfiles.d \
                --with-udevrulesprefix=60- \
                --disable-tcti-libtpms \
                --disable-tcti-spi-ltt2go \
                --disable-tcti-spi-ftdi \
                --disable-tcti-i2c-ftdi \
                --disable-defaultflags \
                --disable-weakcrypto
    cd "$PKG_NAME-4.1.3" && PATH="$PWD/../dummy-bin:$PATH" make

package:
    cd "$PKG_NAME-4.1.3" && make DESTDIR="$DESTDIR" install
    cd "$PKG_NAME-4.1.3" && install -Dm644 LICENSE -t "$DESTDIR/usr/share/licenses/$PKG_NAME"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    [ -d "$DESTDIR/usr/bin" ] && find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
    [ -d "$DESTDIR/usr/sbin" ] && find "$DESTDIR/usr/sbin" -type f -exec chmod 755 {} + || true
    [ -d "$DESTDIR/usr/libexec" ] && find "$DESTDIR/usr/libexec" -type f -exec chmod 755 {} + || true
    find "$DESTDIR" -type f -name "*.so*" -exec chmod 755 {} + || true
