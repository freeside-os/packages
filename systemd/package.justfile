# systemd package build recipe

prepare:
    #!/usr/bin/env bash
    set -e
    find . -mindepth 1 -maxdepth 1 ! -name 'package.manifest' ! -name 'package.justfile' ! -name '*.patch' ! -name '*.tar.gz' -exec rm -rf {} + || true
    tar -xf v$PKG_VERSION.tar.gz --strip-components=1
    
    awk '/^\+\+\+ b\/src\/basic\/parse-printf-format.c/{flag=1; next} /^\+/{if(flag) print substr($0,2)} /^diff --git/{flag=0}' 0004-add-fallback-parse_printf_format-implementation.patch > src/basic/parse-printf-format.c
    awk '/^\+\+\+ b\/src\/basic\/parse-printf-format.h/{flag=1; next} /^\+/{if(flag) print substr($0,2)} /^diff --git/{flag=0}' 0004-add-fallback-parse_printf_format-implementation.patch > src/basic/parse-printf-format.h
    
    sed -i 's/#include "config.h"//' src/basic/parse-printf-format.h || true
    sed -i 's/#if HAVE_PRINTF_H/#if defined(HAVE_PRINTF_H) \&\& HAVE_PRINTF_H/' src/basic/parse-printf-format.h || true
    
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/basic/stdio-util.h || true
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/libsystemd/sd-journal/journal-send.c || true
    sed -i 's/#include <printf.h>/#include "parse-printf-format.h"/' src/test/test-printf.c || true
    sed -i "s/error('Unknown filesystems defined/message('WARNING: Unknown filesystems defined/" src/basic/meson.build || true

    # Fix musl redefinition errors by forcing __UAPI_DEF_ETHHDR to 0 and similar in uapi
    find src -name "libc-compat.h" -exec sed -i 's/#define __UAPI_DEF_ETHHDR\s\+1/#define __UAPI_DEF_ETHHDR 0/g' {} + || true
    find src -name "libc-compat.h" -exec sed -i 's/#define __UAPI_DEF_IP6_MTUINFO\s\+1/#define __UAPI_DEF_IP6_MTUINFO 0/g' {} + || true
    find src -name "if_ether.h" -exec sed -i 's/struct ethhdr {/struct ethhdr_disabled {/g' {} + || true

    # Fix glob_t designated initializers not available on musl
    sed -i '/\.gl_closedir =/d' src/basic/glob-util.c || true
    sed -i '/\.gl_readdir =/d' src/basic/glob-util.c || true
    sed -i '/\.gl_opendir =/d' src/basic/glob-util.c || true
    sed -i '/\.gl_lstat =/d' src/basic/glob-util.c || true
    sed -i '/\.gl_stat =/d' src/basic/glob-util.c || true

    # Fix missing_prctl.h struct redeclaration with musl sys/prctl.h
    sed -i 's|#include <linux/prctl.h>|#define prctl_mm_map __kernel_prctl_mm_map\n#include <linux/prctl.h>\n#undef prctl_mm_map|' src/basic/missing_prctl.h || true

    # Add missing gnu/libc-version.h for musl
    mkdir -p src/include/override/gnu
    cat << 'EOF' > src/include/override/gnu/libc-version.h
    #ifndef _GNU_LIBC_VERSION_H
    #define _GNU_LIBC_VERSION_H
    static inline const char *gnu_get_libc_version(void) { return "musl"; }
    static inline const char *gnu_get_libc_release(void) { return "1.2.5"; }
    #endif
    EOF

    # Add missing gshadow.h for musl
    cat << 'EOF' > src/include/override/gshadow.h
    #ifndef _GSHADOW_H
    #define _GSHADOW_H
    struct sgrp {
        char *sg_namp;
        char *sg_passwd;
        char **sg_adm;
        char **sg_mem;
    };
    static inline int sgetsgent_r(const char *string, struct sgrp *sgrp, char *buf, size_t buflen, struct sgrp **res) { *res = NULL; return -1; }
    static inline int getsgnam_r(const char *name, struct sgrp *sgrp, char *buf, size_t buflen, struct sgrp **res) { *res = NULL; return -1; }
    static inline struct sgrp *sgetsgent(const char *string) { return NULL; }
    static inline struct sgrp *getsgent(void) { return NULL; }
    static inline void setsgent(void) {}
    static inline void endsgent(void) {}
    #endif
    EOF

    cat << 'EOF' >> src/basic/log.c
    #include "parse-printf-format.c"
    #include <ucontext.h>
    int getcontext(ucontext_t *ucp);
    void makecontext(ucontext_t *ucp, void (*func)(void), int argc, ...);
    int swapcontext(ucontext_t *oucp, const ucontext_t *ucp);

    int getcontext(ucontext_t *ucp) { return -1; }
    void makecontext(ucontext_t *ucp, void (*func)(void), int argc, ...) {}
    int swapcontext(ucontext_t *oucp, const ucontext_t *ucp) { return -1; }
    EOF

    # Mock ukify dependency for generating hwids
    cat << 'EOF' > src/boot/generate-hwids-section.py
    #!/usr/bin/env python3
    import sys
    print('''/* SPDX-License-Identifier: LGPL-2.1-or-later */
    #include <stddef.h>
    #include <stdint.h>
    const uint8_t hwids_section_data[] = { 0 };
    const size_t hwids_section_len = 0;
    ''')
    EOF
    chmod +x src/boot/generate-hwids-section.py

build: prepare
    #!/usr/bin/env bash
    set -e
    meson setup build \
        --prefix=/usr \
        --sbindir=bin \
        --libdir=lib \
        --buildtype=release \
        -Dgshadow=false \
        -Ddefault-dnssec=no \
        -Dfirstboot=true \
        -Dinstall-tests=false \
        -Dldconfig=false \
        -Dsysusers=true \
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
        -Dsbat-distro-url="https://github.com/freeside-os" \
        -Doomd=false \
        -Defi=true \
        -Db_lto=false
    
    cat << 'EOF' >> build/config.h
    #if !defined(__GLIBC__)
    #include <stddef.h>
    #include <sys/types.h>
    #include <netinet/in.h>
    #include <net/ethernet.h>
    #include <netinet/if_ether.h>
    #include <sys/socket.h>
    #include <unistd.h>
    #include <sys/syscall.h>
    #include <sys/file.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    struct mallinfo2 { size_t arena; size_t ordblks; size_t smblks; size_t hblks; size_t hblkhd; size_t usmblks; size_t fsmblks; size_t uordblks; size_t fordblks; size_t keepcost; };
    static inline struct mallinfo2 mallinfo2(void) { struct mallinfo2 m = {0}; return m; }
    static inline int malloc_trim(size_t pad) { return 0; }
    static inline int malloc_info(int options, FILE *stream) { return -1; }
    
    static inline char *safe_strerror_r_fallback(int errnum, char *buf, size_t buflen) {
        strerror_r(errnum, buf, buflen);
        return buf;
    }
    #define strerror_r(errnum, buf, buflen) safe_strerror_r_fallback(errnum, buf, buflen)
    
    #define __UAPI_DEF_ETHHDR 0
    #define __UAPI_DEF_IN_ADDR 0
    #define __UAPI_DEF_IN_IPPROTO 0
    #define __UAPI_DEF_IN_PKTINFO 0
    #define __UAPI_DEF_IP_MREQ 0
    #define __UAPI_DEF_SOCKADDR_IN 0
    #define __UAPI_DEF_IN_CLASS 0
    #define __UAPI_DEF_IN6_ADDR 0
    #define __UAPI_DEF_IN6_ADDR_ALT 0
    #define __UAPI_DEF_SOCKADDR_IN6 0
    #define __UAPI_DEF_IPV6_MREQ 0
    #define __UAPI_DEF_IPPROTO_V6 0
    #define __UAPI_DEF_IPV6_OPTIONS 0
    #define __UAPI_DEF_IN6_PKTINFO 0
    #define __UAPI_DEF_IP6_MTUINFO 0
    
    #ifndef STATX_MNT_ID
    #define STATX_MNT_ID 0x00001000U
    #endif
    #ifndef STATX_MNT_ID_UNIQUE
    #define STATX_MNT_ID_UNIQUE 0x00004000U
    #endif
    #ifndef STATX_ATTR_MOUNT_ROOT
    #define STATX_ATTR_MOUNT_ROOT 0x00002000U
    #endif

    #ifndef STATX_ATTR_APPEND
    #define STATX_ATTR_APPEND 0x00000020U
    #endif
    #ifndef STATX_ATTR_AUTOMOUNT
    #define STATX_ATTR_AUTOMOUNT 0x00001000U
    #endif
    #ifndef STATX_ATTR_COMPRESSED
    #define STATX_ATTR_COMPRESSED 0x00000004U
    #endif
    #ifndef STATX_ATTR_DAX
    #define STATX_ATTR_DAX 0x00200000U
    #endif
    #ifndef STATX_ATTR_ENCRYPTED
    #define STATX_ATTR_ENCRYPTED 0x00000800U
    #endif
    #ifndef STATX_ATTR_IMMUTABLE
    #define STATX_ATTR_IMMUTABLE 0x00000010U
    #endif
    #ifndef STATX_ATTR_NODUMP
    #define STATX_ATTR_NODUMP 0x00000040U
    #endif
    #ifndef STATX_ATTR_VERITY
    #define STATX_ATTR_VERITY 0x00100000U
    #endif
    #ifndef STATX_ATTR_WRITE_ATOMIC
    #define STATX_ATTR_WRITE_ATOMIC 0x00400000U
    #endif

    #ifndef STATX_DIOALIGN
    #define STATX_DIOALIGN 0x00002000U
    #endif
    #ifndef STATX_DIO_READ_ALIGN
    #define STATX_DIO_READ_ALIGN 0x00020000U
    #endif
    #ifndef STATX_SUBVOL
    #define STATX_SUBVOL 0x00008000U
    #endif
    #ifndef STATX_WRITE_ATOMIC
    #define STATX_WRITE_ATOMIC 0x00010000U
    #endif



    #ifndef ILL_BADIADDR
    #define ILL_BADIADDR 9
    #endif
    #ifndef FPE_FLTUNK
    #define FPE_FLTUNK 14
    #endif
    #ifndef FPE_CONDTRAP
    #define FPE_CONDTRAP 15
    #endif
    #ifndef SEGV_ACCADI
    #define SEGV_ACCADI 5
    #endif
    #ifndef SEGV_ADIDERR
    #define SEGV_ADIDERR 6
    #endif
    #ifndef SEGV_ADIPERR
    #define SEGV_ADIPERR 7
    #endif

    #ifndef PR_SET_MEMORY_MERGE
    #define PR_SET_MEMORY_MERGE 67
    #endif
    #ifndef PR_GET_MEMORY_MERGE
    #define PR_GET_MEMORY_MERGE 68
    #endif
    #ifndef PR_THP_DISABLE_EXCEPT_ADVISED
    #define PR_THP_DISABLE_EXCEPT_ADVISED 2
    #endif

    /* musl 1.2.6 does not provide a close_range() libc wrapper, invoke the kernel syscall directly */
    static inline int close_range(unsigned int first, unsigned int last, unsigned int flags) {
        return syscall(SYS_close_range, first, last, flags);
    }

    #ifndef GLOB_BRACE
    #define GLOB_BRACE 0
    #endif
    #ifndef GLOB_ALTDIRFUNC
    #define GLOB_ALTDIRFUNC 0
    #endif

    #ifndef strdupa
    #define strdupa(s) ({ const char *__in = (s); size_t __len = strlen(__in) + 1; char *__out = (char *)alloca(__len); (char *)memcpy(__out, __in, __len); })
    #endif
    #ifndef strndupa
    #define strndupa(s, n) ({ const char *__in = (s); size_t __len = strnlen(__in, (n)); char *__out = (char *)alloca(__len + 1); __out[__len] = '\0'; (char *)memcpy(__out, __in, __len); })
    #endif

    #ifndef strptime_l
    #define strptime_l(s, fmt, tm, loc) strptime(s, fmt, tm)
    #endif

    #undef basename
    static inline char *safe_basename(const char *path) {
        if (!path) return NULL;
        const char *p = strrchr(path, '/');
        return (char *)(p ? p + 1 : path);
    }
    #define basename(path) safe_basename(path)

    #ifndef _PATH_UTMPX
    #define _PATH_UTMPX "/var/run/utmp"
    #endif
    #ifndef _PATH_WTMPX
    #define _PATH_WTMPX "/var/log/wtmp"
    #endif
    #ifndef UTMPX_FILE
    #define UTMPX_FILE _PATH_UTMPX
    #endif
    #ifndef WTMPX_FILE
    #define WTMPX_FILE _PATH_WTMPX
    #endif

    #ifndef NI_IDN
    #define NI_IDN 0
    #endif

    #ifndef __comparison_fn_t_defined
    typedef int (*comparison_fn_t)(const void *, const void *);
    #define __comparison_fn_t_defined 1
    #endif

    typedef unsigned long __cpu_mask;
    
    #ifndef FTW_CONTINUE
    #define FTW_CONTINUE 0
    #endif
    
    #ifndef ACCOUNTING
    #define ACCOUNTING 9
    #endif
    
    #endif
    EOF
    
    python3 -c "import os; [open(os.path.join(dp, f), 'a').write('\n#ifndef __DEFINED_wchar_t\ntypedef unsigned short wchar_t;\n#define __DEFINED_wchar_t\n#endif\n') for dp, dn, fn in os.walk('.') for f in fn if 'efi-config.h' in f]" || true
    
    meson compile -C build -j$(nproc)

package destdir=env_var("DESTDIR"):
    #!/usr/bin/env bash
    set -e
    export DESTDIR="{{destdir}}"
    meson install -C build --destdir "$DESTDIR"
    if [ -d "$DESTDIR/bin" ] && [ -n "$(ls -A "$DESTDIR/bin" 2>/dev/null)" ]; then mkdir -p "$DESTDIR/usr/bin" && cp -a "$DESTDIR/bin/". "$DESTDIR/usr/bin/" && rm -rf "$DESTDIR/bin"; fi
    if [ -d "$DESTDIR/sbin" ] && [ -n "$(ls -A "$DESTDIR/sbin" 2>/dev/null)" ]; then mkdir -p "$DESTDIR/usr/bin" && cp -a "$DESTDIR/sbin/". "$DESTDIR/usr/bin/" && rm -rf "$DESTDIR/sbin"; fi
    if [ -d "$DESTDIR/usr/sbin" ] && [ -n "$(ls -A "$DESTDIR/usr/sbin" 2>/dev/null)" ]; then mkdir -p "$DESTDIR/usr/bin" && cp -a "$DESTDIR/usr/sbin/". "$DESTDIR/usr/bin/" && rm -rf "$DESTDIR/usr/sbin"; fi
    if [ -d "$DESTDIR/lib" ] && [ -n "$(ls -A "$DESTDIR/lib" 2>/dev/null)" ]; then mkdir -p "$DESTDIR/usr/lib" && cp -a "$DESTDIR/lib/". "$DESTDIR/usr/lib/" && rm -rf "$DESTDIR/lib"; fi
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f \( -name "*.so*" -o -perm -111 \) -exec chmod 755 {} + || true