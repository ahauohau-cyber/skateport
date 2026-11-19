#!/bin/sh
# Сборка build/sim.rbxm (ядро) и build/sim_data.rbxm (данные) из vendor/.
# PACK — путь к утилите pack (rbx-dom: папка .luau по правилам Rojo -> .rbxm,
# переменная PACK_HEADER — текст в начало каждого скрипта).
#
# ROBLOX:
#  * --!native (нативная компиляция Luau) и --!optimize 2 ускоряют тик ядра.
#  * Ядро лежит в ServerStorage.SkateLib и копируется в PlayerGui только
#    скейтеру (остальные ~25 МБ не скачивают). Модули находят его через
#    ReplicatedStorage.SkateLocator, поэтому жёсткий путь
#    ReplicatedStorage.Skate3.sim в копии заменяем на локатор.
#  * В vendor/ сами файлы не трогаем — правим временную копию.
set -e
cd "$(dirname "$0")/.."
PACK=${PACK:-pack}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

OLD='game:GetService("ReplicatedStorage"):WaitForChild("Skate3")'
NEW='require(game:GetService("ReplicatedStorage"):WaitForChild("SkateLocator")):WaitForChild("Skate3")'

cp -r vendor/sim "$TMP/sim"
mkdir "$TMP/sim_data"
# Данные: только то, что нужно в игре (карты Skate 3, HUD, иконки, предметы
# конструктора не используются).
for item in vendor/sim_data/*; do
	case "$(basename "$item")" in
	build_items | hud | input_icons | maps) ;;
	*) cp -r "$item" "$TMP/sim_data/" ;;
	esac
done
grep -rlF "$OLD" "$TMP" | while read -r f; do
	python3 - "$f" "$OLD" "$NEW" <<'EOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(src.replace(old, new))
EOF
done

PACK_HEADER='--!native\n--!optimize 2\n' "$PACK" "$TMP/sim" sim build/sim.rbxm
PACK_HEADER='' "$PACK" "$TMP/sim_data" sim_data build/sim_data.rbxm
ls -la build/sim.rbxm build/sim_data.rbxm
