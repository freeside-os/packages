prepare:
    #!/usr/bin/env bash
    set -e
    tar -xf procps-ng-4.0.6.tar.xz --strip-components=1 || tar -xf download --strip-components=1

build: prepare
    ./configure \
      --prefix=/usr \
      --exec-prefix=/ \
      --sysconfdir=/etc \
      --libdir=/usr/lib \
      --bindir=/usr/bin \
      --sbindir=/usr/bin \
      --enable-watch8bit \
      --with-systemd \
      --disable-modern-top \
      --disable-kill

    make -j$(nproc)

package destdir=env_var("DESTDIR"):
    export DESTDIR="{{destdir}}"
    make DESTDIR="$DESTDIR" install
