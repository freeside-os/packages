clean:
    find . -maxdepth 1 -type d -name "{{env_var("PKG_NAME")}}-*" -exec rm -rf {} +

build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.gz
    cd {{env_var("PKG_NAME")}}-*/ && ./configure \
        --prefix=/usr \
        --sbindir=/usr/bin \
        --libdir=/usr/lib \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    cd {{env_var("PKG_NAME")}}-*/ && make -j$(nproc)

package:
    cd {{env_var("PKG_NAME")}}-*/ && make DESTDIR="{{env_var("DESTDIR")}}" install
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then find "{{env_var("DESTDIR")}}/usr/lib" -type f -name "*.so*" -exec chmod 755 {} +; fi
