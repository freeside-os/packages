# Base Files Installation rules
build:
    @echo "Preparing base-files layout..."

package destdir:
    # 1. Unpack default lowerdir configurations (/usr/share/freeside/etc/passwd, etc.)
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz -C "{{destdir}}"
    
    # 2. Assert read-only userspace structures are initialized
    mkdir -p "{{destdir}}/usr/bin"
    mkdir -p "{{destdir}}/usr/lib"
    mkdir -p "{{destdir}}/usr/share"
    mkdir -p "{{destdir}}/usr/include"
    mkdir -p "{{destdir}}/var"
    mkdir -p "{{destdir}}/boot"
    mkdir -p "{{destdir}}/usr/share/freeside/etc"
    
    # 3. Install the declarative tmpfiles configuration
    mkdir -p "{{destdir}}/usr/lib/tmpfiles.d"
    cp base-files.conf "{{destdir}}/usr/lib/tmpfiles.d/base-files.conf"
    
    # 4. Install the systemd etc.mount unit file
    mkdir -p "{{destdir}}/usr/lib/systemd/system"
    cp etc.mount "{{destdir}}/usr/lib/systemd/system/etc.mount"
    
    # 5. Enforce permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib/tmpfiles.d" -type f -exec chmod 644 {} +
    find "{{destdir}}/usr/lib/systemd/system" -type f -exec chmod 644 {} +
    find "{{destdir}}/usr/share/freeside/etc" -type f -exec chmod 644 {} +
    
    @echo "Base files layout and declarative systemd configs staged successfully."
