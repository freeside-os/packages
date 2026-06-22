# rust

The Rust Programming Language Compiler and Cargo

| Name | Version | Source | Checksum |
|------|---------|--------|----------|
| rust | 1.96.0 | https://static.rust-lang.org/dist/rust-1.96.0-x86_64-unknown-linux-musl.tar.gz | 545aff63f37dea2fcbd8037b877219fca6fbba97660bdcb8d3a0fc5df5fa9edf |

## Upgrade Notes

- Fixed `package.justfile` to use `{{env_var("PKG_NAME")}}` and `{{env_var("PKG_VERSION")}}` instead of undefined Just variables. This ensures the build system's environment variables are correctly interpolated by Just.
- Verified successful sandboxed compilation and installation.
