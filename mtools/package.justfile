build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}.tar.bz2
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --mandir=/usr/share/man \
        --infodir=/usr/share/info \
        --bindir=/usr/bin \
        --sbindir=/usr/bin \
        --libdir=/usr/lib \
        --without-x && \
    make

package:
    make DESTDIR="{{env_var("DESTDIR")}}" install -C {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}
    install -vDm 644 {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/mtools.conf -t "{{env_var("DESTDIR")}}/etc/"
    sed -i 's/^SAMPLE FILE/# SAMPLE FILE/' "{{env_var("DESTDIR")}}/etc/mtools.conf"
    install -vDm 644 {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/COPYING -t "{{env_var("DESTDIR")}}/usr/share/licenses/{{env_var("PKG_NAME")}}/"
    install -vDm 644 {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/README {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/NEWS -t "{{env_var("DESTDIR")}}/usr/share/doc/{{env_var("PKG_NAME")}}"
    
    # Enforce strict permissions on directories and binaries
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then \
        find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} + || true; \
    fi
