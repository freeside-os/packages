build:
    tar -xf elfutils-{{env_var("PKG_VERSION")}}.tar.bz2
    cd elfutils-{{env_var("PKG_VERSION")}} && ./configure \
      CFLAGS="-O2 -g -DFNM_EXTMATCH=0" \
      LIBS="-largp -lfts -lobstack" \
      --prefix=/usr \
      --sysconfdir=/etc \
      --program-prefix="eu-" \
      --enable-deterministic-archives \
      --disable-debuginfod \
      --disable-libdebuginfod \
      --disable-nls
    cd elfutils-{{env_var("PKG_VERSION")}} && make -j$(nproc)

package:
    cd elfutils-{{env_var("PKG_VERSION")}} && make DESTDIR="{{env_var("DESTDIR")}}" install

    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    find "{{env_var("DESTDIR")}}" -type f -name "*" -executable -exec chmod 755 {} +