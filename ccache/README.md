# ccache

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | ccache |
| **Version** | 4.10.2 |
| **Upstream Reference** | https://github.com/ccache/ccache |
| **Source URL** | https://github.com/ccache/ccache/releases/download/v4.10.2/ccache-4.10.2.tar.xz |
| **Source Checksum (SHA256)** | c0b85ddfc1a3e77b105ec9ada2d24aad617fa0b447c6a94d55890972810f0f5a |

## Upgrade Notes
- Initial recipe configuration for `ccache` version 4.10.2.
- Clean build configured with CMake, ensuring UsrMerge compliance using `/usr` prefix.
- Configured dynamic packaging using `$PKG_NAME` and `$PKG_VERSION`.
- Enforced strict destination directory injection via `$DESTDIR`.
- Enforced directory and executable permissions (chmod 755).
