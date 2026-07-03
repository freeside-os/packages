# pam

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | pam |
| **Version** | 1.7.2 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/pam/-/raw/main/PKGBUILD |
| **Source URL** | https://github.com/linux-pam/linux-pam/releases/download/v1.7.2/Linux-PAM-1.7.2.tar.xz |
| **Source Checksum (SHA256)** | 3d86b6383fb5fd9eb9578d2cd47d92801191f4bf3f9bc61419bfefc8aa1e531a |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Removed invalid Meson option `-Ddoc=disabled`.
- Dropped external `pam.tmpfiles` source; the tmpfiles configuration is now dynamically generated via `echo` inside `package.justfile`.
- Implemented strict directory and executable permissions compliance in `package.justfile`, ensuring that setuid (`4755`) on `unix_chkpwd` is applied dynamically after globally setting permissions to `755`.
