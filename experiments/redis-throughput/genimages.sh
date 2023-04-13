#!/bin/bash

set -x

source ../common/network.sh
source ../common/build.sh
source ../common/set-cpus.sh

BUILDDIR=..
GUESTSTART=$(pwd)/data/guest_start.sh
IMAGES=$(pwd)/images

rm -rf $IMAGES
mkdir -p $IMAGES

# ========================================================================
# Generate Symbiote kernel and initrd's
# ========================================================================

SYMDIR=${BUILDDIR}/.symbios
mkdir -p $SYMDIR
pushd $SYMDIR
git clone https://github.com/Symbi-OS/artifacts.git
cd artifacts
make virt-ramdisk
cp initrd/base-redis.cpio.gz ${IMAGES}/
cp initrd/sym-redis.cpio.gz ${IMAGES}/
cp initrd/deep-sc-redis.cpio.gz ${IMAGES}/
cp all_releases/Linux/bzImage_symbiote_ret ${IMAGES}/vmlinuz.sym-ret
popd

# ========================================================================
# Generate UKL VM Images
# ========================================================================

build_ukl

# ========================================================================
# Generate Unikraft VM images
# ========================================================================

unikraft_eurosys21_build redis mimalloc $IMAGES

# ========================================================================
# Generate Privbox VM image
# ========================================================================

mkdir -p ${IMAGES}/privbox
docker pull fedora:36
CONTAINER=priv-builder
docker stop $CONTAINER
docker rm -f $CONTAINER
docker run --rm --privileged --name=${CONTAINER} -v ${IMAGES}/privbox:/privbox -dit fedora:36 /bin/bash
docker cp ../common/build-privbox.sh ${CONTAINER}:/
docker exec -it $CONTAINER /build-privbox.sh
mv ${IMAGES}/privbox/devenv/scripts/bzImage ${IMAGES}/vmlinuz.privbox
mv ${IMAGES}/privbox/devenv/images/build/base.img ${IMAGES}/privbox-disk.qcow2
mv ${IMAGES}/privbox/devenv/images/build/initrd.img ${IMAGES}/privbox-initrd.cpio.gz

if [[ ! -f ${IMAGES}/vmlinuz.privbox || ! -f ${IMAGES}/privbox-disk.qcow2 ]]; then
	echo "PrivBox build failed."
	exit 1
fi

docker stop $CONTAINER

# ========================================================================
# Generate Lupine VM images + redis ext2 rootfs
# ========================================================================

LUPINEDIR=${BUILDDIR}/.lupine

build_lupine

KERNELS="${LUPINEDIR}/Lupine-Linux/kernelbuild/"
# compressed one for QEMU
LUPINE_KVM_KPATH="${KERNELS}/lupine-djw-kml-qemu++redis/vmlinuz-4.0.0-kml"
GENERIC_KVM_KPATH="${KERNELS}/microvm++redis/vmlinuz-4.0.0"

if [ ! -f "$LUPINE_KVM_KPATH" ]; then
	echo "Lupine not built, something is wrong"
	exit 1
fi

cp $LUPINE_KVM_KPATH ${IMAGES}/lupine-qemu.kernel
cp $GENERIC_KVM_KPATH ${IMAGES}/generic-qemu.kernel

pushd ${LUPINEDIR}/Lupine-Linux/
# various patches...
cp ${GUESTSTART} ./scripts/guest_start.sh
sed -i -e "s/192.168.100/${BASEIP}/" ./scripts/guest_net.sh
sed -i -e "s/seek=20G/seek=500M/" ./scripts/image2rootfs.sh

# build image
./scripts/image2rootfs.sh redis 5.0.4-alpine ext2

# idempotence
git checkout ./scripts/image2rootfs.sh
git checkout ./scripts/guest_net.sh
git checkout ./scripts/guest_start.sh
popd

mv ${LUPINEDIR}/Lupine-Linux/redis.ext2 ${IMAGES}/redis.ext2

modprobe loop
mkdir -p /mnt/redis-tmp
mount -o loop ${IMAGES}/redis.ext2 /mnt/redis-tmp
cp ./data/redis.conf /mnt/redis-tmp
umount /mnt/redis-tmp
rm -rf /mnt/redis-tmp

# ========================================================================
# Generate Baseline kernels
# ========================================================================

build_5()
{
	CONTAINER=builder5
	docker stop $CONTAINER
	docker rm -f $CONTAINER
	docker run --rm --privileged --name=$CONTAINER -v ${IMAGES}:/kernels -dit ${2} /bin/bash
	docker cp ../common/setup-build.sh ${CONTAINER}:/
	docker cp ../common/build-kernel-5.x.sh ${CONTAINER}:/
	docker exec -it $CONTAINER /setup-build.sh dnf openssl-devel
	docker exec -it $CONTAINER /build-kernel-5.x.sh $1
	docker stop $CONTAINER
	docker rm -f $CONTAINER
	sleep 10
}

CONTAINER=builder4
docker stop $CONTAINER
docker rm -f $CONTAINER
docker pull fedora:20
docker pull fedora:30

docker run --rm --privileged --name=$CONTAINER -v ${IMAGES}:/kernels -dit fedora:20 /bin/bash
docker cp ../common/setup-build.sh ${CONTAINER}:/
docker cp ../common/build-kernel-4.0.sh ${CONTAINER}:/
docker exec -it $CONTAINER /setup-build.sh yum
docker exec -it $CONTAINER /build-kernel-4.0.sh
docker stop $CONTAINER
docker rm -f $CONTAINER

build_5 "5.8" "fedora:30"
build_5 "5.14" "fedora:36"
