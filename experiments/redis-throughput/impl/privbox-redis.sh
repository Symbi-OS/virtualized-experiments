#!/bin/bash

# verbose output
set -x

source ../common/set-cpus.sh
source ../common/network.sh
source ../common/redis.sh
source ../common/qemu.sh

IMAGES=$(pwd)/images/
NETIF=unikraft0
mkdir -p rawdata results

kill_qemu

function cleanup {
	# kill all children (evil)
	kill_qemu
	pkill -P $$
	delete_bridge $NETIF
	rm -f images/disk0.qcow2
}

trap "cleanup" EXIT

create_bridge $NETIF $BASEIP

for mits in "mitigations=off mds=off" "" ; do
	if [ -z "$mits" ]; then
		mit="all"
	else
		mit="none"
	fi
	RESULTS=results/privbox-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS

	for ((j = 1 ; j < $RUNS ; j++)); do
		LOG=rawdata/privbox-qemu-redis-${mit}-${j}.txt
		touch $LOG
		qemu-img create -F qcow2 -f qcow2 -b ${IMAGES}/privbox-disk.qcow2 ${IMAGES}/disk0.qcow2
		taskset -c ${CPU1} qemu-guest \
			-i ${IMAGES}/privbox-initrd.cpio.gz \
			-k ${IMAGES}/vmlinuz.privbox \
			-q ${IMAGES}/disk0.qcow2 \
			-e ${IMAGES}/privbox/devenv \
			-a "console=ttyS0 net.ifnames=0 biosdevname=0 nowatchdog nopti nosmap nosmep ${mits} ip=${BASEIP}.2:::255.255.255.0::eth0:none nokaslr root=/dev/vda selinux=0 transparent_hugepage=never" \
			-m ${MEM} -p ${CPU2} \
			-b ${NETIF} -x

		# make sure that the server has properly started
		sleep 20

		# benchmark
		benchmark_redis_server ${BASEIP}.2 6379

		lines=`wc -l $LOG | cut --delimiter " " --fields 1`
        	if [[ $lines -ne 3 ]] ; then
                	((j--))
        	else
                	parse_redis_results $LOG $RESULTS
        	fi

		# stop server
		kill_qemu
		rm -f ${IMAGES}/disk0.qcow2
	done
done
