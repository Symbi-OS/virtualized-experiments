#!/bin/bash

# verbose output
set -x

SYM_ARGS="-be"

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
RESULTS=results/symbiote-el-qemu.csv
LOG_T='rawdata/symbiote-el-qemu-redis-$j.txt'
echo "operation	throughput" > $RESULTS

work
