#!/usr/bin/env bash
# generate_tarball.sh: Orchestrate creation of the base-files-1.0.0.tar.gz template
set -euo pipefail

# Ensure we run from the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== [base-files] Constructing Filesystem Layout ==="
TEMP_DIR=$(mktemp -d -t base-files-build-XXXXXX)
trap 'rm -rf "${TEMP_DIR}"' EXIT

ETC_DIR="${TEMP_DIR}/usr/share/freeside/etc"
mkdir -p "${ETC_DIR}"

# 1. usr/share/freeside/etc/passwd
cat > "${ETC_DIR}/passwd" << 'EOF'
root:x:0:0:root:/root:/usr/bin/bash
daemon:x:1:1:daemon:/usr/bin:/usr/bin/sh
bin:x:2:2:bin:/usr/bin:/usr/bin/sh
nobody:x:65534:65534:nobody:/:/usr/bin/sh
EOF

# 2. usr/share/freeside/etc/group
cat > "${ETC_DIR}/group" << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
wheel:x:10:root
nobody:x:65534:
EOF

# 3. usr/share/freeside/etc/shadow
cat > "${ETC_DIR}/shadow" << 'EOF'
root:::0:99999:7:::
daemon:*:19000:0:99999:7:::
bin:*:19000:0:99999:7:::
nobody:!:19000:0:99999:7:::
EOF

# 4. usr/share/freeside/etc/shells
cat > "${ETC_DIR}/shells" << 'EOF'
/bin/sh
/bin/bash
/usr/bin/sh
/usr/bin/bash
EOF

# 5. usr/share/freeside/etc/hosts
cat > "${ETC_DIR}/hosts" << 'EOF'
127.0.0.1   localhost
::1         localhost
EOF

echo "=== [base-files] Generating Tarball ==="
tar -C "${TEMP_DIR}" -czf base-files-1.0.0.tar.gz usr

echo "=== [base-files] Calculating SHA256 Checksum ==="
CHECKSUM=$(sha256sum base-files-1.0.0.tar.gz | awk '{print $1}')
echo "Tarball checksum: ${CHECKSUM}"

echo "=== [base-files] Generating packages/base-files/package.manifest ==="
cat > package.manifest << EOF
[package]
name = "base-files"
version = "1.0.0"
description = "Freeside OS base filesystem layout, directory topologies, and core OverlayFS templates"
dependencies = []

[source]
file = "base-files-1.0.0.tar.gz"
checksum = { algorithm = "sha256", value = "${CHECKSUM}" }

[build]
dependencies = []
EOF

echo "=== [base-files] Assembly Completed Successfully ==="
