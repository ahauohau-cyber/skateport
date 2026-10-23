--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_frames/native.rs (коммит 2e16697)
--
-- Bank-backed lazy animation samples. Each requested clip is decoded once;
-- registration indexes every record without allocating every decoded frame.
-- ROBLOX: OnceLock<Result<T, String>> -> поле decoded = { ok = T } | { err = строка };
-- BTreeMap с составным ключом -> вложенные таблицы [bank][offset] / [bank][name].
-- validate_samples из animation_frames (init.luau) подставляет init в поле
-- native.validate_samples (без циклического require).

local rt = require("../../rt")
local abin = require("../abin")
local abin_reader = require("../abin/reader")
local vbr = require("../../skate_core/animation/vbr")

local from_bits = rt.from_bits
local is_finite = rt.is_finite
local to_bits = rt.to_bits
local Bank = abin.Bank
local Reader = abin_reader.Reader
local VbrDecoder = vbr.VbrDecoder

local native = {}
native.validate_samples = (nil :: any) :: ({ any }, number) -> ()

type Entry = { bank: number, offset: number, decoded: any }

local function entry_new(bank: number, offset: number): Entry
	return { bank = bank, offset = offset, decoded = nil }
end

-- ROBLOX: bank — индекс банка с нуля.
export type NativeFrames = {
	banks: { any },
	clips: { [string]: Entry },
	clip_order: { string },
	poses: { [number]: { [number]: Entry } },
	pose_names: { [number]: { [string]: number } },
}

local NativeFrames = {}
native.NativeFrames = NativeFrames

local function require_vbr(codec: any)
	if codec ~= "Vbr" then
		local text = if type(codec) == "table" then string.format("Other(%d)", codec.other) else tostring(codec)
		rt.raise(string.format("Unsupported native animation codec %s", text))
	end
end

local function decode_parts(bank: any, parts: { any }, count: number): { { { number } } }
	local hierarchy = Bank.hierarchy(bank)
	if hierarchy == nil then
		rt.raise("Missing stock hierarchy")
	end
	local h = hierarchy :: any
	local bones = h.bone_count
	if #parts ~= #h.parts then
		rt.raise("Animation part count differs from hierarchy")
	end
	local frames: any = table.create(count)
	for i = 1, count do
		local frame = table.create(bones)
		for b = 1, bones do
			frame[b] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
		end
		frames[i] = frame
	end
	local assigned = table.create(bones, false)
	for index, entry in parts do
		local layout = h.parts[index]
		local part = entry.part
		if part == nil then
			rt.raise("Required stock animation part is absent")
		end
		local decoder = VbrDecoder.new(Bank.bytes(bank), part.offset, part.compression_header_relative, part.compressed_data_relative)
		if VbrDecoder.frame_count(decoder) ~= count or VbrDecoder.channel_count(decoder) ~= layout.bone_count then
			rt.raise(string.format("%s: codec frame/channel count disagrees with bank header", layout.name))
		end
		if layout.sqt_offset < 0 then
			rt.raise("Negative animation part offset")
		end
		local start = layout.sqt_offset
		local end_ = start + layout.bone_count
		local overlap = end_ > bones
		if not overlap then
			for b = start + 1, end_ do
				if assigned[b] then
					overlap = true
				end
			end
		end
		if overlap then
			rt.raise("Overlapping animation parts")
		end
		for b = start + 1, end_ do
			assigned[b] = true
		end
		for f = 0, count - 1 do
			local decoded = VbrDecoder.decode_frame(decoder, f)
			local frame = frames[f + 1]
			for k = 1, layout.bone_count do
				frame[start + k] = decoded[k]
			end
		end
	end
	for _, v in assigned do
		if not v then
			rt.raise("Incomplete animation hierarchy channels")
		end
	end
	for _, frame in frames do
		native.validate_samples(frame, bones)
	end
	return frames
end

local function decode_clip(bank: any, offset: number): any
	local record = Bank.record_at(bank, offset)
	if record == nil then
		rt.raise("Missing clip source record")
	end
	if record.data.kind ~= "Clip" then
		rt.raise("Source record is not a clip")
	end
	local clip = record.data.value
	require_vbr(abin.record_codec(record.header))
	local count = from_bits(clip.frame_count_bits)
	if not is_finite(count) or count < 1.0 or count % 1 ~= 0 then
		rt.raise(string.format("%s: invalid frame count", record.header.name))
	end
	local frames, err = rt.catch(decode_parts, bank, clip.parts, count)
	if err ~= nil then
		rt.raise(string.format("%s: %s", record.header.name, abin.error_to_string(err)))
	end
	local hierarchy = Bank.hierarchy(bank)
	if hierarchy == nil then
		rt.raise("No bank hierarchy")
	end
	local h = hierarchy :: any
	local bones = h.bone_count
	local weights = table.create(bones, to_bits(1.0))
	local channel = abin.clip_channel_animation(clip)
	if channel then
		local reader = Reader.new(Bank.bytes(bank))
		for index, entry in clip.parts do
			local layout = h.parts[index]
			if layout == nil then
				break
			end
			local part = entry.part
			if part == nil then
				rt.raise("Channel animation part is absent")
			end
			local range = part.channel_weights
			if range == nil then
				rt.raise("Channel animation weights are absent")
			end
			for lane = 0, layout.bone_count - 1 do
				local word, werr = rt.catch(Reader.u32, reader, range[1] + lane * 4)
				if werr ~= nil then
					rt.raise(abin.error_to_string(werr))
				end
				if not is_finite(from_bits(word)) then
					rt.raise("Nonfinite channel weight")
				end
				weights[layout.sqt_offset + lane + 1] = word
			end
		end
	end
	return {
		name = record.header.name,
		source_offset = offset,
		fps_bits = clip.fps_bits,
		loop_translation_bits = { clip.loop_translation_words[1], clip.loop_translation_words[2], clip.loop_translation_words[3] },
		loop_rotation_bits = table.clone(clip.loop_rotation_words),
		channel_animation = channel,
		channel_weights = weights,
		frames = frames,
	}
end

local function decode_pose(bank: any, offset: number): any
	local record = Bank.record_at(bank, offset)
	if record == nil then
		rt.raise("Missing pose source record")
	end
	if record.data.kind ~= "Pose" then
		rt.raise("Source record is not a pose")
	end
	require_vbr(abin.record_codec(record.header))
	local frames, err = rt.catch(decode_parts, bank, record.data.value.parts, 1)
	if err ~= nil then
		rt.raise(string.format("%s: %s", record.header.name, abin.error_to_string(err)))
	end
	return { name = record.header.name, source_offset = offset, samples = frames[1] }
end

-- ROBLOX: Result<Self, String> -> NativeFrames или rt.raise(строка).
function NativeFrames.new(banks: any): NativeFrames
	local clips: { [string]: Entry } = {}
	local poses = {}
	local pose_names = {}
	for bank_index0, bank in banks.banks do
		local bank_index = bank_index0 - 1
		poses[bank_index] = poses[bank_index] or {}
		pose_names[bank_index] = pose_names[bank_index] or {}
		for _, record in Bank.records(bank) do
			local name = record.header.name
			local at = record.header.offset
			local kind = record.data.kind
			if kind == "Clip" then
				local existing = clips[name]
				if existing ~= nil and existing.bank ~= bank_index then
					rt.raise(string.format("Ambiguous clip %s in multiple animation banks", name))
				end
				clips[name] = entry_new(bank_index, at)
			elseif kind == "Pose" then
				poses[bank_index][at] = entry_new(bank_index, at)
				pose_names[bank_index][name] = at
			end
		end
	end
	-- ROBLOX: BTreeMap — ключи по порядку; порядок имён восстанавливается сортировкой.
	local order = {}
	for name in clips do
		table.insert(order, name)
	end
	table.sort(order)
	return { banks = table.clone(banks.banks), clips = clips, clip_order = order, poses = poses, pose_names = pose_names }
end

function NativeFrames.clip_count(self: NativeFrames): number
	return #self.clip_order
end

function NativeFrames.clip_names(self: NativeFrames): { string }
	return self.clip_order
end

function NativeFrames.clip_bank(self: NativeFrames, name: string): number
	local e = self.clips[string.upper(name)]
	if e == nil then
		rt.raise(string.format("Missing stock animation clip %s", name))
	end
	return e.bank
end

local function get_or_init(entry: Entry, init: () -> any): any
	if entry.decoded == nil then
		local value, err = rt.catch(init)
		entry.decoded = if err ~= nil then { err = tostring(err) } else { ok = value }
	end
	if entry.decoded.err ~= nil then
		rt.raise(entry.decoded.err)
	end
	return entry.decoded.ok
end

function NativeFrames.clip(self: NativeFrames, name: string): any
	local entry = self.clips[string.upper(name)]
	if entry == nil then
		rt.raise(string.format("Missing stock animation clip %s", name))
	end
	return get_or_init(entry, function()
		return decode_clip(self.banks[entry.bank + 1], entry.offset)
	end)
end

function NativeFrames.reference_pose(self: NativeFrames, bank: number, offset: number): any
	local by_bank = self.poses[bank]
	local found = if by_bank ~= nil then by_bank[offset] else nil
	if found == nil then
		rt.raise(string.format("Missing reference pose %d:0x%x", bank, offset))
	end
	local entry = found :: Entry
	return get_or_init(entry, function()
		return decode_pose(self.banks[bank + 1], entry.offset)
	end)
end

function NativeFrames.named_pose(self: NativeFrames, bank: number, name: string): any
	local by_bank = self.pose_names[bank]
	local at = if by_bank ~= nil then by_bank[string.upper(name)] else nil
	if at == nil then
		rt.raise(string.format("Missing reference pose %s in bank %d", name, bank))
	end
	return NativeFrames.reference_pose(self, bank, at :: number)
end

return native
