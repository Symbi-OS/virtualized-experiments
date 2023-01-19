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
dnsmasq_pid=$(run_dhcp $NETIF $BASEIP)

function cleanup {
	# kill all children (evil)
	kill_dhcp $dnsmasq_pid
	kill_qemu
	pkill -P $$
	delete_bridge $NETIF
}

trap "cleanup" EXIT

RESULTS=results/ukl-byp-qemu.csv
echo "operation	throughput" > $RESULTS
touch $LOG

for ((j = 1 ; j < 21 ; j++))
do
	LOG=rawdata/ukl-byp-qemu-redis-$j.txt
	taskset -c ${CPU1} qemu-guest \
		-i ${IMAGES}/redis-ukl-initrd.cpio.gz \
		-k ${IMAGES}/vmlinuz.ukl-redis-byp \
		-a "console=ttyS0 net.ifnames=0 biosdevname=0 nowatchdog nopti nosmap nosmep mds=off ip=${BASEIP}.2:::255.255.255.0::eth0:none nokaslr selinux=0 transparent_hugepage=never mitigations=off" \
		-m 1024 -p ${CPU2} \
		-b ${NETIF} -x

	# make sure that the server has properly started
	sleep 20

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
