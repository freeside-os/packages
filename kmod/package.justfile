build:
    tar -xf kmod-{{env_var("PKG_VERSION")}}.tar.xz
    cd kmod-{{env_var("PKG_VERSION")}} && meson setup build \
      --prefix=/usr \
      --libdir=/usr/lib \
      --sysconfdir=/etc \
      --sbindir=/usr/bin \
      -Dmanpages=false \
      -Dopenssl=enabled \
      -Dxz=enabled \
      -Dzlib=enabled \
      -Dzstd=enabled
    cd kmod-{{env_var("PKG_VERSION")}} && meson compile -C build

package:
    cd kmod-{{env_var("PKG_VERSION")}} && meson install -C build --destdir "{{env_var("DESTDIR")}}"

    # extra directories
    install -dm0755 "{{env_var("DESTDIR")}}/etc/depmod.d"
    install -dm0755 "{{env_var("DESTDIR")}}/etc/modprobe.d"
    install -dm0755 "{{env_var("DESTDIR")}}/usr/lib/depmod.d"
    install -dm0755 "{{env_var("DESTDIR")}}/usr/lib/modprobe.d"

    # Symlinks for kmod utilities
    install -dm0755 "{{env_var("DESTDIR")}}/usr/bin"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/lsmod"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/rmmod"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/insmod"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/modinfo"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/modprobe"
    ln -sf kmod "{{env_var("DESTDIR")}}/usr/bin/depmod"
