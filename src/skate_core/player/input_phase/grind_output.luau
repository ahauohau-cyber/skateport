--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/grind_output.rs (коммит 2e16697)
--
-- Typed Grinds PhysOut block. Offsets identify native producers, not Rust ABI.
-- Reset82DE3518; common Fill82D40EA0; tipslide Fill82D42788;
-- chromosome publication82DEE508; contact conditioner82DF0640.
-- ROBLOX: AttributeName -> таблица из 5 слов; Option -> значение или nil.
-- ROBLOX: u64 -> число Luau (double). u64::MAX не представим точно и
-- хранится как 2^64 (U64_MAX ниже); это только идентичность «нет сплайна».

local name = require("../../animation/skeleton_input/name")

local grind_output = {}

export type RawVector = { number }
export type AttributeName = { number }

export type GrindOutputFields = {
	direction_0: RawVector,
	point_16: RawVector,
	normal_32: RawVector,
	across_48: RawVector,
	primitive_start_64: RawVector,
	primitive_end_80: RawVector,
	camera_target_96: RawVector,
	high_side_112: RawVector,
	impact_speed_128: number,
	crouch_132: number,
	-- Physical family0..5 (not admission kind), then substate.
	words_136_140: { number },
	animation_id_144: number,
	scoring_id_148: number,
	scorable_id_152: number,
	-- Five-word stock FastString representation, not a hash of the display name.
	-- None means the external reset-name template has not been supplied.
	animation_name_156: AttributeName?,
	scoring_name_176: AttributeName?,
	surface_name_196: AttributeName?,
	audio_surface_216: number,
	spline_guids_224_232: { number },
	-- Common physical classification104, consumed by GrindTrickOutTypeAllowed.
	trick_out_240: number,
	-- Approach, location, twist, tilt, orientation, family. No game enum here.
	volatile_chromosome_244: { number },
	-- First component at268 is the graph's filtered approach observation.
	animation_chromosome_268: { number },
	scoring_chromosome_292: { number },
	-- Selector-owned; the camera conditioner must not infer this flag.
	grinding_316: number,
	leaving_317: number,
	flag_318: number,
	flag_319: number,
	is_ledge_320: number,
	curb_321: number,
	flag_322: number,
	flag_323: number,
	dropping_in_324: number,
	tipslide_325: number,
	tipslide_326: number,
}

-- ROBLOX: u64::MAX -> 2^64 (ближайший double).
local U64_MAX = 2 ^ 64
grind_output.U64_MAX = U64_MAX

local GrindOutputFields = {}
grind_output.GrindOutputFields = GrindOutputFields

-- ROBLOX: impl Default for GrindOutputFields.
function GrindOutputFields.default(): GrindOutputFields
	local function x(): RawVector
		return { 0x3f800000, 0, 0, 0 }
	end
	local function y(): RawVector
		return { 0, 0x3f800000, 0, 0 }
	end
	local function empty(): { number }
		return { 0, 0, 0, 0, 0, 0xffffffff }
	end
	return {
		direction_0 = x(),
		point_16 = { 0, 0, 0, 0 },
		normal_32 = y(),
		across_48 = y(),
		primitive_start_64 = { 0, 0, 0, 0 },
		primitive_end_80 = { 0, 0, 0, 0 },
		camera_target_96 = { 0, 0, 0, 0 },
		high_side_112 = { 0, 0, 0, 0 },
		impact_speed_128 = 0,
		crouch_132 = 0,
		words_136_140 = { 0xffffffff, 0 },
		animation_id_144 = 0,
		scoring_id_148 = 0,
		scorable_id_152 = 0xffffffff,
		-- 82F8AF08 initializes template830C0D60 from empty string82060799.
		animation_name_156 = name.encode(""),
		scoring_name_176 = name.encode(""),
		surface_name_196 = nil,
		audio_surface_216 = 0,
		spline_guids_224_232 = { U64_MAX, U64_MAX },
		trick_out_240 = 0,
		volatile_chromosome_244 = empty(),
		animation_chromosome_268 = empty(),
		scoring_chromosome_292 = empty(),
		grinding_316 = 0,
		leaving_317 = 0,
		flag_318 = 0,
		flag_319 = 0,
		is_ledge_320 = 0,
		curb_321 = 0,
		flag_322 = 0,
		flag_323 = 0,
		dropping_in_324 = 0,
		tipslide_325 = 0,
		tipslide_326 = 0,
	}
end

-- The native reset copies two external FastString templates; it does not
-- construct a grind name from family0. Supply decoded original templates.
-- Keeping these optional distinguishes an unavailable template from zeros.
function GrindOutputFields.reset_names(self: GrindOutputFields, grind: AttributeName?, surface: AttributeName?)
	-- ROBLOX: AttributeName — Copy; копируем таблицу, чтобы поля не делили её.
	self.animation_name_156 = if grind then table.clone(grind) else nil
	self.scoring_name_176 = if grind then table.clone(grind) else nil
	self.surface_name_196 = if surface then table.clone(surface) else nil
end

return grind_output
