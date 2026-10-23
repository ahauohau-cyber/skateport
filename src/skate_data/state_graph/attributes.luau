--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/state_graph/attributes.rs (коммит 2e16697)
--
-- BinaryAttributeMap keys (82B92B98) and lookup/insert semantics.
-- This is the graph's 32-bit hash, not Attribulator's 64-bit field hash.

local attributes = {}

local function sub(a: number, b: number): number
	return (a - b) % 0x1_0000_0000
end

-- ROBLOX: &mut u32 ×3 -> возвращаем новые значения.
local function mix(a: number, b: number, c: number): (number, number, number)
	a = bit32.bxor(sub(sub(a, b), c), bit32.rshift(c, 13))
	b = bit32.bxor(sub(sub(b, c), a), bit32.lshift(a, 8))
	c = bit32.bxor(sub(sub(c, a), b), bit32.rshift(b, 13))
	a = bit32.bxor(sub(sub(a, b), c), bit32.rshift(c, 12))
	b = bit32.bxor(sub(sub(b, c), a), bit32.lshift(a, 16))
	c = bit32.bxor(sub(sub(c, a), b), bit32.rshift(b, 5))
	a = bit32.bxor(sub(sub(a, b), c), bit32.rshift(c, 3))
	b = bit32.bxor(sub(sub(b, c), a), bit32.lshift(a, 10))
	c = bit32.bxor(sub(sub(c, a), b), bit32.rshift(b, 15))
	return a, b, c
end

-- /// Complete 82B92B98, including each tail length and wrapping 32-bit arithmetic.
-- ROBLOX: &[u8] -> строка Luau (байты).
function attributes.byte_hash(bytes: string): number
	local a = 0x9e37_79b9
	local b = a
	local c = 0xabcd_ef00
	local len = #bytes
	local full = len // 12
	for chunk = 0, full - 1 do
		local o = chunk * 12 + 1
		local x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11 = string.byte(bytes, o, o + 11)
		a = (a + x0 + x1 * 0x100 + x2 * 0x10000 + x3 * 0x1000000) % 0x1_0000_0000
		b = (b + x4 + x5 * 0x100 + x6 * 0x10000 + x7 * 0x1000000) % 0x1_0000_0000
		c = (c + x8 + x9 * 0x100 + x10 * 0x10000 + x11 * 0x1000000) % 0x1_0000_0000
		a, b, c = mix(a, b, c)
	end
	c = (c + len) % 0x1_0000_0000
	for i = 0, len - full * 12 - 1 do
		local byte = string.byte(bytes, full * 12 + i + 1)
		if i <= 3 then
			a = (a + bit32.lshift(byte, 8 * i)) % 0x1_0000_0000
		elseif i <= 7 then
			b = (b + bit32.lshift(byte, 8 * (i - 4))) % 0x1_0000_0000
		else
			c = (c + bit32.lshift(byte, 8 * (i - 7))) % 0x1_0000_0000
		end
	end
	a, b, c = mix(a, b, c)
	return c
end
local byte_hash = attributes.byte_hash

-- /// Attribute/tag callers use zero for missing or empty strings. The underlying
-- /// 82B92B98 byte hash has a different, nonzero result for a zero-length buffer.
function attributes.key_hash(text: string): number
	if text == "" then
		return 0
	end
	return byte_hash(text)
end
local key_hash = attributes.key_hash

-- /// Native 82C19BB0 is unique insertion by the hashed key: the first record wins
-- /// for duplicate keys, including collisions between differently spelled keys.
-- /// Original record order and all encodings remain available in GraphElement.
export type Attributes = {
	entries: { [number]: any },
}

local Attributes = {}
attributes.Attributes = Attributes

function Attributes.new(list: { any }): Attributes
	local entries = {}
	for _, attribute in list do
		local key = key_hash(attribute.name)
		if entries[key] == nil then
			entries[key] = attribute
		end
	end
	return { entries = entries }
end

-- ROBLOX: Option<&GraphAttribute> -> запись или nil.
function Attributes.get(self: Attributes, name: string): any?
	return self.entries[key_hash(name)]
end

-- /// 82C14E10. A present empty string is not the default.
function Attributes.text(self: Attributes, name: string): string?
	local v = Attributes.get(self, name)
	return if v ~= nil then v.text else nil
end

-- /// 82C151B0 returns the stored byte without boolean normalization.
function Attributes.boolean_byte(self: Attributes, name: string, default: number): number
	local v = Attributes.get(self, name)
	return if v ~= nil then v.boolean_byte else default
end

-- /// 82C15308; callers of 82C15258 supply the native zero default.
function Attributes.float_bits(self: Attributes, name: string, default: number): number
	local v = Attributes.get(self, name)
	return if v ~= nil then v.float_bits else default
end

return attributes
