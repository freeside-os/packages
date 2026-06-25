# httpie

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | httpie |
| **Version** | 3.2.4 |
| **Upstream Reference** | https://httpie.io |
| **Source URL** | https://files.pythonhosted.org/packages/3e/bb/aefb0abbdbadeb9e8e7f04fb0f1942bc084f4215bf8dc729236153d09e1e/httpie-3.2.4.tar.gz |
| **Source Checksum (SHA256)** | 302ad436c3dc14fd0d1b19d4572ef8d62b146bcd94b505f3c2521f701e2e7a2a |

## Upgrade Notes
- Created README.md reference documentation.
- Configured version-dynamic names using standard environment variables `$PKG_NAME` and `$PKG_VERSION`.
- Ensured installation of binaries is compliant with UsrMerge specifications under `/usr`.
- Enforced permission compliance (chmod 755) on all directories and binary executable files under `/usr/bin` within the `$DESTDIR`.
