# pambase

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | pambase |
| **Version** | 20260616 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/pambase |
| **Source URL** | https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/system-auth<br>https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/system-login<br>https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/other<br>https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/system-local-login<br>https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/system-remote-login<br>https://gitlab.archlinux.org/archlinux/packaging/packages/pambase/-/raw/main/system-services |
| **Source Checksum (SHA256)** | 2bb19ead55a7b9014d107eec63cc015426c39d93ddc8af3322649ff5f8b45d5b<br>7272120f0ee937cbe6ba0a6e748ea234ab6799e1e2966c83ee85f97d9f254fd9<br>d5ed59ec2157c19c87964a162f7ca84d53c19fb2bd68d3fbc1671ba8d906346f<br>005736b9bd650ff5e5d82a7e288853776d5bb8c90185d5774c07231c1e1c64a9<br>005736b9bd650ff5e5d82a7e288853776d5bb8c90185d5774c07231c1e1c64a9<br>6eb1acdd3fa9f71a7f93fbd529be57ea65bcafc6e3a98a06af4d88013fc6a567 |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- Resolved dependency cycle (`pambase -> pam -> pambase`) by removing explicit `pam` dependency.
- Fixed `package.justfile` to include an empty `build:` target.
- Package successfully compiled and installed base configuration files into `/etc/pam.d/`.
