"""Замыкание зависимостей Rust-модуля skate-core (эвристика по токенам `имя::`)."""
import os,re,sys,glob
root=os.path.expanduser(sys.argv[1]); start=sys.argv[2]
files={}
for d,_,fs in os.walk(root):
    for f in fs:
        if f.endswith('.rs'):
            p=os.path.relpath(os.path.join(d,f),root)
            if '/tests/' in '/'+p or p.endswith('tests.rs'): continue
            files[p]=open(os.path.join(d,f),errors='ignore').read()
def strip_tests(s):
    i=s.find('#[cfg(test)]'); 
    return s if i<0 else s[:i]
def mod_of(p):
    m=p[:-3]
    if m.endswith('/mod'): m=m[:-4]
    return m
mods={mod_of(p):p for p in files}
def deps(p):
    s=strip_tests(files[p]); here=mod_of(p); parent=os.path.dirname(here) if not p.endswith('mod.rs') else os.path.dirname(here)
    out=set()
    for tok in set(re.findall(r'\b([a-z_][a-z_0-9]*)\s*::',s))|set(re.findall(r'\bmod\s+([a-z_0-9]+)\s*;',s)):
        for base in (here, parent, 'physics', ''):
            m=(base+'/'+tok).lstrip('/')
            if m in mods and mods[m]!=p: out.add(mods[m]); break
    # path attr
    for pa in re.findall(r'#\[path\s*=\s*"([^"]+)"\]\s*mod',s):
        q=os.path.normpath(os.path.join(os.path.dirname(p),pa))
        if q in files: out.add(q)
    return out
done=set()
for f in glob.glob('src/skate_core/**/*.luau',recursive=True):
    r=os.path.relpath(f,'src/skate_core')[:-5]
    if r.endswith('/init'): r=r[:-5]
    if r=='init': r=''
    done.add(r)
seen=set(); st=[start]
while st:
    x=st.pop()
    if x in seen: continue
    seen.add(x); st+=[d for d in deps(x) if d.startswith(os.environ.get("ONLY","")) ]
todo=[f for f in seen if mod_of(f) not in done and f!='lib.rs']
lines=lambda f: files[f].count('\n')
for f in sorted(todo,key=lambda f:-lines(f)): print(lines(f),f)
print(len(todo),'файлов,',sum(lines(f) for f in todo),'строк')
if os.environ.get("TOPO"):
    order=[];state={}
    def visit(x):
        if state.get(x)==2: return
        if state.get(x)==1: return
        state[x]=1
        for d in sorted(deps(x)):
            if d in todo: visit(d)
        state[x]=2; order.append(x)
    for f in sorted(todo): visit(f)
    print("ТОПО:")
    for f in order: print(lines(f), f, "<-", " ".join(sorted(mod_of(d) for d in deps(f) if d in todo)))
