build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    tar -xf ell-*.tar.xz
    ELL_DIR=$(find . -maxdepth 1 -type d -name "ell-*" -print -quit) && rm -rf $PKG_NAME-$PKG_VERSION/ell && mv "$ELL_DIR" $PKG_NAME-$PKG_VERSION/ell
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -exec sh -c 'for f; do if [ -x "$f" ]; then chmod 755 "$f"; fi; done' sh {} +
