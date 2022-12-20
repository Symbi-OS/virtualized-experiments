#!/bin/bash

set -x

wget https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-${1}.tar.gz
tar xf linux-${1}.tar.gz
cd linux-${1}
make defconfig
cat >> .config <<EOF
CONFIG_VIRTIO_NET=y
CONFIG_HYPERVISOR_GUEST=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_CONSOLE=y
CONFIG_VIRTIO_BLK=y
CONFIG_NET_9P=y
CONFIG_NET_9P_VIRTIO=y
CONFIG_SCSI_LOWLEVEL=y
CONFIG_SCSI_VIRTIO=y
CONFIG_DRM_VIRTIO_GPU=y
EOF
make olddefconfig
make -j`nproc`
cp arch/x86/boot/bzImage /kernels/vmlinuz.${1}-baseline
