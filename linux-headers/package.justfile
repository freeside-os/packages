build:
    tar -xf linux-$PKG_VERSION.tar.xz
    cd linux-$PKG_VERSION && make mrproper
    cd linux-$PKG_VERSION && make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/tmp/headers-out

package:
    mkdir -p "$DESTDIR/usr/include"
    cp -a /tmp/headers-out/include/* "$DESTDIR/usr/include/"
    # Remove internal kernel files not meant for userspace
    find "$DESTDIR/usr/include" -name ".install" -o -name "..install.cmd" | xargs rm -f
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/include" -type f -exec chmod 644 {} +
