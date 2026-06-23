build:
    tar -xf *[jJ]inja2-$PKG_VERSION.tar.gz

package:
    cd *[Jj]inja2-$PKG_VERSION && \
    echo 'from setuptools import setup, find_packages' > setup.py && \
    echo 'setup(name="Jinja2", version="'"$PKG_VERSION"'", package_dir={"": "src"}, packages=find_packages(where="src"))' >> setup.py && \
    python3 setup.py install --prefix=/usr --root="$DESTDIR"
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR" -type f -name "*.so" -exec chmod 755 {} +
    if [ -d "$DESTDIR/usr/bin" ]; then find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +; fi
