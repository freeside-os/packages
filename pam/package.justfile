build:
    tar -xf Linux-PAM-{{env_var("PKG_VERSION")}}.tar.xz
    cd Linux-PAM-{{env_var("PKG_VERSION")}} && meson setup build \
      --prefix=/usr \
      --sbindir=/usr/bin \
      --libdir=/usr/lib \
      --libexecdir=/usr/lib \
      -Dlogind=enabled \
      -Deconf=disabled \
      -Dselinux=disabled \
      -Delogind=disabled \
      -Dpam_userdb=disabled \
      -Dpwaccess=disabled \
      -Dnis=disabled \
      -Dvendordir=''
    meson compile -C Linux-PAM-{{env_var("PKG_VERSION")}}/build

package:
    meson install -C Linux-PAM-{{env_var("PKG_VERSION")}}/build --destdir "{{env_var("DESTDIR")}}"
    mkdir -p "{{env_var("DESTDIR")}}/usr/lib/tmpfiles.d"
    echo "d /run/console 0755 root root -" > "{{env_var("DESTDIR")}}/usr/lib/tmpfiles.d/{{env_var("PKG_NAME")}}.conf"

    # remove unreproducible pdf files
    rm -f "{{env_var("DESTDIR")}}"/usr/share/doc/Linux-PAM/*.pdf || true

    # strict directory and executable permissions compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    find "{{env_var("DESTDIR")}}" -type f -perm -111 -exec chmod 755 {} +

    # set unix_chkpwd setuid dynamically after general executable permissions reset
    find "{{env_var("DESTDIR")}}" -name unix_chkpwd -exec chmod 4755 {} +
