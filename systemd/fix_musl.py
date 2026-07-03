import os

def rep(f, old, new):
    if not os.path.exists(f): return
    with open(f, "r") as file: s = file.read()
    if old in s:
        with open(f, "w") as file: file.write(s.replace(old, new))

rep("meson.build", "'valgrind/valgrind.h',", """'valgrind/valgrind.h',
        'printf.h',""")

rep("src/basic/meson.build", "basic_sources += generated_gperf_headers", """basic_sources += generated_gperf_headers

if conf.get('HAVE_PRINTF_H', 0) != 1
        basic_sources += [files('parse-printf-format.c')]
endif
""")

rep("src/basic/alloc-util.h", "/* Free every element of the array. */", """#ifndef strdupa
#define strdupa(s) ({const char *__old=(s); size_t __len=strlen(__old)+1; char *__new=(char*)alloca(__len); (char*)memcpy(__new, __old, __len);})
#endif
#ifndef strndupa
#define strndupa(s, n) ({const char *__old=(s); size_t __len=strnlen(__old, (n)); char *__new=(char*)alloca(__len+1); __new[__len]='\0'; (char*)memcpy(__new, __old, __len);})
#endif
/* Free every element of the array. */""")

rep("src/basic/errno-util.h", '#include "basic-forward.h"', """#include "basic-forward.h"
#if !defined(__GLIBC__)
#undef strerror_r
static inline char *safe_strerror_r(int errnum, char *buf, size_t buflen) { if (strerror_r(errnum, buf, buflen) == 0) return buf; return buf; }
#define strerror_r(errnum, buf, buflen) safe_strerror_r(errnum, buf, buflen)
#endif
""")

rep("src/basic/macro.h", "#include <sys/types.h>", """#include <sys/types.h>
#if !defined(__GLIBC__)
#include <stdio.h>
#include <time.h>
#ifndef strptime_l
#define strptime_l(s, fmt, tm, loc) strptime(s, fmt, tm)
#endif
#ifndef _PATH_UTMPX
#define _PATH_UTMPX "/var/run/utmp"
#endif
#ifndef _PATH_WTMPX
#define _PATH_WTMPX "/var/log/wtmp"
#endif
#endif
""")

rep("src/basic/missing_prctl.h", "#include <linux/prctl.h>", """#define prctl_mm_map __kernel_prctl_mm_map
#include <linux/prctl.h>
#undef prctl_mm_map""")

rep("src/basic/socket-util.c", "#if ENABLE_IDN", "#if ENABLE_IDN && defined(NI_IDN)")

rep("src/shared/user-record-nss.c", "int nss_sgrp_for_group(const struct group *grp, struct sgrp *ret_sgrp, char **ret_buffer) {", """#if ENABLE_GSHADOW
int nss_sgrp_for_group(const struct group *grp, struct sgrp *ret_sgrp, char **ret_buffer) {""")

rep("src/shared/user-record-nss.c", """        return 0;
}

int nss_group_record_by_name(""", """        return 0;
}
#else
int nss_sgrp_for_group(const struct group *grp, struct sgrp *ret_sgrp, char **ret_buffer) { return -EOPNOTSUPP; }
#endif

int nss_group_record_by_name(""")

rep("src/shared/user-record-nss.h", "#include <gshadow.h>", """#if ENABLE_GSHADOW
#include <gshadow.h>
#else
struct sgrp { char *sg_namp; char *sg_passwd; char **sg_adm; char **sg_mem; };
#endif""")

rep("src/test/test-cpu-set-util.c", "TEST(parse_cpu_set) {", """#ifndef __GLIBC__
typedef unsigned long __cpu_mask;
#endif

TEST(parse_cpu_set) {""")

rep("src/test/test-recurse-dir.c", "#include <ftw.h>", """#include <ftw.h>
#ifndef FTW_CONTINUE
#define FTW_CONTINUE 0
#endif""")

rep("src/test/test-utmp.c", "#define UTX_NAMESIZE", """#ifndef ACCOUNTING
#  define ACCOUNTING 9
#endif
#define UTX_NAMESIZE""")

rep("src/basic/sort-util.h", "#include <stdlib.h>", """#include <stdlib.h>
#ifndef __comparison_fn_t_defined
typedef int (*comparison_fn_t)(const void *, const void *);
#define __comparison_fn_t_defined 1
#endif""")

glob_c = """#if GLOB_ALTDIRFUNC
static void closedir_wrapper(void* v) { (void) closedir(v); }
#endif
int safe_glob(const char *path, int flags, glob_t *pglob) {"""
rep("src/basic/glob-util.c", "int safe_glob(const char *path, int flags, glob_t *pglob) {", glob_c)

rep("src/basic/glob-util.c", "if (!pglob->gl_closedir)", """#if GLOB_ALTDIRFUNC
        if (!pglob->gl_closedir)""")
rep("src/basic/glob-util.c", "pglob->gl_stat = stat;", """pglob->gl_stat = stat;
#endif""")

rep("src/basic/glob-util.h", "#include <stdbool.h>", """#include <stdbool.h>
#ifndef GLOB_ALTDIRFUNC
#define GLOB_ALTDIRFUNC 0
#endif
#ifndef GLOB_BRACE
#define GLOB_BRACE 0
#endif""")

rep("src/test/test-glob-util.c", "TEST(safe_glob) {", """#if GLOB_ALTDIRFUNC
static void closedir_wrapper(void* v) { (void) closedir(v); }
#endif
TEST(safe_glob) {""")

rep("src/test/test-glob-util.c", """        (void) rm_rf(template, REMOVE_ROOT|REMOVE_PHYSICAL);
}

TEST(safe_glob)""", """        (void) rm_rf(template, REMOVE_ROOT|REMOVE_PHYSICAL);
#endif
}

TEST(safe_glob)""")

rep("src/test/test-glob-util.c", "TEST(safe_glob_dot) {", """#if GLOB_ALTDIRFUNC
TEST(safe_glob_dot) {""")

arphdr_fix = """#include <net/if_arp.h>
#include <netinet/if_ether.h>
#define arphdr __kernel_arphdr
#define arpreq __kernel_arpreq
#define arpreq_old __kernel_arpreq_old
#include <linux/if_arp.h>
#undef arphdr
#undef arpreq
#undef arpreq_old
"""

for f in ["src/basic/arphrd-util.c", "src/network/networkd-link.c", "src/udev/net/link-config.c", "src/basic/linux/if_arp.h"]:
    rep(f, "#include <linux/if_arp.h>", arphdr_fix)

os.makedirs('src/include/uapi/linux', exist_ok=True)
with open('src/include/uapi/linux/if_arp.h', 'w') as f:
    f.write("""#pragma once
#if !defined(__GLIBC__)
#include <net/if_arp.h>
#include <netinet/if_ether.h>
#endif
#if defined(_NET_IF_ARP_H)
#define arpreq __kernel_arpreq
#define arpreq_old __kernel_arpreq_old
#define arphdr __kernel_arphdr
#endif
#include_next <linux/if_arp.h>
#if defined(_NET_IF_ARP_H)
#undef arpreq
#undef arpreq_old
#undef arphdr
#endif
""")

with open('src/include/uapi/linux/if_ether.h', 'w') as f:
    f.write("""#define _UAPI_LINUX_IF_ETHER_H
#if !defined(__GLIBC__)
#ifdef arpreq
#define _SAVE_ARPREQ arpreq
#undef arpreq
#endif
#ifdef arpreq_old
#define _SAVE_ARPREQ_OLD arpreq_old
#undef arpreq_old
#endif
#ifdef arphdr
#define _SAVE_ARPHDR arphdr
#undef arphdr
#endif
#include <net/if_arp.h>
#include <netinet/if_ether.h>
#ifdef _SAVE_ARPREQ
#define arpreq _SAVE_ARPREQ
#undef _SAVE_ARPREQ
#endif
#ifdef _SAVE_ARPREQ_OLD
#define arpreq_old _SAVE_ARPREQ_OLD
#undef _SAVE_ARPREQ_OLD
#endif
#ifdef _SAVE_ARPHDR
#define arphdr _SAVE_ARPHDR
#undef _SAVE_ARPHDR
#endif
#endif
#if defined(_NETINET_IF_ETHER_H) || defined(_NET_ETHERNET_H)
#define __UAPI_DEF_ETHHDR 0
#else
#define ethhdr __kernel_ethhdr
#endif
#include_next <linux/if_ether.h>
#ifdef ethhdr
#undef ethhdr
#endif
""")

with open('src/include/uapi/linux/in6.h', 'w') as f:
    f.write("""#define _UAPI_LINUX_IN6_H
#if !defined(__GLIBC__)
#include <netinet/in.h>
#endif
#include_next <linux/in6.h>
""")

with open('src/include/uapi/linux/in.h', 'w') as f:
    f.write("""#define _UAPI_LINUX_IN_H
#if !defined(__GLIBC__)
#include <netinet/in.h>
#endif
#include_next <linux/in.h>
""")

with open('src/include/uapi/linux/libc-compat.h', 'w') as f:
    f.write("""#define _UAPI_LIBC_COMPAT_H
#if !defined(__GLIBC__)
#if defined(_NETINET_IN_H)
#define __UAPI_DEF_IN_ADDR              0
#define __UAPI_DEF_IN_IPPROTO           0
#define __UAPI_DEF_IN_PKTINFO           0
#define __UAPI_DEF_IP_MREQ              0
#define __UAPI_DEF_SOCKADDR_IN          0
#define __UAPI_DEF_IN_CLASS             0
#define __UAPI_DEF_IN6_ADDR             0
#define __UAPI_DEF_IN6_ADDR_ALT         0
#define __UAPI_DEF_SOCKADDR_IN6         0
#define __UAPI_DEF_IPV6_MREQ            0
#define __UAPI_DEF_IPPROTO_V6           0
#define __UAPI_DEF_IPV6_OPTIONS         0
#define __UAPI_DEF_IN6_PKTINFO          0
#define __UAPI_DEF_IP6_MTUINFO          0
#endif
#if defined(_NET_IF_H)
#define __UAPI_DEF_IF_IFCONF 0
#define __UAPI_DEF_IF_IFMAP 0
#define __UAPI_DEF_IF_IFNAMSIZ 0
#define __UAPI_DEF_IF_IFREQ 0
#define __UAPI_DEF_IF_NET_DEVICE_FLAGS 0
#define __UAPI_DEF_IF_NET_DEVICE_FLAGS_LOWER_UP_DORMANT_ECHO 0
#endif
#endif
#include_next <linux/libc-compat.h>
""")

p = 'src/boot/efi/efi.h'
if os.path.exists(p):
    with open(p, 'r') as f: content = f.read()
    content = content.replace('typedef __WCHAR_TYPE__ wchar_t;', '#undef wchar_t\n#define wchar_t unsigned short\n#ifndef __DEFINED_wchar_t\n#define __DEFINED_wchar_t\n#endif')
    with open(p, 'w') as f: f.write(content)

p = 'tools/elf2efi.py'
if os.path.exists(p):
    with open(p, 'r') as f: content = f.read()
    content = content.replace('raise RuntimeError("Overlapping PE sections.")', 'pe_s.VirtualAddress = last_vma')
    with open(p, 'w') as f: f.write(content)
