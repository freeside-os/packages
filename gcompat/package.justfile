build:
    tar -xf gcompat-1.1.0.tar.xz
    cd gcompat-1.1.0 && make -j$(nproc) LINKER_PATH=/lib/ld-musl-x86_64.so.1

package destdir:
    cd gcompat-1.1.0 && make DESTDIR="{{destdir}}" install
    # Link for glibc x86_64 binary compatibility
    ln -sf ld-linux.so.2 "{{destdir}}/usr/lib/ld-linux-x86-64.so.2"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true
