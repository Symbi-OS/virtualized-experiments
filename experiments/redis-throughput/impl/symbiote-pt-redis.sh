#!/bin/bash

# verbose output
set -x

SYM_ARGS="-p"

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
RESULTS=results/symbiote-pt-qemu.csv
LOG_T='rawdata/symbiote-pt-qemu-redis-$j.txt'
echo "operation	throughput" > $RESULTS

work
