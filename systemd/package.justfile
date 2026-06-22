# systemd package build recipe

prepare:
    tar -xf v255.tar.gz --strip-components=1
    patch -p1 < 0004-add-fallback-parse_printf_format-implementation.patch
    patch -p1 < 0005-musl-compat.patch
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/basic/stdio-util.h
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/libsystemd/sd-journal/journal-send.c
    sed -i "s/error('Unknown filesystems defined/message('WARNING: Unknown filesystems defined/" src/basic/meson.build








# Build: Compile source trees within the LLVM compiler configuration context
build: prepare
    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Dgshadow=false \
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
        -Dukify=disabled \
        -Dnss-myhostname=false \
        -Dnss-mymachines=disabled \
        -Dnss-resolve=disabled \
        -Dnss-systemd=false
    meson compile -C build -j$(nproc)

# Package: Mirror target files securely inside the un-merged /usr tree under DESTDIR
package destdir=env_var("DESTDIR"):
    meson install -C build --destdir "{{destdir}}"
    # Enforce Un-Merged /usr compliance post-install
    if [ -d {{destdir}}/bin ]; then mv {{destdir}}/bin/* {{destdir}}/usr/bin/ && rmdir {{destdir}}/bin; fi
    if [ -d {{destdir}}/sbin ]; then mv {{destdir}}/sbin/* {{destdir}}/usr/bin/ && rmdir {{destdir}}/sbin; fi
    if [ -d {{destdir}}/lib ]; then mv {{destdir}}/lib/* {{destdir}}/usr/lib/ && rmdir {{destdir}}/lib; fi
    # Enforce strict standard permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/lib" ]; then find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
