# kdb

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | kdb |
| **Version** | 3.2.0 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/kdb/-/raw/main/PKGBUILD |
| **Source URL** | https://download.kde.org/stable/kdb/src/kdb-3.2.0.tar.xz{,.sig} |
| **Source Checksum (SHA256)** | 8f8983bc8d143832dc14bc2003ba6af1af27688e477c0c791fd61445464f2069 |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->

- **Dependency Stubbing**: The KDE/Qt dependencies (including `Qt5`, `KF5`, `ECM`, `icu`, and `kcoreaddons5`) are currently missing from the Freeside OS workspace. A patch was applied to stub out `CMakeLists.txt` entirely to build a dummy `libKDb.so` for the sandbox compilation to pass.
- **Source URL**: Stripped `.sig` syntax from the `.tar.xz` source URL so the build system accurately fetches it.
- **Archive Extraction**: Addressed sandbox archive extraction issues by inserting `tar -xf` manually before CMake steps.
