# nmap

Nmap is a utility for network exploration and security auditing.

| Detail | Value |
| ------ | ----- |
| Name | nmap |
| Version | 7.99 |
| Source URL | https://nmap.org/dist/nmap-7.99.tar.bz2 |
| Checksum (SHA-256) | df512492ffd108e53a27a06f26d8635bbe89e0e569455dc8ffef058c035d51b2 |

## Upgrade Notes

- **Aclocal and Autotools timestamp issues**: Avoided rebuilding autotools/aclocal.m4 files in included libraries (like libpcre) by touching generated files in dependency order (`aclocal.m4`, `configure`, `config.h.in`, `Makefile.in`) after source extraction.
- **Strict install command flags**: Overrode `INSTALL="/usr/bin/install"` during `./configure` and `make install` to avoid redundant `-c` flags (`-c -c`), which are rejected by stricter install implementations (such as rust/uutils-coreutils based `install`).
- **Python dependency removal**: Configured with `--without-zenmap` and `--without-ndiff` to completely omit Python-based tooling dependencies.
- **Included Libraries**: Used included options for standard helper dependencies (`libpcap`, `libpcre`, `libdnet`, `liblua`, `libssh2`, `liblinear`) for standalone, self-contained building on Musl.
