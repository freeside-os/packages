# Freeside OS Packages Repository

This repository contains the declarative package recipes (metadata manifests and build scripts) for the Freeside OS package distribution system.

## Repository Layout

Each package lives in its own subdirectory containing a manifest and a build recipe:

```text
packages/<package-name>/
├── package.manifest     # Package metadata, dependencies, and source configurations (TOML)
├── package.justfile     # Step-by-step build and installation recipe (Justfile)
├── files/               # (Optional) Local configurations, patches, templates, or services
└── patches/             # (Optional) Patches applied during source extraction
```

## Creating a Package

### 1. The Package Manifest (`package.manifest`)

Written in TOML, the manifest specifies compile-time and runtime dependencies, source archives (with verification checksums), and build environment variables.

Example:
```toml
[package]
name = "openssl"
version = "3.3.0"
description = "Secure Sockets Layer toolkit"
dependencies = ["musl"]
group = "base"

[[sources]]
url = "https://www.openssl.org/source/openssl-3.3.0.tar.gz"
checksum = { algorithm = "sha256", value = "53e66b043322a606abf0087e7699a0e033a37fa13feb9742df35c3a33b18fb02" }

[build]
dependencies = ["musl"]

[build.environment]
CONFIGURE_ARGS = "--prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic"
```

### 2. The Build Recipe (`package.justfile`)

Written as a `justfile`, the recipe defines targets for building and packaging the software.

Typical layout:
```just
# Build target: compiles the source code
build:
    ./configure {{env_var("CONFIGURE_ARGS")}}
    make {{env_var("MAKE_FLAGS")}}

# Package target: installs build output into DESTDIR staging directory
package:
    make DESTDIR={{env_var("DESTDIR")}} install
```

## How to Build Packages

To compile a package, use the `straylight` CLI tool inside the workspace:
```bash
sudo build/straylight build packages/<package-name>
```

Successfully compiled packages will generate `.tgz` or target tarball outputs in the workspace build directory.
