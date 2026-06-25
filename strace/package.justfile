build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.xz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    ./configure {{env_var("CONFIGURE_ARGS")}} && \
    make -j$(nproc)

package:
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    make DESTDIR="{{env_var("DESTDIR")}}" install
    
    # Strict permissions and UsrMerge compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
