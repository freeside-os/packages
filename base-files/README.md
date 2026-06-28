# base-files

Freeside OS base filesystem layout, directory topologies, and core OverlayFS templates.

## Metadata
| Field | Value |
| --- | --- |
| Name | base-files |
| Version | 1.1.0 |
| Source File 1 | base-files-1.1.0.tar.gz |
| Checksum 1 | c20c6b3d033d91e222cf322ece5afd617f2f4fdc8322dac51dffcd4e49309676 |
| Source File 2 | base-files.conf |
| Checksum 2 | 11cc53bcebcfaaaf57acc69690ae2b465922f68abb3efa04b6e051a1dfb5fe54 |
| Source File 3 | etc.mount |
| Checksum 3 | c548b6f35a37d8df161fe4ae6b7323c9759d1615c27187677e09b02c8138b903 |
| Source File 4 | os-release |
| Checksum 4 | 421f486916e967de9d6770fa1cd304e7b1be11254ec92959a00321b1dfedc58b |

## Upgrade Notes
- Refactored `os-release` tracking: it is now tracked as a template source file instead of being generated directly by the `justfile`.
- Configured the `justfile` to update the version placeholder (`__VERSION__`) using `sed` and the `FREESIDE_VERSION` variable defined in the manifest build environment.
- Configured URLs in `os-release` to point to `https://github.com/freeside-os`.
