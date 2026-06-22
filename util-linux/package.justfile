# util-linux package build recipe

# Prepare: Unpack source structures and apply local patches
prepare:
    tar -xf "$PKG_NAME-$PKG_VERSION.tar.xz" --strip-components=1
    # Apply custom patches for musl compliance if located in files/
    if [ -d files/patches ]; then \
        for patch in files/patches/*.patch; do \
            patch -p1 < "$patch"; \
        done; \
    fi

# Build: Compile source trees within the LLVM compiler configuration context
build: prepare
    ./configure $CONFIGURE_ARGS
    make -j$(nproc)

# Package: Mirror target files securely inside the un-merged /usr tree under DESTDIR
package destdir=env_var("DESTDIR"):
    make DESTDIR="{{destdir}}" install
    # Enforce Un-Merged /usr compliance post-install
    if [ -d "{{destdir}}/bin" ]; then mv "{{destdir}}/bin/"* "{{destdir}}/usr/bin/" && rmdir "{{destdir}}/bin"; fi
    if [ -d "{{destdir}}/sbin" ]; then mv "{{destdir}}/sbin/"* "{{destdir}}/usr/bin/" && rmdir "{{destdir}}/sbin"; fi
    if [ -d "{{destdir}}/lib" ]; then mv "{{destdir}}/lib/"* "{{destdir}}/usr/lib/" && rmdir "{{destdir}}/lib"; fi
    # Enforce strict standard permissions
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/lib" ]; then find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
