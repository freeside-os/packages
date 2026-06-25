# package.justfile for bmon

set shell := ["/bin/bash", "-cu"]

build:
    tar -zxf bmon-{{env_var("PKG_VERSION")}}.tar.gz
    echo "=== grep SYS_ ==="
    grep -rn "SYS_" bmon-4.0/src/ bmon-4.0/include/ || true
    exit 1

package:
    mkdir -p "$DESTDIR/usr/bin"