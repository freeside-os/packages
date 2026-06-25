# fish

A smart and user-friendly command line shell

## Upgrade Notes

- Version 4.8.0 built cleanly using CMake and Ninja.
- As of fish 4, it is rewritten in Rust, so it requires the `rust` package to compile.
- Core dependencies include `rust`, `gettext`, `ncurses`, `cmake`, `ninja`, and `pkgconf`.
- Documentation generation was disabled for faster builds using `-DWITH_DOCS=OFF`.