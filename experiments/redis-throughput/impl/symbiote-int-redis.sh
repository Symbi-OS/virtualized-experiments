#!/bin/bash

# verbose output
set -x

SYM_ARGS=""

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
LOG_T='rawdata/symbiote-int-qemu-redis-$mit-$j.txt'

for mits in "mitigations=off mds=off" "" ; do
        if [ -z $mits ]; then
                mit="all"
        else
                mit="none"
        fi


	RESULTS=results/symbiote-int-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS
	work
done
