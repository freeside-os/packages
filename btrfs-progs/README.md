# btrfs-progs

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | btrfs-progs |
| **Version** | 7.0 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/btrfs-progs/-/raw/main/PKGBUILD |
| **Source URL** | https://mirrors.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v7.0.tar.xz |
| **Source Checksum (SHA256)** | c286d6876cbcd72327a0b417e4cfd280353ec23e37b549fdbcd7800a832d9a99 |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- **Source Fix:** Changed the Source URL to download the release tarball directly from `mirrors.kernel.org` as `git+https` clone endpoints are not fully supported by the default sandbox source fetcher. Configured the correct `sha256` checksum.
- **Build Automation:** Modified `package.justfile` to explicitly extract the tarball (`tar -xf`) and cd into `$PKG_NAME-v$PKG_VERSION`. Removed `./autogen.sh` execution because the release tarball already provides a pre-generated `configure` script.
- **Configure Adjustments:** 
  - Added `--disable-documentation` to avoid failures due to `sphinx-build` not being available in the core build tools.
  - Added `--disable-convert` because `ext2fs` (provided by `e2fsprogs`) is not available in the current base dependency graph, which skips the compilation of the `btrfs-convert` utility.