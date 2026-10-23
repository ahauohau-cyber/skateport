--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/input_config.rs (коммит 2e16697)
--
-- Compatibility check for the stock gameplay expressions specialized by
-- skate-core's GameplayActions. This is not the full native expression VM.

local rt = require("../rt")
local files = require("./files")
local gameplay_map = require("../skate_core/input/gameplay_map")

local ACTIONS = gameplay_map.ACTIONS

local input_config = {}

-- ROBLOX: путь в упакованных файлах (files.luau), без "private/".
input_config.STOCK_INPUT_PATH = "stock/data/config/input.cfg"

local BUTTON_NAMES = {
	"DPadU", "DPadD", "DPadL", "DPadR", "Start", "Back", "LStick", "RStick", "LBumper", "RBumper",
	"LTrigger", "RTrigger", "A", "B", "X", "Y", "LStickR", "LStickL", "LStickU", "LStickD",
	"RStickR", "RStickL", "RStickU", "RStickD",
}
input_config.BUTTON_NAMES = table.freeze(BUTTON_NAMES)

-- ROBLOX: unit struct StockGameplayConfig -> пустая таблица.
export type StockGameplayConfig = {}

local StockGameplayConfig = {}
input_config.StockGameplayConfig = StockGameplayConfig

local function require_definition(definitions: { [string]: string }, name: string, expected: string)
	local actual = definitions[name]
	if actual == nil then
		rt.raise(string.format("Missing gameplay input definition %s", name))
	end
	if actual ~= expected then
		rt.raise(string.format("Unsupported %s = %s; the implemented stock mapping requires %s", name, actual, expected))
	end
end

local function trim(s: string): string
	return (string.match(s, "^%s*(.-)%s*$") :: string)
end

-- /// Require the actual file to agree with the supported native mapping.
-- /// A modified expression fails explicitly instead of silently running the
-- /// stock specialization against different user data.
function StockGameplayConfig.validate(source_in: string): StockGameplayConfig
	local lines = {}
	for line in string.gmatch(source_in .. "\n", "([^\n]*)\n") do
		if string.sub(line, -1) == "\r" then
			line = string.sub(line, 1, -2)
		end
		table.insert(lines, string.match(line, "^(.-)//") or line)
	end
	-- ROBLOX: str::lines() не даёт пустой строки после завершающего '\n'.
	if string.sub(source_in, -1) == "\n" then
		table.remove(lines)
	end
	local source = table.concat(lines, "\n")
	local definitions: { [string]: string } = {}
	local known = {}
	for _, name in BUTTON_NAMES do
		known[name] = true
	end
	for _, action in ACTIONS do
		known[action.name] = true
	end
	for statement in string.gmatch(source .. ";", "([^;]*);") do
		local eq = string.find(statement, "=", 1, true)
		if eq == nil then
			continue
		end
		local name = trim(string.sub(statement, 1, eq - 1))
		if known[name] then
			local expression = string.gsub(string.sub(statement, eq + 1), "%s", "")
			if definitions[name] ~= nil then
				rt.raise(string.format("Duplicate gameplay input definition %s", name))
			end
			definitions[name] = expression
		end
	end
	for index, name in BUTTON_NAMES do
		require_definition(definitions, name, string.format("Button%d", index - 1))
	end
	for _, action in ACTIONS do
		require_definition(definitions, action.name, action.expression)
	end
	return {}
end

function StockGameplayConfig.load(): StockGameplayConfig
	local path = "private/" .. input_config.STOCK_INPUT_PATH
	local source, err = rt.catch(files.read_string, input_config.STOCK_INPUT_PATH)
	if err ~= nil then
		rt.raise(string.format("Cannot read %s: %s", path, tostring(err)))
	end
	local result, err2 = rt.catch(StockGameplayConfig.validate, source)
	if err2 ~= nil then
		rt.raise(string.format("Input configuration %s: %s", path, tostring(err2)))
	end
	return result
end

return input_config
