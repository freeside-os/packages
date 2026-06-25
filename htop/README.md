# htop

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | htop |
| **Version** | 3.5.1 |
| **Upstream Reference** | https://github.com/htop-dev/htop |
| **Source URL** | https://github.com/htop-dev/htop/releases/download/3.5.1/htop-3.5.1.tar.xz |
| **Source Checksum (SHA256)** | 526cecd62870aa8d14d2a79a35ea197e4e2b5317d275b567cee0574b2ddb2e9a |

## Upgrade Notes
- Created README.md reference documentation.
- Packaged htop version 3.5.1 with `--enable-cgroup` and `--enable-taskstats`.
- Added pkgconf dependency to build config to support robust ncurses discovery.
- Configured flags to be compliant with UsrMerge specifications (`--prefix=/usr`, `--sbindir=/usr/bin`, `--libdir=/usr/lib`).
- Applied directory and executable permissions compliance (755).
- Clean and successful build confirmed with standard compiler and linker flags on musl toolchain.
- Performed verification checking and clean-room container sandboxed builds to guarantee recipe reproducibility.
- **Builder Agent Update**: Validated the full sandboxed container compilation process. Verified standard build output with clean room reproducibility testing (with `keep_sandbox=false`), and verified final recipe schema compliance. All built components successfully compiled from scratch, packaged, and verified.
