build:
    tar -xf *[jJ]inja2-$PKG_VERSION.tar.gz

package:
    cd *[Jj]inja2-$PKG_VERSION && \
    echo 'from setuptools import setup, find_packages' > setup.py && \
    echo 'setup(name="Jinja2", version="3.1.4", package_dir={"": "src"}, packages=find_packages(where="src"))' >> setup.py && \
    python3 setup.py install --prefix=/usr --root="$DESTDIR"
    find "$DESTDIR" -type d -exec chmod 755 {} +
