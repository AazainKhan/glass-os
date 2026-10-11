#!/usr/bin/env python3
"""Shared removal list for both tracks. Usage:
  replace_list.py <manifests.json> <remove.tsv> --upto N [--format magisk|paths]
One line per package directory to remove, sorted.
  magisk: module-relative dir (Glass Pro puts an empty dir with a .replace marker there):
          system/system_ext/priv-app/<Dir>, system/product/app/<Dir>, system/vendor/app/<Dir>
  paths:  <image>TAB<path inside that image> for tools/img_edit.py (Glass OS):
          system<TAB>/system/system_ext/priv-app/<Dir>, product<TAB>/app/<Dir>, vendor<TAB>/app/<Dir>
The system image is system-as-root, so its own tree has a top-level system/ directory.
Exit 1 if a listed package is not in the image."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # python -I drops the script dir
from romlib import load_removals, package_dirs


def split_dir(d):
    """'system/system/system_ext/priv-app/X' -> ('system', '/system/system_ext/priv-app/X'); 'product/app/X' -> ('product', '/app/X')."""
    image, rest = d.split('/', 1)
    if image not in ('system', 'product', 'vendor'):
        raise ValueError(f'unexpected partition in {d}')
    return image, '/' + rest


def magisk_dir(d):
    image, inner = split_dir(d)
    return ('system' + inner[len('/system'):]) if image == 'system' else 'system/' + image + inner


def generate(M, removals, fmt='magisk'):
    missing = sorted({p for p, _, _ in removals} - set(M))
    if missing:
        raise KeyError('not in image: ' + ', '.join(missing))
    lines = set()
    for p, _, _ in removals:
        for d in package_dirs(M[p]):
            if d.count('/') < 2:
                raise ValueError(f'{p}: APK not in its own directory ({d}); refusing to remove a shared dir')
            if fmt == 'magisk':
                lines.add(magisk_dir(d))
            else:
                image, inner = split_dir(d)
                lines.add(f'{image}\t{inner}')
    return sorted(lines)


def main(argv):
    if len(argv) < 3 or '--upto' not in argv:
        sys.exit(__doc__)
    upto = argv[argv.index('--upto') + 1]
    fmt = argv[argv.index('--format') + 1] if '--format' in argv else 'magisk'
    if fmt not in ('magisk', 'paths'):
        sys.exit(__doc__)
    M = json.load(open(argv[1]))
    try:
        lines = generate(M, load_removals(argv[2], upto), fmt)
    except KeyError as e:
        print('ERROR', e.args[0], file=sys.stderr)
        return 1
    print('\n'.join(lines))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
