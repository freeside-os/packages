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
systemd-journal-remote:x:197:197:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:198:198:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:192:192:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:193:193:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:194:194:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:195:195:systemd Core Dumper:/:/usr/bin/false
systemd-oom:x:196:196:systemd Userspace OOM Killer:/:/usr/bin/false
nobody:x:65534:65534:nobody:/:/usr/bin/sh
EOF

# 2. usr/share/freeside/etc/group
cat > "${ETC_DIR}/group" << 'EOF'
root:x:0:
daemon:x:1:
bin:x:2:
tty:x:5:
disk:x:6:
lp:x:7:
kmem:x:9:
wheel:x:10:root
cdrom:x:11:
dialout:x:18:
audio:x:29:
video:x:44:
utmp:x:50:
users:x:100:
render:x:106:
input:x:107:
kvm:x:108:
systemd-journal:x:190:
systemd-network:x:192:
systemd-resolve:x:193:
systemd-timesync:x:194:
systemd-coredump:x:195:
systemd-oom:x:196:
systemd-journal-remote:x:197:
systemd-journal-upload:x:198:
nobody:x:65534:
EOF

# 3. usr/share/freeside/etc/shadow
cat > "${ETC_DIR}/shadow" << 'EOF'
root:::0:99999:7:::
daemon:*:19000:0:99999:7:::
bin:*:19000:0:99999:7:::
systemd-journal-remote:!:19000:0:99999:7:::
systemd-journal-upload:!:19000:0:99999:7:::
systemd-network:!:19000:0:99999:7:::
systemd-resolve:!:19000:0:99999:7:::
systemd-timesync:!:19000:0:99999:7:::
systemd-coredump:!:19000:0:99999:7:::
systemd-oom:!:19000:0:99999:7:::
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

# 6. usr/share/freeside/etc/nsswitch.conf
cat > "${ETC_DIR}/nsswitch.conf" << 'EOF'
passwd:     files
group:      files
shadow:     files

hosts:      files dns
networks:   files

protocols:  files
services:   files
ethers:     files
rpc:        files
EOF

echo "=== [base-files] Generating Tarball ==="
tar -C "${TEMP_DIR}" -czf base-files-1.1.0.tar.gz usr

echo "=== [base-files] Calculating SHA256 Checksum ==="
CHECKSUM=$(sha256sum base-files-1.1.0.tar.gz | awk '{print $1}')
echo "Tarball checksum: ${CHECKSUM}"

BASE_FILES_CONF_SUM=$(sha256sum base-files.conf | awk '{print $1}')
ETC_MOUNT_SUM=$(sha256sum etc.mount | awk '{print $1}')
OS_RELEASE_SUM=$(sha256sum os-release | awk '{print $1}')

echo "=== [base-files] Generating packages/base-files/package.manifest ==="
cat > package.manifest << EOF
[package]
name = "base-files"
version = "1.1.0"
description = "Freeside OS base filesystem layout, directory topologies, and core OverlayFS templates"
dependencies = []
group = "base"

[[sources]]
file = "base-files-1.1.0.tar.gz"
checksum = { algorithm = "sha256", value = "${CHECKSUM}" }

[[sources]]
file = "base-files.conf"
checksum = { algorithm = "sha256", value = "${BASE_FILES_CONF_SUM}" }

[[sources]]
file = "etc.mount"
checksum = { algorithm = "sha256", value = "${ETC_MOUNT_SUM}" }

[[sources]]
file = "os-release"
checksum = { algorithm = "sha256", value = "${OS_RELEASE_SUM}" }

[build]
dependencies = []

[build.environment]
FREESIDE_VERSION = "0.1.0"
EOF

echo "=== [base-files] Assembly Completed Successfully ==="
