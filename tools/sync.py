#!/usr/bin/env python3
"""Собирает Luau-скрипт, который создаёт/обновляет дерево модулей в Studio.

src/<путь>.luau      -> ModuleScript
src/<папка>/init.luau -> ModuleScript-папка (с детьми)
src/<папка>/ без init -> Folder

Использование: python3 tools/sync.py <корень src> <Сервис.Имя> > out.luau
"""
import os
import sys

root = sys.argv[1]
target = sys.argv[2]  # например ReplicatedStorage.SkatePort
service, name = target.split(".", 1)

entries = []  # (путь-части, класс, исходник)
for dirpath, dirnames, filenames in os.walk(root):
    dirnames.sort()
    rel = os.path.relpath(dirpath, root)
    parts = [] if rel == "." else rel.split(os.sep)
    if parts:
        init = os.path.join(dirpath, "init.luau")
        if os.path.exists(init):
            entries.append((parts, "ModuleScript", open(init, encoding="utf-8").read()))
        else:
            entries.append((parts, "Folder", None))
    for f in sorted(filenames):
        if f.endswith(".luau") and f != "init.luau":
            entries.append((parts + [f[:-5]], "ModuleScript", open(os.path.join(dirpath, f), encoding="utf-8").read()))

entries.sort(key=lambda e: len(e[0]))

def lua_str(s):
    level = 4
    while ("]" + "=" * level + "]") in s:
        level += 1
    eq = "=" * level
    return "[" + eq + "[\n" + s + "]" + eq + "]"

out = []
out.append(f'local root = game:GetService("{service}"):FindFirstChild("{name}")')
out.append(f'if not root then root = Instance.new("Folder"); root.Name = "{name}"; root.Parent = game:GetService("{service}") end')
out.append("local function node(parts, class)")
out.append("\tlocal cur = root")
out.append("\tfor i, p in parts do")
out.append("\t\tlocal nxt = cur:FindFirstChild(p)")
out.append("\t\tlocal want = if i == #parts then class else nil")
out.append("\t\tif nxt and want and nxt.ClassName ~= want then")
out.append("\t\t\tlocal repl = Instance.new(want); repl.Name = p")
out.append("\t\t\tfor _, c in nxt:GetChildren() do c.Parent = repl end")
out.append("\t\t\tnxt:Destroy(); repl.Parent = cur; nxt = repl")
out.append("\t\telseif not nxt then")
out.append("\t\t\tnxt = Instance.new(want or 'Folder'); nxt.Name = p; nxt.Parent = cur")
out.append("\t\tend")
out.append("\t\tcur = nxt")
out.append("\tend")
out.append("\treturn cur")
out.append("end")
out.append("local n = 0")
for parts, cls, src in entries:
    plist = "{" + ", ".join(f'"{p}"' for p in parts) + "}"
    if cls == "Folder":
        out.append(f'node({plist}, "Folder")')
    else:
        out.append(f'node({plist}, "ModuleScript").Source = {lua_str(src)}; n += 1')
out.append('return "synced " .. n .. " modules into " .. root:GetFullName()')
print("\n".join(out))
