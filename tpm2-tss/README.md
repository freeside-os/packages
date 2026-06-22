# tpm2-tss

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | tpm2-tss |
| **Version** | 4.1.3 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/tpm2-tss/-/raw/main/PKGBUILD |
| **Source URL** | git+https://github.com/tpm2-software/tpm2-tss?signed#tag=4.1.3 |
| **Source Checksum (SHA256)** |  |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->

- Switched source from `git+https` to upstream tarball because the downloader does not support git URLs directly.
- Added `json-c` as a required dependency which wasn't previously imported.
- Applied a workaround to provide dummy `useradd` and `groupadd` scripts in the `PATH` since configure script rigidly requires them, though we do not want to manipulate host groups during containerized build phases.
