--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/deck_angular_correction.rs (коммит 2e16697)
--
-- Deck angular corrections from TU3 82C07000 and 82C075B8.
-- These add angular acceleration before the shared solve. They never set yaw
-- or orientation directly. Both native fixed-step conversions are retained.

local rt = require("../../rt")
local bmo = require("./board_motion_output")
local native_arithmetic = require("./native_arithmetic")
local rigid_body = require("./rigid_body")
local math_mod = require("../math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, inverse_length_squared = bmo.dot, bmo.inverse_length_squared

type Vector3 = vector
type Basis3 = math_mod.Basis3

local STEP = from_bits(0x3c88_8889)
local NORMAL_MINIMUM = from_bits(0x3586_37bd) --82F826F8 ->830BD350.

local deck_angular_correction = {}

local function scale(v: Vector3, x: number): Vector3
	return vector.create(f32(v.x * x), f32(v.y * x), f32(v.z * x))
end
local function subtract(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end
local function cross(a: Vector3, b: Vector3): Vector3
	return vector.create(mul_add(-a.z, b.y, f32(a.y * b.z)), mul_add(-a.x, b.z, f32(a.z * b.x)), mul_add(-a.y, b.x, f32(a.x * b.y)))
end
local function multiply(matrix: Basis3, v: Vector3): Vector3
	local c = matrix.columns
	local function lane(i: number): number
		return mul_add(c[3][i], v.z, mul_add(c[2][i], v.y, f32(c[1][i] * v.x)))
	end
	return vector.create(lane(1), lane(2), lane(3))
end
local function reciprocal_refined(value: number): number
	local estimate = native_arithmetic.reciprocal_estimate(value)
	local first = mul_add(estimate, mul_add(-estimate, value, 1.0), estimate)
	return mul_add(first, mul_add(-first, value, 1.0), first)
end
local function invert_symmetric(tensor: Basis3): Basis3
	local c = tensor.columns
	local a = vector.create(c[1][1], c[1][2], c[1][3])
	local b = vector.create(c[2][1], c[2][2], c[2][3])
	local cc = vector.create(c[3][1], c[3][2], c[3][3])
	local first = cross(b, cc)
	local second = cross(cc, a)
	local third = cross(a, b)
	local inverse_det = reciprocal_refined(dot(a, first))
	return {
		columns = {
			{ f32(first.x * inverse_det), f32(second.x * inverse_det), f32(third.x * inverse_det) },
			{ f32(first.y * inverse_det), f32(second.y * inverse_det), f32(third.y * inverse_det) },
			{ f32(first.z * inverse_det), f32(second.z * inverse_det), f32(third.z * inverse_det) },
		},
	}
end

-- /// 82C075B8. The inverse of the current world inverse-inertia tensor converts
-- /// displacement/step to torque; another step division and the original tensor
-- /// convert it to angular acceleration. Do not algebraically cancel the tensor
-- /// pair: its rounded cofactors and ordered products are observable.
function deck_angular_correction.apply_angular_displacement(body: rigid_body.RetailBodyRates, displacement: Vector3)
	local tensor = body.world_inverse_inertia
	local inverse = invert_symmetric(tensor)
	local inverse_step = reciprocal_refined(STEP)
	local target_rate = scale(displacement, inverse_step)
	local momentum = multiply(inverse, target_rate)
	local torque = scale(momentum, reciprocal_refined(STEP))
	local acceleration = multiply(tensor, torque)
	local t = body.torque_acceleration
	body.torque_acceleration = vector.create(f32(t.x + acceleration.x), f32(t.y + acceleration.y), f32(t.z + acceleration.z))
	-- Native accumulator +172 shares its vector with the cooldown word.
	body.cool_down = 0
end
local apply_angular_displacement = deck_angular_correction.apply_angular_displacement

local function direction_of(requested: Vector3): Vector3
	local squared = dot(requested, requested)
	local inverse = inverse_length_squared(squared, 2)
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	return if length > NORMAL_MINIMUM then scale(requested, inverse) else vector.zero
end

-- ///82C07328 subtracts the current angular displacement along the requested
-- ///axis, without07000's directional clamps, then performs the same tensor and
-- ///fixed-step conversion as075B8. The thrown-board controller calls this leaf.
function deck_angular_correction.apply_axis_displacement(body: rigid_body.RetailBodyRates, requested: Vector3)
	local direction = direction_of(requested)
	local existing = scale(direction, dot(direction, scale(body.angular_velocity, STEP)))
	apply_angular_displacement(body, subtract(requested, existing))
end

-- /// 82C07000 first limits the requested angular displacement against the
-- /// displacement already supplied by angular velocity along that same axis.
function deck_angular_correction.apply_limited_displacement(body: rigid_body.RetailBodyRates, requested: Vector3)
	local direction = direction_of(requested)
	local existing = scale(direction, dot(direction, scale(body.angular_velocity, STEP)))
	local remainder = subtract(requested, existing)
	if dot(remainder, requested) < 0.0 then
		remainder = vector.zero
	end
	local selected = if dot(existing, requested) < 0.0 then requested else remainder
	apply_angular_displacement(body, selected)
end

local function ground_torque_scalar(): number
	-- Positive fixed input10 has exponent3 and mantissa1.25. Thus the native
	-- vlog estimate followed by floor selects3; its sign/special-value masks
	-- cannot select another branch for these immutable instruction inputs.
	local x = 0.25
	local square = f32(x * x)
	local cube = f32(x * square)
	local fourth = f32(square * square)
	local log = { 0x3fb8aa0e, 0xbf389e52, 0x3ef5162d, 0xbeb1d204, 0x3e77adbd, 0xbe0cd4fb, 0x3d5541c6, 0xbc188b0b }
	for i, w in log do
		log[i] = from_bits(w)
	end
	local low = mul_add(cube, log[4], mul_add(square, log[3], mul_add(x, log[2], log[1])))
	local high = mul_add(cube, log[8], mul_add(square, log[7], mul_add(x, log[6], log[5])))
	local exponent = mul_add(-x, mul_add(fourth, high, low), -3.0)
	local integral = math.floor(exponent)
	local fraction = f32(exponent - integral)
	local square2 = f32(fraction * fraction)
	local cube2 = f32(fraction * square2)
	local fourth2 = f32(square2 * square2)
	local e = { 0x3f800000, 0xbf317218, 0x3e75fded, 0xbd6357ca, 0x3c1d8c54, 0xbaae1854, 0x391aa7d7, 0xb7364261 }
	for i, w in e do
		e[i] = from_bits(w)
	end
	local low2 = mul_add(cube2, e[4], mul_add(square2, e[3], mul_add(fraction, e[2], e[1])))
	local high2 = mul_add(cube2, e[8], mul_add(square2, e[7], mul_add(fraction, e[6], e[5])))
	local polynomial = mul_add(fourth2, high2, low2)
	--vexptefp sees an integral exponent here, so its power of two is exact.
	local power_of_two = from_bits(bit32.lshift(127 + integral, 23))
	return f32(f32(power_of_two * reciprocal_refined(polynomial)) * from_bits(0xc0c1_999a))
end

-- /// Ground board update82D389DC..82D38C98. Skateboard+16 is the cached deck
-- /// rigid body (ctor82C01278); this torque therefore enters the same accumulator.
-- /// The inline pow calculation has fixed inputs10 and-1. Retain its two
-- /// coefficient trees and reciprocal refinements instead of replacing it by.1.
function deck_angular_correction.apply_ground_body_torque(body: rigid_body.RetailBodyRates)
	local loc = vector.create(0.0, ground_torque_scalar(), 0.0)
	local world = multiply(body.basis, loc)
	local acceleration = multiply(body.world_inverse_inertia, world)
	local t = body.torque_acceleration
	body.torque_acceleration = vector.create(f32(acceleration.x + t.x), f32(acceleration.y + t.y), f32(acceleration.z + t.z))
	body.cool_down = 0
end

return deck_angular_correction
