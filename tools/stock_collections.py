#!/usr/bin/env python3
"""Собирает Luau-модули настроек Skate 3 из skater-collections.json.

Берёт только классы, на которые ссылается код Rust-движка (строковые литералы,
в том числе в виде хеша AttribSys). Модули попадают в src/skate_data/stock/ —
эта папка в .gitignore: это данные игры, в репозиторий они не идут.

Использование:
  python3 -I tools/stock_collections.py <skater-collections.json> <путь к skate-3-rust-engine/crates> <src/skate_data/stock>
"""
import json, os, re, sys

M = (1 << 64) - 1

def mix(a, b, c):
    for x, y, z in [(43, 9, 8), (38, 23, 5), (35, 49, 11), (12, 18, 22)]:
        a = ((a - b - c) & M) ^ (c >> x)
        b = ((b - c - a) & M) ^ ((a << y) & M)
        c = ((c - a - b) & M) ^ (b >> z)
    return a, b, c

def attrib_hash(t):
    bs = t.encode()
    if not bs:
        return 0
    a = 0xabcdef0011223344; b = a; c = 0x9e3779b97f4a7c13
    n = len(bs) // 24
    for k in range(n):
        ch = bs[k * 24:k * 24 + 24]
        a, b, c = mix((a + int.from_bytes(ch[:8], 'little')) & M, (b + int.from_bytes(ch[8:16], 'little')) & M,
                      (c + int.from_bytes(ch[16:], 'little')) & M)
    c = (c + len(bs)) & M
    for i, byte in enumerate(bs[n * 24:]):
        if i <= 7: a = (a + (byte << (i * 8))) & M
        elif i <= 15: b = (b + (byte << ((i - 8) * 8))) & M
        else: c = (c + (byte << ((i - 15) * 8))) & M
    return mix(a, b, c)[2]

def numeric_name(t):
    for p in ('Hash_', '0x'):
        if t.startswith(p):
            try:
                return 'Hash_%016X' % int(t[len(p):], 16)
            except ValueError:
                pass
    return 'Hash_%016X' % attrib_hash(t)

def lua_str(s):
    out = ['"']
    for ch in s:
        o = ord(ch)
        if ch == '"': out.append('\\"')
        elif ch == '\\': out.append('\\\\')
        elif 32 <= o < 127: out.append(ch)
        else:
            for byte in ch.encode('utf-8'):
                out.append('\\%03d' % byte)
    out.append('"')
    return ''.join(out)

def main():
    src, crates, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    data = json.load(open(src, encoding='utf-8'))
    literals = set()
    for d, _, fs in os.walk(crates):
        for f in fs:
            if f.endswith('.rs'):
                literals.update(re.findall(r'"([A-Za-z_][A-Za-z0-9_]*)"', open(os.path.join(d, f), errors='ignore').read()))
    wanted = {numeric_name(l) for l in literals}
    chosen = [c for c in data['collections'] if numeric_name(c['class']) in wanted]
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith('.luau'):
            os.remove(os.path.join(out_dir, f))
    parts, current, size = [], [], 0
    for c in chosen:
        lines = ['\t{', '\t\tclass_name = %s,' % lua_str(c['class']), '\t\tkey = %s,' % lua_str(c['key']),
                 '\t\tparent = %s,' % lua_str(c['parent']), '\t\tsource = %s,' % lua_str(c.get('source', '')),
                 '\t\tsha256 = %s,' % lua_str(c.get('sha256', '')), '\t\tfields = {']
        for name in sorted(c['fields']):
            f = c['fields'][name]
            extra = ''
            if f.get('array'):
                items = ', '.join(lua_str(x) for x in f['array'].get('text_items', []))
                extra = ', array = { text_items = { %s } }' % items
            lines.append('\t\t\t[%s] = { type_name = %s, data = %s%s },' % (lua_str(name), lua_str(f['type']), lua_str(f['data']), extra))
        lines += ['\t\t},', '\t},']
        text = '\n'.join(lines) + '\n'
        if size + len(text) > 180_000 and current:
            parts.append(current); current, size = [], 0
        current.append(text); size += len(text)
    if current:
        parts.append(current)
    header = '--!strict\n-- Сгенерировано tools/stock_collections.py из skater-collections.json (данные Skate 3).\n-- Не править и не добавлять в git.\n'
    for i, part in enumerate(parts):
        with open(os.path.join(out_dir, 'part_%02d.luau' % i), 'w', encoding='utf-8') as fh:
            fh.write(header + 'return {\n' + ''.join(part) + '}\n')
    with open(os.path.join(out_dir, 'init.luau'), 'w', encoding='utf-8') as fh:
        fh.write(header + '-- ROBLOX: таблица в формате skater-collections.json (version, collections).\n')
        fh.write('local collections = {}\n')
        for i in range(len(parts)):
            fh.write('for _, c in require("@self/part_%02d") :: any do\n\ttable.insert(collections, c)\nend\n' % i)
        fh.write('return { version = %d, collections = collections }\n' % data['version'])
    print('классов', len({c['class'] for c in chosen}), 'наборов', len(chosen), 'модулей', len(parts) + 1)

main()
