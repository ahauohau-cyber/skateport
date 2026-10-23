--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_metadata/native.rs (коммит 2e16697)
--
-- Lossless original ABIN metadata layouts. No pose codec or numerical decoder.
-- Clip header827B8AB0, attribute82D164F8, tree lookup82D1B5B8.
-- ROBLOX: `impl AnimationMetadata { fn from_bank }` -> native.read_file(bank, ...)
-- собирает File, а AnimationMetadata.from_bank (init.luau) передаёт его в from_file
-- (без циклического require).

local rt = require("../../rt")
local abin = require("../abin")
local abin_reader = require("../abin/reader")
local blend_space = require("./blend_space")
local selection_space = require("./selection_space")

local Reader = abin_reader.Reader
local Bank = abin.Bank

local native = {}

local function fail(offset: number, message: string): never
	return rt.raise({ offset = offset, message = message })
end

local function read_clip(r: abin_reader.Reader, h: any, clip: any): any
	local at = clip.attribute_offset
	local attributes = {}
	for _ = 1, clip.attribute_count do
		-- Original GetAttribute82D25CA0 advances by the record's first word.
		local size = Reader.u32(r, at)
		if size < 48 then
			fail(at, "attribute record smaller than header")
		end
		local end_ = at + size
		local a = Reader.bounded(r, at, end_)
		local data = bit32.band(at + 51, bit32.bnot(15))
		if end_ < data then
			fail(at, "attribute payload outside record")
		end
		local payload = Reader.take(a, data, end_ - data)
		if (end_ - data) % 4 ~= 0 then
			fail(at, "unaligned attribute payload")
		end
		local words = {}
		for i = 0, (end_ - data) // 4 - 1 do
			table.insert(words, Reader.u32(a, payload + i * 4))
		end
		table.insert(attributes, {
			name = Reader.name(a, at + 12, 5),
			type_id = Reader.u8(a, at + 32),
			begin_bits = Reader.u32(a, at + 4),
			end_bits = Reader.u32(a, at + 8),
			payload_words = words,
			source_offset = at,
		})
		at = end_
	end
	return {
		name = h.name,
		source_offset = h.offset,
		fps_bits = clip.fps_bits,
		frames_bits = clip.frame_count_bits,
		base_speed_bits = clip.base_speed_bits,
		flags_word = clip.flags,
		attributes = attributes,
	}
end

local function read_phase_blend(r: abin_reader.Reader, h: any): any
	-- Type7 construction82D1B5B8: count+8, parameter+16, child names+36.
	local p = h.payload_offset
	local count = Reader.u32(r, p + 8)
	Reader.take(r, p + 36, count * 24)
	local children = {}
	for i = 0, count - 1 do
		table.insert(children, Reader.name(r, p + 36 + 24 * i, 6))
	end
	return { name = h.name, source_offset = h.offset, parameter = Reader.name(r, p + 16, 5), children = children }
end

local function read_selector(r: abin_reader.Reader, h: any): any
	-- Type8 construction82D1B5B8 keeps the first name as authored default.
	-- Child/value order matters: runtime chooses the first matching value.
	local p = h.payload_offset
	local count = Reader.u32(r, p + 28)
	local names_size = math.max(count, 1) * 24
	local keys_size = count * 20
	local names = Reader.relative(r, p, Reader.u32(r, p + 20), names_size)
	local keys = Reader.relative(r, p, Reader.u32(r, p + 24), keys_size)
	local children, values = {}, {}
	for i = 0, count - 1 do
		table.insert(children, Reader.name(r, names + 24 * i, 6))
	end
	for i = 0, count - 1 do
		table.insert(values, Reader.name(r, keys + 20 * i, 5))
	end
	return {
		name = h.name,
		source_offset = h.offset,
		parameter = Reader.name(r, p, 5),
		default = Reader.name(r, names, 6),
		children = children,
		values = values,
	}
end

-- /// Read the retained bytes without constructing or evaluating animation
-- /// trees. Caller supplies the independently calculated bank SHA-256.
-- ROBLOX: ошибки abin переводятся в строку (e.to_string()).
function native.read_file(bank: any, source_bank: string, source_sha256: string): any
	local file = {
		version = 1,
		source_bank = source_bank,
		source_sha256 = source_sha256,
		source_bytes = buffer.len(Bank.bytes(bank)),
		clips = {},
		phase_blends = {},
		blend_spaces = {},
		selectors = {},
		selection_spaces = {},
		unsupported_trees = {},
	}
	local reader = Reader.new(Bank.bytes(bank))
	for _, record in Bank.records(bank) do
		local h = record.header
		local _, err = rt.catch(function()
			local r = Reader.bounded(reader, h.offset, h.offset + h.size)
			local data = record.data
			if data.kind == "Clip" then
				table.insert(file.clips, read_clip(r, h, data.value))
			elseif data.kind == "Opaque" then
				local kind = h.type_id
				if kind == 6 then
					table.insert(file.blend_spaces, blend_space.read(r, h))
				elseif kind == 7 then
					table.insert(file.phase_blends, read_phase_blend(r, h))
				elseif kind == 8 then
					table.insert(file.selectors, read_selector(r, h))
				elseif kind == 11 then
					table.insert(file.selection_spaces, selection_space.read(r, h))
				else
					table.insert(file.unsupported_trees, { name = h.name, source_offset = h.offset, type_id = kind })
				end
			end
		end)
		if err ~= nil then
			rt.raise(abin.error_to_string(err))
		end
	end
	return file
end

return native
