#!/bin/bash

# verbose output
set -x

SYM_ARGS="-be"

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
LOG_T='rawdata/symbiote-el-qemu-redis-$j.txt'

for mits in "mitigations=off mds=off" "" ; do
        if [ -z $mits ]; then
                mit="none"
        else
                mit="all"
        fi

	RESULTS=results/symbiote-el-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS

	work
done
