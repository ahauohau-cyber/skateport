--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/math.rs (коммит 2e16697)
--
-- Independent arithmetic for original PhysicsAir's jump-velocity helpers.
-- Retains original refinements; PC results are not certified Xenon bit-exact.
-- ROBLOX: unit struct AirMath + impl PhysicsAirMath -> таблица с методами.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local board_motion_output = require("../../physics/board_motion_output")
local board_ground = require("../../physics/board_ground")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = board_motion_output.inverse_length_squared

type V = { number }

local math_ = {}

local AirMath = {}
math_.AirMath = AirMath

function AirMath.minimum_vminfp(_self: any, left: number, right: number): number
	return native_arithmetic.vector_min(left, right)
end
function AirMath.length_squared_vmsum3fp(_self: any, value: V): number
	return native_arithmetic.dot3(value, value)
end
function AirMath.length_vmsum3fp_vrsqrte(_self: any, value: V): number
	local square = native_arithmetic.dot3(value, value)
	local length = f32(square * inverse_length_squared(square, 2))
	if square == 0.0 then
		return 0.0
	end
	return length
end
function AirMath.clamp_vector_within_max_length(self: any, value: V, maximum: number): V
	-- 82BD3D90..3E74, including the original short-vector bge and fsel.
	local length = AirMath.length_vmsum3fp_vrsqrte(self, value)
	if not (length >= from_bits(0x3780_0000)) then
		return value
	end
	local bound = if f32(maximum - length) >= -0.0 then length else maximum
	local inverse = native_arithmetic.reciprocal_estimate(length)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, length, 1.0), inverse)
	end
	return {
		f32(f32(value[1] * bound) * inverse),
		f32(f32(value[2] * bound) * inverse),
		f32(f32(value[3] * bound) * inverse),
		f32(f32(value[4] * bound) * inverse),
	}
end

-- 8296EBB0 uses one normalization refinement and a clamped dot product.
function math_.angle_between_vectors(left: V, right: V): number
	return board_ground.angle_between(vector.create(left[1], left[2], left[3]), vector.create(right[1], right[2], right[3]))
end

-- Toolkit_ClampJumpVelocity82D93518. The output uses the CURRENT velocity's
-- direction; the supplied reference only bounds its magnitude.
function math_.clamp_jump_velocity(reference: V, current: V): V
	local reference_speed = AirMath.length_vmsum3fp_vrsqrte(AirMath, reference)
	local speed = AirMath.length_vmsum3fp_vrsqrte(AirMath, current)
	local denominator = if f32(speed - 1.0) >= -0.0 then speed else 1.0
	local scale = if denominator > reference_speed then f32(reference_speed / denominator) else 1.0
	return { f32(current[1] * scale), f32(current[2] * scale), f32(current[3] * scale), f32(current[4] * scale) }
end

return math_
