# xorriso

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | xorriso |
| **Version** | 1.5.6.pl02 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/xorriso/-/raw/main/PKGBUILD |
| **Source URL** | https://ftp.gnu.org/gnu/xorriso/xorriso-1.5.6.pl02.tar.gz |
| **Source Checksum (SHA256)** | 786f9f5df9865cc5b0c1fecee3d2c0f5e04cab8c9a859bd1c9c7ccd4964fdae1 |

## Upgrade Notes
- Compiled successfully with standard musl and UsrMerge configurations.
- Fixed an issue in `package.justfile` where `cd xorriso-*` threw a "too many arguments" error by modifying the wildcard reference to `cd xorriso-*/`.
