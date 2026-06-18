build:
    tar -xf 0.0.28.tar.gz
    cd coreutils-0.0.28 && cargo build --release --features feat_os_unix_musl

package destdir:
    mkdir -p "{{destdir}}/usr/bin"
    cp coreutils-0.0.28/target/release/coreutils "{{destdir}}/usr/bin/coreutils"
    for cmd in cat chgrp chmod chown cp date dd df du echo false ln ls mkdir mknod mv pwd rm rmdir sleep sync touch true uname whoami base64 basename cksum comm csplit cut dir dircolors dirname env expand expr factor fmt fold head hostid id install join link logname md5sum mkfifo mktemp nice nl nohup nproc od paste pathchk pinky pr printenv printf ptx readlink realpath runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sort split stat stty sum tac tail tee test timeout tr truncate tsort tty unexpand uniq unlink users vdir wc who yes; do \
        ln -sf coreutils "{{destdir}}/usr/bin/${cmd}"; \
    done
    find "{{destdir}}" -type d -exec chmod 755 {} +
    find "{{destdir}}/usr/bin" -type f -exec chmod 755 {} +
