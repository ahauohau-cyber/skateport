#!/usr/bin/env python3
"""Упаковывает бинарные файлы Skate 3 (банки анимаций, графы, жесты) в Luau-модули.

В Roblox нет файловой системы, поэтому байты кладутся base64-строками в
ModuleScript'ы src/skate_data/stock_files/ (папка в .gitignore: это данные игры).
Читает их модуль src/skate_data/files.luau (ROBLOX-замена std::fs::read).

Использование:
  python3 -I tools/stock_files.py <папка assets из установки skate3rust> <src/skate_data/stock_files>
"""
import base64, os, sys

FILES = [
    'private/stock/data/anim/OnBoard.abin',
    'private/stock/data/anim/OffBoard.abin',
    'private/stock/data/state/ActionGraph_OnBoard.stategraph',
    'private/stock/data/state/MotionGraph_OnBoard.stategraph',
    'private/stock/data/joystick/skater.pat',
    'private/stock/data/joystick/skater_air.pat',
    'private/stock/data/joystick/skater_fingerflip.pat',
    'private/stock/data/joystick/skater90.pat',
    'private/stock/data/joystick/skaterN90.pat',
    'private/stock/data/joystick/skaterls.pat',
    'private/stock/data/joystick/skaterstep.pat',
    'private/stock/data/config/input.cfg',
    'private/stock/physics-skeletons.json',
    'private/game.json',
]
CHUNK = 900_000  # символов base64 на один ModuleScript

def main():
    root, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        if f.endswith('.luau'):
            os.remove(os.path.join(out, f))
    entries = []
    for n, rel in enumerate(FILES):
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            print('нет файла:', rel)
            continue
        data = open(path, 'rb').read()
        text = base64.b64encode(data).decode()
        parts = []
        for k in range(0, len(text), CHUNK):
            name = 'f%02d_%03d' % (n, k // CHUNK)
            with open(os.path.join(out, name + '.luau'), 'w') as m:
                m.write('-- Сгенерировано tools/stock_files.py (данные Skate 3). Не править и не добавлять в git.\n')
                m.write('return "%s"\n' % text[k:k + CHUNK])
            parts.append(name)
        entries.append((rel[len('private/'):], len(data), parts))
    with open(os.path.join(out, 'init.luau'), 'w') as m:
        m.write('--!strict\n-- Сгенерировано tools/stock_files.py (данные Skate 3). Не править и не добавлять в git.\n')
        m.write('-- Каждая запись: путь (как в assets/private), размер в байтах и куски base64.\nreturn {\n')
        for rel, size, parts in entries:
            m.write('\t["%s"] = { size = %d, parts = { %s } },\n' % (rel, size, ', '.join('function() return require("@self/%s") end' % p for p in parts)))
        m.write('}\n')
    print('файлов:', len(entries))

main()
