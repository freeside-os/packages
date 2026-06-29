# Freeside OS Live ISO Image Assembly
set dotenv-load := false

build:
    #!/usr/bin/env bash
    set -euo pipefail

    STAGING="/tmp/iso_staging"
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
        echo "options console=ttyS0 earlyprintk=ttyS0 console=tty0 debug"
    } > "$STAGING/loader/entries/live.conf"

    # 3. Assemble the UEFI FAT boot image (efiboot.img)
    BOOTLOADER="/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
    EFIBOOT="$STAGING/EFI/boot/efiboot.img"

    # Create an empty 90MB FAT image file (large enough to hold kernel + initrd + bootloader)
    dd if=/dev/zero of="$EFIBOOT" bs=1M count=90
    mkfs.vfat -F 32 -n "FSEFIBOOT" "$EFIBOOT"

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

    # 5. Compile the final ISO with UEFI boot parameters using xorriso
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
