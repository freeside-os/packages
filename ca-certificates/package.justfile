build:
    echo "No compilation required — certificate bundle is pre-built."

package:
    mkdir -p "$DESTDIR/usr/share/ca-certificates"
    mkdir -p "$DESTDIR/etc/ssl/certs"
    cp cacert-2024-07-02.pem "$DESTDIR/usr/share/ca-certificates/ca-certificates.crt"
    ln -sf /usr/share/ca-certificates/ca-certificates.crt "$DESTDIR/etc/ssl/certs/ca-certificates.crt"
    chmod 644 "$DESTDIR/usr/share/ca-certificates/ca-certificates.crt"
    find "$DESTDIR" -type d -exec chmod 755 {} +
