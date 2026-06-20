#!/usr/bin/env bash
# generate_tarball.sh: Package local straylight source code
set -euo pipefail

# Ensure we run from the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== [straylight] Packaging Straylight CLI Source ==="
# Exclude cargo build targets and temporary config files
tar --exclude='target' --exclude='.straylight' --exclude='.cargo' -czf straylight-1.0.0.tar.gz -C ../../ straylight

echo "=== [straylight] Calculating SHA256 Checksum ==="
CHECKSUM=$(sha256sum straylight-1.0.0.tar.gz | awk '{print $1}')
echo "Tarball checksum: ${CHECKSUM}"

echo "=== [straylight] Generating package.manifest ==="
cat > package.manifest << EOF
[package]
name = "straylight"
version = "1.0.0"
description = "Straylight Package Manager CLI"
dependencies = ["musl", "rust"]
group = "system"

[[sources]]
file = "straylight-1.0.0.tar.gz"
checksum = { algorithm = "sha256", value = "${CHECKSUM}" }

[build]
dependencies = ["musl", "rust"]
EOF

echo "=== [straylight] Tarball Generation and Manifest Update Completed ==="
