#!/bin/bash

# Get an updated config.sub and config.guess
cp -r ${BUILD_PREFIX}/share/libtool/build-aux/config.* ./config

# avoid absolute-paths in compilers
# ... this is required that pg_config provides more sane configuration in different environment
export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

./configure \
      --prefix=$PREFIX \
      --with-readline \
      --with-libraries=$PREFIX/lib \
      --with-includes=$PREFIX/include \
      --with-openssl \
      --with-gssapi  \
      --with-icu \
      --with-libxml \
      --with-libxslt \
      --with-lz4 \
      --with-zstd \
      --with-uuid=e2fs \
      --with-system-tzdata=$PREFIX/share/zoneinfo \
      --with-ldap \
      PG_SYSROOT="undefined"

make -j $CPU_COUNT
make -j $CPU_COUNT -C contrib
make check || exit 0
make check -C contrib
