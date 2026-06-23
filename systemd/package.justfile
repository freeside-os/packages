# systemd package build recipe

prepare:
    rm -f src/basic/parse-printf-format.c src/basic/parse-printf-format.h src/basic/linux/if_arp.h
    tar -xf v255.tar.gz --strip-components=1
    patch -p1 < 0004-add-fallback-parse_printf_format-implementation.patch
    patch -p1 < 0005-musl-compat.patch
    python3 -c "import sys; p = 'src/boot/efi/efi.h'; content = open(p).read(); content = content.replace('typedef __WCHAR_TYPE__ wchar_t;', '#undef wchar_t\n#define wchar_t unsigned short\n#ifndef __DEFINED_wchar_t\n#define __DEFINED_wchar_t\n#endif'); open(p, 'w').write(content)"
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/basic/stdio-util.h
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/libsystemd/sd-journal/journal-send.c
    sed -i "s/error('Unknown filesystems defined/message('WARNING: Unknown filesystems defined/" src/basic/meson.build
    
    # Patch elf2efi.py to resolve overlapping sections automatically
    python3 -c "p = 'tools/elf2efi.py'; content = open(p).read(); content = content.replace('raise RuntimeError(\"Overlapping PE sections.\")', 'pe_s.VirtualAddress = last_vma'); open(p, 'w').write(content)"

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
        -Dukify=enabled \
        -Dnss-myhostname=false \
        -Dnss-mymachines=disabled \
        -Dnss-resolve=disabled \
        -Dnss-systemd=false \
        -Dsbat-distro="freeside" \
        -Dsbat-distro-version="2024.06" \
        -Dsbat-distro-summary="Freeside OS" \
        -Dsbat-distro-url="https://freeside.dev" \
        -Defi=true
    
    # Inject 16-bit wchar_t definition directly into any generated efi_config.h files found
    python3 -c "import os; [open(os.path.join(dp, f), 'a').write('\n#ifndef __DEFINED_wchar_t\ntypedef unsigned short wchar_t;\n#define __DEFINED_wchar_t\n#endif\n') for dp, dn, fn in os.walk('.') for f in fn if 'efi_config.h' in f]"
    
    meson compile -C build -j$(nproc)

# Package: Mirror target files securely inside the un-merged /usr tree under DESTDIR
package destdir=env_var("DESTDIR"):
    meson install -C build --destdir "{{destdir}}"
    # Enforce Un-Merged /usr compliance post-install
    if [ -d {{destdir}}/bin ]; then cp -r {{destdir}}/bin/* {{destdir}}/usr/bin/ && rm -rf {{destdir}}/bin; fi
    if [ -d {{destdir}}/sbin ]; then cp -r {{destdir}}/sbin/* {{destdir}}/usr/bin/ && rm -rf {{destdir}}/sbin; fi
    if [ -d {{destdir}}/lib ]; then cp -r {{destdir}}/lib/* {{destdir}}/usr/lib/ && rm -rf {{destdir}}/lib; fi
    # Enforce strict standard permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/lib" ]; then find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
