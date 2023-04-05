#!/bin/bash

# verbose output
set -x

SYM_ARGS='-be -s "write->__x64_sys_write" -s "read->__x64_sys_read"'

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
LOG_T='rawdata/symbiote-sc-rw-qemu-redis-$mit-$j.txt'
INITRD='${IMAGES}/sym-redis.cpio.gz'

for mits in "mitigations=off mds=off" "" ; do
        if [ -z $mits ]; then
                mit="all"
        else
                mit="none"
        fi

	RESULTS=results/symbiote-sc-rw-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS

	work
done
