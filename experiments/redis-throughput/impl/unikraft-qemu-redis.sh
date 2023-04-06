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

create_bridge $NETIF $BASEIP

kill_qemu

function cleanup {
	# kill all children (evil)
	kill_qemu
	pkill -P $$
	delete_bridge $NETIF
}

trap "cleanup" EXIT

RESULTS=results/unikraft-qemu.csv
echo "operation	throughput" > $RESULTS

for ((j = 1 ; j < 21 ; j++))
do
	LOG=rawdata/unikraft-qemu-redis-$j.txt
	touch $LOG
	taskset -c ${CPU1} qemu-guest \
		-i data/redis.cpio \
		-k ${IMAGES}/unikraft+mimalloc.kernel \
		-a "netdev.ipv4_addr=${BASEIP}.2 netdev.ipv4_gw_addr=${BASEIP}.1 netdev.ipv4_subnet_mask=255.255.255.0 -- /redis.conf" -m ${MEM} -p ${CPU2} \
		-b ${NETIF} -x

	# make sure that the server has properly started
	sleep 8

	# benchmark
	benchmark_redis_server ${BASEIP}.2 6379

	lines=`wc -l $LOG | cut --delimiter " " --fields 1`
        if [[ $lines -ne 3 ]] ; then
                rm $LOG
                ((j--))
        else
                parse_redis_results $LOG $RESULTS
        fi

	# stop server
	kill_qemu
done
