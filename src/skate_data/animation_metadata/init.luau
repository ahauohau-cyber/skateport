--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_metadata.rs (коммит 2e16697)
--
-- Runtime clip metadata read directly from the stock Andale bank.
-- Clock/attribute evaluation belongs to core/game; this loader preserves bits
-- and record order and rejects malformed or ambiguous source data.
-- ROBLOX: BTreeMap<String, Vec<T>> -> таблица имя -> массив; Result<_, String>
-- -> значение или rt.raise(строка); serde_json -> json.luau.

local rt = require("../rt")
local files = require("./files")
local json = require("./json")
local blend_space = require("@self/blend_space")
local selection_space = require("@self/selection_space")
local native = require("@self/native")

local from_bits = rt.from_bits
local is_finite = rt.is_finite

local animation_metadata = {}

export type BlendSpaceMetadata = blend_space.BlendSpaceMetadata
export type BlendSimplexMetadata = blend_space.BlendSimplexMetadata
export type SelectionCandidateMetadata = selection_space.SelectionCandidateMetadata
export type SelectionParameterMetadata = selection_space.SelectionParameterMetadata
export type SelectionSpaceMetadata = selection_space.SelectionSpaceMetadata

-- /// Bank-relative record offsets are meaningful only with this source identity.
export type BankSource = {
	source_bank: string,
	source_sha256: string,
	source_bytes: number,
}

export type ClipAttribute = {
	name: string,
	type_id: number,
	begin_bits: number,
	end_bits: number,
	-- Raw aligned payload, including opaque curve data and padding. Consumers
	-- select the lanes written by Attribute::Init for this type.
	payload_words: { number },
	source_offset: number,
}

export type ClipMetadata = {
	name: string,
	source_offset: number,
	fps_bits: number,
	frames_bits: number,
	base_speed_bits: number,
	flags_word: number,
	attributes: { ClipAttribute },
}

export type PhaseBlendMetadata = {
	name: string,
	source_offset: number,
	parameter: string,
	children: { string },
}

export type SelectorMetadata = {
	name: string,
	source_offset: number,
	parameter: string,
	default: string,
	children: { string },
	values: { string },
}

-- ROBLOX: enum TreeMetadata<'a> -> { kind = "Clip" | "BlendSpace" | "PhaseBlend" | "Selector" | "SelectionSpace", value }.
export type TreeMetadata = { kind: string, value: any }

-- ROBLOX: приватные поля структуры хранятся в той же таблице.
export type AnimationMetadata = {
	source_bank: string,
	source_sha256: string,
	clips: { [string]: { ClipMetadata } },
	phase_blends: { [string]: { PhaseBlendMetadata } },
	blend_spaces: { [string]: { BlendSpaceMetadata } },
	selectors: { [string]: { SelectorMetadata } },
	selection_spaces: { [string]: { SelectionSpaceMetadata } },
	unsupported: { [string]: { { number } } },
	sources: { BankSource },
	-- ROBLOX: индекс источника с нуля.
	origins: { [string]: number },
}

local AnimationMetadata = {}
animation_metadata.AnimationMetadata = AnimationMetadata

local function validate_name(name: string, length: number)
	if name == "" or #name > length or string.find(name, "[^A-Z0-9_]") then
		-- ROBLOX: {name:?} -> строка в кавычках.
		rt.raise(string.format("Invalid canonical FastString name %q", name))
	end
end
animation_metadata.validate_name = validate_name
-- ROBLOX: `use super::validate_name` в подмодулях.
blend_space.validate_name = validate_name
selection_space.validate_name = validate_name

local function entry<T>(map: { [string]: { T } }, key: string): { T }
	local list = map[key]
	if list == nil then
		list = {}
		map[key] = list
	end
	return list :: { T }
end

local function is_hex(s: string): boolean
	return string.find(s, "^[0-9a-fA-F]*$") ~= nil
end

local function from_file(file: any): AnimationMetadata
	if file.version ~= 1 then
		rt.raise(string.format("Unsupported animation metadata version %d", file.version))
	end
	if file.source_bank == "" or #file.source_sha256 ~= 64 or not is_hex(file.source_sha256) or file.source_bytes < 48 then
		rt.raise("Invalid animation bank source identity")
	end
	local clips = {}
	for _, clip in file.clips do
		validate_name(clip.name, 36)
		local fps = from_bits(clip.fps_bits)
		local frames = from_bits(clip.frames_bits)
		local base = from_bits(clip.base_speed_bits)
		if not is_finite(fps) or fps <= 0.0 or not is_finite(frames) or frames < 1.0 or not is_finite(base) or base <= 0.0 or clip.source_offset >= file.source_bytes then
			rt.raise(string.format("%s: invalid clip header", clip.name))
		end
		local previous = clip.source_offset
		for _, attribute in clip.attributes do
			validate_name(attribute.name, 30)
			if not is_finite(from_bits(attribute.begin_bits)) or not is_finite(from_bits(attribute.end_bits)) or attribute.source_offset <= previous or attribute.source_offset >= file.source_bytes then
				rt.raise(string.format("%s: invalid attribute record/order", clip.name))
			end
			local t = attribute.type_id
			local minimum = if t == 0 then 1 elseif t == 1 then 4 elseif t == 3 then 6 else 0
			if #attribute.payload_words < minimum then
				rt.raise(string.format("%s: truncated %s payload", clip.name, attribute.name))
			end
			previous = attribute.source_offset
		end
		table.insert(entry(clips, clip.name), clip)
	end
	local phase_blends = {}
	for _, tree in file.phase_blends do
		validate_name(tree.name, 36)
		validate_name(tree.parameter, 30)
		if #tree.children < 2 then
			rt.raise(string.format("%s: PhaseBlend needs two children", tree.name))
		end
		if tree.source_offset >= file.source_bytes then
			rt.raise(string.format("%s: tree offset outside bank", tree.name))
		end
		for _, child in tree.children do
			validate_name(child, 36)
		end
		table.insert(entry(phase_blends, tree.name), tree)
	end
	local blend_spaces = {}
	for _, tree in file.blend_spaces do
		blend_space.validate(tree, file.source_bytes)
		table.insert(entry(blend_spaces, tree.name), tree)
	end
	local selectors = {}
	for _, tree in file.selectors do
		validate_name(tree.name, 36)
		validate_name(tree.parameter, 30)
		validate_name(tree.default, 36)
		if #tree.children ~= #tree.values then
			rt.raise(string.format("%s: selector key/child count mismatch", tree.name))
		end
		if tree.source_offset >= file.source_bytes then
			rt.raise(string.format("%s: tree offset outside bank", tree.name))
		end
		for _, child in tree.children do
			validate_name(child, 36)
		end
		for _, value in tree.values do
			validate_name(value, 30)
		end
		table.insert(entry(selectors, tree.name), tree)
	end
	local selection_spaces = {}
	for _, tree in file.selection_spaces do
		selection_space.validate(tree, file.source_bytes)
		table.insert(entry(selection_spaces, tree.name), tree)
	end
	local unsupported = {}
	for _, tree in file.unsupported_trees do
		validate_name(tree.name, 36)
		if tree.source_offset >= file.source_bytes then
			rt.raise(string.format("%s: tree offset outside bank", tree.name))
		end
		table.insert(entry(unsupported, tree.name), { tree.source_offset, tree.type_id })
	end
	local origins = {}
	for _, map in { clips, phase_blends, blend_spaces, selectors, selection_spaces, unsupported } :: { any } do
		for name in map do
			origins[name] = 0
		end
	end
	local sources = { { source_bank = file.source_bank, source_sha256 = file.source_sha256, source_bytes = file.source_bytes } }
	return {
		source_bank = file.source_bank,
		source_sha256 = file.source_sha256,
		clips = clips,
		phase_blends = phase_blends,
		blend_spaces = blend_spaces,
		selectors = selectors,
		selection_spaces = selection_spaces,
		unsupported = unsupported,
		sources = sources,
		origins = origins,
	}
end

-- ROBLOX: serde_json::from_str::<File> -> json.decode + проверка полей
-- (deny_unknown_fields; поля с #[serde(default)] необязательны).
local function parse_file(text: string): any
	local f = json.decode(text)
	local function fields(object: any, required: { string }, optional: { string }, what: string)
		if type(object) ~= "table" then
			rt.raise(what .. ": expected struct")
		end
		local allowed = {}
		for _, k in required do
			allowed[k] = true
			if object[k] == nil then
				rt.raise(string.format("missing field `%s`", k))
			end
		end
		for _, k in optional do
			allowed[k] = true
		end
		for k in object do
			if not allowed[k] then
				rt.raise(string.format("unknown field `%s`", tostring(k)))
			end
		end
	end
	fields(f, { "version", "source_bank", "source_sha256", "source_bytes", "clips", "unsupported_trees" }, { "phase_blends", "blend_spaces", "selectors", "selection_spaces" }, "File")
	for _, k in { "phase_blends", "blend_spaces", "selectors", "selection_spaces" } do
		if f[k] == nil then
			f[k] = {}
		end
	end
	for _, c in f.clips do
		fields(c, { "name", "source_offset", "fps_bits", "frames_bits", "base_speed_bits", "flags_word", "attributes" }, {}, "ClipMetadata")
		for _, a in c.attributes do
			fields(a, { "name", "type_id", "begin_bits", "end_bits", "payload_words", "source_offset" }, {}, "ClipAttribute")
		end
	end
	for _, t in f.phase_blends do
		fields(t, { "name", "source_offset", "parameter", "children" }, {}, "PhaseBlendMetadata")
	end
	for _, t in f.blend_spaces do
		fields(t, { "name", "source_offset", "parameters", "children", "simplexes" }, {}, "BlendSpaceMetadata")
		for _, s in t.simplexes do
			fields(s, { "children", "vertex_bits", "normal_bits", "scale_bits" }, {}, "BlendSimplexMetadata")
		end
	end
	for _, t in f.selectors do
		fields(t, { "name", "source_offset", "parameter", "default", "children", "values" }, {}, "SelectorMetadata")
	end
	for _, t in f.selection_spaces do
		fields(t, { "name", "source_offset", "parameters", "candidates" }, {}, "SelectionSpaceMetadata")
		for _, p in t.parameters do
			fields(p, { "name", "mode", "weight_bits", "minimum_bits", "maximum_bits" }, {}, "SelectionParameterMetadata")
		end
		for _, c in t.candidates do
			fields(c, { "child", "value_bits" }, {}, "SelectionCandidateMetadata")
		end
	end
	for _, t in f.unsupported_trees do
		fields(t, { "name", "source_offset", "type_id" }, {}, "UnsupportedTree")
	end
	return f
end

function AnimationMetadata.parse(text: string): AnimationMetadata
	local file, err = rt.catch(parse_file, text)
	if err ~= nil then
		rt.raise(tostring(err))
	end
	return from_file(file)
end

-- ROBLOX: path — путь в упакованных файлах (files.luau).
function AnimationMetadata.load(path: string): AnimationMetadata
	local text, err = rt.catch(files.read_string, path)
	if err ~= nil then
		rt.raise(string.format("Cannot read animation metadata %s: %s", path, tostring(err)))
	end
	local result, err2 = rt.catch(AnimationMetadata.parse, text)
	if err2 ~= nil then
		rt.raise(string.format("%s: %s", path, tostring(err2)))
	end
	return result
end

-- /// Read the retained bytes without constructing or evaluating animation
-- /// trees. Caller supplies the independently calculated bank SHA-256.
function AnimationMetadata.from_bank(bank: any, source_bank: string, source_sha256: string): AnimationMetadata
	return from_file(native.read_file(bank, source_bank, source_sha256))
end

local function sorted_keys(map: { [string]: any }): { string }
	local keys = {}
	for k in map do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

-- /// Combine disjoint animation namespaces without comparing offsets from
-- /// different files. Same-bank duplicates still obey native last-record wins.
-- /// All collision checks precede mutation; the primary rig identity remains.
function AnimationMetadata.merge(self: AnimationMetadata, other: AnimationMetadata)
	for _, name in sorted_keys(other.origins) do
		if self.origins[name] ~= nil then
			rt.raise(string.format("Animation bank merge collides at %s", name))
		end
	end
	local base = #self.sources
	for name, index in other.origins do
		self.origins[name] = base + index
	end
	for _, s in other.sources do
		table.insert(self.sources, s)
	end
	for _, key in { "clips", "phase_blends", "blend_spaces", "selectors", "selection_spaces", "unsupported" } do
		local dst = (self :: any)[key]
		for name, list in (other :: any)[key] do
			dst[name] = list
		end
	end
end

function AnimationMetadata.sources(self: AnimationMetadata): { BankSource }
	return self.sources
end

function AnimationMetadata.source_for(self: AnimationMetadata, name: string): BankSource?
	local index = self.origins[string.upper(name)]
	if index == nil then
		return nil
	end
	return self.sources[index + 1]
end

-- ROBLOX: Iterator::max_by_key — при равных ключах берётся последний элемент.
local function last_max(list: { any }): any?
	local best = nil
	for _, item in list do
		if best == nil or item.source_offset >= best.source_offset then
			best = item
		end
	end
	return best
end

-- /// The serialized names use FastString's canonical uppercase alphabet.
-- /// The API accepts only that alphabet plus lowercase ASCII, so uppercase
-- /// lookup is equivalent to native FastString encoding for accepted inputs.
function AnimationMetadata.clip(self: AnimationMetadata, name_in: string): ClipMetadata
	local name = string.upper(name_in)
	validate_name(name, 36)
	-- SetDBContent82D1B428..434 updates its separate clip map on every
	-- clip record; repeated keys overwrite with the later bank record.
	local list = self.clips[name]
	local clip = if list ~= nil then last_max(list) else nil
	if clip == nil then
		rt.raise(string.format("Missing direct clip %s", name))
	end
	return clip
end

function AnimationMetadata.tree(self: AnimationMetadata, name_in: string): TreeMetadata
	local name = string.upper(name_in)
	validate_name(name, 36)
	local clips = self.clips[name] or {}
	local trees = self.unsupported[name] or {}
	local phase_blends = self.phase_blends[name] or {}
	local blend_spaces = self.blend_spaces[name] or {}
	local selectors = self.selectors[name] or {}
	local selection_spaces = self.selection_spaces[name] or {}
	-- TU382D1B438..45C inserts into the tree map in file order and writes
	-- the record pointer even when map[]82D27320 finds an existing key.
	local last: number? = nil
	local function consider(offset: number)
		if last == nil or offset > (last :: number) then
			last = offset
		end
	end
	for _, list in { clips, phase_blends, blend_spaces, selectors, selection_spaces } :: { any } do
		for _, t in list do
			consider(t.source_offset)
		end
	end
	for _, t in trees do
		consider(t[1])
	end
	for _, pair in { { "Clip", clips }, { "PhaseBlend", phase_blends }, { "BlendSpace", blend_spaces }, { "Selector", selectors }, { "SelectionSpace", selection_spaces } } :: { any } do
		for _, t in pair[2] do
			if t.source_offset == last then
				return { kind = pair[1], value = t }
			end
		end
	end
	for _, t in trees do
		if t[1] == last then
			rt.raise(string.format("Animation %s is tree type %d; tree evaluation is required", name, t[2] :: number))
		end
	end
	return rt.raise(string.format("Missing animation %s in %s", name, self.source_bank))
end

function AnimationMetadata.clip_count(self: AnimationMetadata): number
	local n = 0
	for _, list in self.clips do
		n += #list
	end
	return n
end

return animation_metadata
