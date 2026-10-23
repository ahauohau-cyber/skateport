--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/vbr/mod.rs (коммит 2e16697)
--
-- Direct stock VBR SQT decoding from original Skate 3 TU3.
-- Source: 82E88FA8/82E8A780 (header), 82E8A928 (bits), 82E89770 (transform),
-- 82E89A60/82E88BA0 (output), and 82D20298 (SQT channel descriptors).
-- Host allocation/cache ownership is independent. PC floating-point arithmetic
-- is not claimed to emulate the Xenon's numerical instructions bit for bit.
-- ROBLOX: байты банка — buffer; смещения — с нуля.

local rt = require("../../rt")
local bits = require("@self/bits")
local header_mod = require("@self/header")
local transform = require("@self/transform")

local to_bits = rt.to_bits

local vbr = {}
vbr.bits = bits
vbr.header = header_mod
vbr.transform = transform

export type VbrDecoder = {
	bytes: buffer,
	header: header_mod.Header,
	cached_index: number?,
	cached_block: { { number } }?,
}

local VbrDecoder = {}
vbr.VbrDecoder = VbrDecoder

function VbrDecoder.new(bytes: buffer, part_offset: number, compression_header_relative: number, compressed_data_relative: number): VbrDecoder
	return { bytes = bytes, header = header_mod.read(bytes, part_offset, compression_header_relative, compressed_data_relative), cached_index = nil, cached_block = nil }
end

function VbrDecoder.frame_count(self: VbrDecoder): number
	return self.header.frames
end
function VbrDecoder.channel_count(self: VbrDecoder): number
	return self.header.bones
end

-- Return each authored bone's scaleXYZ, quaternionXYZW, translationXYZ bits.
-- No quaternion normalization, retargeting, hierarchy changes or weight edits.
-- ROBLOX: Vec<[u32; 10]> -> таблица костей по 10 слов.
function VbrDecoder.decode_frame(self: VbrDecoder, frame: number): { { number } }
	local h = self.header
	if frame >= h.frames then
		rt.raise(string.format("VBR frame %d out of range", frame))
	end
	local block_index = frame // 8
	local range = h.blocks[block_index + 1]
	local start, end_ = range[1], range[2]
	if self.cached_index ~= block_index then
		self.cached_block = bits.unpack(self.bytes, start + 3, end_ - start - 3, h.widths)
		self.cached_index = block_index
	end
	local coefficients = self.cached_block :: { { number } }
	local output: { { number } } = {}
	for b = 1, h.bones do
		output[b] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	end
	local constant = 0
	local dynamic = 0
	local component_offset = 0
	for channel_index, channel in h.channels do
		local q = buffer.readu8(self.bytes, start + channel_index - 1)
		for bone = 1, h.bones do
			local sqt = output[bone]
			local is_constant = h.constant_flags[(channel_index - 1) * h.bones + bone]
			for component = 1, channel.components do
				local value
				if is_constant then
					constant += 1
					value = h.constants[constant]
				else
					dynamic += 1
					value = transform.decode(frame % 8, q, h.dct_scale, coefficients[dynamic], channel.min, channel.range)
				end
				sqt[component_offset + component] = to_bits(value)
			end
		end
		component_offset += channel.components
	end
	return output
end

return vbr
