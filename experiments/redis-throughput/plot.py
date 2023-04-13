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

labels = {
    'unikraft-qemu': 'Unikraft',
    'ukl-sc-qemu-none': 'UKL SC',
    'ukl-byp-qemu-none': 'UKL BYP',
    'ukl-base-qemu-none': 'UKL BASE',
    'symbiote-pt-qemu-none': 'Symbiote PT',
    'symbiote-int-qemu-none': 'Symbiote INT',
    'symbiote-el-qemu-none': 'Symbiote EL',
    'symbiote-sc-rw-qemu-none': 'Symbiote SC RW',
    'symbiote-deep-rw-qemu-none': 'Symbiote Deep SC RW',
    'linux-5.14-qemu-none': 'Linux 5.14',
    'linux-5.8-qemu-none': 'Linux 5.8',
    'linux-4.0-qemu-none': 'Linux 4.0',
    'privbox-qemu-none': 'PrivBox',
    'lupine-qemu-none': 'Lupine',
    'ukl-sc-qemu-all': 'UKL SC with mitigations',
    'ukl-byp-qemu-all': 'UKL BYP with mitigations',
    'ukl-base-qemu-all': 'UKL BASE with mitigations',
    'symbiote-pt-qemu-all': 'Symbiote PT with mitigations',
    'symbiote-int-qemu-all': 'Symbiote INT with mitigations',
    'symbiote-el-qemu-all': 'Symbiote EL with mitigations',
    'symbiote-sc-rw-qemu-all': 'Symbiote SC RW with mitigations',
    'symbiote-deep-rw-qemu-all': 'Symbiote Deep SC RW with mitigations',
    'linux-5.14-qemu-all': 'Linux 5.14 with mitigations',
    'linux-5.8-qemu-all': 'Linux 5.8 with mitigations',
    'linux-4.0-qemu-all': 'Linux 4.0 with mitigations',
    'privbox-qemu-all': 'PrivBox with mitigations',
    'lupine-qemu-all': 'Lupine with mitigations'
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
                    ops[row[0]].append(float(row[1]))

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

    stats['tput_max'] += 20000
    return stats

def plot_figure():
    plt.rcParams['font.family'] = 'serif'
    plt.rcParams['font.serif'] = ['Times New Roman'] + plt.rcParams['font.serif']

    colors = {'GET':'blue', 'SET':'orange'}

    stats = load_data()
    xlabels = []
    fig, ax = plt.subplots(figsize=(5,4), dpi= 100, facecolor='w', edgecolor='k')

    count = 0
    group = 0.8

    ax.set_ylabel("Avg. Throughput")
    ax.grid(which='major', axis='y', linestyle=':', alpha=0.5, zorder=0)
    ymax = stats['tput_max'] + (stats['tput_max'] * 0.2)
    ax1_yticks = np.arange(0, ymax, step=int(round(ymax / 10, -4)))
    ax.set_yticks(ax1_yticks, minor=False)
    ax.set_yticklabels(ax1_yticks)
    ax.set_ylim(0, ymax)

    for kernel in ['linux-4.0-qemu-none', 'lupine-qemu-none', 'linux-5.8-qemu-none', 'privbox-qemu-none',
                   'linux-5.14-qemu-none', 'symbiote-pt-qemu-none', 'symbiote-int-qemu-none',
                   'symbiote-el-qemu-none', 'symbiote-sc-rw-qemu-none', 'symbiote-deep-rw-qemu-none',
                   'ukl-base-qemu-none', 'ukl-byp-qemu-none', 'ukl-sc-qemu-none', 'unikraft-qemu']:
        xlabels.append(labels[kernel])
        ops = stats[kernel]
        width = group / len(ops)
        offset = (width / 2) - (group / 2)
        for op in sorted(ops):
            bar = ax.bar([count + 1 + offset], ops[op]['mean'],
                        label=op,
                        align='center',
                        zorder=4,
                        yerr=ops[op]['stddev'],
                        error_kw=dict(lw=1, capsize=0, capthick=1),
                        width=width,
                        color=colors[op],
                        linewidth=0.5)

            if kernel in ['linux-4.0-qemu-none', 'lupine-qemu-none']:
                base = stats['linux-4.0-qemu-none']
            elif kernel in ['linux-5.8-qemu-none', 'privbox-qemu-none']:
                base = stats['linux-5.8-qemu-none']
            else:
                base = stats['linux-5.14-qemu-none']

            pct_change = 100.0 * (ops[op]['mean'] - base[op]['mean']) / base[op]['mean']
            color = 'black'
            if pct_change < 0:
                color = 'red'
            ax.text(count + 1 + offset, ops[op]['amax'] + 0.2,
                   '{}%'.format(round(pct_change, 2)),
                   ha='center',
                   va='bottom',
                   zorder=6,
                   fontsize=7,
                   color=color,
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
    plt.show()
    fig.savefig('redis-virt.pdf')


def create_table():
    stats = load_data()

    with open('redis-virt.tex', 'w') as outfile:
        outfile.write('\t\\begin{tabular}{|c|c|c|c|c|}\n')
        outfile.write('\t\t\\hline\n')
        outfile.write('\t\t\\multirow{2}{*}{System} & \\multicolumn{2}{|c|}{No Mitigations} & \\multicolumn{2}{|c|}{With Mitigations} \\\\\n')
        outfile.write('\t\t\\cline{2-5}\n')
        outfile.write('\t\t & GET & SET & GET & SET \\\\\n')
        outfile.write('\t\t\\hline\n')

        for base in ['linux-4.0-qemu-', 'lupine-qemu-', 'linux-5.8-qemu-', 'privbox-qemu-',
                     'linux-5.14-qemu-', 'symbiote-pt-qemu-', 'symbiote-int-qemu-',
                     'symbiote-el-qemu-', 'symbiote-sc-rw-qemu-', 'symbiote-deep-rw-qemu-',
                     'ukl-base-qemu-', 'ukl-byp-qemu-', 'ukl-sc-qemu-']:
            mit = '{}all'.format(base)
            no_mit = '{}none'.format(base)
            outfile.write('\t\t{} & '.format(labels[mit]))
            outfile.write('${:.4f} \\pm {:.4f}$ & '.format(stats[no_mit]['GET']['mean'], stats[no_mit]['GET']['stddev']))
            outfile.write('${:.4f} \\pm {:.4f}$ & '.format(stats[no_mit]['SET']['mean'], stats[no_mit]['SET']['stddev']))
            outfile.write('${:.4f} \\pm {:.4f}$ & '.format(stats[mit]['GET']['mean'], stats[mit]['GET']['stddev']))
            outfile.write('${:.4f} \\pm {:.4f}$ \\\\\n '.format(stats[mit]['SET']['mean'], stats[mit]['SET']['stddev']))
            outfile.write('\t\t\\hline\n')

        outfile.write('\t\t{} &'.format(labels['unikraft-qemu']))
        outfile.write('${:.4f} \\pm {:.4f}$ & '.format(stats['unikraft-qemu']['GET']['mean'], stats['unikraft-qemu']['GET']['stddev']))
        outfile.write('${:.4f} \\pm {:.4f}$ & '.format(stats['unikraft-qemu']['SET']['mean'], stats['unikraft-qemu']['SET']['stddev']))
        outfile.write('-- & -- \\\\\n')
        outfile.write('\t\t\\hline\n')


        outfile.write('\t\\end{tabular}\n')


create_table()
plot_figure()
