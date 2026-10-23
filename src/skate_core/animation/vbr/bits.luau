--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/vbr/bits.rs (коммит 2e16697)
--
-- TU3 Vector_UnPackFrameBlock 82E8A928, expressed as scalar bit readers.
-- The native reverse-byte permutation 830CEAD0 (initializer 82F96DF8) makes
-- both streams little endian. Width nibbles come from big-endian header words.
--
-- ROBLOX: &[u8] -> buffer + смещение начала + длина (без копирования среза).

local rt = require("../../../rt")

local bits = {}

type Bits = { bytes: buffer, base: number, len: number, position: number }

local function read(self: Bits, count: number): number
	local value = 0
	for bit = 0, count - 1 do
		local index = self.position // 8
		if index >= self.len then
			rt.raise("VBR coefficient bit stream truncated")
		end
		local byte = buffer.readu8(self.bytes, self.base + index)
		value = bit32.bor(value, bit32.lshift(bit32.band(bit32.rshift(byte, self.position % 8), 1), bit))
		self.position += 1
	end
	return value
end

-- pub(super) fn unpack(block: &[u8], widths: &[u32]) -> Result<Vec<[f32; 8]>, String>
-- ROBLOX: блок — bytes[start .. start + len).
function bits.unpack(bytes: buffer, start: number, len: number, widths: { number }): { { number } }
	if #widths == 0 then
		return {}
	end
	if len < 1 then
		rt.raise("VBR block has no selector length")
	end
	local prefix = buffer.readu8(bytes, start)
	local skip = 1 + (prefix + 7) // 8
	if skip > len then
		rt.raise("VBR selector length exceeds block")
	end
	local selected: Bits = { bytes = bytes, base = start + 1, len = len - 1, position = 0 }
	local packed: Bits = { bytes = bytes, base = start + skip, len = len - skip, position = 0 }
	local output: { { number } } = {}
	for _, descriptor in widths do
		local coefficients = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
		for i = 0, 7 do
			local width = bit32.band(bit32.rshift(descriptor, 4 * i), 15)
			-- A zero width consumes neither a selector nor packed data.
			if width ~= 0 and read(selected, 1) ~= 0 then
				local positive = read(packed, 1) ~= 0
				local magnitude = read(packed, width)
				-- The original complements the sign bit, then shifts it to
				-- bit31 and ORs it into the converted unsigned magnitude.
				-- Preserve negative zero; this is not two's complement.
				coefficients[i + 1] = if positive then magnitude else -magnitude
				if not positive and magnitude == 0 then
					coefficients[i + 1] = -0.0
				end
			end
		end
		table.insert(output, coefficients)
	end
	return output
end

return bits
