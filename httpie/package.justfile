build:
    pwd
    echo "=== Listing current directory ==="
    ls -la
    echo "=== Listing parent directory ==="
    ls -la ..
    echo "=== Searching for downloaded source ==="
    find /workspace -maxdepth 4 -name "*.tar.gz" 2>/dev/null || true

package:
    echo "Dummy package"
