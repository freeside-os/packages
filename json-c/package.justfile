build:
    tar xzf json-c-0.17-20230812.tar.gz
    cd json-c-json-c-0.17-20230812 && \
    cmake -B build -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DENABLE_THREADING=ON \
        -DCMAKE_BUILD_TYPE=Release
    cd json-c-json-c-0.17-20230812 && cmake --build build

package:
    cd json-c-json-c-0.17-20230812 && DESTDIR="$DESTDIR" cmake --install build
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -name "*.so*" -exec chmod 755 {} + || true
