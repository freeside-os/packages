# cryptsetup

Maintainer reference documentation for package version upgrades and security updates.

| Field | Value |
| :--- | :--- |
| **Package Name** | cryptsetup |
| **Version** | 2.8.6 |
| **Upstream Reference** | https://gitlab.archlinux.org/archlinux/packaging/packages/cryptsetup/-/raw/main/PKGBUILD |
| **Source URL** | https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8/cryptsetup-2.8.6.tar.xz |
| **Source Checksum (SHA256)** | 8004265fd993885d08f7b633dbe056851de1a210307613a4ebddc743fccefe5a |

## Upgrade Notes
<!-- Wintermute or maintainers will add valuable upgrade notes below -->

* **LVM2 dependency**: Uses `libdevmapper` statically. LVM2 build is required inline in `package.justfile`. LDFLAGS require `-Wl,--undefined-version` on `ld.lld` when building LVM2 because of `dm_udev_create_cookie` inside the version script mapping.
* **Libtool quirks**: We must link static libraries as `-L... -ldevmapper` and `-L... -lpopt` instead of explicitly listing `.a` paths (e.g. `/path/to/libdevmapper.a`), otherwise libtool tries to add them directly as `.a` inside `libcryptsetup.a` which causes a linker error (`archive member 'libdevmapper.a' is neither ET_REL nor LLVM bitcode`).
