# dbus-broker package build recipe

# Prepare: Unpack source structures and apply local patches
prepare:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz --strip-components=1
    # Apply custom patches for musl compliance if located in files/
    if [ -d files/patches ]; then \
        for patch in files/patches/*.patch; do \
            patch -p1 < "$patch"; \
        done; \
    fi

# Build: Compile source trees within the LLVM compiler configuration context
build: prepare
    meson setup builddir \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        -Dlauncher=true \
        -Daudit=false
    ninja -C builddir

# Package: Mirror target files securely inside the un-merged /usr tree under DESTDIR
package destdir=env_var("DESTDIR"):
    #!/usr/bin/env bash
    set -e
    DESTDIR={{destdir}} ninja -C builddir install
    # Enforce Un-Merged /usr compliance post-install
    if [ -d {{destdir}}/bin ]; then mv {{destdir}}/bin/* {{destdir}}/usr/bin/ && rmdir {{destdir}}/bin; fi
    if [ -d {{destdir}}/lib ]; then mv {{destdir}}/lib/* {{destdir}}/usr/lib/ && rmdir {{destdir}}/lib; fi
    # Enforce strict standard permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/lib" ]; then find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi

    # dbus-broker upstream does not ship systemd unit files — distributions
    # are expected to provide their own. Create the socket, service alias,
    # and vendor enablement symlink.
    mkdir -p "{{destdir}}/usr/lib/systemd/system"

    # System bus socket unit
    printf '%s\n' \
        '[Unit]' \
        'Description=D-Bus System Message Bus Socket' \
        '' \
        '[Socket]' \
        'ListenStream=/run/dbus/system_bus_socket' \
        'SocketMode=0666' \
        '' \
        '[Install]' \
        'WantedBy=sockets.target' \
        > "{{destdir}}/usr/lib/systemd/system/dbus.socket"

    # Alias dbus.service -> dbus-broker.service
    ln -sf dbus-broker.service "{{destdir}}/usr/lib/systemd/system/dbus.service"

    # Enable dbus.socket by default (vendor preset)
    mkdir -p "{{destdir}}/usr/lib/systemd/system/sockets.target.wants"
    ln -sf ../dbus.socket "{{destdir}}/usr/lib/systemd/system/sockets.target.wants/dbus.socket"

    # User bus socket unit
    mkdir -p "{{destdir}}/usr/lib/systemd/user"
    printf '%s\n' \
        '[Unit]' \
        'Description=D-Bus User Message Bus Socket' \
        '' \
        '[Socket]' \
        'ListenStream=%t/bus' \
        'ExecStartPost=-/usr/bin/systemctl --user set-environment DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus' \
        '' \
        '[Install]' \
        'WantedBy=sockets.target' \
        > "{{destdir}}/usr/lib/systemd/user/dbus.socket"

    # Alias user dbus.service -> dbus-broker.service
    ln -sf dbus-broker.service "{{destdir}}/usr/lib/systemd/user/dbus.service"

    # Install D-Bus bus configuration files (required by dbus-broker-launch)
    # dbus-broker reads the standard dbus config format but does not ship
    # its own config files — they normally come from the dbus reference package.
    mkdir -p "{{destdir}}/usr/share/dbus-1"
    cp system.conf "{{destdir}}/usr/share/dbus-1/system.conf"
    cp session.conf "{{destdir}}/usr/share/dbus-1/session.conf"

    # Remove --audit flag from service file (audit disabled at compile time)
    sed -i 's/ --audit//' "{{destdir}}/usr/lib/systemd/system/dbus-broker.service"

    # Install sysusers.d config so the 'dbus' system user is created
    mkdir -p "{{destdir}}/usr/lib/sysusers.d"
    cp dbus-broker.sysusers "{{destdir}}/usr/lib/sysusers.d/dbus-broker.conf"