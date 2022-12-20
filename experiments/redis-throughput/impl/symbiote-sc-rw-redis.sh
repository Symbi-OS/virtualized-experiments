#!/bin/bash

# verbose output
set -x

SYM_ARGS='-be -s "write->ksys_write" -s "read->ksys_read"'

source ./impl/symbiote-base-redis.sh

kill_qemu

create_bridge $NETIF $BASEIP
RESULTS=results/symbiote-sc-rw-qemu.csv
LOG_T='rawdata/symbiote-sc-rw-qemu-redis-$j.txt'
echo "operation	throughput" > $RESULTS

work
