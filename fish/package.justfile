build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.xz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    cmake -B build -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_SYSCONFDIR=/etc \
        -DCMAKE_BUILD_TYPE=Release \
        -DWITH_DOCS=OFF
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && cmake --build build

package:
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && DESTDIR="{{env_var("DESTDIR")}}" cmake --install build
    
    # Enforce strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
