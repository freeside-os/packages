build:
    tar -xf Python-{{env_var("PKG_VERSION")}}.tar.xz
    cd Python-{{env_var("PKG_VERSION")}} && ./configure {{env_var("CONFIGURE_ARGS")}} && make -j$(nproc)

package:
    cd Python-{{env_var("PKG_VERSION")}} && make DESTDIR="{{env_var("DESTDIR")}}" install
    # Enforce strict permissions compliance (chmod 755 on directories and binaries)
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
