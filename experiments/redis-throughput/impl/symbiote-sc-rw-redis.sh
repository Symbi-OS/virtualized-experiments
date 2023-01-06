#!/bin/bash

# verbose output
set -x

SYM_ARGS='-be -s "write->ksys_write" -s "read->ksys_read"'

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
LOG_T='rawdata/symbiote-sc-rw-qemu-redis-$j.txt'

for mits in "mitigations=off mds=off" "" ; do
        if [ -z $mits ]; then
                mit="none"
        else
                mit="all"
        fi

	RESULTS=results/symbiote-sc-rw-qemu-${mit}.csv
	echo "operation	throughput" > $RESULTS

	work
done
