build:
    tar -xf bc-{{env_var("PKG_VERSION")}}.tar.gz
    cd bc-{{env_var("PKG_VERSION")}} && ./configure \
      --prefix=/usr \
      --mandir=/usr/share/man \
      --infodir=/usr/share/info \
      --with-readline \
      MAKEINFO=true
    cd bc-{{env_var("PKG_VERSION")}} && make -j$(nproc) MAKEINFO=true

package:
    cd bc-{{env_var("PKG_VERSION")}} && make DESTDIR="{{env_var("DESTDIR")}}" install MAKEINFO=true

    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    find "{{env_var("DESTDIR")}}" -type f -name "*" -executable -exec chmod 755 {} +
