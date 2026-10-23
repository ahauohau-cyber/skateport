--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: замена std::fs::read для файлов данных игры.
--
-- В Rust движок читает файлы из папки assets. В Roblox файлов нет: байты
-- лежат base64-строками в src/skate_data/stock_files (собирает
-- tools/stock_files.py, в git не идут). Здесь они превращаются в buffer.
-- Путь — как в assets/private, например "stock/data/anim/OnBoard.abin".

local files = {}

local cache: { [string]: buffer } = {}

local DECODE = buffer.create(256)
do
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	buffer.fill(DECODE, 0, 255)
	for i = 1, 64 do
		buffer.writeu8(DECODE, string.byte(alphabet, i), i - 1)
	end
end

-- Base64 -> байты, с записью в out начиная с offset. Возвращает число байтов.
local function decode_into(text: string, out: buffer, offset: number): number
	local src = buffer.fromstring(text)
	local n = buffer.len(src)
	local o = offset
	local i = 0
	while i + 4 <= n do
		local a = buffer.readu8(DECODE, buffer.readu8(src, i))
		local b = buffer.readu8(DECODE, buffer.readu8(src, i + 1))
		local c3 = buffer.readu8(src, i + 2)
		local d4 = buffer.readu8(src, i + 3)
		buffer.writeu8(out, o, bit32.bor(bit32.lshift(a, 2), bit32.rshift(b, 4)))
		o += 1
		if c3 ~= 61 then
			local c = buffer.readu8(DECODE, c3)
			buffer.writeu8(out, o, bit32.band(bit32.bor(bit32.lshift(b, 4), bit32.rshift(c, 2)), 255))
			o += 1
			if d4 ~= 61 then
				local d = buffer.readu8(DECODE, d4)
				buffer.writeu8(out, o, bit32.band(bit32.bor(bit32.lshift(c, 6), d), 255))
				o += 1
			end
		end
		i += 4
	end
	return o - offset
end

-- Модуль с данными подставляется снаружи (в Studio — ReplicatedStorage,
-- в тестах — require по пути), чтобы ядро не зависело от места хранения.
local source: any = nil
function files.set_source(stock_files: any)
	source = stock_files
	table.clear(cache)
end

-- Есть ли файл в упакованных данных.
function files.exists(path: string): boolean
	return source ~= nil and source[path] ~= nil
end

-- ROBLOX: fs::read(path) -> buffer или ошибка (как Err в Rust: вызывающий код
-- превращает её в свою ошибку загрузки).
function files.read(path: string): buffer
	local hit = cache[path]
	if hit then
		return hit
	end
	if source == nil then
		error("skateport: данные игры не подключены (skate_data/stock_files)", 2)
	end
	local entry = source[path]
	if entry == nil then
		error("skateport: нет файла данных " .. path, 2)
	end
	local out = buffer.create(entry.size)
	local offset = 0
	for _, part in entry.parts do
		offset += decode_into(part(), out, offset)
	end
	assert(offset == entry.size, "skateport: повреждён файл данных " .. path)
	cache[path] = out
	return out
end

function files.read_string(path: string): string
	return buffer.tostring(files.read(path))
end

return files
