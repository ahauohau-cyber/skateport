import os,re,sys,json
root=sys.argv[1]
files={}
for d,_,fs in os.walk(root):
    for f in fs:
        if f.endswith('.rs'):
            p=os.path.relpath(os.path.join(d,f),root); files[p]=open(os.path.join(d,f),errors='ignore').read()
def is_test(p): return '/tests/' in '/'+p or p.startswith('tests/') or p.endswith('_tests.rs') or p.endswith('/tests.rs') or p=='tests.rs'
def modpath(p):
    parts=p[:-3].split('/')
    if parts[-1] in('mod','lib'): parts=parts[:-1]
    return parts
mods={tuple(modpath(p)):p for p in files}
def resolve(segs):
    for n in range(len(segs),0,-1):
        if tuple(segs[:n]) in mods: return mods[tuple(segs[:n])]
def strip_tests(src):
    # drop #[cfg(test)] mod blocks roughly
    return re.sub(r'#\[cfg\(test\)\]\s*(#\[[^\]]*\]\s*)*mod\s+\w+\s*(;|\{)','',src)
E={}
for p,src in files.items():
    if is_test(p): continue
    src=strip_tests(src)
    src=re.sub(r'//[^\n]*','',src)
    me=modpath(p); deps=set()
    for m in re.finditer(r'\b((?:crate|super|self|[a-z_][a-z0-9_]*)(?:::[a-z_][a-z0-9_]*)+)',src):
        segs=m.group(1).split('::')
        if segs[0]=='crate': s=segs[1:]
        elif segs[0]=='self': s=me+segs[1:]
        elif segs[0]=='super':
            s=list(me); 
            while segs and segs[0]=='super': s=s[:-1]; segs=segs[1:]
            s=s+segs
        else:
            # bare: child module of me, or a module in scope via use? try child first
            if tuple(me+[segs[0]]) in mods: s=me+segs
            else: continue
        t=resolve(s)
        if t and t!=p and not is_test(t): deps.add(t)
    E[p]=sorted(deps)
L={p:files[p].count('\n') for p in files if not is_test(p)}
json.dump({"edges":E,"lines":L},open(sys.argv[2],'w'))
