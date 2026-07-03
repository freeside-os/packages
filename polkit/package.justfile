build:
    tar -xf 127.tar.gz || tar -xf polkit-127.tar.gz || tar -xf "$PKG_VERSION".tar.gz || tar -xf "$PKG_NAME"-"$PKG_VERSION".tar.gz || tar -xf *"$PKG_VERSION".tar.gz
    tar -xf duktape-2.7.0.tar.xz

    # Compile and install duktape to a local staging directory first so polkit can find it without writing to the host's /usr during build!
    mkdir -p dist/lib/pkgconfig
    mkdir -p dist/include
    
    cd duktape-2.7.0 && sed -i 's/-Os/-O2/' Makefile.sharedlibrary
    cd duktape-2.7.0 && make -j$(nproc) -f Makefile.sharedlibrary INSTALL_PREFIX="$(pwd)/../dist" DESTDIR=""
    cd duktape-2.7.0 && make -f Makefile.sharedlibrary INSTALL_PREFIX="$(pwd)/../dist" DESTDIR="" install

    # Create duktape.pc in the staging directory pointing to the local staging path
    echo "prefix=$(pwd)/dist" > dist/lib/pkgconfig/duktape.pc
    echo "exec_prefix=\${prefix}" >> dist/lib/pkgconfig/duktape.pc
    echo "libdir=\${exec_prefix}/lib" >> dist/lib/pkgconfig/duktape.pc
    echo "includedir=\${prefix}/include" >> dist/lib/pkgconfig/duktape.pc
    echo "" >> dist/lib/pkgconfig/duktape.pc
    echo "Name: duktape" >> dist/lib/pkgconfig/duktape.pc
    echo "Description: Embeddable Javascript engine with a compact footprint" >> dist/lib/pkgconfig/duktape.pc
    echo "Version: 2.7.0" >> dist/lib/pkgconfig/duktape.pc
    echo "Libs: -L\${libdir} -lduktape -lm" >> dist/lib/pkgconfig/duktape.pc
    echo "Cflags: -I\${includedir}" >> dist/lib/pkgconfig/duktape.pc

    cd "$PKG_NAME"-"$PKG_VERSION" && PKG_CONFIG_PATH="$(pwd)/../dist/lib/pkgconfig" meson setup build \
        --prefix=/usr \
        --sbindir=/usr/bin \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --buildtype=release \
        -Dman=false \
        -Dintrospection=false \
        -Dtests=false \
        -Dsession_tracking=logind
    cd "$PKG_NAME"-"$PKG_VERSION" && ninja -C build -j$(nproc)

package:
    # Install duktape to DESTDIR
    cd duktape-2.7.0 && make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr DESTDIR="$DESTDIR" install

    # Install our generated duktape.pc to DESTDIR pointing to /usr
    mkdir -p "$DESTDIR/usr/lib/pkgconfig"
    echo "prefix=/usr" > "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "exec_prefix=\${prefix}" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "libdir=\${exec_prefix}/lib" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "includedir=\${prefix}/include" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "Name: duktape" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "Description: Embeddable Javascript engine with a compact footprint" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "Version: 2.7.0" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "Libs: -L\${libdir} -lduktape -lm" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"
    echo "Cflags: -I\${includedir}" >> "$DESTDIR/usr/lib/pkgconfig/duktape.pc"

    # Install polkit to DESTDIR
    cd "$PKG_NAME"-"$PKG_VERSION" && DESTDIR="$DESTDIR" ninja -C build install

    # Install run0 policy rule to allow wheel group users to use run0
    mkdir -p "$DESTDIR/usr/share/polkit-1/rules.d"
    echo 'polkit.addRule(function(action, subject) {' > "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"
    echo '    if ((action.id == "org.freedesktop.systemd1.manage-units" || action.id == "org.freedesktop.systemd1.run") && subject.isInGroup("wheel")) {' >> "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"
    echo '        return polkit.Result.YES;' >> "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"
    echo '    }' >> "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"
    echo '});' >> "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"

    # Enforce standard permissions on directories and files
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} + || true
    find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
    chmod 644 "$DESTDIR/usr/share/polkit-1/rules.d/10-run0.rules"

    # Set SUID permissions on pkexec and polkit-agent-helper-1 (essential for polkit functionality)
    find "$DESTDIR" -name "pkexec" -exec chmod 4755 {} +
    find "$DESTDIR" -name "polkit-agent-helper-1" -exec chmod 4755 {} +

    # Ensure pkttyagent is built and present in the final package
    test -f "$DESTDIR/usr/bin/pkttyagent"