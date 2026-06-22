build:
    tar -xf {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}-x86_64-unknown-linux-musl.tar.gz

package:
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}-x86_64-unknown-linux-musl && ./install.sh --prefix="{{env_var("DESTDIR")}}/usr" --components=rustc,cargo,rust-std-x86_64-unknown-linux-musl
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/bin" ]; then find "{{env_var("DESTDIR")}}/usr/bin" -type f -exec chmod 755 {} +; fi
