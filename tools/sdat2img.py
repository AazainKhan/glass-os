#!/usr/bin/env python3
"""Rebuild a raw partition image from a block-based OTA's .transfer.list + .new.dat."""
import sys
BS = 4096
def ranges(s):
    n = [int(x) for x in s.split(',')]
    return list(zip(n[1::2], n[2::2]))
tl, dat, out = sys.argv[1:4]
lines = open(tl).read().splitlines()
cmds = lines[4:] if int(lines[0]) >= 2 else lines[2:]
maxblk = 0
with open(dat, 'rb') as src, open(out, 'wb') as dst:
    for line in cmds:
        op, _, arg = line.partition(' ')
        rs = ranges(arg)
        maxblk = max([maxblk] + [e for _, e in rs])
        if op == 'new':
            for b, e in rs:
                dst.seek(b * BS)
                dst.write(src.read((e - b) * BS))
    dst.truncate(maxblk * BS)
