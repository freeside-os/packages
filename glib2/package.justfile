build:
    tar -xf glib-{{env_var("PKG_VERSION")}}.tar.xz
    cd glib-{{env_var("PKG_VERSION")}} && \
    export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt && \
    meson setup build \
        --prefix=/usr \
        --libdir=/usr/lib \
        --libexecdir=/usr/libexec \
        --sbindir=/usr/bin \
        --buildtype=release \
        -Dintrospection=disabled \
        -Dman-pages=disabled \
        -Dtests=false \
        -Dselinux=disabled \
        -Dsysprof=disabled \
        -Dsystemtap=disabled \
        -Ddtrace=disabled \
        -Dglib_debug=disabled && \
    meson compile -C build

package:
    cd glib-{{env_var("PKG_VERSION")}} && DESTDIR="{{env_var("DESTDIR")}}" meson install -C build
    
    # Strict permissions and UsrMerge compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
