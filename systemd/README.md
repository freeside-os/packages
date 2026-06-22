# Systemd Package for Freeside Linux

This directory contains the Freeside Linux packaging files for compiling `systemd` (version 255) using a pure LLVM/Musl toolchain.

## Musl Compatibility Patches

Because `systemd` has historically been tightly coupled with GNU libc (glibc) extensions and behaviors, compiling it against Musl libc requires a series of targeted compatibility overrides. These overrides are maintained as patch files in this directory:

### [0004-add-fallback-parse_printf_format-implementation.patch](file:///home/dq/Code/freeside/packages/systemd/0004-add-fallback-parse_printf_format-implementation.patch)
* **Description:** Injects a fallback implementation of `parse_printf_format()`.
* **Reason:** Glibc's `<printf.h>` contains the `parse_printf_format()` API, which is missing from Musl libc.

### [0005-musl-compat.patch](file:///home/dq/Code/freeside/packages/systemd/0005-musl-compat.patch)
This is a unified patch containing several critical compatibility workarounds across the codebase:
* **`strerror_r` signature difference (`src/basic/errno-util.h`):** Musl uses the POSIX-compliant `int strerror_r(...)` returning an integer, while glibc implements a GNU-specific `char *strerror_r(...)`. We wrap the call to convert the output to a safe `char *`.
* **`comparison_fn_t` definition (`src/basic/sort-util.h`):** Defines the GNU-specific comparison function type `comparison_fn_t` if the header guard macro `__comparison_fn_t_defined` is missing.
* **`struct ethhdr` redefinition (`src/basic/linux/if_ether.h`):** Uses macro guards to suppress the duplicate definition of `struct ethhdr` between userspace networking headers (`<netinet/if_ether.h>`) and Linux kernel UAPI headers (`<linux/if_ether.h>`).
* **`struct prctl_mm_map` redefinition (`src/basic/missing_prctl.h`):** Wraps `<linux/prctl.h>` with a temporary preprocessor rename of `prctl_mm_map` to prevent collisions with the Musl definition in `<sys/prctl.h>`.
* **GNU `glob` extensions (`src/basic/glob-util.h` / `src/basic/glob-util.c`):** Musl does not implement `GLOB_ALTDIRFUNC` or `GLOB_BRACE`. We define these to `0` and conditionally disable the custom directory-reading hook wrappers if `GLOB_ALTDIRFUNC` is not supported.
* **`NI_IDN` flag support (`src/basic/socket-util.c`):** Musl does not support Internationalized Domain Names (IDN) in `getnameinfo`. We guard `NI_IDN` so it resolves to `0` on Musl.
* **`strdupa` and `strndupa` (`src/basic/alloc-util.h`):** Maps the GNU-specific stack-allocating string copy functions to systemd's built-in, safer fallbacks (`strdupa_safe`/`strndupa_safe`).
* **GNU `basename` wrapper (`src/basic/macro.h`):** Injects a GNU-compatible fallback macro/inline for `basename()` which does not modify the input string.
* **`malloc_trim` fallback (`src/basic/macro.h`):** Stubs out the glibc-specific `malloc_trim()` function to return 0 on Musl.
* **`malloc_info` fallback (`src/basic/macro.h`):** Stubs out the glibc-specific `malloc_info()` function to return -1 and set `errno = EOPNOTSUPP` on Musl.
* **`strptime_l` fallback (`src/basic/macro.h`):** Defines a lightweight macro for the glibc-specific `strptime_l()` function to delegate to the standard POSIX `strptime()` function on Musl, discarding the locale argument.
* **BSD flock macros (`src/basic/lock-util.h`):** Explicitly includes `<sys/file.h>` to expose `LOCK_EX` / `LOCK_SH` BSD locking operation definitions to file consumers (since Musl's `<fcntl.h>` doesn't pull it in automatically).
* **`struct ethhdr` definition / wrapper (`src/basic/linux/if_ether.h`):** Pre-includes `<netinet/if_ether.h>` under Musl to ensure `struct ethhdr` is fully defined, and wraps the inclusion by temporarily saving, undefining, and restoring the `arpreq`, `arpreq_old`, and `arphdr` macros to prevent field type mismatch/incomplete type errors in Musl's `<netinet/if_ether.h>`.
* **`linux/if_arp.h` wrapper (`src/basic/linux/if_arp.h`):** Intercepts `<linux/if_arp.h>` to pre-include `<netinet/if_ether.h>` and `<net/if_arp.h>` under Musl, and defines temporary macro renames for `arpreq`, `arpreq_old`, and `arphdr` during the kernel header parsing to prevent conflicts and redefinition errors.
* **NSS group compatibility / gshadow fallback (`src/shared/user-record-nss.h` / `src/shared/user-record-nss.c`):** Guards `<gshadow.h>` and `getsgnam_r` with `#if ENABLE_GSHADOW` and defines a fallback stub structure `struct sgrp` to allow NSS user database code to compile successfully on Musl where `gshadow` is missing.
* **utmp/wtmp stub fallbacks (`src/basic/macro.h`):** Defuses compilation errors in `wall.c` and `utmp-wtmp.c` under Musl by defining missing `_PATH_UTMPX` / `_PATH_WTMPX` macros (since Musl declares `utmpxname` and `updwtmpx` in `<utmpx.h>` but lacks the standard path macros).
* **Linux UAPI/libc compatibility headers (`src/basic/linux/libc-compat.h`, `in.h`, `in6.h`):** Coordinates definitions between Musl's `<netinet/in.h>` / `<net/if.h>` and the kernel's `<linux/in6.h>` / `<linux/if.h>` by setting UAPI def guards to `0` when the corresponding libc headers are already included. Pre-includes userspace `<netinet/in.h>` inside the local `linux/in.h` and `linux/in6.h` wrappers to ensure the libc definitions take precedence and avoid redefinition or `struct __in6_union` mismatch errors on Musl.

## Iterative Patch Debugging (Incremental Builds)

By default, the package manager cleans up the package workspace directory after a successful build or before starting a new build. To keep the workspace directory and compiled objects for faster iterative debugging, run `just` with the `keep_sandbox=true` override:

```bash
just keep_sandbox=true build systemd
```

This preserves `build/workspace/systemd-<version>` on the host, meaning you can edit files inside the workspace directly and recompilation will run incrementally, only building the modified files rather than re-extracting and compiling everything from scratch.

---

## Instructions for Future Updates

When upgrading the `systemd` package to a new version, follow these steps to rebase the compatibility patches:

### 1. Extract the Original Sources
Extract the clean source tarball for the target systemd version:
```bash
mkdir -p /tmp/systemd-original
tar -xf build/workspace/systemd-<version>/src/v<version>.tar.gz -C /tmp/systemd-original --strip-components=1
```

### 2. Prepare the Modified Workspace
Copy the clean sources to a separate directory where you will apply the patches:
```bash
cp -r /tmp/systemd-original /tmp/systemd-modified
cd /tmp/systemd-modified
```

### 3. Apply and Rebase the Patches
Apply the existing patches manually or using `patch -p1`:
```bash
patch -p1 < /home/dq/Code/freeside/packages/systemd/0004-add-fallback-parse_printf_format-implementation.patch
patch -p1 < /home/dq/Code/freeside/packages/systemd/0005-musl-compat.patch
```
If any patch rejects occur, resolve the conflicts in the modified files.

### 4. Re-generate the Patches
Once the code compiles successfully inside the sandbox, generate a new unified diff:
```bash
diff -Naur /tmp/systemd-original/src/ /tmp/systemd-modified/src/ > /home/dq/Code/freeside/packages/systemd/0005-musl-compat.patch
```

### 5. Update Manifest Checksums
Calculate the new SHA256 checksum of your updated patch file:
```bash
sha256sum packages/systemd/0005-musl-compat.patch
```
Update the `checksum` block for the patch inside [package.manifest](file:///home/dq/Code/freeside/packages/systemd/package.manifest).

### 6. Referencing Other Distributions' Patches
If you encounter complex compilation or linking issues that are difficult to resolve from scratch, check how other Musl-based distributions/layers patch systemd:
* **OpenEmbedded-Core (Yocto):** Browse the patches under `meta/recipes-core/systemd/systemd/` in the [OpenEmbedded-Core Layer](https://git.openembedded.org/openembedded-core/). They have a long history of maintaining systemd-musl compatibility patches.
* **Gentoo Linux (Musl Profile):** Check the Gentoo ebuild repository's systemd patchsets for the musl profile.
