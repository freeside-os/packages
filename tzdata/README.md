# tzdata

Time Zone Database package for Freeside OS.

## Upgrade Notes
- Successfully built tzdata 2026b from scratch.
- Customized compilation and installation using `make DESTDIR="$DESTDIR" TOPDIR=/usr TZDIR=/usr/share/zoneinfo BINDIR=/usr/bin SBINDIR=/usr/bin MANDIR=/usr/share/man LIBDIR=/usr/lib`.
- Removed overlapping `/etc/localtime` logic during the build so that it does not override system-wide symlinks out of the box.