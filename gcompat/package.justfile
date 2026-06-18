build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc) LINKER_PATH=/lib/ld-musl-x86_64.so.1

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" LIBGCOMPAT_PATH=/usr/lib/libgcompat.so.0 LOADER_PATH=/usr/lib/ld-linux.so.2 install
    # Link for glibc x86_64 binary compatibility
    ln -sf ld-linux.so.2 "$DESTDIR/usr/lib/ld-linux-x86-64.so.2"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
