# squashfs-tools

## Description
Tools for squashfs, a highly compressed read-only filesystem for Linux.

## Upgrade Notes
- `make install` fails on `generate-manpages` scripts due to missing `which` command. Applied a patch (`0001-fix-functions_sh.patch`) to replace `which` with `command -v` in `generate-manpages/functions.sh` and `generate-manpages/install-manpages.sh`.
- Added `uutils-coreutils` to build dependencies because `generate-manpages/functions.sh` explicitly checks for a non-builtin `echo`.
- Patches are applied with `-p1 -d $PKG_NAME-$PKG_VERSION`.