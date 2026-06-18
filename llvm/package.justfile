build:
    tar -xf llvm-project-$PKG_VERSION.src.tar.xz
    mkdir -p llvm-project-$PKG_VERSION.src/build
    cd llvm-project-$PKG_VERSION.src/build && cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DLLVM_TARGETS_TO_BUILD="X86" \
        -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-freeside-linux-musl" \
        -DLLVM_ENABLE_PROJECTS="clang;lld" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
        -DCLANG_DEFAULT_LINKER="lld" \
        -DCLANG_DEFAULT_RTLIB="compiler-rt" \
        -DCLANG_DEFAULT_CXX_STDLIB="libc++" \
        ../llvm && make -j$(nproc)

package destdir:
    cd llvm-project-$PKG_VERSION.src/build && make DESTDIR="{{destdir}}" install
    find "{{destdir}}" -type d -exec chmod 755 {} +
    if [ -d "{{destdir}}/usr/bin" ]; then find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +; fi
    if [ -d "{{destdir}}/usr/lib" ]; then find "{{destdir}}/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
