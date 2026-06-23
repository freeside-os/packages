build:
    tar -xf v{{env_var("PKG_VERSION")}}.tar.gz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    echo '#define HAVE_DIRFD 1' > config.h && \
    gcc -O2 -fPIC -D_GNU_SOURCE -I. -c fts.c -o fts.o && \
    ar rcs libfts.a fts.o && \
    gcc -shared -o libfts.so fts.o

package:
    mkdir -p "{{env_var("DESTDIR")}}/usr/include"
    mkdir -p "{{env_var("DESTDIR")}}/usr/lib"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/fts.h "{{env_var("DESTDIR")}}/usr/include/"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/libfts.a "{{env_var("DESTDIR")}}/usr/lib/"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/libfts.so "{{env_var("DESTDIR")}}/usr/lib/"

    # Strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
