build:
    tar -xf argp-standalone-{{env_var("PKG_VERSION")}}.tar.gz
    cd argp-standalone-{{env_var("PKG_VERSION")}} && ./configure --prefix=/usr CFLAGS="-g -O2 -fgnu89-inline"
    cd argp-standalone-{{env_var("PKG_VERSION")}} && make -j$(nproc)

package:
    mkdir -p "{{env_var("DESTDIR")}}"/usr/lib
    mkdir -p "{{env_var("DESTDIR")}}"/usr/include
    cp argp-standalone-{{env_var("PKG_VERSION")}}/libargp.a "{{env_var("DESTDIR")}}"/usr/lib/libargp.a
    cp argp-standalone-{{env_var("PKG_VERSION")}}/argp.h "{{env_var("DESTDIR")}}"/usr/include/argp.h

    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    find "{{env_var("DESTDIR")}}" -type f -name "*" -exec chmod 644 {} +
    find "{{env_var("DESTDIR")}}"/usr/lib -type f -exec chmod 755 {} + || true
