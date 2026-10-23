--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/manifest.rs (коммит 2e16697)

local rt = require("../rt")
local files = require("./files")
local json = require("./json")

local manifest = {}

export type GameAssets = {
	version: number,
	character_scene: string,
	initial_animation: string,
	action_graph: string,
	motion_graph: string,
}

-- ROBLOX: AssetError(String) -> ошибка-строка через rt.raise.
-- Display печатает саму строку, поэтому строка и есть ошибка.

local GameAssets = {}
manifest.GameAssets = GameAssets

-- ROBLOX: Path::components() / extension() -> разбор строки с '/'.
local function validate_path(value: string, field: string, extension: string)
	local ok = value ~= "" and not string.find(value, "[:\\#]")
	if ok then
		for part in string.gmatch(value .. "/", "([^/]*)/") do
			if part == "" or part == "." or part == ".." then
				ok = false
			end
		end
		if string.sub(value, 1, 1) == "/" then
			ok = false
		end
	end
	if not ok then
		rt.raise(string.format("%s must be a relative asset path using forward slashes", field))
	end
	local name = string.match(value, "([^/]*)$") :: string
	local ext = string.match(name, "^.+%.([^%.]+)$")
	if ext ~= extension then
		rt.raise(string.format("%s must name a .%s file", field, extension))
	end
end

function GameAssets.parse(text: string): GameAssets
	local _, err = rt.catch(function()
		local decoded = json.decode(text)
		json.expect_fields(decoded, { "version", "character_scene", "initial_animation", "action_graph", "motion_graph" }, "GameAssets")
		return decoded
	end)
	if err ~= nil then
		rt.raise("Invalid game asset manifest: " .. tostring(err))
	end
	local m = json.decode(text) :: GameAssets
	if m.version ~= 1 then
		rt.raise(string.format("Unsupported asset manifest version %d", m.version))
	end
	validate_path(m.character_scene, "character_scene", "glb")
	validate_path(m.action_graph, "action_graph", "stategraph")
	validate_path(m.motion_graph, "motion_graph", "stategraph")
	if string.match(m.initial_animation, "^%s*$") then
		rt.raise("initial_animation must name a stock animation")
	end
	return m
end

-- ROBLOX: root.join(relative) -> путь в упакованных файлах без префикса "private/".
function manifest.private_path(relative: string): string
	return (string.gsub(relative, "^private/", ""))
end

-- ROBLOX: файлы читаются из src/skate_data/stock_files (files.luau), а не с диска.
function GameAssets.load(): GameAssets
	if not files.exists("game.json") then
		rt.raise("Cannot read private/game.json. Run pipeline/Prepare-Assets.ps1 or select the correct --assets directory.")
	end
	local m = GameAssets.parse(files.read_string("game.json"))
	for _, entry in { { "Character scene", m.character_scene }, { "ActionGraph", m.action_graph }, { "MotionGraph", m.motion_graph } } do
		-- ROBLOX: сцена персонажа (skater.glb) в Roblox не нужна — вместо неё R15-аватар;
		-- её наличие не проверяется.
		if entry[1] == "Character scene" then
			continue
		end
		if not files.exists(manifest.private_path(entry[2])) then
			rt.raise(string.format("%s missing: %s", entry[1], entry[2]))
		end
	end
	return m
end

return manifest
