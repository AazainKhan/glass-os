#!/usr/bin/env python3
"""Privileged-permission allowlist for a priv-app APK.
Usage: privapp_xml.py <apk> [--extra-from <RootFeatures.kt>] [--declared-from <manifests.json>] > privapp-permissions-<pkg>.xml
Lists every permission the APK requests (aapt2 dump permissions), plus the strings of EXTRA_PRIVILEGED in the
given Kotlin file (Glass only; exit 1 if that constant cannot be found), sorted, in the shape
RootFeatures.installSystemApp writes. Fire OS enforces the allowlist (ro.control_privapp_permissions=enforce):
a requested privileged permission missing from the file stops boot, an extra entry is harmless.
--declared-from drops names that no package in the image declares (API 31+ names such as
UPDATE_PACKAGES_WITHOUT_USER_ACTION on this Android 11 image), except names given with --keep.
Env: AAPT2 (default: build-tools 36.0.0 under ~/Library/Android/sdk)."""
import json, os, re, subprocess, sys

DEFAULT_AAPT2 = os.path.expanduser('~/Library/Android/sdk/build-tools/36.0.0/aapt2')


def requested(apk, aapt2=None):
    aapt2 = aapt2 or os.environ.get('AAPT2') or DEFAULT_AAPT2
    r = subprocess.run([aapt2, 'dump', 'permissions', apk], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f'aapt2 failed on {apk}: {r.stderr.strip()}')
    pkg = re.search(r'^package: (\S+)', r.stdout, re.M).group(1)
    perms = re.findall(r"^uses-permission(?:-sdk-23)?: name='([^']+)'", r.stdout, re.M)
    return pkg, perms


def extra_privileged(kt_path):
    src = open(kt_path).read()
    m = re.search(r'EXTRA_PRIVILEGED\s*=\s*listOf\((.*?)\)\s*$', src, re.S | re.M)
    if not m:
        raise RuntimeError(f'EXTRA_PRIVILEGED not found in {kt_path}')
    names = re.findall(r'"([^"]+)"', re.sub(r'//[^\n]*', '', m.group(1)))
    if not names:
        raise RuntimeError(f'EXTRA_PRIVILEGED in {kt_path} lists no permissions')
    return names


def declared_names(manifests_json):
    M = json.load(open(manifests_json))
    return {pr for es in M.values() for e in es for pr in e['decl_perm']}


def render(pkg, perms):
    lines = ['<?xml version="1.0" encoding="utf-8"?>', '<permissions>', f'    <privapp-permissions package="{pkg}">']
    lines += [f'        <permission name="{p}"/>' for p in perms]
    lines += ['    </privapp-permissions>', '</permissions>']
    return '\n'.join(lines) + '\n'


def generate(apk, extra_from=None, declared_from=None, keep=(), aapt2=None):
    pkg, perms = requested(apk, aapt2)
    names = set(perms) | set(keep)
    if extra_from:
        names |= set(extra_privileged(extra_from))
    if declared_from:
        known = declared_names(declared_from)
        names = {n for n in names if n in known or n in keep}
    return render(pkg, sorted(names))


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    def opt(flag):
        return argv[argv.index(flag) + 1] if flag in argv else None
    keep = [argv[i + 1] for i, a in enumerate(argv) if a == '--keep']
    try:
        sys.stdout.write(generate(argv[1], opt('--extra-from'), opt('--declared-from'), keep))
    except (RuntimeError, OSError) as e:
        print('ERROR', e, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
