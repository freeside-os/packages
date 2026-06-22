build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.xz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    ./configure --prefix=/usr --shared && \
    make
    ls -R {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/contrib/minizip

package:
    make install DESTDIR="{{env_var("DESTDIR")}}" -C {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}
    install -D -m644 {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/LICENSE -t "{{env_var("DESTDIR")}}/usr/share/licenses/{{env_var("PKG_NAME")}}/"
    
    # Strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
