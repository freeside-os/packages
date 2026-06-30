# Freeside OS Live ISO Image Assembly
set dotenv-load := false

build:
    #!/usr/bin/env bash
    set -euo pipefail

    STAGING="/workspace/build/iso_staging"
    rm -rf "$STAGING"
    mkdir -p "$STAGING/EFI/boot" "$STAGING/EFI/BOOT" "$STAGING/loader/entries"

    # 1. Copy Kernel and Initramfs (from sandbox filesystem)
    KERNEL_PATH="/usr/lib/freeside/linux/kernel/vmlinuz"
    INITRD_PATH="/usr/lib/freeside/initramfs.cpio"

    cp "$KERNEL_PATH" "$STAGING/vmlinuz"
    cp "$INITRD_PATH" "$STAGING/initramfs.cpio.gz"

    # 2. Write systemd-boot Loader Configurations
    echo "default live" > "$STAGING/loader/loader.conf"
    echo "timeout 3" >> "$STAGING/loader/loader.conf"

    {
        echo "title   Freeside OS Live Installer"
        echo "linux   /vmlinuz"
        echo "initrd  /initramfs.cpio.gz"
        echo "options console=tty0 console=ttyS0 earlyprintk=serial,ttyS0,115200 systemd.volatile=overlay debug"
    } > "$STAGING/loader/entries/live.conf"

    # 3. Assemble the UEFI FAT boot image (efiboot.img)
    BOOTLOADER="/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
    EFIBOOT="$STAGING/EFI/boot/efiboot.img"

    # Create an empty 70MB FAT image file (large enough to hold kernel + pre-compressed initrd + bootloader)
    dd if=/dev/zero of="$EFIBOOT" bs=1M count=70
    mkfs.vfat -F 16 -n "FSEFIBOOT" "$EFIBOOT"

    # Populate the FAT image using mtools (requires zero loopback mounts)
    mmd -i "$EFIBOOT" ::/EFI
    mmd -i "$EFIBOOT" ::/EFI/BOOT
    mcopy -i "$EFIBOOT" "$BOOTLOADER" ::/EFI/BOOT/BOOTX64.EFI
    mmd -i "$EFIBOOT" ::/loader
    mmd -i "$EFIBOOT" ::/loader/entries
    mcopy -i "$EFIBOOT" "$STAGING/loader/loader.conf" ::/loader/loader.conf
    mcopy -i "$EFIBOOT" "$STAGING/loader/entries/live.conf" ::/loader/entries/live.conf
    mcopy -i "$EFIBOOT" "$STAGING/vmlinuz" ::/vmlinuz
    mcopy -i "$EFIBOOT" "$STAGING/initramfs.cpio.gz" ::/initramfs.cpio.gz

    # 4. Copy bootloader directly to staging for standard UEFI directory loading
    cp "$BOOTLOADER" "$STAGING/EFI/BOOT/BOOTX64.EFI"

    # 5. Assemble the SquashFS rootfs
    echo "=== Staging SquashFS root filesystem ==="
    SQ_STAGING="/workspace/build/squashfs_staging"
    rm -rf "$SQ_STAGING"
    mkdir -p "$SQ_STAGING"

    # Set up UsrMerge symlinks in the squashfs root
    mkdir -p "$SQ_STAGING/usr/bin" "$SQ_STAGING/usr/lib"
    ln -sf usr/bin "$SQ_STAGING/bin"
    ln -sf usr/bin "$SQ_STAGING/sbin"
    ln -sf usr/lib "$SQ_STAGING/lib"
    ln -sf usr/lib "$SQ_STAGING/lib64"
    ln -sf lib "$SQ_STAGING/usr/lib64"
    ln -sf bin "$SQ_STAGING/usr/sbin"

    # Resolve package build order for base, builder, and system groups
    RESOLVED_PACKAGES=$(python3 /workspace/packages/fspack.py resolve base builder system)
    for pkg in $RESOLVED_PACKAGES; do
        TARBALL=$(find /workspace/build/packages/ -maxdepth 1 -name "${pkg}-*.tar.gz" | head -n1)
        if [ -n "$TARBALL" ]; then
            echo "Extracting $pkg to squashfs staging..."
            tar -xzf "$TARBALL" --keep-directory-symlink --exclude='./meta' --exclude='meta' -C "$SQ_STAGING"
        else
            echo "WARNING: Tarball for $pkg not found!"
        fi
    done

    # Create runtime folders
    for dir in tmp proc sys dev run var etc root home boot; do
        mkdir -p "$SQ_STAGING/$dir"
    done
    chmod 1777 "$SQ_STAGING/tmp"

    # Copy sandbox-root.tgz
    CACHE_DIR="$SQ_STAGING/var/cache/freeside"
    mkdir -p "$CACHE_DIR/packages"
    cp /workspace/build/sandbox-root.tgz "$CACHE_DIR/sandbox-root.tgz"

    # Copy package tarballs from base and system groups
    BASE_SYSTEM_PACKAGES=$(python3 /workspace/packages/fspack.py resolve base system)
    for pkg in $BASE_SYSTEM_PACKAGES; do
        TARBALL=$(find /workspace/build/packages/ -maxdepth 1 -name "${pkg}-*.tar.gz" | head -n1)
        if [ -n "$TARBALL" ]; then
            cp "$TARBALL" "$CACHE_DIR/packages/"
        fi
    done

    # Generate the rootfs.squashfs filesystem
    mksquashfs "$SQ_STAGING" "$STAGING/rootfs.squashfs" -comp zstd
    rm -rf "$SQ_STAGING"

    # 6. Compile the final ISO with UEFI boot parameters using xorriso
    xorriso \
        -as mkisofs \
        -R -J -joliet-long \
        -volid "FREESIDE_LIVE" \
        -eltorito-alt-boot \
        -e EFI/boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output "$DESTDIR/freeside-live.iso" \
        "$STAGING"

    # Cleanup temporary staging directories
    rm -rf "$STAGING"

package:
    # Straylight expects a package target. Since build generates the .iso directly in DESTDIR, 
    # the package target can be a placeholder.
    echo "Live ISO generated successfully."
