--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/two_bone.rs (коммит 2e16697)
--
-- Math::_TwoBoneIKSolve8296F8C0, TU3 complete reachable/recursive/invalid path.
-- Plane construction uses the native general inverse, not a rigid transpose.

local rt = require("../../../rt")
local m = require("./math")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")
local sar = require("../../physics/skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local cross, inverse_affine, length, normalize, reciprocal = m.cross, m.inverse_affine, m.length, m.normalize, m.reciprocal
local dot3, vector_max, vector_min = native_arithmetic.dot3, native_arithmetic.vector_max, native_arithmetic.vector_min
local transform_point = sar.transform_point
local acos, cos, sin_cos = trigonometry.acos, trigonometry.cos, trigonometry.sin_cos

type Vector = m.Vector
type Transform = sar.AnimationPartTransform

local two_bone = {}

-- ROBLOX: enum SolveResult -> строки.
export type SolveResult = "Solved" | "Extended" | "Invalid"

export type AngleLimits = {
	minimum_degrees: number,
	maximum_degrees: number,
}

local EPSILON = from_bits(0x3A03_126F) --830BD4B0 <-821A0318
local TO_DEGREES = from_bits(0x4265_2EE1) --830BD390
local TO_RADIANS = from_bits(0x3C8E_FA35) --830BD360

-- ///The source uses830BD310=0 and830BD430=1 for these clamps. The lower
-- ///constant is not minus one; its initializer82F82718 loads82165A10.
local function clamp_native_cosine(value: number): number
	return vector_min(1.0, vector_max(0.0, value))
end

local function square_root(squared: number): number
	local inverse = board_motion_output.inverse_length_squared(squared, 2)
	local value = f32(squared * inverse)
	return if squared == 0.0 then 0.0 else value
end

local function subtract(a: Vector, b: Vector): Vector
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

local function scaled_add(a: Vector, scale: number, b: Vector): Vector
	return { mul_add(a[1], scale, b[1]), mul_add(a[2], scale, b[2]), mul_add(a[3], scale, b[3]), mul_add(a[4], scale, b[4]) }
end

local function candidate(delta: Vector, angle: number, upper_length: number, root: Vector, basis: Transform): Vector
	local sine, cosine = sin_cos(angle)
	local rotation = {
		{ cosine, sine, 0.0, cosine },
		{ -sine, cosine, 0.0, -sine },
		{ 0.0, 0.0, 1.0, 0.0 },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
	local rotated = normalize(transform_point(rotation, delta))
	return transform_point(basis, scaled_add(rotated, upper_length, root))
end

-- ROBLOX: solved_middle и target — `&mut Vector` -> ячейки { value }.
function two_bone.solve(root: Vector, middle: Vector, end_: Vector, solved_middle: { value: Vector }, target: { value: Vector }, limits: AngleLimits, override_maximum_with_original: boolean, recursion_budget: number): SolveResult
	if recursion_budget == 0 then
		target.value = table.clone(end_)
		solved_middle.value = table.clone(middle)
		return "Invalid"
	end
	local upper = subtract(middle, root)
	local lower = subtract(end_, middle)
	local upper_length = length(upper)
	local lower_length = length(lower)
	if EPSILON > upper_length or EPSILON > lower_length then
		solved_middle.value = table.clone(middle)
		return "Invalid"
	end
	local requested_delta = subtract(target.value, root)
	local forward = normalize(subtract(end_, root))
	local normal = normalize(cross(upper, lower))
	local original_basis = { forward, cross(forward, normal), normal, root }
	local target_forward = normalize(requested_delta)
	local target_lateral = cross(target_forward, normal)
	local target_normal = cross(target_lateral, target_forward)
	local target_basis = { target_forward, target_lateral, target_normal, root }
	local original_inverse = inverse_affine(original_basis)
	local target_inverse = inverse_affine(target_basis)
	-- Each point is transformed separately, retaining the original origin's
	-- rounding; do not replace these with pre-subtracted vectors.
	local local_root = transform_point(original_inverse, root)
	local local_middle = transform_point(original_inverse, middle)
	local local_end = transform_point(original_inverse, end_)
	local local_target = transform_point(target_inverse, target.value)
	local target_delta = subtract(local_target, local_root)
	local planar_squared = mul_add(target_delta[1], target_delta[1], f32(target_delta[2] * target_delta[2]))
	local distance = square_root(planar_squared)
	local upper_squared = f32(upper_length * upper_length)
	local lower_squared = f32(lower_length * lower_length)
	local twice_upper = f32(2.0 * upper_length)
	local twice_product = f32(twice_upper * lower_length)
	local sum_squared = f32(upper_squared + lower_squared)
	local negative_lower = {}
	for i = 1, 4 do
		negative_lower[i] = from_bits(bit32.bxor(to_bits(lower[i]), 0x8000_0000))
	end
	local negative_length = from_bits(bit32.bxor(to_bits(lower_length), 0x8000_0000))
	local original_angle = f32(acos(f32(reciprocal(f32(upper_length * negative_length), 2) * dot3(upper, negative_lower))) * TO_DEGREES)
	local maximum = limits.maximum_degrees
	if original_angle > maximum and override_maximum_with_original then
		maximum = original_angle
	end
	local minimum_distance = square_root(f32(sum_squared - f32(twice_product * cos(f32(limits.minimum_degrees * TO_RADIANS)))))
	local maximum_distance = square_root(f32(sum_squared - f32(twice_product * cos(f32(maximum * TO_RADIANS)))))
	if minimum_distance > distance or distance > maximum_distance then
		if distance > f32(upper_length + lower_length) and maximum == 180.0 then
			local direction = normalize(target_delta)
			local middle_local = scaled_add(direction, upper_length, local_root)
			local end_local = scaled_add(direction, lower_length, middle_local)
			solved_middle.value = transform_point(target_basis, middle_local)
			target.value = transform_point(target_basis, end_local)
			return "Extended"
		end
		local d = if distance > maximum_distance then f32(maximum_distance - EPSILON) else f32(minimum_distance + EPSILON)
		target.value = scaled_add(normalize(requested_delta), d, root)
		return two_bone.solve(root, middle, end_, solved_middle, target, limits, override_maximum_with_original, recursion_budget - 1)
	end
	local cosine = clamp_native_cosine(f32(reciprocal(twice_product, 2) * f32(sum_squared - planar_squared)))
	local interior_angle = f32(acos(cosine) * TO_DEGREES)
	if limits.minimum_degrees >= interior_angle then
		target.value = scaled_add(normalize(requested_delta), f32(minimum_distance + EPSILON), root)
		return two_bone.solve(root, middle, end_, solved_middle, target, limits, override_maximum_with_original, recursion_budget - 1)
	end
	local target_angle = acos(clamp_native_cosine(f32(reciprocal(distance, 2) * target_delta[1])))
	if (local_middle[2] < 0.0 and local_target[2] > 0.0) or (local_middle[2] > 0.0 and local_target[2] < 0.0) then
		target_angle = f32(target_angle * -1.0)
	end
	-- The target heading is an addend *inside* this acos in the TU3 body
	-- (vmaddfp82970088). Preserve it rather than fitting a textbook IK formula.
	local ratio = mul_add(reciprocal(f32(twice_upper * distance), 2), f32(f32(upper_squared + planar_squared) - lower_squared), target_angle)
	local angle = acos(clamp_native_cosine(ratio))
	local original_delta = subtract(local_end, local_root)
	local positive = candidate(original_delta, angle, upper_length, local_root, target_basis)
	local negative = candidate(original_delta, f32(from_bits(0x40C9_0FDB) - angle), upper_length, local_root, target_basis)
	solved_middle.value = if local_end[2] > local_middle[2] then negative else positive
	return "Solved"
end

return two_bone
