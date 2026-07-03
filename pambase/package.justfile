build:

package:
    install -vDm 644 system-auth "$DESTDIR/etc/pam.d/system-auth"
    install -vDm 644 system-login "$DESTDIR/etc/pam.d/system-login"
    install -vDm 644 other "$DESTDIR/etc/pam.d/other"
    install -vDm 644 system-local-login "$DESTDIR/etc/pam.d/system-local-login"
    install -vDm 644 system-remote-login "$DESTDIR/etc/pam.d/system-remote-login"
    install -vDm 644 system-services "$DESTDIR/etc/pam.d/system-services"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -exec chmod 644 {} +
