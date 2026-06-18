build:
    echo "No compilation required — certificate bundle is pre-built."

package destdir:
    mkdir -p "{{destdir}}/usr/share/ca-certificates"
    mkdir -p "{{destdir}}/etc/ssl/certs"
    cp cacert-2024-07-02.pem "{{destdir}}/usr/share/ca-certificates/ca-certificates.crt"
    ln -sf /usr/share/ca-certificates/ca-certificates.crt "{{destdir}}/etc/ssl/certs/ca-certificates.crt"
    chmod 644 "{{destdir}}/usr/share/ca-certificates/ca-certificates.crt"
    find "{{destdir}}" -type d -exec chmod 755 {} +
