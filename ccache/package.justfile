build:
    tar -xf ccache-4.10.2.tar.xz
    cd ccache-4.10.2 && cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build -j$(nproc)

package destdir:
    cd ccache-4.10.2 && cmake --install build --destdir "{{destdir}}"
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
