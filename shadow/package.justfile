build:
    tar -xf v$PKG_VERSION.tar.gz
    cd shadow-$PKG_VERSION && cargo build --release

package:
    cd shadow-$PKG_VERSION && make install DESTDIR="$DESTDIR" PREFIX="/usr" sbindir="/usr/bin" SBINDIR="/usr/bin"
    if [ -d "$DESTDIR/usr/sbin" ]; then \
        mkdir -p "$DESTDIR/usr/bin"; \
        mv "$DESTDIR/usr/sbin"/* "$DESTDIR/usr/bin/"; \
        rmdir "$DESTDIR/usr/sbin"; \
    fi
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then \
        find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; \
    fi
