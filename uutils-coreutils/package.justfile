build:
    tar -xf $PKG_VERSION.tar.gz
    cd coreutils-$PKG_VERSION && cargo build --release --features feat_os_unix_musl

package:
    mkdir -p "$DESTDIR/usr/bin"
    cp coreutils-$PKG_VERSION/target/release/coreutils "$DESTDIR/usr/bin/coreutils"
    for cmd in cat chgrp chmod chown cp date dd df du echo false ln ls mkdir mknod mv pwd rm rmdir sleep sync touch true uname whoami base64 basename cksum comm csplit cut dir dircolors dirname env expand expr factor fmt fold head hostid id install join link logname md5sum mkfifo mktemp nice nl nohup nproc od paste pathchk pinky pr printenv printf ptx readlink realpath runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sort split stat stty sum tac tail tee test timeout tr truncate tsort tty unexpand uniq unlink users vdir wc who yes; do \
        ln -sf coreutils "$DESTDIR/usr/bin/${cmd}"; \
    done
    find "$DESTDIR" -type d -exec chmod 755 {} +
    find "$DESTDIR/usr/bin" -type f -exec chmod 755 {} +
