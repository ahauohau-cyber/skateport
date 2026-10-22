--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/attrib_hash.rs (коммит 2e16697)
--
-- AttribSys lookup8 identity. Numeric names preserve fields without debug strings.
-- ROBLOX: в Luau нет u64. Число хранится парой половин (hi, lo) по 32 бита;
-- wrapping-сложение, вычитание, xor и сдвиги собраны из bit32.

local attrib_hash = {}

type U64 = { number } -- { hi, lo }

local TWO32 = 0x1_0000_0000

local function add(a: U64, b: U64): U64
	local lo = a[2] + b[2]
	local carry = if lo >= TWO32 then 1 else 0
	return { (a[1] + b[1] + carry) % TWO32, lo % TWO32 }
end

local function sub(a: U64, b: U64): U64
	local lo = a[2] - b[2]
	local borrow = if lo < 0 then 1 else 0
	return { (a[1] - b[1] - borrow) % TWO32, lo % TWO32 }
end

local function xor(a: U64, b: U64): U64
	return { bit32.bxor(a[1], b[1]), bit32.bxor(a[2], b[2]) }
end

local function shr(a: U64, n: number): U64
	if n >= 32 then
		return { 0, bit32.rshift(a[1], n - 32) }
	end
	return { bit32.rshift(a[1], n), bit32.bor(bit32.rshift(a[2], n), bit32.lshift(a[1], 32 - n)) }
end

local function shl(a: U64, n: number): U64
	if n >= 32 then
		return { bit32.lshift(a[2], n - 32), 0 }
	end
	return { bit32.bor(bit32.lshift(a[1], n), bit32.rshift(a[2], 32 - n)), bit32.lshift(a[2], n) }
end

local ROUNDS = { { 43, 9, 8 }, { 38, 23, 5 }, { 35, 49, 11 }, { 12, 18, 22 } }

local function mix(a: U64, b: U64, c: U64): (U64, U64, U64)
	for _, r in ROUNDS do
		local x, y, z = r[1], r[2], r[3]
		a = xor(sub(sub(a, b), c), shr(c, x))
		b = xor(sub(sub(b, c), a), shl(a, y))
		c = xor(sub(sub(c, a), b), shr(b, z))
	end
	return a, b, c
end

-- Восемь байт строки начиная с позиции p (с 1), little-endian.
local function le64(text: string, p: number): U64
	local b0, b1, b2, b3, b4, b5, b6, b7 = string.byte(text, p, p + 7)
	local lo = b0 + b1 * 0x100 + b2 * 0x10000 + b3 * 0x1000000
	local hi = b4 + b5 * 0x100 + b6 * 0x10000 + b7 * 0x1000000
	return { hi, lo }
end

-- Байт byte, сдвинутый влево на shift бит (0..56), как u64.
local function byte_at(byte: number, shift: number): U64
	return shl({ 0, byte }, shift)
end

-- pub fn hash(text: &str) -> u64
-- ROBLOX: возвращает две половины (hi, lo).
function attrib_hash.hash(text: string): (number, number)
	if #text == 0 then
		return 0, 0
	end
	local a: U64 = { 0xabcdef00, 0x11223344 }
	local b: U64 = { a[1], a[2] }
	local c: U64 = { 0x9e3779b9, 0x7f4a7c13 }
	local chunks = #text // 24
	for k = 0, chunks - 1 do
		local p = k * 24 + 1
		a, b, c = mix(add(a, le64(text, p)), add(b, le64(text, p + 8)), add(c, le64(text, p + 16)))
	end
	c = add(c, { 0, #text })
	local start = chunks * 24
	for i = 0, #text - start - 1 do
		local byte = string.byte(text, start + i + 1)
		if i <= 7 then
			a = add(a, byte_at(byte, i * 8))
		elseif i <= 15 then
			b = add(b, byte_at(byte, (i - 8) * 8))
		else
			c = add(c, byte_at(byte, (i - 15) * 8))
		end
	end
	local _, _, result = mix(a, b, c)
	return result[1], result[2]
end

local function parse_hex64(hex: string): (number?, number?)
	if #hex == 0 or #hex > 16 or string.find(hex, "[^%x]") then
		return nil, nil
	end
	local padded = string.rep("0", 16 - #hex) .. hex
	return tonumber(string.sub(padded, 1, 8), 16), tonumber(string.sub(padded, 9, 16), 16)
end

local cache: { [string]: string } = {}

-- pub fn numeric_name(text: &str) -> String
-- ROBLOX: результат кэшируется — имена запрашиваются многократно.
function attrib_hash.numeric_name(text: string): string
	local cached = cache[text]
	if cached then
		return cached
	end
	local hi, lo
	for _, prefix in { "Hash_", "0x" } do
		if string.sub(text, 1, #prefix) == prefix then
			hi, lo = parse_hex64(string.sub(text, #prefix + 1))
			break
		end
	end
	if hi == nil then
		hi, lo = attrib_hash.hash(text)
	end
	local result = string.format("Hash_%08X%08X", hi :: number, lo :: number)
	cache[text] = result
	return result
end

return attrib_hash
