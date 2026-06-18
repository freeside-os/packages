build:
    tar -xf linux-$PKG_VERSION.tar.xz
    cd linux-$PKG_VERSION && make mrproper
    cd linux-$PKG_VERSION && make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/tmp/headers-out

package destdir:
    mkdir -p "{{destdir}}/usr/include"
    cp -a /tmp/headers-out/include/* "{{destdir}}/usr/include/"
    # Remove internal kernel files not meant for userspace
    find "{{destdir}}/usr/include" -name ".install" -o -name "..install.cmd" | xargs rm -f
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/include" -type f -exec chmod 644 {} +
