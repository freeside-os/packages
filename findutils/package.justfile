build:
    tar -xf $PKG_NAME-$PKG_VERSION.tar.xz
    cd $PKG_NAME-$PKG_VERSION && sed -e '/^SUBDIRS/s/locate//' -e 's/frcode locate updatedb//' -i Makefile.in
    cd $PKG_NAME-$PKG_VERSION && ./configure $CONFIGURE_ARGS
    cd $PKG_NAME-$PKG_VERSION && make -C locate dblocation.texi
    cd $PKG_NAME-$PKG_VERSION && make -j$(nproc)

package:
    cd $PKG_NAME-$PKG_VERSION && make DESTDIR="$DESTDIR" install