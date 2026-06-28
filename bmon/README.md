# bmon

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | bmon |
| **Version** | 4.0 |
| **Upstream Reference** | https://github.com/tgraf/bmon |
| **Source URL** | https://github.com/tgraf/bmon/releases/download/v4.0/bmon-4.0.tar.gz |
| **Source Checksum (SHA256)** | 02fdc312b8ceeb5786b28bf905f54328f414040ff42f45c83007f24b76cc9f7a |

## Upgrade Notes
- Initial package recipe for bmon 4.0.
- Statically bundles libconfuse 3.3 and libnl 3.11.0 to satisfy dependency requirements without adding global overhead.
- Added `bison` and `flex` as build dependencies.
- Enforced UsrMerge and strict destination/permission compliance.
