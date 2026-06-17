# Base Files Installation rules
build:
    @echo "Preparing base-files layout..."

package destdir:
    tar -xf base-files-1.0.0.tar.gz -C "{{destdir}}"
    mkdir -p "{{destdir}}/usr/bin"
    mkdir -p "{{destdir}}/usr/lib"
    mkdir -p "{{destdir}}/usr/share"
    mkdir -p "{{destdir}}/usr/include"
    mkdir -p "{{destdir}}/var"
    mkdir -p "{{destdir}}/boot"
    mkdir -p "{{destdir}}/usr/share/freeside/etc"
    ln -sf usr/bin "{{destdir}}/bin"
    ln -sf usr/bin "{{destdir}}/sbin"
    ln -sf usr/lib "{{destdir}}/lib"
    ln -sf usr/lib "{{destdir}}/lib64"
