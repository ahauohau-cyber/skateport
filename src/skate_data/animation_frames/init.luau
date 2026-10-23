--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_frames.rs (коммит 2e16697)
--
-- Decoded stock samples. Playback/interpolation and reference composition are
-- separate core operations; this loader never repairs missing bone channels.
-- ROBLOX: Result<_, String> -> значение или rt.raise(строка); serde_json -> json.luau.

local rt = require("../rt")
local files = require("./files")
local json = require("./json")
local animation_metadata = require("./animation_metadata")
local abin = require("./abin")
local native = require("@self/native")

local from_bits = rt.from_bits
local is_finite = rt.is_finite
local AnimationMetadata = animation_metadata.AnimationMetadata
local NativeFrames = native.NativeFrames

local animation_frames = {}

-- /// Scale xyz, quaternion xyzw, translation xyz; each component is an f32 word.
export type SampleWords = { number }

export type ClipFrames = {
	name: string,
	source_offset: number,
	fps_bits: number,
	loop_translation_bits: { number },
	loop_rotation_bits: { number },
	channel_animation: boolean,
	channel_weights: { number },
	frames: { { SampleWords } },
}

export type ReferencePose = {
	name: string,
	source_offset: number,
	samples: { SampleWords },
}

-- ROBLOX: приватные поля структуры хранятся в той же таблице; native — NativeFrames или nil.
export type AnimationFrames = {
	source_sha256: string,
	decoder_sha256: string,
	decoder_hardware_verified: boolean,
	parents: { number },
	bone_names: { string },
	mirror_indices: { number },
	has_trajectory: boolean,
	clips: { [string]: ClipFrames },
	reference_poses: { [number]: ReferencePose },
	native: native.NativeFrames?,
}

local AnimationFrames = {}
animation_frames.AnimationFrames = AnimationFrames

local function validate_samples(samples: { SampleWords }, bones: number)
	local bad = #samples ~= bones
	if not bad then
		for _, sample in samples do
			for _, word in sample do
				if not is_finite(from_bits(word)) then
					bad = true
				end
			end
		end
	end
	if bad then
		rt.raise("Decoded stock frame is incomplete or nonfinite")
	end
end
animation_frames.validate_samples = validate_samples
-- ROBLOX: `use super::validate_samples` в native.
native.validate_samples = validate_samples

function AnimationFrames.from_banks(banks: any): AnimationFrames
	local hierarchy = abin.Bank.hierarchy(banks.banks[1])
	if hierarchy == nil then
		rt.raise("Missing animation hierarchy")
	end
	local h = hierarchy :: any
	return {
		source_sha256 = banks.identities[1],
		decoder_sha256 = "",
		decoder_hardware_verified = false,
		parents = table.clone(h.parents),
		bone_names = table.clone(h.bone_names),
		mirror_indices = table.clone(h.mirrors),
		has_trajectory = h.has_trajectory,
		clips = {},
		reference_poses = {},
		native = NativeFrames.new(banks),
	}
end

local function is_hex(s: string): boolean
	return string.find(s, "^[0-9a-fA-F]*$") ~= nil
end

local function decode_file(text: string): any
	local f = json.decode(text)
	json.expect_fields(f, { "version", "source_sha256", "decoder_sha256", "decoder_hardware_verified", "parents", "bone_names", "mirror_indices", "has_trajectory", "clips", "reference_poses" }, "File")
	for _, c in f.clips do
		json.expect_fields(c, { "name", "source_offset", "fps_bits", "loop_translation_bits", "loop_rotation_bits", "channel_animation", "channel_weights", "frames" }, "ClipFrames")
	end
	for _, p in f.reference_poses do
		json.expect_fields(p, { "name", "source_offset", "samples" }, "ReferencePose")
	end
	return f
end

function AnimationFrames.parse(text: string, metadata: animation_metadata.AnimationMetadata): AnimationFrames
	local file, err = rt.catch(decode_file, text)
	if err ~= nil then
		rt.raise(tostring(err))
	end
	if file.version ~= 3 or file.source_sha256 ~= metadata.source_sha256 then
		rt.raise("Animation sample format or stock bank identity differs from metadata")
	end
	if #file.decoder_sha256 ~= 64 or not is_hex(file.decoder_sha256) then
		rt.raise("Animation sample decoder identity is invalid")
	end
	local bones = #file.parents
	if bones == 0 or bones > 255 then
		rt.raise("Animation sample hierarchy has invalid bone count")
	end
	for index0, parent in file.parents do
		local index = index0 - 1
		if parent < -1 or parent >= index then
			rt.raise(string.format("Animation bone%d has invalid parent%d", index, parent))
		end
	end
	if #file.bone_names ~= bones or #file.mirror_indices ~= bones then
		rt.raise("Animation hierarchy names/mirrors are incomplete")
	end
	local names = {}
	for i0, partner in file.mirror_indices do
		local i = i0 - 1
		local name = file.bone_names[i0]
		local dup = names[name] ~= nil
		names[name] = true
		if name == "" or dup or partner < -1 or partner >= bones or (partner >= 0 and file.mirror_indices[partner + 1] ~= i) then
			rt.raise(string.format("Animation bone%d has an invalid name/mirror mapping", i))
		end
	end
	local clips = {}
	for _, clip in file.clips do
		local source = AnimationMetadata.clip(metadata, clip.name)
		if source.source_offset ~= clip.source_offset or source.fps_bits ~= clip.fps_bits or from_bits(source.frames_bits) ~= rt.f32(#clip.frames) or clip.channel_animation ~= (bit32.band(source.flags_word, bit32.lshift(1, 29)) ~= 0) then
			rt.raise(string.format("%s: decoded samples disagree with stock clip header", clip.name))
		end
		local bad = #clip.channel_weights ~= bones
		for _, list in { clip.channel_weights, clip.loop_translation_bits, clip.loop_rotation_bits } do
			for _, word in list do
				if not is_finite(from_bits(word)) then
					bad = true
				end
			end
		end
		if bad then
			rt.raise(string.format("%s: invalid loop transform or missing channel weights", clip.name))
		end
		for _, frame in clip.frames do
			validate_samples(frame, bones)
		end
		if clips[clip.name] ~= nil then
			rt.raise(string.format("Duplicate decoded clip%s", clip.name))
		end
		clips[clip.name] = clip
	end
	local reference_poses = {}
	for _, pose in file.reference_poses do
		validate_samples(pose.samples, bones)
		local ok = pose.name == "RIG_TPOSE" or pose.name == "BOARD_BACKWARDS" or pose.name == "BOARD_BACKWARDS_IK"
		if not ok or reference_poses[pose.source_offset] ~= nil then
			rt.raise("Invalid or duplicated reference-pose source record")
		end
		reference_poses[pose.source_offset] = pose
	end
	return {
		source_sha256 = file.source_sha256,
		decoder_sha256 = file.decoder_sha256,
		decoder_hardware_verified = file.decoder_hardware_verified,
		parents = file.parents,
		bone_names = file.bone_names,
		mirror_indices = file.mirror_indices,
		has_trajectory = file.has_trajectory,
		clips = clips,
		reference_poses = reference_poses,
		native = nil,
	}
end

-- ROBLOX: path — путь в упакованных файлах (files.luau).
function AnimationFrames.load(path: string, metadata: animation_metadata.AnimationMetadata): AnimationFrames
	local text, err = rt.catch(files.read_string, path)
	if err ~= nil then
		rt.raise(string.format("Cannot read %s: %s", path, tostring(err)))
	end
	local result, err2 = rt.catch(AnimationFrames.parse, text, metadata)
	if err2 ~= nil then
		rt.raise(string.format("%s: %s", path, tostring(err2)))
	end
	return result
end

function AnimationFrames.clip(self: AnimationFrames, name: string): ClipFrames
	if self.native ~= nil then
		return NativeFrames.clip(self.native, name)
	end
	local clip = self.clips[string.upper(name)]
	if clip == nil then
		rt.raise(string.format("Required decoded stock clip is absent: %s", name))
	end
	return clip
end

-- /// Explicit source-record lookup, useful when auditing original bank data.
function AnimationFrames.reference_pose(self: AnimationFrames, source_offset: number): ReferencePose
	if self.native ~= nil then
		return NativeFrames.reference_pose(self.native, 0, source_offset)
	end
	local pose = self.reference_poses[source_offset]
	if pose == nil then
		rt.raise(string.format("Required reference-pose record0x%x is absent", source_offset))
	end
	return pose
end

-- ROBLOX: bank — индекс банка с нуля.
function AnimationFrames.named_pose_in(self: AnimationFrames, bank: number, name: string): ReferencePose
	if self.native ~= nil then
		return NativeFrames.named_pose(self.native, bank, name)
	end
	if bank ~= 0 then
		rt.raise("Converted animation data contains only one bank")
	end
	-- ROBLOX: BTreeMap::values().rev() — по убыванию смещения.
	local offsets: { number } = {}
	for offset in self.reference_poses do
		table.insert(offsets, offset)
	end
	table.sort(offsets, function(a: number, b: number)
		return a > b
	end)
	for _, offset in offsets do
		local pose = self.reference_poses[offset]
		if string.lower(pose.name) == string.lower(name) then
			return pose
		end
	end
	return rt.raise(string.format("Required stock reference pose is absent: %s", name))
end

-- /// SetDBContent82D1B45C assigns into the selected database's name map,
-- /// replacing earlier same-name records in that bank.
function AnimationFrames.named_pose(self: AnimationFrames, name: string): ReferencePose
	return AnimationFrames.named_pose_in(self, 0, name)
end

function AnimationFrames.clip_count(self: AnimationFrames): number
	if self.native ~= nil then
		return NativeFrames.clip_count(self.native)
	end
	local n = 0
	for _ in self.clips do
		n += 1
	end
	return n
end

-- ROBLOX: Box<dyn Iterator<Item=&str>> -> массив имён по возрастанию.
function AnimationFrames.clip_names(self: AnimationFrames): { string }
	if self.native ~= nil then
		return NativeFrames.clip_names(self.native)
	end
	local names = {}
	for name in self.clips do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function AnimationFrames.clip_bank(self: AnimationFrames, name: string): number
	if self.native ~= nil then
		return NativeFrames.clip_bank(self.native, name)
	end
	AnimationFrames.clip(self, name)
	return 0
end

return animation_frames
