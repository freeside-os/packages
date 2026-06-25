# zsh

A very advanced and programmable command interpreter (shell)

## Upgrade Notes
- Compiled successfully with musl, ncurses, and libcap.
- Ensure `--prefix=/usr --sbindir=/usr/bin --libdir=/usr/lib` are maintained for UsrMerge compliance.
- Explicit permissions enforced correctly in justfile for directories, binaries, and shared libraries.
