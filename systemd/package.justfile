build:
    tar -xf v255.tar.gz
    cd systemd-255 && meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault-dnssec=no \
        -Dfirstboot=false \
        -Dinstall-tests=false \
        -Dldconfig=false \
        -Dsysusers=false \
        -Drpmmacrosdir=no \
        -Dhomed=disabled \
        -Dman=disabled \
        -Dmode=release \
        -Dpamconfdir=no \
        -Ddev-kvm-mode=0660 \
        -Dnobody-group=nogroup \
        -Dsysupdate=disabled \
        -Dukify=disabled
    cd systemd-255 && meson compile -C build -j$(nproc)

package destdir:
    cd systemd-255 && meson install -C build --destdir "{{destdir}}"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
