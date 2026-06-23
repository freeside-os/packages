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

## Modern Distro Adjustments & Legacy Drops

Freeside is a modern, x86_64-only Linux distribution focused on security and predictability. The default kernel configuration [freeside_defconfig](file:///home/dq/Code/freeside/packages/linux-mainline/files/freeside_defconfig) has been optimized to exclude legacy and obsolete components:

### 1. Compiler-Agnostic Scaffolding
* **Stripped Probed Compiler Variables:** Removed `CONFIG_CC_VERSION_TEXT` (originally containing host-probed gcc compiler version strings), `CONFIG_CC_IS_GCC`, `CONFIG_GCC_VERSION`, and `CONFIG_CLANG_VERSION`. The Kconfig system will dynamically probe the actual LLVM/Clang compiler during sandboxed builds.

### 2. Dropped Legacy Storage, Buses, and Peripherals
* **Floppy Disk Support:** Disabled `CONFIG_BLK_DEV_FD`.
* **Parallel Ports:** Disabled parallel port support (`CONFIG_PARPORT`), serial line printers, and PLIP.
* **PCMCIA / CardBus:** Disabled `CONFIG_PCMCIA` (16-bit card/PC Card support).
* **FireWire (IEEE 1394):** Disabled `CONFIG_FIREWIRE` and sub-drivers.

### 3. Dropped Legacy Networking Protocols
* **AppleTalk:** Disabled `CONFIG_ATALK` routing.
* **Amateur Radio (HAM):** Disabled `CONFIG_HAMRADIO` subsystem.
* **Nokia Phonet:** Disabled `CONFIG_PHONET` cellular protocol.

### 4. Security Hardening & Obsolete x86 Modes
* **16-bit Mode Execution:** Disabled `CONFIG_X86_16BIT` to prevent execution of 16-bit code segments.
* **modify_ldt Syscall:** Disabled `CONFIG_MODIFY_LDT_SYSCALL` to reduce kernel attack surface.
* **Vsyscall Emulation:** Disabled `CONFIG_X86_VSYSCALL_EMULATION` and set `CONFIG_LEGACY_VSYSCALL_NONE=y` to drop support for the deprecated vsyscall memory page used by ancient glibc versions.

### 5. Dropped Legacy & Niche Filesystems
* **Niche Filesystems:** Disabled IBM JFS (`CONFIG_JFS_FS`), GFS2 (`CONFIG_GFS2_FS`), Oracle OCFS2 (`CONFIG_OCFS2_FS`), and NILFS2 (`CONFIG_NILFS2_FS`).
* **Legacy Partition / Disk FS:** Disabled read-only legacy NTFS driver (`CONFIG_NTFS_FS`), Amiga AFFS (`CONFIG_AFFS_FS`), BeOS BEFS (`CONFIG_BEFS_FS`), Macintosh HFS/HFS+ (`CONFIG_HFS_FS`, `CONFIG_HFSPLUS_FS`), and Unix UFS (`CONFIG_UFS_FS`).
* **Embedded/Flash FS:** Disabled raw MTD flash filesystems JFFS2 (`CONFIG_JFFS2_FS`) and UBIFS (`CONFIG_UBIFS_FS`), ROMFS (`CONFIG_ROMFS_FS`), CramFS (`CONFIG_CRAMFS`), and Minix FS (`CONFIG_MINIX_FS`).
* **Obsolete Networking FS:** Disabled NFS v2 client support (`CONFIG_NFS_V2`).

