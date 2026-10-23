--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/gesture_patterns.rs (коммит 2e16697)
--
-- Authored joystick PAT data consumed by TU3 82696B18.

local rt = require("../rt")
local files = require("./files")
local gesture = require("../skate_core/input/gesture")

local f32 = rt.f32

local gesture_patterns = {}

-- ROBLOX: str::parse::<f32>() -> tonumber + f32. Отличия: tonumber принимает
-- шестнадцатеричную запись; округление идёт через double (для коротких
-- десятичных литералов PAT совпадает с прямым разбором в f32).
local function parse_f32(text: string): number?
	if string.find(text, "^[+-]?0[xX]") then
		return nil
	end
	local v = tonumber(text)
	if v == nil then
		return nil
	end
	return f32(v)
end

-- ROBLOX: Result<Vec<Pattern>, String> -> массив или rt.raise(строка).
function gesture_patterns.parse(source: string): { gesture.Pattern }
	local patterns: { gesture.Pattern } = {}
	local tolerance: number? = nil
	local line = 0
	for text in string.gmatch(source .. "\n", "([^\n]*)\n") do
		line += 1
		-- ROBLOX: str::lines() отбрасывает завершающий '\r'.
		if string.sub(text, -1) == "\r" then
			text = string.sub(text, 1, -2)
		end
		local code = string.match(text, "^(.-)//") or text
		local words = {}
		for w in string.gmatch(code, "%S+") do
			table.insert(words, w)
		end
		if #words == 0 then
			continue
		end
		local function fail(): string
			return string.format("invalid PAT directive at line %d: %s", line, text)
		end
		local function number(index: number): number
			local word = words[index + 1]
			if word == nil then
				rt.raise(fail())
			end
			local value = parse_f32(word)
			if value == nil or not rt.is_finite(value) then
				rt.raise(fail())
			end
			return value :: number
		end
		local d = words[1]
		if d == "global_tolerance_dist" and #words == 2 then
			local v = number(1)
			tolerance = f32(v * v)
		elseif (d == "global_tolerance_time" or d == "global_tolerance_speed" or d == "global_anticipation_delay" or d == "tolerance_time") and #words == 2 then
			-- The native loader reads but does not store these values.
			number(1)
		elseif d == "pattern" and #words == 2 then
			if tolerance == nil then
				rt.raise("PAT lacks global_tolerance_dist")
			end
			table.insert(patterns, { name = words[2], points = {}, tolerance_squared = tolerance :: number } :: gesture.Pattern)
		elseif d == "tolerance_dist" and #words == 2 then
			local v = number(1)
			local last = patterns[#patterns]
			if last == nil then
				rt.raise(fail())
			end
			last.tolerance_squared = f32(v * v)
		elseif d == "coord" and #words == 3 then
			local point = { number(1), number(2) }
			local last = patterns[#patterns]
			if last == nil then
				rt.raise(fail())
			end
			table.insert(last.points, point)
		else
			-- Fail explicitly on polar or modified directives until their
			-- transcendental implementation is provided. Stock skater.pat uses coord.
			rt.raise(fail())
		end
	end
	gesture.Recognizer.new(patterns)
	return patterns
end

-- ROBLOX: path — путь в упакованных файлах (files.luau).
function gesture_patterns.load(path: string): { gesture.Pattern }
	local text, err = rt.catch(files.read_string, path)
	if err ~= nil then
		rt.raise(string.format("%s: %s", path, tostring(err)))
	end
	local result, err2 = rt.catch(gesture_patterns.parse, text)
	if err2 ~= nil then
		rt.raise(string.format("%s: %s", path, tostring(err2)))
	end
	return result
end

return gesture_patterns
