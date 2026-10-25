#!/bin/sh
# Сборка build/sim.rbxm из vendor/sim. PACK — путь к утилите pack (rbx-dom:
# папка .luau по правилам Rojo -> .rbxm, переменная PACK_HEADER — текст в начало
# каждого скрипта).
# ROBLOX: --!native (нативная компиляция Luau) и --!optimize 2 ускоряют тик ядра
# и его загрузку; в vendor/sim сами файлы не трогаем.
set -e
cd "$(dirname "$0")/.."
PACK=${PACK:-pack}
PACK_HEADER='--!native\n--!optimize 2\n' "$PACK" vendor/sim sim build/sim.rbxm
ls -la build/sim.rbxm
