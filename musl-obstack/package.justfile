build:
    tar -xf v{{env_var("PKG_VERSION")}}.tar.gz
    cd {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}} && \
    gcc -O2 -fPIC -D_GNU_SOURCE -Wno-implicit-function-declaration -I. -c obstack.c -o obstack.o && \
    gcc -O2 -fPIC -D_GNU_SOURCE -Wno-implicit-function-declaration -I. -c obstack_printf.c -o obstack_printf.o && \
    ar rcs libobstack.a obstack.o obstack_printf.o && \
    gcc -shared -o libobstack.so obstack.o obstack_printf.o

package:
    mkdir -p "{{env_var("DESTDIR")}}/usr/include"
    mkdir -p "{{env_var("DESTDIR")}}/usr/lib"
    mkdir -p "{{env_var("DESTDIR")}}/usr/lib/pkgconfig"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/obstack.h "{{env_var("DESTDIR")}}/usr/include/"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/libobstack.a "{{env_var("DESTDIR")}}/usr/lib/"
    cp {{env_var("PKG_NAME")}}-{{env_var("PKG_VERSION")}}/libobstack.so "{{env_var("DESTDIR")}}/usr/lib/"

    echo "Name: musl-obstack" > "{{env_var("DESTDIR")}}/usr/lib/pkgconfig/musl-obstack.pc"
    echo "Description: Standalone obstack implementation for musl" >> "{{env_var("DESTDIR")}}/usr/lib/pkgconfig/musl-obstack.pc"
    echo "Version: {{env_var("PKG_VERSION")}}" >> "{{env_var("DESTDIR")}}/usr/lib/pkgconfig/musl-obstack.pc"
    echo "Libs: -L/usr/lib -lobstack" >> "{{env_var("DESTDIR")}}/usr/lib/pkgconfig/musl-obstack.pc"
    echo "Cflags: -I/usr/include" >> "{{env_var("DESTDIR")}}/usr/lib/pkgconfig/musl-obstack.pc"

    # Strict permissions and compliance
    find "{{env_var("DESTDIR")}}" -type d -exec chmod 755 {} +
    if [ -d "{{env_var("DESTDIR")}}/usr/lib" ]; then \
        find "{{env_var("DESTDIR")}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; \
    fi
