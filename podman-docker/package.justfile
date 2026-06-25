build:
    tar -xf v$PKG_VERSION.tar.gz || tar -xf $PKG_VERSION.tar.gz || tar -xf ${PKG_NAME%-docker}-$PKG_VERSION.tar.gz

package:
    mkdir -p "$DESTDIR/usr/bin"
    mkdir -p "$DESTDIR/etc/profile.d"
    mkdir -p "$DESTDIR/usr/lib/tmpfiles.d"

    # Generate /usr/bin/docker wrapper using envsubst
    cd ${PKG_NAME%-docker}-$PKG_VERSION && env BINDIR=/usr/bin ETCDIR=/etc envsubst '$BINDIR;$ETCDIR' < docker/docker.in > "$DESTDIR/usr/bin/docker"
    chmod 755 "$DESTDIR/usr/bin/docker"

    # Copy profile.d scripts
    cd ${PKG_NAME%-docker}-$PKG_VERSION && cp docker/podman-docker.sh "$DESTDIR/etc/profile.d/podman-docker.sh"
    cd ${PKG_NAME%-docker}-$PKG_VERSION && cp docker/podman-docker.csh "$DESTDIR/etc/profile.d/podman-docker.csh"
    chmod 644 "$DESTDIR/etc/profile.d/podman-docker.sh" "$DESTDIR/etc/profile.d/podman-docker.csh"

    # Copy tmpfiles.d config
    cd ${PKG_NAME%-docker}-$PKG_VERSION && cp contrib/systemd/system/podman-docker.conf "$DESTDIR/usr/lib/tmpfiles.d/podman-docker.conf"
    chmod 644 "$DESTDIR/usr/lib/tmpfiles.d/podman-docker.conf"

    # Ensure correct directory permissions
    find "$DESTDIR" -type d -exec chmod 755 {} +
