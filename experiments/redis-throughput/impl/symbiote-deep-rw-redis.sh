#!/bin/bash

# verbose output
set -x

SYM_ARGS='-be -s "write->tcp_sendmsg" -s "read->tcp_recvmsg"'

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
LOG_T='rawdata/symbiote-deep-rw-qemu-redis-$mit-$j.txt'
INITRD='${IMAGES}/deep-sc-redis.cpio.gz'

for mits in "mitigations=off mds=off" "" ; do
        if [ -z "$mits" ]; then
                mit="all"
        else
                mit="none"
        fi

	RESULTS=results/symbiote-deep-rw-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS

	work
done
