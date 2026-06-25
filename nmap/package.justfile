build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.bz2
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    find . -name "aclocal.m4" -exec touch {} + && \
    find . -name "configure" -exec touch {} + && \
    find . -name "config.h.in" -exec touch {} + && \
    find . -name "Makefile.in" -exec touch {} + && \
    find . -name "configure" -exec sed -i 's/int foo() { return ETH_P_ALL; }/int foo = ETH_P_ALL;/g' {} + && \
    ./configure \
        INSTALL="/usr/bin/install" \
        --prefix=/usr \
        --sbindir=/usr/bin \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --without-zenmap \
        --without-ndiff \
        --with-openssl \
        --with-libz \
        --with-libpcap=included \
        --with-libpcre=included \
        --with-libdnet=included \
        --with-liblua=included \
        --with-libssh2=included \
        --with-liblinear=included \
        LDFLAGS="-Wl,--undefined-version" && \
    make

package:
    make install INSTALL="/usr/bin/install" DESTDIR="{{env_var("DESTDIR")}}" -C {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}
    
    # UsrMerge compliance
    if [ -d "{{env_var("DESTDIR")}}/sbin" ]; then \
        mkdir -p "{{env_var("DESTDIR")}}/usr/bin" && \
        mv "{{env_var("DESTDIR")}}/sbin"/* "{{env_var("DESTDIR")}}/usr/bin/" || true; \
        rmdir "{{env_var("DESTDIR")}}/sbin" || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/usr/sbin" ]; then \
        mkdir -p "{{env_var("DESTDIR")}}/usr/bin" && \
        mv "{{env_var("DESTDIR")}}/usr/sbin"/* "{{env_var("DESTDIR")}}/usr/bin/" || true; \
        rmdir "{{env_var("DESTDIR")}}/usr/sbin" || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/lib" ]; then \
        mkdir -p "{{env_var("DESTDIR")}}/usr/lib" && \
        mv "{{env_var("DESTDIR")}}/lib"/* "{{env_var("DESTDIR")}}/usr/lib/" || true; \
        rmdir "{{env_var("DESTDIR")}}/lib" || true; \
    fi
    
    # Clean up libtool archives and glibc-specific locale/extension leftovers if any
    find "{{env_var("DESTDIR")}}" -name "*.la" -delete || true
    
    # Strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
