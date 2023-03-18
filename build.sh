#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

apk add \
  curl \
  gcc \
  git \
  musl-dev \
  linux-headers \
  make \
  patch \
  pcre-dev \
  perl-dev \
  zlib-dev

BUILD_PATH=/tmp/build
mkdir -pv "$BUILD_PATH" && cd "$BUILD_PATH"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

# Git tuning
git config --global --add core.compression -1

git clone --depth 1 https://github.com/Kong/kong-build-tools.git
git clone --depth 1 https://github.com/nbs-system/naxsi.git

cd kong-build-tools/openresty-build-tools
mkdir -pv work
./kong-ngx-build -p /usr/local --openresty 1.19.9.1 --openssl 1.1.1s --luarocks 3.9.1 --add-module $BUILD_PATH/naxsi/naxsi_src --force

# remove .a files
find /usr/local -name "*.a" -exec /bin/rm -fv "{}" \;
