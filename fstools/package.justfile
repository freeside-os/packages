build:
    @echo "No compilation required — using pre-built host fstools binary."

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp fstools "$DESTDIR/usr/bin/fstools"
    chmod 755 "$DESTDIR/usr/bin/fstools"
