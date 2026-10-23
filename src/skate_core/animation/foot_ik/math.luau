--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/math.rs (коммит 2e16697)
--
-- Matrix interpolation used by SkeletonIK, TU3 82BD3150/82BD2E60.
-- The shared Xenon estimate primitives remain host approximations pending
-- hardware comparison; the recovered branch and refinement order is retained.

local rt = require("../../../rt")
local angle_mod = require("../../input/angle")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")
local sar = require("../../physics/skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local atan = angle_mod.atan
local inverse_length_squared = board_motion_output.inverse_length_squared
local dot3 = native_arithmetic.dot3
local reciprocal_estimate = native_arithmetic.reciprocal_estimate
local sin_cos = trigonometry.sin_cos
local IDENTITY = sar.IDENTITY
local copy_transform = sar.copy_transform

type Transform = sar.AnimationPartTransform
export type Vector = { number }

local math_ = {}

function math_.reciprocal(value: number, refinements: number): number
	local inverse = reciprocal_estimate(value)
	for _ = 1, refinements do
		local error_ = mul_add(-inverse, value, 1.0)
		inverse = mul_add(inverse, error_, inverse)
	end
	return inverse
end
local reciprocal = math_.reciprocal

function math_.length(value: Vector): number
	local squared = dot3(value, value)
	local result = f32(squared * inverse_length_squared(squared, 2))
	return if squared == 0.0 then 0.0 else result
end
local length = math_.length

function math_.normalize(value: Vector): Vector
	local inverse = inverse_length_squared(dot3(value, value), 2)
	return { f32(value[1] * inverse), f32(value[2] * inverse), f32(value[3] * inverse), f32(value[4] * inverse) }
end
local normalize = math_.normalize

function math_.cross(left: Vector, right: Vector): Vector
	return {
		mul_add(-left[3], right[2], f32(left[2] * right[3])),
		mul_add(-left[1], right[3], f32(left[3] * right[1])),
		mul_add(-left[2], right[1], f32(left[1] * right[2])),
		mul_add(-left[4], right[4], f32(left[4] * right[4])),
	}
end
local cross = math_.cross

-- ROBLOX: f32::copysign — знак берётся из битов (учитывает -0 и NaN).
local function copysign(magnitude: number, sign: number): number
	local m = math.abs(magnitude)
	return if bit32.band(to_bits(sign), 0x8000_0000) ~= 0 then -m else m
end

-- ///82BD3D90. The very short-vector branch preserves the original fourth lane.
function math_.limit_length(value: Vector, limit: number): Vector
	local magnitude = length(value)
	if not (magnitude >= from_bits(0x3780_0000)) then
		return value
	end
	local capped = if f32(limit - magnitude) >= 0.0 then magnitude else limit
	local inverse = reciprocal(magnitude, 2)
	local out = {}
	for i = 1, 4 do
		out[i] = f32(f32(value[i] * capped) * inverse)
	end
	return out
end

-- ///827B7400 selects the greatest diagonal. Its selected component is squared
-- /// before normalization (e.g. vmulfp at827B7488), unlike a common textbook
-- /// matrix-to-axis conversion. Preserve the native formula and tie ordering.
local function half_turn_axis(rotation: Transform): Vector
	local selected
	if rotation[1][1] > rotation[2][2] then
		selected = if rotation[1][1] > rotation[3][3] then 0 else 2
	elseif rotation[2][2] > rotation[3][3] then
		selected = 1
	else
		selected = 2
	end
	local axis = { 0.0, 0.0, 0.0, 0.0 }
	for lane = 0, 2 do
		if lane == selected then
			local diagonal = f32(1.0 + rotation[selected + 1][selected + 1])
			axis[lane + 1] = f32(diagonal * diagonal)
		else
			axis[lane + 1] = f32(rotation[selected + 1][lane + 1] + rotation[lane + 1][selected + 1])
		end
	end
	axis[4] = axis[1]
	return normalize(axis)
end

-- ///82BD2E60's axis/angle outputs. The unused screw-pivot output is omitted.
-- ROBLOX: кортеж (Vector, f32) -> два возвращаемых значения.
function math_.rotation_axis_angle(rotation: Transform): (Vector, number)
	local skew = {
		f32(rotation[2][3] - rotation[3][2]),
		f32(rotation[3][1] - rotation[1][3]),
		f32(rotation[1][2] - rotation[2][1]),
		0.0,
	}
	local sine_twice = length(skew)
	local cosine_twice = f32(f32(f32(rotation[1][1] + rotation[2][2]) + rotation[3][3]) - 1.0)
	local axis
	if sine_twice > 0.0 then
		local inverse = f32(reciprocal(sine_twice, 2) * 1.0)
		axis = { f32(skew[1] * inverse), f32(skew[2] * inverse), f32(skew[3] * inverse), f32(skew[4] * inverse) }
	else
		axis = { 0.0, 0.0, 0.0, 0.0 }
	end
	local ratio = mul_add(sine_twice, reciprocal(cosine_twice, 1), 0.0)
	local angle = atan(ratio)
	if cosine_twice < 0.0 then
		angle = f32(angle + copysign(from_bits(0x4049_0FDB), sine_twice))
	end
	if cosine_twice == 0.0 then
		angle = copysign(from_bits(0x3FC9_0FDB), sine_twice)
	end
	-- Literal word 820CFC28, loaded with lvlx. Do not replace this with a
	-- conventional numerical tolerance.
	if sine_twice <= from_bits(0x0020_0000) and cosine_twice <= 0.0 then
		axis = half_turn_axis(rotation)
	end
	return axis, angle
end
local rotation_axis_angle = math_.rotation_axis_angle

-- ///Rodrigues construction in82BD34E0..3548. The native permutation duplicates
-- /// each column's X component into W; W is not a fabricated affine zero.
function math_.axis_rotation(axis: Vector, angle: number): Transform
	local sine, cosine = sin_cos(angle)
	local complement = f32(1.0 - cosine)
	local x, y, z = axis[1], axis[2], axis[3]
	local sx = f32(sine * x)
	local sy = f32(sine * y)
	local sz = f32(sine * z)
	local tx = f32(complement * x)
	local ty = f32(complement * y)
	local tz = f32(complement * z)
	local xx = mul_add(tx, x, cosine)
	local yy = mul_add(ty, y, cosine)
	local zz = mul_add(tz, z, cosine)
	local xy_positive = mul_add(tx, y, sz)
	local xy_negative = f32(f32(ty * x) - sz)
	local xz_positive = mul_add(tz, x, sy)
	local xz_negative = f32(f32(tx * z) - sy)
	local yz_positive = mul_add(ty, z, sx)
	local yz_negative = f32(f32(tz * y) - sx)
	return {
		{ xx, xy_positive, xz_negative, xx },
		{ xy_negative, yy, yz_positive, xy_negative },
		{ xz_positive, yz_negative, zz, xz_positive },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
end
local axis_rotation = math_.axis_rotation

-- ///82BD3150 returns the remaining rotation angle as well as the blended frame.
-- ROBLOX: кортеж (Transform, f32) -> два возвращаемых значения.
function math_.interpolate(a: Transform, b: Transform, weight: number): (Transform, number)
	if weight >= 1.0 then
		return copy_transform(b), 0.0
	end
	local relative = IDENTITY()
	for column = 1, 3 do
		local c = {}
		for lane = 1, 4 do
			local x = f32(a[1][column] * b[1][lane])
			local y = mul_add(a[2][column], b[2][lane], x)
			c[lane] = mul_add(a[3][column], b[3][lane], y)
		end
		relative[column] = c
	end
	local axis, angle = rotation_axis_angle(relative)
	if weight <= 0.0 then
		return copy_transform(a), angle
	end
	local output = IDENTITY()
	if angle < from_bits(0x3D0E_FA35) then
		for column = 1, 3 do
			local c = {}
			for lane = 1, 4 do
				c[lane] = mul_add(f32(b[column][lane] - a[column][lane]), weight, a[column][lane])
			end
			output[column] = normalize(c)
		end
	else
		local rotation = axis_rotation(axis, f32(angle * weight))
		for column = 1, 3 do
			local c = {}
			for lane = 1, 4 do
				local x = f32(a[column][1] * rotation[1][lane])
				local y = mul_add(a[column][2], rotation[2][lane], x)
				c[lane] = mul_add(a[column][3], rotation[3][lane], y)
			end
			output[column] = c
		end
	end
	local t = {}
	for lane = 1, 4 do
		t[lane] = mul_add(f32(b[4][lane] - a[4][lane]), weight, a[4][lane])
	end
	output[4] = t
	return output, f32(angle - f32(angle * weight))
end
local interpolate = math_.interpolate

-- ///82E0A570 overrides the interpolation helper's translation, including at
-- /// endpoint weights. Preserve its weighted-sum rounding instead of delta lerp.
function math_.interpolate_affine(a: Transform, b: Transform, weight: number): Transform
	local translation = {}
	for lane = 1, 4 do
		translation[lane] = mul_add(a[4][lane], f32(1.0 - weight), f32(b[4][lane] * weight))
	end
	local output = interpolate(a, b, weight)
	output[4] = translation
	return output
end

-- /// General inverse expanded at8296FB50..FD14 and SkeletonData Init82BD6E9C.
-- /// The transpose permutation retains the second cofactor in the fourth lane.
function math_.inverse_affine(frame: Transform): Transform
	local cofactors = {
		cross(frame[2], frame[3]),
		cross(frame[3], frame[1]),
		cross(frame[1], frame[2]),
	}
	local inverse = reciprocal(dot3(frame[1], cofactors[1]), 2)
	local result: Transform = {}
	for column = 1, 3 do
		result[column] = {
			f32(cofactors[1][column] * inverse),
			f32(cofactors[2][column] * inverse),
			f32(cofactors[3][column] * inverse),
			f32(cofactors[2][column] * inverse),
		}
	end
	local t = frame[4]
	local negative = {}
	for i = 1, 4 do
		negative[i] = from_bits(bit32.bxor(to_bits(t[i]), 0x8000_0000))
	end
	local out = {}
	for lane = 1, 4 do
		local x = f32(negative[1] * result[1][lane])
		local y = mul_add(negative[2], result[2][lane], x)
		out[lane] = mul_add(negative[3], result[3][lane], y)
	end
	result[4] = out
	return result
end

return math_
