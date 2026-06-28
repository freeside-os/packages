set shell := ["/bin/bash", "-cu"]

build:
    tar xf confuse-3.3.tar.xz
    tar xf libnl-3.11.0.tar.gz
    tar xf bmon-4.0.tar.gz
    
    # Build libconfuse
    cd confuse-3.3 && ./configure --prefix=/usr --disable-shared --enable-static --disable-examples && make -j$(nproc)
    
    # Build libnl
    cd libnl-3.11.0 && ./configure --prefix=/usr --sysconfdir=/etc --disable-shared --enable-static && make -j$(nproc)

    # Build bmon
    cd bmon-4.0 && \
    export CONFUSE_CFLAGS="-I$PWD/../confuse-3.3/src" && \
    export CONFUSE_LIBS="-L$PWD/../confuse-3.3/src/.libs -lconfuse" && \
    export LIBNL_CFLAGS="-I$PWD/../libnl-3.11.0/include" && \
    export LIBNL_LIBS="-L$PWD/../libnl-3.11.0/lib/.libs -lnl-3" && \
    export LIBNL_ROUTE_CFLAGS="-I$PWD/../libnl-3.11.0/include" && \
    export LIBNL_ROUTE_LIBS="-L$PWD/../libnl-3.11.0/lib/.libs -lnl-route-3 -lnl-3" && \
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make -j$(nproc)

package:
    cd bmon-4.0 && make DESTDIR=${DESTDIR} install
