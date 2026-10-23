--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/vbr/header.rs (коммит 2e16697)
--
-- Original TU3 InitPerAnim 82E88FA8 and UnPackHeaderBits 82E8A780.
-- ROBLOX: Range<usize> блоков -> { start, end } (полуинтервал байтов).

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local header = {}

export type Channel = { dynamic: number, constant: number, components: number, min: number, range: number }

export type Header = {
	frames: number,
	bones: number,
	dct_scale: number,
	channels: { Channel },
	constants: { number },
	constant_flags: { boolean },
	widths: { number },
	blocks: { { number } },
}

-- pub(super) fn take / u16_at / u32_at — чтение с проверкой границ.
local function check(bytes: buffer, at: number, count: number)
	if at < 0 or at + count > buffer.len(bytes) then
		rt.raise(string.format("VBR read %#x+%d out of bounds", at, count))
	end
end
function header.u8_at(bytes: buffer, at: number): number
	check(bytes, at, 1)
	return buffer.readu8(bytes, at)
end
function header.u16_at(bytes: buffer, at: number): number
	check(bytes, at, 2)
	return bit32.bor(bit32.lshift(buffer.readu8(bytes, at), 8), buffer.readu8(bytes, at + 1))
end
function header.u32_at(bytes: buffer, at: number): number
	check(bytes, at, 4)
	return bit32.bor(bit32.lshift(buffer.readu8(bytes, at), 24), bit32.lshift(buffer.readu8(bytes, at + 1), 16), bit32.lshift(buffer.readu8(bytes, at + 2), 8), buffer.readu8(bytes, at + 3))
end
local u8_at, u16_at, u32_at = header.u8_at, header.u16_at, header.u32_at

-- ROBLOX: Result<Self, String> -> значение или rt.raise.
function header.read(bytes: buffer, part: number, header_relative: number, data_relative: number): Header
	local header_word = u32_at(bytes, part)
	local bones = bit32.band(bit32.rshift(header_word, 6), 63) + 1
	local h = part + header_relative
	local header_end = h + bit32.rshift(header_word, 12)
	local data = part + data_relative
	local data_end = data + u32_at(bytes, part + 4)
	if header_end < h then
		rt.raise("VBR header range")
	end
	check(bytes, h, header_end - h)
	if data_end < data then
		rt.raise("VBR data range")
	end
	check(bytes, data, data_end - data)
	local frames = u16_at(bytes, h + 2)
	check(bytes, h + 12, 2)
	local count0, count1 = buffer.readu8(bytes, h + 12), buffer.readu8(bytes, h + 13)
	if count0 ~= 3 or frames == 0 then
		rt.raise("VBR SQT requires three channel types and a nonempty frame range")
	end
	local dictionary = h + 16
	local dictionary_count = count1
	local size_table = dictionary + dictionary_count * 4
	local block_count = (frames + 7) // 8
	local types = bit32.band(size_table + block_count * 2 + 15, bit32.bnot(15))
	if types + 48 > header_end then
		rt.raise("VBR channel descriptions exceed compression header")
	end
	local channels: { Channel } = {}
	for i, expected_components in { 3, 4, 3 } do
		local at = types + 16 * (i - 1)
		local dynamic = u16_at(bytes, at)
		local constant = u16_at(bytes, at + 2)
		local components = u8_at(bytes, at + 12)
		local min = from_bits(u32_at(bytes, at + 4))
		local max = from_bits(u32_at(bytes, at + 8))
		if components ~= expected_components or dynamic + constant ~= bones then
			rt.raise(string.format("VBR channel %d does not match its SQT output descriptor", i - 1))
		end
		table.insert(channels, { dynamic = dynamic, constant = constant, components = components, min = min, range = f32(max - min) })
	end
	local cursor = data
	local constants = {}
	for _, channel in channels do
		for _ = 1, channel.constant * channel.components do
			local index = u8_at(bytes, cursor)
			cursor += 1
			if index >= dictionary_count then
				rt.raise("VBR constant dictionary index out of bounds")
			end
			local value = from_bits(u32_at(bytes, dictionary + index * 4))
			-- Original scalar fmadds 82E8A804..878, including constants.
			table.insert(constants, mul_add(value, channel.range, channel.min))
		end
	end
	local runs = u16_at(bytes, h)
	local constant_flags = {}
	for run = 0, runs - 1 do
		local length = u8_at(bytes, cursor)
		cursor += 1
		if #constant_flags + length > 3 * bones then
			rt.raise("VBR constant-channel run exceeds channel count")
		end
		for _ = 1, length do
			table.insert(constant_flags, run % 2 == 1)
		end
	end
	if runs == 0 and #constants == 0 then
		for _ = #constant_flags + 1, 3 * bones do
			table.insert(constant_flags, false)
		end
	end
	if #constant_flags ~= 3 * bones then
		rt.raise("VBR constant-channel runs do not cover all channels")
	end
	for i, channel in channels do
		local n = 0
		for k = (i - 1) * bones + 1, i * bones do
			if constant_flags[k] then
				n += 1
			end
		end
		if n ~= channel.constant then
			rt.raise(string.format("VBR channel %d constant count differs from its runs", i - 1))
		end
	end
	local dynamic_count = 0
	for _, c in channels do
		dynamic_count += c.dynamic * c.components
	end
	local widths: { number } = {}
	for _ = 1, dynamic_count do
		table.insert(widths, u32_at(bytes, cursor))
		cursor += 4
	end
	local block_start = cursor
	local blocks: { { number } } = {}
	-- Vector_ExtractPackedNVBR 82D1E0E4..118 accumulates u16 block sizes.
	local displacement = 0
	for block = 0, block_count - 1 do
		local size = u16_at(bytes, size_table + 2 * block)
		local start = block_start + displacement
		local end_ = start + size
		if end_ > data_end or size < 3 then
			rt.raise(string.format("VBR block %d exceeds compressed data", block))
		end
		table.insert(blocks, { start, end_ })
		displacement = (displacement + size) % 0x10000
	end
	local low = math.abs(from_bits(u32_at(bytes, h + 4)))
	local high = math.abs(from_bits(u32_at(bytes, h + 8)))
	return {
		frames = frames,
		bones = bones,
		dct_scale = rt.fmax(low, high),
		channels = channels,
		constants = constants,
		constant_flags = constant_flags,
		widths = widths,
		blocks = blocks,
	}
end

return header
