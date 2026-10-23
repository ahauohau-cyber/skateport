--!strict
-- ROBLOX: замена serde_json для данных skate-data (своего Rust-файла нет).
--
-- Минимальный разбор JSON (RFC 8259) на чистом Luau: в Roblox есть
-- HttpService:JSONDecode, но ядро и тесты запускаются и вне Roblox.
-- Объект -> таблица со строковыми ключами (порядок ключей не хранится),
-- массив -> массив с 1, null -> json.null. Ошибка -> rt.raise(строка).

local rt = require("../rt")

local json = {}

-- Отдельное значение для null, чтобы отличать его от отсутствующего ключа.
json.null = table.freeze({})

local ESCAPES = {
	[string.byte('"')] = '"',
	[string.byte("\\")] = "\\",
	[string.byte("/")] = "/",
	[string.byte("b")] = "\b",
	[string.byte("f")] = "\f",
	[string.byte("n")] = "\n",
	[string.byte("r")] = "\r",
	[string.byte("t")] = "\t",
}

function json.decode(text: string): any
	local pos = 1
	local n = #text

	local function fail(message: string): never
		return rt.raise(string.format("JSON: %s в позиции %d", message, pos))
	end

	local function skip()
		while pos <= n do
			local c = string.byte(text, pos)
			if c == 32 or c == 9 or c == 10 or c == 13 then
				pos += 1
			else
				break
			end
		end
	end

	local value: () -> any

	local function parse_string(): string
		pos += 1 -- открывающая кавычка
		local parts = {}
		local start = pos
		while true do
			if pos > n then
				fail("незакрытая строка")
			end
			local c = string.byte(text, pos)
			if c == 34 then
				table.insert(parts, string.sub(text, start, pos - 1))
				pos += 1
				return table.concat(parts)
			elseif c == 92 then
				table.insert(parts, string.sub(text, start, pos - 1))
				local e = string.byte(text, pos + 1)
				if e == 117 then
					local hex = string.sub(text, pos + 2, pos + 5)
					local code = tonumber(hex, 16)
					if code == nil then
						fail("плохой \\u")
					end
					pos += 6
					local cp = code :: number
					if cp >= 0xD800 and cp <= 0xDBFF and string.sub(text, pos, pos + 1) == "\\u" then
						local low = tonumber(string.sub(text, pos + 2, pos + 5), 16)
						if low and low >= 0xDC00 and low <= 0xDFFF then
							cp = 0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)
							pos += 6
						end
					end
					table.insert(parts, utf8.char(cp))
				else
					local s = ESCAPES[e]
					if s == nil then
						fail("плохая escape-последовательность")
					end
					table.insert(parts, s)
					pos += 2
				end
				start = pos
			elseif c < 32 then
				fail("управляющий символ в строке")
			else
				pos += 1
			end
		end
	end

	local function parse_number(): number
		local s, e = string.find(text, "^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
		if s == nil then
			fail("плохое число")
		end
		local literal = string.sub(text, s :: number, e :: number)
		local v = tonumber(literal)
		if v == nil then
			fail("плохое число")
		end
		pos = (e :: number) + 1
		return v :: number
	end

	value = function(): any
		skip()
		if pos > n then
			fail("неожиданный конец")
		end
		local c = string.byte(text, pos)
		if c == 123 then -- {
			pos += 1
			local obj = {}
			skip()
			if string.byte(text, pos) == 125 then
				pos += 1
				return obj
			end
			while true do
				skip()
				if string.byte(text, pos) ~= 34 then
					fail("ожидался ключ")
				end
				local key = parse_string()
				skip()
				if string.byte(text, pos) ~= 58 then
					fail("ожидалось ':'")
				end
				pos += 1
				obj[key] = value()
				skip()
				local d = string.byte(text, pos)
				pos += 1
				if d == 125 then
					return obj
				elseif d ~= 44 then
					fail("ожидалось ',' или '}'")
				end
			end
		elseif c == 91 then -- [
			pos += 1
			local arr = {}
			skip()
			if string.byte(text, pos) == 93 then
				pos += 1
				return arr
			end
			while true do
				table.insert(arr, value())
				skip()
				local d = string.byte(text, pos)
				pos += 1
				if d == 93 then
					return arr
				elseif d ~= 44 then
					fail("ожидалось ',' или ']'")
				end
			end
		elseif c == 34 then
			return parse_string()
		elseif string.sub(text, pos, pos + 3) == "true" then
			pos += 4
			return true
		elseif string.sub(text, pos, pos + 4) == "false" then
			pos += 5
			return false
		elseif string.sub(text, pos, pos + 3) == "null" then
			pos += 4
			return json.null
		end
		return parse_number()
	end

	local result = value()
	skip()
	if pos <= n then
		fail("лишние данные после значения")
	end
	return result
end

-- ROBLOX: #[serde(deny_unknown_fields)] + обязательные поля.
-- Проверяет, что у объекта ровно эти ключи; иначе rt.raise(строка).
function json.expect_fields(object: any, fields: { string }, what: string)
	if type(object) ~= "table" then
		rt.raise(what .. ": ожидался объект")
	end
	local allowed = {}
	for _, f in fields do
		allowed[f] = true
		if object[f] == nil then
			rt.raise(string.format("%s: missing field `%s`", what, f))
		end
	end
	for k in object do
		if not allowed[k] then
			rt.raise(string.format("%s: unknown field `%s`", what, tostring(k)))
		end
	end
end

return json
