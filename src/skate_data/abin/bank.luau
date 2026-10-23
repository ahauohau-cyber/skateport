--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/abin/bank.rs (коммит 2e16697)
--
-- Ordered bank indexing and lossless header decoding. Codec math is separate.
-- ROBLOX: Bank::load(path) нет — файлов в Roblox нет; байты приходят buffer'ом
-- из skate_data/stock_files (см. tools/stock_files.py). BTreeMap -> словари.
-- Индексы записей — с нуля (records[i + 1]).

local reader_mod = require("./reader")

local Reader = reader_mod.Reader
type Reader = reader_mod.Reader
local fail = reader_mod.fail

local bank = {}

export type Bank = {
	bytes: buffer,
	wrapper_bytes: number,
	trailer: { number },
	records: { any },
	offsets: { [number]: number },
	animations: { [string]: number },
	clips: { [string]: number },
	poses: { [string]: number },
	hierarchy: number?,
}

local function read_parts(r: Reader, base: number, tbl: number, count: number, channel: boolean): { any }
	Reader.take(r, base + tbl, count * 4)
	local parts = table.create(count)
	for i = 0, count - 1 do
		local table_offset = base + tbl + 4 * i
		local word = Reader.u32(r, table_offset)
		local relative = bit32.band(word, 0x00ffffff)
		local part = nil
		if relative ~= 0 then
			local offset = Reader.relative(r, base, relative, 16)
			local header_word = Reader.u32(r, offset)
			local compressed_size = Reader.u32(r, offset + 4)
			local compression_header_relative = Reader.u32(r, offset + 8)
			local compressed_data_relative = Reader.u32(r, offset + 12)
			local channel_count = bit32.band(bit32.rshift(header_word, 6), 63) + 1
			local ch_s, ch_e = Reader.relative(r, offset, compression_header_relative, bit32.rshift(header_word, 12))
			local cd_s, cd_e = Reader.relative(r, offset, compressed_data_relative, compressed_size)
			local channel_weights = nil
			if channel then
				local s, e = Reader.relative(r, offset, 16, 4 * channel_count)
				channel_weights = { s, e }
			end
			part = {
				offset = offset,
				header_word = header_word,
				compressed_size = compressed_size,
				compression_header_relative = compression_header_relative,
				compressed_data_relative = compressed_data_relative,
				channel_count = channel_count,
				compression_header = { ch_s, ch_e },
				compressed_data = { cd_s, cd_e },
				channel_weights = channel_weights,
			}
		end
		table.insert(parts, { table_index = i, table_offset = table_offset, raw_word = word, encoded_id = bit32.rshift(word, 24), part = part })
	end
	return parts
end

local function read_clip(r: Reader, h: any): any
	local p = h.payload_offset
	Reader.take(r, p, 56)
	local flags = Reader.u32(r, p + 52)
	local attribute_count = bit32.band(flags, 255)
	local attribute_offset = Reader.relative(r, p, Reader.u32(r, p + 44), 0)
	return {
		fps_bits = Reader.u32(r, p + 32),
		frame_count_bits = Reader.u32(r, p + 36),
		base_speed_bits = Reader.u32(r, p + 40),
		flags = flags,
		loop_translation_words = Reader.words(r, p, 4),
		loop_rotation_words = Reader.words(r, p + 16, 4),
		attribute_offset = attribute_offset,
		attribute_count = attribute_count,
		parts = read_parts(r, p, 56, bit32.band(bit32.rshift(flags, 8), 31), bit32.band(flags, 0x20000000) ~= 0),
	}
end

local function read_hierarchy(r: Reader, p: number): any
	local bone_count = Reader.u16(r, p)
	local n = bone_count
	local count = Reader.u32(r, p + 4)
	local part_bytes = count * 36
	local part_base = p + 8 + 8 * n
	Reader.take(r, p + 8, 8 * n)
	Reader.take(r, part_base, part_bytes)
	local name_base = part_base + part_bytes
	Reader.take(r, name_base, 20 * n)
	local parents, mirrors, bone_names = {}, {}, {}
	for i = 0, n - 1 do
		local parent = Reader.i32(r, p + 8 + 4 * i)
		local mirror = Reader.i32(r, p + 8 + 4 * n + 4 * i)
		if parent < -1 or parent >= i or mirror < -1 or mirror >= n then
			fail(p + 8 + 4 * i, "invalid parent or mirror index")
		end
		table.insert(parents, parent)
		table.insert(mirrors, mirror)
		table.insert(bone_names, Reader.name(r, name_base + 20 * i, 5))
	end
	local parts = {}
	for i = 0, count - 1 do
		local at = part_base + i * 36
		local bc = Reader.u32(r, at + 24)
		local sqt_offset = Reader.i32(r, at + 28)
		if sqt_offset < 0 or sqt_offset + bc > n then
			fail(at, "part extends outside skeleton output")
		end
		table.insert(parts, { name = Reader.name(r, at, 6), bone_count = bc, sqt_offset = sqt_offset, flags = Reader.u16(r, at + 32), encoded_id = Reader.u16(r, at + 34) })
	end
	return { offset = p, bone_count = bone_count, has_trajectory = Reader.u16(r, p + 2) ~= 0, parents = parents, mirrors = mirrors, bone_names = bone_names, parts = parts }
end

local Bank = {}
bank.Bank = Bank

-- ROBLOX: Result<Self> -> Bank или rt.raise({ offset, message }).
function Bank.parse(bytes: buffer): Bank
	local reader = Reader.new(bytes)
	local end_ = Reader.u32(reader, 0)
	if Reader.u32(reader, 4) ~= 1 or end_ < 48 or end_ > buffer.len(bytes) then
		fail(0, "invalid type1 bank wrapper")
	end
	local records = {}
	local offsets, animations, clips, poses = {}, {}, {}, {}
	local hierarchy = nil
	local at = 48
	while at < end_ do
		local size = Reader.u32(reader, at)
		if size < 48 or size % 16 ~= 0 or size > end_ - at then
			fail(at, "invalid record size/alignment")
		end
		local r = Reader.bounded(reader, at, at + size)
		local header = {
			name = Reader.name(r, at + 16, 6),
			name_words = Reader.words(r, at + 16, 6),
			offset = at,
			size = size,
			payload_offset = bit32.band(at + 55, bit32.bnot(15)),
			type_id = Reader.u32(r, at + 4),
			codec_word = Reader.u32(r, at + 8),
			guid = Reader.u32(r, at + 12),
		}
		local data
		local t = header.type_id
		if t == 2 then
			data = { kind = "Clip", value = read_clip(r, header) }
		elseif t == 3 then
			data = { kind = "Pose", value = { parts = read_parts(r, header.payload_offset, 4, Reader.u32(r, header.payload_offset), false) } }
		elseif t == 4 then
			data = { kind = "Hierarchy", value = read_hierarchy(r, header.payload_offset) }
		elseif t == 5 then
			local n = Reader.u32(r, header.payload_offset)
			local s, e = Reader.relative(r, header.payload_offset, 16, n * 112)
			data = { kind = "PhysicsPose", value = { bone_count = n, records = { s, e } } }
		else
			data = { kind = "Opaque" }
		end
		local index = #records
		-- SetDBContent 82D1B428..45C overwrites map entries in file order.
		-- Clips also participate in the animation-tree map, poses do not.
		if t == 2 then
			clips[header.name] = index
			animations[header.name] = index
		elseif t == 3 then
			poses[header.name] = index
		elseif t == 4 then
			hierarchy = index
		elseif t >= 6 and t <= 11 then
			animations[header.name] = index
		end
		offsets[at] = index
		table.insert(records, { header = header, data = data })
		at += size
	end
	return {
		bytes = bytes,
		wrapper_bytes = end_,
		trailer = { end_, buffer.len(bytes) },
		records = records,
		offsets = offsets,
		animations = animations,
		clips = clips,
		poses = poses,
		hierarchy = hierarchy,
	}
end

function Bank.bytes(self: Bank): buffer
	return self.bytes
end
function Bank.records(self: Bank): { any }
	return self.records
end
function Bank.record_at(self: Bank, offset: number): any?
	local i = self.offsets[offset]
	return if i ~= nil then self.records[i + 1] else nil
end
function Bank.animation(self: Bank, name: string): any?
	local i = self.animations[string.upper(name)]
	return if i ~= nil then self.records[i + 1] else nil
end
-- ROBLOX: Option<(&RecordHeader, &Clip)> -> (header, clip) или nil.
function Bank.clip(self: Bank, name: string): (any?, any?)
	local i = self.clips[string.upper(name)]
	if i == nil then
		return nil, nil
	end
	local record = self.records[i + 1]
	if record.data.kind == "Clip" then
		return record.header, record.data.value
	end
	return nil, nil
end
function Bank.pose(self: Bank, name: string): (any?, any?)
	local i = self.poses[string.upper(name)]
	if i == nil then
		return nil, nil
	end
	local record = self.records[i + 1]
	if record.data.kind == "Pose" then
		return record.header, record.data.value
	end
	return nil, nil
end
function Bank.hierarchy(self: Bank): any?
	if self.hierarchy == nil then
		return nil
	end
	local d = self.records[self.hierarchy + 1].data
	return if d.kind == "Hierarchy" then d.value else nil
end

-- The stock OnBoard/OffBoard VBR banks carry all eight parts in hierarchy
-- order. Their encoded ids are all zero; source 82D20608/82D20924 advances
-- its equal-id cursor one entry at a time, preserving this ordinal mapping.
-- Call before using positional part association; partial banks may require
-- the original named/id association and are not silently treated as full.
function Bank.validate_positional_parts(self: Bank)
	local hierarchy = Bank.hierarchy(self)
	if hierarchy == nil then
		fail(0, "missing hierarchy")
	end
	for _, record in self.records do
		local k = record.data.kind
		if k == "Clip" or k == "Pose" then
			local parts = record.data.value.parts
			if #parts ~= #hierarchy.parts then
				fail(record.header.offset, "part table differs from full hierarchy")
			end
			for i, entry in parts do
				local part = entry.part
				if part ~= nil and part.channel_count ~= hierarchy.parts[i].bone_count then
					fail(part.offset, "part channel count differs from hierarchy")
				end
			end
		end
	end
end

return bank
