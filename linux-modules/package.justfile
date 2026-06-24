pkg_name := env_var_or_default("PKG_NAME", "linux-modules")
pkg_version := env_var_or_default("PKG_VERSION", "7.1.0")
destdir := env_var_or_default("DESTDIR", "pkg-dest")

llvm_flags := "CC=clang LD=ld.lld LLVM=1 LLVM_IAS=1"

build:
    # Nothing to compile, it's already compiled by linux-mainline.

package:
    # Install driver modules using the build tree at /usr/lib/freeside/linux/linux-mainline
    mkdir -p "{{destdir}}"/usr/lib/modules
    cd /usr/lib/freeside/linux/linux-mainline && make ARCH=x86_64 {{llvm_flags}} INSTALL_MOD_PATH="{{destdir}}"/usr modules_install
    
    # Strip debugging symbols and remove transient development symlinks
    find "{{destdir}}"/usr/lib/modules/ -name "*.ko" -exec llvm-objcopy --strip-debug {} \;
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}/build || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}/source || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}-freeside/build || true
    rm -f "{{destdir}}"/usr/lib/modules/{{pkg_version}}-freeside/source || true

    # Strict permissions: Enforce chmod 755 on directories and binaries at the end of the package step
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}"/usr -type f -executable -exec chmod 755 {} + || true
