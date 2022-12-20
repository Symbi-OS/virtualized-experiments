#!/bin/bash

# verbose output
set -x

RESULTS=results/lupine-qemu.csv
echo "operation	throughput" > $RESULTS
mkdir -p rawdata
touch $LOG

IMAGES=$(pwd)/images

source ../common/set-cpus.sh
source ../common/network.sh
source ../common/redis.sh

IMAGES=$(pwd)/images/
NETIF=unikraft0
mkdir -p rawdata results

create_bridge $NETIF $BASEIP
killall -9 qemu-system-x86
pkill -9 qemu-system-x86

function cleanup {
	# kill all children (evil)
	delete_bridge $NETIF
	rm -f ${IMAGES}/redis.ext2.disposible
	killall -9 qemu-system-x86
	pkill -9 qemu-system-x86
	pkill -P $$
}

trap "cleanup" EXIT

for ((j = 1 ; j < 21 ; j++))
do
	LOG=rawdata/lupine-qemu-redis-$j.txt
	cp ${IMAGES}/redis.ext2 ${IMAGES}/redis.ext2.disposible

	taskset -c ${CPU1} qemu-guest \
		-k ${IMAGES}/lupine-qemu.kernel \
		-d ${IMAGES}/redis.ext2.disposible \
		-a "console=ttyS0 net.ifnames=0 biosdevname=0 nowatchdog mitigations=off nosmap nosmep mds=off nokaslr selinux=0 transparent_hugepage=never root=/dev/vda rw console=ttyS0 init=/guest_start.sh /trusted/redis-server" \
                -m 1024 -p ${CPU2} \
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
	killall -9 qemu-system-x86
	pkill -9 qemu-system-x86
	rm ${IMAGES}/redis.ext2.disposible
done
