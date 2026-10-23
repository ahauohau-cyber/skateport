--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_output/board.rs (коммит 2e16697)
--
-- Board portion of original TU3 physical pose worker82DB993C..A55C.

local rt = require("../../../rt")
local board_motion_output = require("../board_motion_output")
local native_arithmetic = require("../native_arithmetic")
local sar = require("../skeleton_animation_record")
local collision_response = require("../../riding/collision_response")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = board_motion_output.inverse_length_squared
local dot3 = native_arithmetic.dot3
local compose_affine = sar.compose_affine
local signed_angle = collision_response.signed_angle
local sin_cos = trigonometry.sin_cos

type Transform = sar.AnimationPartTransform
type F4 = { number }

local board = {}

export type Settings = {
	truck_tilt_scalar: number,
	truck_tilt_max_angle: number,
	truck_tilt_wobble_scalar: number,
	truck_displacement_max: number,
}

-- ROBLOX: индексы костей с нуля.
export type BoneIndices = {
	front_truck: number,
	back_truck: number,
	front_left_wheel: number,
	front_right_wheel: number,
	back_left_wheel: number,
	back_right_wheel: number,
}

local BoneIndices = {}
board.BoneIndices = BoneIndices

function BoneIndices.all(self: BoneIndices): { number }
	return { self.front_truck, self.back_truck, self.front_left_wheel, self.front_right_wheel, self.back_left_wheel, self.back_right_wheel }
end

export type Input = {
	-- Raw dynamic-body matrices82585B58, native parts0..5; not82585CB0.
	bodies: { Transform },
	-- SkeletonPhysicalRecord.part0, captured separately by82DB670C.
	skeleton_board: Transform,
	-- SkateboardBody7840/7904, not7712/7776 steering-drive base frames.
	truck_frames: { Transform },
	deck_wobble_tilt: number,
	deck_wobble_squish: number,
	-- CalculateAverageWheelCompressions82C08968, front8372/back8376.
	average_compression: { number },
}

local function angle(a: F4, b: F4, axis: F4): number
	local function v(x: F4): vector
		return vector.create(x[1], x[2], x[3])
	end
	return signed_angle(v(a), v(b), v(axis))
end

local function inverse_direction(frame: Transform, value: F4): F4
	local output = { 0.0, 0.0, 0.0, 0.0 }
	for lane = 1, 3 do
		local x = f32(value[1] * frame[lane][1])
		local y = mul_add(value[2], frame[lane][2], x)
		output[lane] = mul_add(value[3], frame[lane][3], y)
	end
	return output
end

local function normalize_safe(value: F4): F4
	local squared = dot3(value, value)
	local inverse = inverse_length_squared(squared, 2)
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	if length > from_bits(0x3586_37BD) then
		return { f32(value[1] * inverse), f32(value[2] * inverse), f32(value[3] * inverse), f32(value[4] * inverse) }
	end
	return { 0.0, 0.0, 0.0, 0.0 }
end

local function subtract(a: F4, b: F4): F4
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

local function wrap(a: number): number
	local turns = f32(a * from_bits(0x3E22_F983))
	local fraction = f32(turns - math.floor(turns))
	return f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * from_bits(0x40C9_0FDB))
end

local function clamp(value: number, minimum: number, maximum: number): number
	local low = if f32(minimum - value) >= 0.0 then minimum else value
	return if f32(maximum - low) >= 0.0 then low else maximum
end

local function rotation_x(a: number): Transform
	local sine, cosine = sin_cos(a)
	--vperm822FB890 replicates X in W; vrlimi2 replaces only Z.
	return {
		{ 1.0, 0.0, 0.0, 1.0 },
		{ 0.0, cosine, sine, 0.0 },
		{ 0.0, -sine, cosine, 0.0 },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
end

-- ROBLOX: locals — `&mut [Transform]` (индекс кости с нуля -> [bone + 1]).
function board.publish(input: Input, settings: Settings, bones: BoneIndices, locals: { Transform })
	local y = { 0.0, 1.0, 0.0, 0.0 }
	local z = { 0.0, 0.0, 1.0, 0.0 }
	local wheels = {}
	for wheel = 0, 3 do
		local up = inverse_direction(input.bodies[4 + wheel // 2 + 1], input.bodies[wheel + 1][2])
		wheels[wheel + 1] = rotation_x(angle(up, y, z))
	end
	--82DB9C60/9E00 choose opposite axle directions at the two ends.
	local front = inverse_direction(input.skeleton_board, normalize_safe(subtract(input.bodies[1][4], input.bodies[2][4])))
	local back = inverse_direction(input.skeleton_board, normalize_safe(subtract(input.bodies[4][4], input.bodies[3][4])))
	if 0.5 > dot3(front, front) then
		front = table.clone(input.truck_frames[1][3])
	end
	if 0.5 > dot3(back, back) then
		local c = input.truck_frames[2][3]
		back = { -c[1], -c[2], -c[3], -c[4] }
	end
	local negative_x = { -1.0, -0.0, -0.0, -0.0 }
	local back_angle = wrap(angle(back, negative_x, input.truck_frames[2][1]))
	local front_angle = wrap(angle(front, negative_x, input.truck_frames[1][1]))
	local wobble = f32(input.deck_wobble_tilt * settings.truck_tilt_wobble_scalar)
	local back_tilt = clamp(mul_add(-settings.truck_tilt_scalar, back_angle, -wobble), -settings.truck_tilt_max_angle, settings.truck_tilt_max_angle)
	local front_tilt = clamp(mul_add(-settings.truck_tilt_scalar, front_angle, wobble), -settings.truck_tilt_max_angle, settings.truck_tilt_max_angle)
	for _, entry in { { 0, bones.front_truck, front_tilt }, { 1, bones.back_truck, back_tilt } } do
		local side, bone, tilt = entry[1], entry[2], entry[3]
		local compression = if input.average_compression[side + 1] < from_bits(0x3A83_126F) then 0.0 else input.average_compression[side + 1]
		local displacement = clamp(f32(compression - input.deck_wobble_squish), 0.0, settings.truck_displacement_max)
		local rotated = compose_affine(locals[bone + 1], rotation_x(tilt))
		--82DBA130..A318 left-multiplies the rotated local by translation.
		local translation = {
			{ 1.0, 0.0, 0.0, 0.0 },
			{ 0.0, 1.0, 0.0, 0.0 },
			{ 0.0, 0.0, 1.0, 0.0 },
			{ 0.0, displacement, 0.0, 0.0 },
		}
		locals[bone + 1] = compose_affine(translation, rotated)
	end
	--Native physical-body order and animation-name order differ.
	for wheel, bone in { bones.front_left_wheel, bones.front_right_wheel, bones.back_left_wheel, bones.back_right_wheel } do
		locals[bone + 1] = compose_affine(locals[bone + 1], wheels[wheel])
	end
end

return board
