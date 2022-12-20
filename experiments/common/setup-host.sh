#!/bin/bash

# verbose output
set -x

modprobe kvm_intel
sysctl -w net.ipv4.conf.all.forwarding=1

sysctl -w net.ipv4.netfilter.ip_conntrack_max=99999999
sysctl -w net.nf_conntrack_max=99999999
sysctl -w net.netfilter.nf_conntrack_max=99999999

sysctl -w net.ipv4.neigh.default.gc_thresh1=1024
sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
sysctl -w net.ipv4.neigh.default.gc_thresh3=4096

echo 1024 > /proc/sys/net/core/somaxconn
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# CPU frequency
cpupower frequency-set -g performance

# Disable hyperthreading
for CPU in `ls -d -v /sys/devices/system/cpu/cpu[0-9]*`; do
    CPUID=$(basename $CPU)
    echo "CPU: $CPUID";
    if test -e $CPU/online; then
        echo "1" > $CPU/online;
    fi;
    COREID="$(cat $CPU/topology/core_id)";
    SOCKETID="$(cat $CPU/topology/physical_package_id)";
    eval "COREENABLE=\"\${core${SOCKETID}_${COREID}enable}\"";
    if ${COREENABLE:-true}; then
        echo "${CPU} socket=${SOCKETID} core=${COREID} -> enable"
        eval "core${SOCKETID}_${COREID}enable='false'";
    else
        echo "$CPU socket=${SOCKETID} core=${COREID} -> disable";
        echo "0" > "$CPU/online";
    fi;
done

# Disable turbo boost
cores=$(cat /proc/cpuinfo | grep processor | grep -o '[[:digit:]]*')
for core in $cores; do
	wrmsr -p${core} 0x1a0 0x4000850089
	state=$(rdmsr -p${core} 0x1a0 -f 38:38)
	if [[ $state -eq 1 ]]; then
		echo "core ${core}: disabled"
	else
		echo "core ${core}: enabled"
	fi
done

