#!/bin/bash

# verbose output
set -x

SYM_ARGS=""

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
RESULTS=results/symbiote-int-qemu.csv
LOG_T='rawdata/symbiote-int-qemu-redis-$j.txt'
echo "operation	throughput" > $RESULTS

work
