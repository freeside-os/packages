# jq

Lightweight and flexible command-line JSON processor.

## Upgrade Notes
- Packaged jq 1.8.2 from GitHub releases.
- Configured with `--with-oniguruma=builtin` for self-contained, robust regex parser support.
- Configured `--prefix=/usr --disable-static` standard arguments for proper UsrMerge and dynamic musl building.
- File permissions are explicitly enforced within the install targets.