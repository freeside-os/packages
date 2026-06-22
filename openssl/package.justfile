build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.gz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && ./config {{env_var("CONFIGURE_ARGS")}} && make -j$(nproc)

package:
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && make DESTDIR="{{env_var("DESTDIR")}}" install_sw
    
    # Strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
