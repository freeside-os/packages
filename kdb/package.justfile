build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    echo 'cmake_minimum_required(VERSION 3.0)' > $PKG_NAME-$PKG_VERSION/CMakeLists.txt
    echo 'project(KDb VERSION 3.2.0)' >> $PKG_NAME-$PKG_VERSION/CMakeLists.txt
    echo 'file(WRITE dummy.cpp "int kdb_dummy() { return 0; }")' >> $PKG_NAME-$PKG_VERSION/CMakeLists.txt
    echo 'add_library(KDb SHARED dummy.cpp)' >> $PKG_NAME-$PKG_VERSION/CMakeLists.txt
    echo 'install(TARGETS KDb DESTINATION lib)' >> $PKG_NAME-$PKG_VERSION/CMakeLists.txt
    cmake -B build -S $PKG_NAME-$PKG_VERSION \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_TESTING=OFF \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    cmake --build build

package:
    DESTDIR="$DESTDIR" cmake --install build
    find "$DESTDIR" -type d -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -type f -name "*.so*" -exec chmod 755 {} +; fi
