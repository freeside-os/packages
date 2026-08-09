build:
    tar -xf LVM2.$PKG_VERSION.tgz
    cd LVM2.$PKG_VERSION && ./configure \
      --prefix=/usr \
      --sbindir=/usr/bin \
      --libdir=/usr/lib \
      --with-udevdir=/usr/lib/udev/rules.d \
      --with-symvers=no \
      --enable-udev_rules \
      --disable-udev_sync || exit 1
    cd LVM2.$PKG_VERSION && make device-mapper
    cd LVM2.$PKG_VERSION && make -C libdm/dm-tools device-mapper
    cd LVM2.$PKG_VERSION/libdm && find . -name "*.o" | xargs ar rcs libdevmapper.a
    cd LVM2.$PKG_VERSION && make -C udev

package:
    mkdir -p "$DESTDIR"/usr/lib "$DESTDIR"/usr/include "$DESTDIR"/usr/lib/pkgconfig "$DESTDIR"/usr/bin "$DESTDIR"/usr/lib/udev/rules.d
    
    # Install libdevmapper
    cp LVM2.$PKG_VERSION/libdm/ioctl/libdevmapper.so.1.02 "$DESTDIR"/usr/lib/
    ln -sf libdevmapper.so.1.02 "$DESTDIR"/usr/lib/libdevmapper.so.1
    ln -sf libdevmapper.so.1.02 "$DESTDIR"/usr/lib/libdevmapper.so
    cp LVM2.$PKG_VERSION/libdm/libdevmapper.a "$DESTDIR"/usr/lib/
    cp LVM2.$PKG_VERSION/libdm/libdevmapper.h "$DESTDIR"/usr/include/
    if [ -f LVM2.$PKG_VERSION/libdm/libdevmapper.pc ]; then cp LVM2.$PKG_VERSION/libdm/libdevmapper.pc "$DESTDIR"/usr/lib/pkgconfig/devmapper.pc; fi

    # Install dmsetup binary
    cp LVM2.$PKG_VERSION/libdm/dm-tools/dmsetup "$DESTDIR"/usr/bin/
    chmod 755 "$DESTDIR"/usr/bin/dmsetup

    # Install device-mapper udev rules
    for r in 10-dm.rules 13-dm-disk.rules 95-dm-notify.rules; do \
        if [ -f LVM2.$PKG_VERSION/udev/$r ]; then cp -v LVM2.$PKG_VERSION/udev/$r "$DESTDIR"/usr/lib/udev/rules.d/; fi; \
    done

    # Enforce strict permissions
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR"/usr/bin ]; then find "$DESTDIR"/usr/bin -type f -exec chmod 755 {} +; fi
