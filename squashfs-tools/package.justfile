build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.gz
    patch -p1 -d $PKG_NAME-$PKG_VERSION < /workspace/packages/$PKG_NAME/patches/0001-fix-functions_sh.patch
    cd $PKG_NAME-$PKG_VERSION/squashfs-tools && make -j$(nproc) \
        GZIP_SUPPORT=1 \
        XZ_SUPPORT=1 \
        ZSTD_SUPPORT=1 \
        LZO_SUPPORT=0 \
        LZ4_SUPPORT=0 \
        XATTR_SUPPORT=1 \
        USE_PREBUILT_MANPAGES=y

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp $PKG_NAME-$PKG_VERSION/squashfs-tools/mksquashfs "$DESTDIR/usr/bin/"
    cp $PKG_NAME-$PKG_VERSION/squashfs-tools/unsquashfs "$DESTDIR/usr/bin/"
    ln -sf unsquashfs "$DESTDIR/usr/bin/sqfscat"
    ln -sf mksquashfs "$DESTDIR/usr/bin/sqfstar"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
