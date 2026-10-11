#!/usr/bin/env python3
"""Deterministic zip of a staging directory. Usage: mkzip.py <stage_dir> <out.zip>
Entries sorted by path, fixed timestamp, fixed modes (0755 for scripts, update-binary and glass-keymap, 0644
otherwise), no extra fields, so the same inputs always give the same bytes."""
import os, sys, zipfile

EXEC_NAMES = {'update-binary', 'glass-keymap'}


def main(stage, out):
    entries = []
    for d, _, fs in os.walk(stage):
        for f in fs:
            if f == '.DS_Store':
                continue
            full = os.path.join(d, f)
            entries.append((os.path.relpath(full, stage).replace(os.sep, '/'), full))
    entries.sort()
    tmp = out + '.tmp'
    with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for rel, full in entries:
            zi = zipfile.ZipInfo(rel, date_time=(2020, 1, 1, 0, 0, 0))
            zi.create_system = 3
            zi.compress_type = zipfile.ZIP_DEFLATED
            mode = 0o755 if (rel.endswith('.sh') or os.path.basename(rel) in EXEC_NAMES) else 0o644
            zi.external_attr = (0o100000 | mode) << 16
            with open(full, 'rb') as fh:
                z.writestr(zi, fh.read(), compresslevel=9)
    os.replace(tmp, out)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
