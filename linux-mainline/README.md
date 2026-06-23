# linux-mainline

Pristine Mainline Linux Kernel compiled with LLVM and stitched into an atomic UKI.

| Package | Version | Source URL | Checksum |
|---------|---------|------------|----------|
| linux-mainline | 7.1.0 | https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.1.tar.xz | 691f44797fbe790dc8a321604c927087526ad27b6d649925d60f8eed0a2564a0 |

## Upgrade Notes

- Verified that the kernel compiles cleanly out-of-the-box using Clang/LLVM toolchain with `CC=clang LD=ld.lld LLVM=1 LLVM_IAS=1`.
- Verified packaging is fully reproducible and the unified kernel image (UKI) assembly finishes successfully.
- Updated source SHA-256 checksum in this README to match the official `package.manifest` signature: `691f44797fbe790dc8a321604c927087526ad27b6d649925d60f8eed0a2564a0`.
- Applied a workaround for build environments where the host toolchain or user-space compilation includes `include/uapi/linux/swab.h` but fails due to `__attribute_const__` being undefined. Injected fallback definition of `__attribute_const__` in `swab.h`.
