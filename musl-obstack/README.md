# musl-obstack

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | musl-obstack |
| **Version** | 1.1 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/musl-obstack/-/raw/main/PKGBUILD |
| **Source URL** | https://github.com/pullmoll/musl-obstack/archive/v1.1.tar.gz |
| **Source Checksum (SHA256)** | 52a216613e7d55e8725e43d017bb2d49a4b1ffa1e06da472f03c7f9875df7d0d |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Added `group = "base"` to `package.manifest`.
- Removed reliance on autotools (`autoconf`, `automake`, `libtool`, etc.) as the bootstrap script was failing without them being present in the workspace. Instead, directly compile the library components (`obstack.c`, `obstack_printf.c`) into static (`libobstack.a`) and shared (`libobstack.so`) libraries, mirroring `musl-fts` build strategies.
- Manually generated and installed the `musl-obstack.pc` pkg-config file during packaging.
- Injected `-Wno-implicit-function-declaration` into CFLAGS to prevent build errors on modern GCC (`abort` and `exit` missing `<stdlib.h>` includes).