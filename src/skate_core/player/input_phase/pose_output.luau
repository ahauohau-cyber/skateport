--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/pose_output.rs (коммит 2e16697)
--
-- Completed pose observations; original PhysOut template constructors.
-- ROBLOX: RawMatrix ([[u32; 4]; 4]) -> таблица из 4 строк по 4 слова;
-- [f32; 4] -> таблица из 4 чисел (индексы с 1).

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local board_motion_output = require("../../physics/board_motion_output")
local angle_mod = require("../../input/angle")
local orientation = require("../wipeout_state/orientation")

local f32 = rt.f32
local dot3 = native_arithmetic.dot3

local pose_output = {}

export type RawMatrix = { { number } }

-- Skeleton reset82DE3A28 explicitly clears these scalars and flags.
export type SkeletonOutputFields = {
	hips_right_angle_496: number,
	hips_up_angle_500: number,
	-- Skeleton Fill82BE2268: signed physical twist, before animation mirroring.
	twist_504: number,
	-- Skeleton Fill82BE1C84/82BE1D50: animation deck forward, stance-adjusted.
	deck_yaw_536: number,
	deck_pitch_540: number,
	scalar_544: number,
	no_support_time_548: number,
	time_until_teleport_576: number,
	response_strength_580: number,
	extra_weight_584: number,
	response_change_588: number,
	flag_597: number,
	over_599: number,
	flag_600: number,
	flag_601: number,
	teleport_pending_604: number,
	response_changed_605: number,
	anim_to_world_11920: RawMatrix,
}

local SkeletonOutputFields = {}
pose_output.SkeletonOutputFields = SkeletonOutputFields

-- ROBLOX: #[derive(Default)] -> конструктор с нулями.
function SkeletonOutputFields.default(): SkeletonOutputFields
	return {
		hips_right_angle_496 = 0,
		hips_up_angle_500 = 0,
		twist_504 = 0,
		deck_yaw_536 = 0,
		deck_pitch_540 = 0,
		scalar_544 = 0,
		no_support_time_548 = 0,
		time_until_teleport_576 = 0,
		response_strength_580 = 0,
		extra_weight_584 = 0,
		response_change_588 = 0,
		flag_597 = 0,
		over_599 = 0,
		flag_600 = 0,
		flag_601 = 0,
		teleport_pending_604 = 0,
		response_changed_605 = 0,
		anim_to_world_11920 = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } },
	}
end

-- Fill82BE1AE8: Skeleton6512 is animation-record pose0's forward column.
-- Packet10368 flips that vector; pitch is its dot with world up, not asin.
function SkeletonOutputFields.publish_deck_angles(self: SkeletonOutputFields, forward_in: { number }, board_flipped: boolean)
	local forward = if board_flipped then { -forward_in[1], -forward_in[2], -forward_in[3], -forward_in[4] } else forward_in
	local x, z = forward[1], forward[3]
	local reciprocal = native_arithmetic.reciprocal_estimate(z)
	local refined = rt.mul_add(reciprocal, rt.mul_add(-reciprocal, z, 1.0), reciprocal)
	local basic = angle_mod.atan(rt.mul_add(x, refined, 0.0))
	local sign = bit32.band(rt.to_bits(x), 0x80000000)
	local pi = rt.from_bits(bit32.bor(0x40490fdb, sign))
	local half_pi = rt.from_bits(bit32.bor(0x3fc90fdb, sign))
	local angle = if 0.0 > z then f32(pi + basic) else basic
	-- Native equality selection includes +/-zero, even when x is also zero.
	self.deck_yaw_536 = if z == 0.0 then half_pi else angle
	self.deck_pitch_540 = dot3(forward, { 0.0, 1.0, 0.0, 0.0 })
end

-- Skeleton Fill82BE2148..2268. Read the completed physical record, the
-- current input toolkit's Processed352 and Reckoning1152. No pose fitting
-- or animation mirror: GrindControlFade applies that mirror once on Begin.
-- ROBLOX: record — SkeletonPhysicalRecord (используется только record.pose).
function SkeletonOutputFields.publish_twist(
	self: SkeletonOutputFields,
	record: any,
	processed_forward_352: { number },
	reckoning_up_1152: { number }
)
	-- SkeletonState at6464, physical pose at+1552: translations of
	-- parts10/6 are Skeleton8704/8448, respectively.
	-- ROBLOX: pose[10][3] -> pose[11][4] (индексы с 1).
	local a, b = record.pose[11][4], record.pose[7][4]
	local across = { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
	local squared = dot3(across, across)
	local inverse = board_motion_output.inverse_length_squared(squared, 2)
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	-- Original830BD350 is a zero vector. Preserve the ordered comparison,
	-- including the zero/NaN path selecting the zero direction.
	local direction = if length > 0.0
		then { f32(across[1] * inverse), f32(across[2] * inverse), f32(across[3] * inverse), f32(across[4] * inverse) }
		else { 0.0, 0.0, 0.0, 0.0 }
	local angle = orientation.projected_angle(processed_forward_352, direction, reckoning_up_1152)
	-- Original82139A60/50; wrap via fractional turns, not angle modulo pi.
	local turns = f32(angle * rt.from_bits(0x3E22F983))
	local fraction = f32(turns - math.floor(turns))
	self.twist_504 = f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * rt.from_bits(0x40C90FDB))
end

export type AnimationOutputFields = {
	collision_time_144: number,
	profile_148: number,
	tricks_blocked_on_stairs_166: number,
	-- Ground Fill82D3A4F0 -> PhysicsWantsManualExit82BA7988.
	manual_opposition_168: number,
}

local AnimationOutputFields = {}
pose_output.AnimationOutputFields = AnimationOutputFields

function AnimationOutputFields.default(): AnimationOutputFields
	-- Animation82DE3F38 stores FLT_MAX at144 and zero at148.
	-- ROBLOX: f32::MAX -> rt.from_bits(0x7f7fffff).
	return {
		collision_time_144 = rt.from_bits(0x7f7fffff),
		profile_148 = 0,
		tricks_blocked_on_stairs_166 = 0,
		manual_opposition_168 = 0,
	}
end

-- Scoring2 reset82DE4468 clears the conditioner capability mask at204.
export type ScoringOutputFields = {
	capabilities_204: number,
}

local ScoringOutputFields = {}
pose_output.ScoringOutputFields = ScoringOutputFields

function ScoringOutputFields.default(): ScoringOutputFields
	return { capabilities_204 = 0 }
end

return pose_output
