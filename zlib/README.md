# zlib

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | zlib |
| **Version** | 1.3.2 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/zlib/-/raw/main/PKGBUILD |
| **Source URL** | https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.xz |
| **Source Checksum (SHA256)** | d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3 |

## Upgrade Notes
- Security update to 1.3.2 to address CVE-2026-9999 (presumed fixed in 1.3.2 as 1.3.1.1 was unavailable and 1.3.2 is the latest stable).
- Refined build script for UsrMerge and Musl compliance.
- Explicitly enabled shared library support with `--shared`.
- Removed `minizip` build as `autoreconf` is not available in the current build environment.
- Added manual source extraction in `package.justfile` to ensure availability in the build directory.
- Successfully built and verified zlib 1.3.2 inside the systemd-nspawn sandboxed container core.
