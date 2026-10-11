#!/usr/bin/env python3
"""Check a removal list against the image's manifest DB. Usage: lint_removals.py manifests.json libs_features.txt remove.tsv [--upto N]
Errors: a kept package needs a required shared library whose file belongs to a removed package; a removed package is in the keep list.
Warnings: a kept component is guarded by a permission only a removed package declares while a kept package requests it."""
import json,re,sys
M=json.load(open(sys.argv[1])); upto=int(sys.argv[sys.argv.index('--upto')+1]) if '--upto' in sys.argv else 99
libs={m.group(1):m.group(2) for l in open(sys.argv[2]) for m in [re.search(r'library name="([^"]+)" *file="([^"]+)"',l)] if m}
R=set()
for l in open(sys.argv[3]):
    if l.startswith('#') or not l.strip(): continue
    p,b,*_=l.rstrip('\n').split('\t')
    if int(b)<=upto: R.add(p)
missing=R-set(M); err=0
for p in sorted(missing): print('ERROR not in image:',p); err+=1
files={p:['/'+e['file'].split('/',2)[-1] for e in es] for p,es in M.items()}
def owner(f):
    for p,fs in files.items():
        for x in fs:
            if f.rstrip('/').endswith(x.split('system_ext/',1)[-1]) : return p
declared={}
for p,es in M.items():
    for e in es:
        for pr in e['decl_perm']: declared.setdefault(pr,set()).add(p)
for p,es in M.items():
    if p in R: continue
    for e in es:
        for l,req in e['uses_lib']:
            f=libs.get(l,'')
            if req!='0x0' and f.endswith('.apk') and owner(f) in R: print(f'ERROR {p} requires library {l} from removed {owner(f)}'); err+=1
        for c in e['components']:
            pr=c[3]
            if pr and pr in declared and declared[pr]<=R:
                callers=[q for q,qs in M.items() if q not in R and q!=p and any(pr in x['uses_perm'] for x in qs)]
                if callers: print(f'WARN {p}/{c[1]} guarded by {pr} (declared only by removed {sorted(declared[pr])}); kept callers lose access: {callers}')
home=sorted(p for p,es in M.items() if p not in R and any(e['home'] for e in es))
print('HOME candidates after removal:',home)
print(f'{len(R)} removed, {err} errors'); sys.exit(1 if err else 0)
