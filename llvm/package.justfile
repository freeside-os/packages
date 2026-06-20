build:
	tar -xf llvm-project-$PKG_VERSION.src.tar.xz
	mkdir -p llvm-project-$PKG_VERSION.src/build
	cd llvm-project-$PKG_VERSION.src/build && cmake -G "Unix Makefiles" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-freeside-linux-musl" \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
		-DCLANG_DEFAULT_LINKER="lld" \
		-DCLANG_DEFAULT_RTLIB="compiler-rt" \
		-DCLANG_DEFAULT_CXX_STDLIB="libc++" \
		-DLIBCXX_HAS_MUSL_LIBC=ON \
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF \
		-DCOMPILER_RT_BUILD_GWP_ASAN=OFF \
		-DCOMPILER_RT_BUILD_XRAY=OFF \
		-DCOMPILER_RT_BUILD_ORC=OFF \
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
		-DCOMPILER_RT_BUILD_MEMPROF=OFF \
		../llvm && make -j$(nproc)

package:
	#!/usr/bin/env bash
	set -euo pipefail
	cd llvm-project-$PKG_VERSION.src/build && make DESTDIR="$DESTDIR" install
	ln -sf clang "$DESTDIR/usr/bin/cc"
	ln -sf clang "$DESTDIR/usr/bin/gcc"
	ln -sf clang++ "$DESTDIR/usr/bin/c++"
	ln -sf clang++ "$DESTDIR/usr/bin/g++"
	ln -sf clang-cpp "$DESTDIR/usr/bin/cpp"
	ln -sf llvm-ar "$DESTDIR/usr/bin/ar"
	ln -sf llvm-ranlib "$DESTDIR/usr/bin/ranlib"
	ln -sf llvm-nm "$DESTDIR/usr/bin/nm"
	ln -sf llvm-strip "$DESTDIR/usr/bin/strip"
	ln -sf llvm-objcopy "$DESTDIR/usr/bin/objcopy"
	ln -sf llvm-objdump "$DESTDIR/usr/bin/objdump"
	ln -sf llvm-readelf "$DESTDIR/usr/bin/readelf"
	ln -sf lld "$DESTDIR/usr/bin/ld"
	BUILTINS_LIB=$(find "$DESTDIR/usr/lib/clang" -name "libclang_rt.builtins.a" | head -n1)
	if [ -n "$BUILTINS_LIB" ]; then
		REL_PATH=$(realpath --relative-to="$DESTDIR/usr/lib" "$BUILTINS_LIB")
		ln -sf "$REL_PATH" "$DESTDIR/usr/lib/libgcc.a"
	fi
	if [ -d "$DESTDIR/usr/lib/x86_64-freeside-linux-musl" ]; then
		for lib in "$DESTDIR/usr/lib/x86_64-freeside-linux-musl"/*.so*; do
			if [ -e "$lib" ]; then
				ln -sf "x86_64-freeside-linux-musl/$(basename "$lib")" "$DESTDIR/usr/lib/$(basename "$lib")"
			fi
		done
	fi
	find "$DESTDIR" -type d -exec chmod 755 {} +
	if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
	if [ -d "$DESTDIR/usr/lib" ]; then find "$DESTDIR/usr/lib" -name "*.so*" -exec chmod 755 {} + || true; fi
