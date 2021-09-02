#!/bin/bash

cp -r ${BUILD_PREFIX}/share/libtool/build-aux/config.* ./config

if [ "$(uname)" == "Darwin" ]; then
    LDFLAGS="-Wl,-rpath,$PREFIX/lib $LDFLAGS"
fi

./configure \
    --prefix=$PREFIX \
    --with-readline \
    --with-libraries=$PREFIX/lib \
    --with-includes=$PREFIX/include \
    --with-openssl \
    --with-gssapi

make -j $CPU_COUNT
# make check # Failing with 'initdb: cannot be run as root'.
make install
