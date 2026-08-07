import gzip
import stat

files = {
    "etc/systemd/system/run-initramfs-live.mount": """[Unit]
Description=Mount Live Boot Medium
DefaultDependencies=no
After=udevadm-trigger-service.service

[Mount]
What=/dev/disk/by-label/FREESIDE_LIVE
Where=/run/initramfs/live
Type=iso9660
Options=ro,nofail
""",
    "etc/systemd/system/sysroot.mount": """[Unit]
Description=Mount Live Root Filesystem
DefaultDependencies=no
Requires=run-initramfs-live.mount
After=run-initramfs-live.mount

[Mount]
What=/run/initramfs/live/rootfs.squashfs
Where=/sysroot
Type=squashfs
Options=ro,loop
"""
}

class CpioWriter:
    def __init__(self, f):
        self.f = f
        self.ino = 1

    def write_file(self, name, data_str):
        data = data_str.encode("utf-8")
        name_b = name.encode("utf-8") + b"\x00"
        hdr = (
            b"070701"
            + f"{self.ino:08x}".encode()
            + f"{stat.S_IFREG | 0o644:08x}".encode()
            + b"00000000000000000000000100000000"
            + f"{len(data):08x}".encode()
            + b"00000003000000010000000000000000"
            + f"{len(name_b):08x}".encode()
            + b"00000000"
        )
        self.ino += 1
        self.f.write(hdr + name_b)
        rem = len(hdr + name_b) % 4
        if rem: self.f.write(b"\x00" * (4 - rem))
        self.f.write(data)
        rem = len(data) % 4
        if rem: self.f.write(b"\x00" * (4 - rem))

    def write_symlink(self, name, target):
        data = target.encode("utf-8")
        name_b = name.encode("utf-8") + b"\x00"
        hdr = (
            b"070701"
            + f"{self.ino:08x}".encode()
            + f"{stat.S_IFLNK | 0o777:08x}".encode()
            + b"00000000000000000000000100000000"
            + f"{len(data):08x}".encode()
            + b"00000003000000010000000000000000"
            + f"{len(name_b):08x}".encode()
            + b"00000000"
        )
        self.ino += 1
        self.f.write(hdr + name_b)
        rem = len(hdr + name_b) % 4
        if rem: self.f.write(b"\x00" * (4 - rem))
        self.f.write(data)
        rem = len(data) % 4
        if rem: self.f.write(b"\x00" * (4 - rem))

    def close(self):
        name_b = b"TRAILER!!!\x00"
        hdr = b"070701000000000000000000000000000000000000000100000000000000000000000000000000" + f"{len(name_b):08x}".encode() + b"00000000"
        self.f.write(hdr + name_b)
        rem = len(hdr + name_b) % 4
        if rem: self.f.write(b"\x00" * (4 - rem))

with gzip.open("initramfs-live.cpio.gz", "wb", compresslevel=9) as gz:
    w = CpioWriter(gz)
    for path, content in files.items():
        w.write_file(path, content)
    w.write_symlink("etc/systemd/system/initrd.target.wants/sysroot.mount", "../sysroot.mount")
    w.close()
