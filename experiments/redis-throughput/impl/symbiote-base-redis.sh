#!/bin/bash

source ../common/set-cpus.sh
source ../common/network.sh
source ../common/redis.sh
source ../common/qemu.sh

IMAGES=$(pwd)/images/
BASEIP=172.190.0
NETIF=unikraft0

function cleanup {
	# kill all children (evil)
	kill_qemu
	pkill -P $$
	delete_bridge $NETIF
}

trap "cleanup" EXIT

function work {
	for ((j = 1 ; j < 21 ; j++)); do
		LOG=`echo $(eval echo \"$LOG_T\")`
		taskset -c ${CPU1} qemu-guest \
			-i ${IMAGES}/sym-redis.cpio.gz \
			-k ${IMAGES}/vmlinuz.sym-ret \
			-a "console=ttyS0 net.ifnames=0 biosdevname=0 nowatchdog mitigations=off nosmap nosmep mds=off ip=172.190.0.2:::255.255.255.0::eth0:none nokaslr selinux=0 transparent_hugepage=never root=/dev/ram0 init=/init -- $SYM_ARGS" \
			-m 1024 -p ${CPU2} \
			-b ${NETIF} -x

		# make sure that the server has properly started
		sleep 10

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
}
