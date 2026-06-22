build:
    mkdir -p sysroot/lib sysroot/include sysroot/lib/pkgconfig
    
    curl -LO https://ftp.osuosl.org/pub/blfs/conglomeration/popt/popt-1.19.tar.gz
    tar xf popt-1.19.tar.gz
    cd popt-1.19 && ./configure --prefix=$PWD/../sysroot --libdir=$PWD/../sysroot/lib --enable-static --disable-shared && make install DESTDIR=""
    
    curl -LO https://mirrors.kernel.org/sourceware/lvm2/LVM2.2.03.22.tgz
    tar xf LVM2.2.03.22.tgz
    cd LVM2.2.03.22 && LDFLAGS="-Wl,--undefined-version" ./configure --prefix=/usr --enable-static_link || exit 1
    cd LVM2.2.03.22 && make device-mapper
    cd LVM2.2.03.22/libdm && find . -name "*.o" | xargs ar rcs libdevmapper.a
    cp LVM2.2.03.22/libdm/libdevmapper.a sysroot/lib/
    cp LVM2.2.03.22/libdm/libdevmapper.h sysroot/include/
    
    tar xf cryptsetup-2.8.6.tar.xz
    cd cryptsetup-2.8.6 && \
    CFLAGS="-I$PWD/../sysroot/include -O2 -g" \
    LDFLAGS="-L$PWD/../sysroot/lib -Wl,--undefined-version" \
    PKG_CONFIG_PATH="$PWD/../sysroot/lib/pkgconfig" \
    DEVMAPPER_CFLAGS="-I$PWD/../sysroot/include" \
    DEVMAPPER_LIBS="-L$PWD/../sysroot/lib -ldevmapper -lpthread -lrt -lm" \
    POPT_CFLAGS="-I$PWD/../sysroot/include" \
    POPT_LIBS="-L$PWD/../sysroot/lib -lpopt" \
    ./configure \
      --prefix=/usr \
      --sbindir=/usr/bin \
      --libdir=/usr/lib \
      --disable-ssh-token \
      --disable-shared \
      --enable-static \
      --disable-asciidoc || { cat config.log; exit 1; }
    cd cryptsetup-2.8.6 && make

package:
    cd cryptsetup-2.8.6 && make DESTDIR="$DESTDIR" install

    # install docs
    cd cryptsetup-2.8.6 && install -D -m0644 -t "$DESTDIR"/usr/share/doc/$PKG_NAME/ FAQ.md docs/{Keyring,LUKS2-locking}.txt

    # Enforce strict permissions
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR"/usr/bin ]; then find "$DESTDIR"/usr/bin -type f -exec chmod 755 {} +; fi
