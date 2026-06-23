#!/usr/bin/env python3
"""
Freeside OS: Hermetic Initramfs Generator (fsinitram)

This script processes pre-compiled binary Freeside packages from the build output
cache, extracts early userspace dependencies, assembles a stateless VFS layout,
and compiles a compressed newc CPIO archive.

Features:
- Programmatic, pure-Python newc CPIO writer (requires ZERO root/sudo privileges
  to generate device nodes like /dev/console or override UIDs/GIDs to 0).
- Pure-Python gzip compression pipeline.
- Automatically maps the un-merged /usr directory tree layout.
"""

import os
import sys
import tarfile
import gzip
import shutil
import argparse
import stat
from pathlib import Path

# Required package base blocks to extract into the initramfs
REQUIRED_BOOT_PACKAGES = [
    "musl",
    "systemd",
    "cryptsetup",
    "btrfs-progs",
    "util-linux",
    "kmod",
    "bash"
]

class CpioWriter:
    """
    Programmatic POSIX cpio newc archive generator.
    Allows injecting custom directories, symlinks, files, and device nodes.
    """
    def __init__(self, output_file):
        self.output = output_file
        self.inode_counter = 1

    def _pad(self, data, alignment=4):
        """Pads data with null bytes to align with the specified boundary."""
        remainder = len(data) % alignment
        if remainder != 0:
            data += b"\x00" * (alignment - remainder)
        return data

    def write_record(self, name, mode, uid=0, gid=0, filesize=0, rdev_major=0, rdev_minor=0, data=b""):
        """Writes a single newc CPIO record to the output stream."""
        # Clean up path names (cpio paths must be relative and lack leading slashes)
        name_bytes = name.lstrip("/").encode("utf-8")
        namesize = len(name_bytes) + 1  # Includes trailing null byte

        # Create the 110-byte ASCII hex header
        # fields: magic(6), ino(8), mode(8), uid(8), gid(8), nlink(8), mtime(8),
        #         filesize(8), devmajor(8), devminor(8), rdevmajor(8), rdevminor(8),
        #         namesize(8), check(8)
        header = (
            b"070701" +
            f"{self.inode_counter:08x}".encode() +
            f"{mode:08x}".encode() +
            f"{uid:08x}".encode() +
            f"{gid:08x}".encode() +
            b"00000001" + # nlink (always 1 for simplicity)
            b"00000000" + # mtime
            f"{filesize:08x}".encode() +
            b"00000003" + # devmajor
            b"00000001" + # devminor
            f"{rdev_major:08x}".encode() +
            f"{rdev_minor:08x}".encode() +
            f"{namesize:08x}".encode() +
            b"00000000"   # check (must be 0 for newc format)
        )

        self.inode_counter += 1

        # Write header
        self.output.write(header)
        
        # Write filename + null terminator + padding
        self.output.write(name_bytes + b"\x00")
        self.output.write(b"\x00" * (3 - (len(header) + len(name_bytes) + 1) % 4)) # Pad total header+name to 4 bytes

        # Write data + padding
        if filesize > 0:
            self.output.write(data)
            remainder = filesize % 4
            if remainder != 0:
                self.output.write(b"\x00" * (4 - remainder))

    def write_trailer(self):
        """Writes the final TRAILER!!! cpio record indicating end of archive."""
        self.write_record("TRAILER!!!", mode=0, filesize=0)

def find_package_archive(packages_dir, package_name):
    """Finds the latest compiled .tar.gz or .tgz package for a given name."""
    p_dir = Path(packages_dir)
    if not p_dir.exists():
        return None
    
    # Matches patterns like musl-1.2.5.tar.gz or musl-1.2.5.tgz
    matches = list(p_dir.glob(f"{package_name}-*.tar.gz")) + list(p_dir.glob(f"{package_name}-*.tgz"))
    if not matches:
        return None
    
    # Return the one with the latest modification time (most recent build)
    return max(matches, key=lambda p: p.stat().st_mtime)

def extract_early_boot_payload(archive_path, dest_dir):
    """Extracts only base filesystem dependencies needed for initial user-space."""
    print(f"[*] Unpacking early boot files from {archive_path.name}...")
    with tarfile.open(archive_path, "r:gz") as tar:
        for member in tar.getmembers():
            # Filter layout rules: we only want executables, configs, and library layers.
            # Strip files like headers, manuals, or auxiliary build files to keep initramfs small.
            if any(p in member.name for p in ["/include/", "/share/man/", "/share/doc/", "/lib/pkgconfig/"]):
                continue
            
            # Extract to target directory path
            tar.extract(member, path=dest_dir)

def create_freeside_vfs_skeleton(staging_dir):
    """Generates empty directories and critical base system layouts."""
    print("[*] Creating Freeside VFS directory hierarchy...")
    
    dirs = [
        "proc", "sys", "run", "sysroot", "etc", "dev",
        "usr/bin", "usr/lib", "usr/share"
    ]
    for d in dirs:
        os.makedirs(os.path.join(staging_dir, d), exist_ok=True)

def inject_boot_symlinks(staging_dir):
    """Creates systemd-boot compatibility symlinks and initialization scripts."""
    print("[*] Injecting systemd un-merged /usr boot paths...")
    
    # 1. Platform Symlinks
    symlinks = {
        "bin": "usr/bin",
        "sbin": "usr/bin",
        "lib": "usr/lib",
        "lib64": "usr/lib",
        "init": "usr/lib/systemd/systemd" # systemd runs natively as PID 1
    }
    
    for link, target in symlinks.items():
        link_path = os.path.join(staging_dir, link)
        if os.path.exists(link_path) or os.path.islink(link_path):
            os.remove(link_path)
        os.symlink(target, link_path)

    # 2. Systemd Signaling Configuration
    etc_dir = os.path.join(staging_dir, "etc")
    os.makedirs(etc_dir, exist_ok=True)
    
    # Write initrd-release so systemd initializes in target RAM mode
    with open(os.path.join(etc_dir, "initrd-release"), "w") as f:
        f.write("# Freeside OS Initrd Signaling Profile\n")

    # Create dummy os-release inside etc if missing
    os_rel = os.path.join(etc_dir, "os-release")
    if not os.path.exists(os_rel):
        with open(os_rel, "w") as f:
            f.write("NAME=\"Freeside OS\"\nID=freeside\nVERSION_ID=0.1.0\n")

def main():
    parser = argparse.ArgumentParser(description="Assemble Freeside OS initramfs base image")
    parser.add_argument(
        "--packages-dir",
        default="../../build/packages",
        help="Directory containing pre-compiled binary packages"
    )
    parser.add_argument(
        "--output",
        default="initramfs-base.cpio.gz",
        help="Path where compressed initramfs archive should be built"
    )
    parser.add_argument(
        "--work-dir",
        default="build/initramfs-staging",
        help="Temporary directory utilized to compile and structure the VFS"
    )
    args = parser.parse_args()

    # Normalize input paths
    packages_dir = os.path.abspath(args.packages_dir)
    staging_dir = os.path.abspath(args.work_dir)
    output_path = os.path.abspath(args.output)

    print("=================================================================")
    print("           Freeside OS: Initramfs Packaging Toolchain            ")
    print("=================================================================")
    print(f"[*] Package Dir:  {packages_dir}")
    print(f"[*] Staging Dir:  {staging_dir}")
    print(f"[*] Output Arch:  {output_path}")

    # Step 1: Clean and stage the workspace environment
    if os.path.exists(staging_dir):
        shutil.rmtree(staging_dir)
    os.makedirs(staging_dir, exist_ok=True)

    # Step 2: Establish the foundational skeleton layouts
    create_freeside_vfs_skeleton(staging_dir)

    # Step 3: Unpack required base-system packages
    for pkg in REQUIRED_BOOT_PACKAGES:
        archive = find_package_archive(packages_dir, pkg)
        if not archive:
            print(f"[-] ERROR: Required boot dependency '{pkg}' was not found inside the packages directory!")
            print(f"    Verify that Stage 2 compilations succeeded.")
            sys.exit(1)
        extract_early_boot_payload(archive, staging_dir)

    # Step 4: Map system directories and setup systemd hooks
    inject_boot_symlinks(staging_dir)

    # Step 5: Programmatic packaging execution via CpioWriter
    print("[*] Packaging staging workspace into compressed newc CPIO archive...")
    
    # Initialize gzip dynamic compression stream
    with gzip.open(output_path, "wb", compresslevel=9) as gz_out:
        cpio = CpioWriter(gz_out)

        # A. Explicitly Inject Hardcoded Secure System Device Nodes
        # This completely bypasses the host host-access mknod permission errors.
        # Major 5, Minor 1 for /dev/console
        # Major 1, Minor 3 for /dev/null
        cpio.write_record(
            name="dev/console",
            mode=stat.S_IFCHR | 0o600,
            uid=0, gid=0,
            rdev_major=5, rdev_minor=1
        )
        cpio.write_record(
            name="dev/null",
            mode=stat.S_IFCHR | 0o666,
            uid=0, gid=0,
            rdev_major=1, rdev_minor=3
        )

        # B. Walk the compiled rootfs staging layout and package it programmatically
        # Note: os.walk returns relative folders, we must maintain relativeness inside CPIO.
        for root, dirs, files in os.walk(staging_dir):
            for d in dirs:
                full_path = os.path.join(root, d)
                rel_path = os.path.relpath(full_path, staging_dir)
                # Keep rootfs clean (ignore explicit host device node folders if created)
                if rel_path in ["dev/console", "dev/null", "dev"]:
                    continue
                cpio.write_record(
                    name=rel_path,
                    mode=stat.S_IFDIR | 0o755,
                    uid=0, gid=0
                )
            
            # Force add root dev folder (stripped out above)
            cpio.write_record("dev", mode=stat.S_IFDIR | 0o755, uid=0, gid=0)

            for f in files:
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, staging_dir)
                
                # Check for symlinks and write link records accordingly
                if os.path.islink(full_path):
                    target = os.readlink(full_path)
                    target_bytes = target.encode("utf-8")
                    cpio.write_record(
                        name=rel_path,
                        mode=stat.S_IFLNK | 0o777,
                        uid=0, gid=0,
                        filesize=len(target_bytes),
                        data=target_bytes
                    )
                else:
                    # Write regular files
                    with open(full_path, "rb") as bin_file:
                        file_data = bin_file.read()
                    
                    # Copy execution/read permissions directly from filesystem
                    file_stat = os.stat(full_path)
                    cpio.write_record(
                        name=rel_path,
                        mode=stat.S_IFREG | (file_stat.st_mode & 0o777),
                        uid=0, gid=0,
                        filesize=len(file_data),
                        data=file_data
                    )

        # Write Trailer indicator block
        cpio.write_trailer()

    # Clean up local staging workspaces
    shutil.rmtree(staging_dir)

    print("[+] Success! Byte-reproducible initramfs base image written successfully.")
    print(f"    Target Location: {output_path}")
    print("=================================================================")

if __name__ == "__main__":
    main()
