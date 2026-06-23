# python-pyelftools

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | python-pyelftools |
| **Version** | 0.33 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/python-pyelftools/-/raw/main/PKGBUILD |
| **Source URL** | https://github.com/eliben/pyelftools/archive/v0.33.tar.gz |
| **Source Checksum (SHA256)** | 5507d69b42ac7211e5db57b42f427376b2cf3e3ab9a72b9239f4fc243566869d |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->
- The build process was changed from using `setup.py` directly to using `python3 -m pip`. This was done to work around issues with the build environment that were preventing the `setup.py` script from running correctly. The `justfile` was updated to reflect this change.
