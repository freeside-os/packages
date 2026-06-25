# strace

System call tracer for Linux.

| Package | Version | Source URL | Checksum (SHA-256) |
|---|---|---|---|
| strace | 7.1 | https://github.com/strace/strace/releases/download/v7.1/strace-7.1.tar.xz | 81743ecf2a5b44186b2f5038afdc8beda7e5c70aed15b4fbfbcc6e9ece24490f |

## Upgrade Notes
* **Build Quirk Resolved:** Appended `--enable-mpers=no` to `CONFIGURE_ARGS` to fix compilation failure on `m32 personality support` checks, where `mpers.sh` failed with an unknown argument error from `readelf` (`--debug-dump=info`).
