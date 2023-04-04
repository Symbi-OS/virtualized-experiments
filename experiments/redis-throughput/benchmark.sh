#!/bin/bash

# makes sure to run host setup
../common/setup-host.sh

rm -rf rawdata results
mkdir rawdata results

# run benchmarks
./impl/privbox-redis.sh
./impl/lupine-qemu-redis.sh
./impl/linux-redis.sh
./impl/symbiote-pt-redis.sh
./impl/symbiote-int-redis.sh
./impl/symbiote-el-redis.sh
./impl/symbiote-sc-rw-redis.sh
./impl/symbiote-deep-rw-redis.sh
./impl/unikraft-qemu-redis.sh
