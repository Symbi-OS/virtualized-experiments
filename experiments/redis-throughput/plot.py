#!/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
#

import pandas as pd
import numpy as np
import math
import scipy.stats as st
from matplotlib import pyplot as plt
import matplotlib.ticker as mtick
from matplotlib.ticker import MultipleLocator
import os
import csv

plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman'] + plt.rcParams['font.serif']

colors = {'GET':'blue', 'SET':'orange'}

labels = {
    'unikraft-qemu': 'Unikraft',
    'ukl-qemu': 'UKL SC',
    'ukl-byp-qemu': 'UKL BYP',
    'symbiote-pt-qemu': 'Symbiote PT',
    'symbiote-int-qemu': 'Symbiote INT',
    'symbiote-el-qemu': 'Symbiote EL',
    'symbiote-sc-rw-qemu': 'Symbiote SC RW',
    'linux-5.14-qemu': 'Linux 5.14',
    'linux-5.8-qemu': 'Linux 5.8',
    'linux-4.0-qemu': 'Linux 4.0',
    'privbox-qemu': 'PrivBox',
    'lupine-qemu': 'Lupine'
}

def load_data():
    stats = {}
    stats['tput_max'] = 0.0

    for f in os.listdir("./results"):
        if f.endswith(".csv"):
            entry = f.replace(".csv", "")
            if entry not in stats:
                stats[entry] = {}

            with open(os.path.join("./results", f), "r") as infile:
                data = csv.reader(infile, delimiter="\t")
                # first row is header
                next(data)

                ops = {}
                for row in data:
                    if row[0] not in ops:
                        ops[row[0]] = []
                    ops[row[0]].append(float(row[1]) / 1000.0)

                for op in ops:
                    all_ops = np.array(ops[op])
                    ops[op] = {
                        'mean': np.average(all_ops),
                        'median': np.median(all_ops),
                        'amax': np.amax(all_ops),
                        'amin': np.amin(all_ops),
                        'stddev': np.std(all_ops),
                    }

                    if ops[op]['amax'] > stats['tput_max']:
                        stats['tput_max'] = ops[op]['amax']
                stats[entry] = ops

    stats['tput_max'] += 0.5
    return stats

stats = load_data()
xlabels = []

fig, ax = plt.subplots(figsize=(5,4), dpi= 100, facecolor='w', edgecolor='k')

count = 0
group = 0.8
base = stats['linux-5.14-qemu']

ax.set_ylabel("Avg. Throughput (Normed to Linux 5.14)")
ax.grid(which='major', axis='y', linestyle=':', alpha=0.5, zorder=0)
ax1_yticks = np.arange(0, 1.75, step=0.5)
ax.set_yticks(ax1_yticks, minor=False)
ax.set_yticklabels(ax1_yticks)
ax.set_ylim(0, 1.75)

for kernel in ['linux-4.0-qemu', 'lupine-qemu', 'linux-5.8-qemu', 'privbox-qemu', 'linux-5.14-qemu', 'symbiote-pt-qemu', 'symbiote-int-qemu', 'symbiote-el-qemu', 'symbiote-sc-rw-qemu', 'unikraft-qemu']:
    xlabels.append(labels[kernel])
    ops = stats[kernel]
    width = group / len(ops)
    offset = (width / 2) - (group / 2)
    for op in sorted(ops):
        bar = ax.bar([count + 1 + offset], ops[op]['mean'] / base[op]['mean'],
                    label=op,
                    align='center',
                    zorder=4,
                    yerr=ops[op]['stddev'],
                    error_kw=dict(lw=1, capsize=0, capthick=1),
                    width=width,
                    color=colors[op],
                    linewidth=0.5)
        ax.text(count + 1 + offset, ops[op]['amax'] / base[op]['mean'] + 0.2,
               round(ops[op]['mean'] / base[op]['mean'], 2),
               ha='center',
               va='bottom',
               zorder=6,
               fontsize=12,
               linespacing=0,
               bbox=dict(pad=-.6, facecolor='white', linewidth=0),
               rotation='vertical')

        offset += width
    count += 1

xticks = range(1, len(xlabels) + 1)
ax.set_xticks(xticks)
ax.set_xticklabels(xlabels, fontsize=10, rotation=40, ha='right', rotation_mode='anchor')
ax.set_xlim(.5, len(xlabels) + .5)
ax.yaxis.grid(True, zorder=0, linestyle=':')
ax.tick_params(axis='both', which='both', length=0)

h,l = plt.gca().get_legend_handles_labels()
by_label = dict(zip(l, h))
leg = plt.legend(by_label.values(), by_label.keys(),
    loc='upper left',
    ncol=2,
    fontsize=12,
)
leg.get_frame().set_linewidth(0.0)

plt.setp(ax.lines, linewidth=.5)

# Save to file
fig.tight_layout()
fig.savefig('redis-virt.pdf')
