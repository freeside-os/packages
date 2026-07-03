# procps-ng

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | procps-ng |
| **Version** | 4.0.6 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/procps-ng/-/raw/main/PKGBUILD |
| **Source URL** | https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.6.tar.xz |
| **Source Checksum (SHA256)** | 67bea6fbc3a42a535a0230c9e891e5ddfb4d9d39422d46565a2990d1ace15216 |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Switched source from the GitLab `git+https` URL to the SourceForge Production tarball release. The SourceForge release tarballs contain the pre-generated `configure` script, which avoids the need to run `autogen.sh` and completely eliminates the need for `autoconf`, `automake`, and `libtool` build dependencies which are not included in the standard Freeside OS pure-LLVM sandbox.
- Corrected runtime dependencies in the manifest: removed non-existent `glibc`, `libncursesw.so`, and `systemd-libs` in favor of `musl`, `ncurses`, and `systemd`.
- Added missing build dependencies to `package.manifest`: `pkgconf`, `gettext`, `make`.
