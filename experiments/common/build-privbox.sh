#!/bin/bash

set -x

dnf install -y \
     'dnf-command(builddep)' \
     git \
     ninja-build \
     podman \
     libguestfs-tools \
     qemu-img \
     flex \
     bison \
     elfutils-libelf-devel \
     openssl-devel \
     glibc-static \
     automake \
     rsync \
     bc \
     hostname \
     libevent-devel \
     pcre-devel \
     libtool \
     sudo

dnf builddep -y clang

export WORKDIR=/privbox

cd ${WORKDIR?}
git clone -b privbox https://github.com/privbox/llvm-project
git clone -b privbox https://github.com/privbox/linux kernel
git clone -b privbox https://github.com/privbox/musl
git clone -b privbox https://github.com/Symbi-OS/privbox-devenv.git devenv
git clone -b privbox https://github.com/privbox/redis
git clone https://github.com/privbox/redis redis-vanilla

cd ${WORKDIR?}/devenv/images
make kernel-headers
make kernel
make initrd
make rootfs
make tools

cd ${WORKDIR?}/llvm-project
cmake \
    -S llvm \
    -B build \
    -G Ninja \
    -DLLVM_ENABLE_PROJECTS='clang;compiler-rt;lld' \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DBUILD_SHARED_LIBS=OFF

# The final link can OOM a machine, if the build fails (and hopefully doesn't kill this process)
# Retry with 1 process
cmake --build build || cmake --build build -j 1

cd ${WORKDIR?}/musl
./build.sh

# redis:
cd ${WORKDIR?}/redis
./build-all.sh

cd ${WORKDIR?}/redis-vanilla/deps
make jemalloc
cd ${WORKDIR?}/redis-vanilla
make -j$(nproc)
cp src/redis-benchmark ${WORKDIR?}/devenv/bin/

