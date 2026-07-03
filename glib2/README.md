# glib2

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | glib2 |
| **Version** | 2.88.2 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/glib2/-/raw/main/PKGBUILD |
| **Source URL** | https://download.gnome.org/sources/glib/2.88/glib-2.88.2.tar.xz |
| **Source Checksum (SHA256)** | cf3f215a640c8a4257f14317586b8f1fdd25a10a93cb4bdda147c0f9ad88e74f |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Added `ca-certificates` to dependencies.
- Exported `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` in build steps to fix meson fallback subproject downloads SSL certificate verification failures.