build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) LINKER_PATH=/lib/ld-musl-x86_64.so.1

package destdir:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="{{destdir}}" install
    # Link for glibc x86_64 binary compatibility
    ln -sf ld-linux.so.2 "{{destdir}}/usr/lib/ld-linux-x86-64.so.2"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
