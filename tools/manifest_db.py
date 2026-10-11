import os,re,json,sys,glob,collections
D=sys.argv[1]
rx=re.compile(r'^(\s*)(E|A): (.*)$')
def parse(p):
    root={'tag':'root','attrs':{},'kids':[]};stack=[(-1,root)]
    for line in open(p,errors='ignore'):
        m=rx.match(line.rstrip('\n'))
        if not m: continue
        ind=len(m.group(1));k=m.group(2);t=m.group(3)
        if k=='E':
            tag=t.split(' ')[0];n={'tag':tag,'attrs':{},'kids':[]}
            while stack[-1][0]>=ind: stack.pop()
            stack[-1][1]['kids'].append(n);stack.append((ind,n))
        else:
            mm=re.match(r'(?:\S+:)?(\w+)(?:\(0x[0-9a-f]+\))?=(.*)$',t.split('android:')[-1] if 'android:' in t else t)
            if mm:
                v=mm.group(2);v2=re.match(r'"([^"]*)"',v);v=v2.group(1) if v2 else v.split(' ')[0]
                stack[-1][1]['attrs'][mm.group(1)]=v
    return root
def walk(n):
    yield n
    for k in n['kids']: yield from walk(k)
out={}
for f in sorted(glob.glob(D+'/*.txt')):
    r=parse(f);man=next((n for n in walk(r) if n['tag']=='manifest'),None)
    if not man: continue
    pkg=man['attrs'].get('package');e={'file':os.path.basename(f)[:-4].replace('__','/'),'sharedUserId':man['attrs'].get('sharedUserId'),
     'uses_perm':[],'decl_perm':{},'uses_lib':[],'uses_feature':[],'components':[],'authorities':[],'actions':set(),'home':False,'persistent':False,'targets':set()}
    for n in walk(man):
        a=n['attrs'];t=n['tag']
        if t=='uses-permission': e['uses_perm'].append(a.get('name'))
        elif t=='permission': e['decl_perm'][a.get('name')]=a.get('protectionLevel')
        elif t in('uses-library','uses-static-library'): e['uses_lib'].append((a.get('name'),a.get('required','true')))
        elif t=='uses-feature' and a.get('name','').startswith('com.'): e['uses_feature'].append(a.get('name'))
        elif t=='application': e['persistent']=a.get('persistent')=='0xffffffff'
        elif t in('activity','service','receiver','provider','activity-alias'):
            ex=a.get('exported');hasf=any(k['tag']=='intent-filter' for k in n['kids'])
            e['components'].append((t,a.get('name'),'exp' if ex=='0xffffffff' or (ex is None and hasf) else '',a.get('permission')))
            if t=='provider' and a.get('authorities'): e['authorities']+=a['authorities'].split(';')
        elif t=='action': e['actions'].add(a.get('name'))
        elif t=='category' and a.get('name')=='android.intent.category.HOME': e['home']=True
        elif t=='meta-data' or t=='queries' or t=='package':
            for v in a.values():
                if isinstance(v,str) and re.match(r'^com\.amazon\.[\w.]+$',v): e['targets'].add(v)
    e['actions']=sorted(x for x in e['actions'] if x);e['targets']=sorted(e['targets'])
    out.setdefault(pkg,[]).append(e)
json.dump(out,open(sys.argv[2],'w'),indent=1,default=list)
print(len(out))
