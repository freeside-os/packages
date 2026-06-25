# podman-docker

Emulate Docker CLI using Podman.

## Upgrade Notes

* **Build Quirk**: Instead of relying on `make install.docker` (which inadvertently requires a full Go toolchain due to the upstream Makefile dependencies), the `package.justfile` directly manually processes and installs the needed files using `envsubst` and standard copy commands. This prevents adding heavyweight dependencies (like `go`) to this lightweight emulation package.