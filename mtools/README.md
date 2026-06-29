# mtools

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | mtools |
| **Version** | 4.0.49 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/mtools/-/raw/main/PKGBUILD |
| **Source URL** | https://ftp.gnu.org/gnu/mtools/mtools-4.0.49.tar.bz2 |
| **Source Checksum (SHA256)** | 6fe5193583d6e7c59da75e63d7234f76c0b07caf33b103894f46f66a871ffc9f |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Built successfully against `musl` libc.
- Configured with `--without-x` to ensure a minimal, highly compatible Musl-compliant build without X11 dependencies.
- Enforced strict permissions across installed binaries in `/usr/bin`.