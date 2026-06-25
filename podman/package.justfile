build:
    curl -sLO https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
    tar -xf go1.22.4.linux-amd64.tar.gz
    tar -xf v$PKG_VERSION.tar.gz || tar -xf $PKG_VERSION.tar.gz || tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    cd $PKG_NAME-$PKG_VERSION && PATH="$PWD/../go/bin:$PATH" make BUILDTAGS="containers_image_openpgp exclude_graphdriver_btrfs exclude_graphdriver_devicemapper" binaries

package:
    cd $PKG_NAME-$PKG_VERSION && PATH="$PWD/../go/bin:$PATH" make DESTDIR="$DESTDIR" PREFIX="/usr" BINDIR="/usr/bin" SBINDIR="/usr/bin" ETCDIR="/etc" install.bin
    if [ -d "$DESTDIR/usr/sbin" ]; then \
        mkdir -p "$DESTDIR/usr/bin"; \
        mv "$DESTDIR/usr/sbin"/* "$DESTDIR/usr/bin/" || true; \
        rmdir "$DESTDIR/usr/sbin" || true; \
    fi
    if [ -d "$DESTDIR/sbin" ]; then \
        mkdir -p "$DESTDIR/usr/bin"; \
        mv "$DESTDIR/sbin"/* "$DESTDIR/usr/bin/" || true; \
        rmdir "$DESTDIR/sbin" || true; \
    fi
    if [ -d "$DESTDIR/bin" ]; then \
        mkdir -p "$DESTDIR/usr/bin"; \
        mv "$DESTDIR/bin"/* "$DESTDIR/usr/bin/" || true; \
        rmdir "$DESTDIR/bin" || true; \
    fi
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/libexec" ]; then find "$DESTDIR/usr/libexec" -type f -exec chmod 755 {} +; fi
    find "$DESTDIR" -name "*.so*" -exec chmod 755 {} + || true
