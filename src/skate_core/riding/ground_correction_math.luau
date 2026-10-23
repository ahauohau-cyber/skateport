--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/ground_correction_math.rs (коммит 2e16697)
--
-- Remaining numerical ground corrections from TU3 82D38800 and its callees.
-- These operate on actual physical vectors; phase/counter gates stay in the
-- grounded state owner and all body writes target the shared board solver.

local rt = require("../../rt")
local bmo = require("../physics/board_motion_output")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local dot, inverse_length_squared, length = bmo.dot, bmo.inverse_length_squared, bmo.length

type Vector3 = vector
type F4 = { number }

local m = {}

local function xyz(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end
local function map(v: F4, s: number): F4
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end
local function subtract(a: F4, b: F4): F4
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function cross(a: F4, b: F4): F4
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end
local function reciprocal_refined(value: number): number
	local estimate = native_arithmetic.reciprocal_estimate(value)
	local first = mul_add(estimate, mul_add(-estimate, value, 1.0), estimate)
	return mul_add(first, mul_add(-first, value, 1.0), first)
end

-- 82D38838..AC: length of Skeleton11008, with two reciprocal-square-root refinements.
function m.center_of_mass_height(com_to_deck_world: F4): number
	return length(xyz(com_to_deck_world))
end

function m.dot_product(a: F4, b: F4): number
	return native_arithmetic.dot3(a, b)
end

-- 82D38E18..82D38EA8: normalize the force with two refinements, reject
-- lengths no greater than the live native epsilon, then dot with velocity.
-- Velocity deliberately remains unnormalized.
function m.collision_force_projection(force: F4, velocity: F4): number
	local squared = dot(xyz(force), xyz(force))
	local inverse = inverse_length_squared(squared, 2)
	local len = if squared == 0.0 then 0.0 else f32(squared * inverse)
	local direction = if len > from_bits(0x3586_37bd) then map(force, inverse) else { 0.0, 0.0, 0.0, 0.0 }
	return dot(xyz(direction), xyz(velocity))
end

-- 82D37048: edge direction is divided by its computed length. The native
-- code uses two reciprocal refinements after its two square-root refinements;
-- it does not replace that sequence with direct inverse-length scaling.
function m.edge_direction(start: F4, end_: F4): F4
	local delta = subtract(end_, start)
	local inverse = reciprocal_refined(length(xyz(delta)))
	return map(delta, inverse)
end

-- 82D370F8: positive-Y perpendicular to an edge. The degenerate result is
-- native world X (82139A10), not world Y or an arbitrary orthogonal vector.
function m.edge_up(direction: F4): F4
	local first = cross({ 0.0, 1.0, 0.0, 0.0 }, direction)
	local perpendicular = cross(first, direction)
	local magnitude = length(xyz(perpendicular))
	if magnitude <= 0.0 then
		return { 1.0, 0.0, 0.0, 0.0 }
	end
	local signed_length = if perpendicular[2] < 0.0 then -magnitude else magnitude
	local inverse = reciprocal_refined(signed_length)
	return map(perpendicular, inverse)
end

-- 82D395AC..82D396AC: push away from the obstructing edge and upward.
-- Inputs are Processed1312,1328 and the actual deck position112.
function m.hang_force(edge_start: F4, edge_end: F4, deck: F4): F4
	local direction = m.edge_direction(edge_start, edge_end)
	local up = m.edge_up(direction)
	local side = cross(up, direction)
	if dot(xyz(subtract(deck, edge_start)), xyz(side)) < 0.0 then
		side = map(side, -1.0)
	end
	local lift = { 0.0, 160.0, 0.0, 0.0 }
	local out = {}
	for i = 1, 4 do
		out[i] = mul_add(side[i], 50.0, lift[i])
	end
	return out
end

-- 82D39950..82D399FC: signed deck-Z cross deck-Y, scaled by the native
-- displacement0.007. The caller already checked halfpipe/contact geometry.
function m.wheel_catch_displacement(deck_y: F4, deck_z: F4): F4
	local signed_z = deck_z
	if not (deck_z[2] > 0.0) then
		signed_z = {}
		for i = 1, 4 do
			signed_z[i] = rt.from_bits(bit32.bxor(to_bits(deck_z[i]), 0x8000_0000))
		end
	end
	return map(cross(signed_z, deck_y), from_bits(0x3be5_6042))
end

-- 82D39B04..82D39B8C: only captured X/Z are restored. Current position Y
-- appears in both terms, so no vertical pinning correction is introduced.
function m.pinning_velocity(position: F4, captured_x: number, captured_z: number, dt: number): F4
	local target = { captured_x, position[2], captured_z, 0.0 }
	local inverse_dt = reciprocal_refined(dt)
	return map(subtract(target, position), inverse_dt)
end

function m.scale_to_magnitude(v: F4, squared: number, magnitude: number): F4
	local inverse = inverse_length_squared(squared, 2)
	local len = if squared == 0.0 then 0.0 else f32(squared * inverse)
	-- 82D394D8 divides50 by the computed length with scalar fdivs.
	local factor = f32(magnitude / len)
	return map(v, factor)
end

-- ApplyWorldSpaceForceToDeck82C03F98. Its moment arm is measured from the
-- physical deck part origin returned by82585CB0, not the body's COM origin.
function m.apply_world_force(body: any, deck_part_position: Vector3, force: Vector3, point: Vector3)
	local arm = vector.create(f32(point.x - deck_part_position.x), f32(point.y - deck_part_position.y), f32(point.z - deck_part_position.z))
	local torque = cross({ arm.x, arm.y, arm.z, 0.0 }, { force.x, force.y, force.z, 0.0 })
	local inverse = body.inertia.inverse_mass
	local rates = body.rates
	local fa = rates.force_acceleration
	rates.force_acceleration = vector.create(
		f32(fa.x + f32(force.x * inverse)),
		f32(fa.y + f32(force.y * inverse)),
		f32(fa.z + f32(force.z * inverse))
	)
	local columns = rates.world_inverse_inertia.columns
	local function angular(i: number): number
		return mul_add(columns[3][i], torque[3], mul_add(columns[2][i], torque[2], f32(columns[1][i] * torque[1])))
	end
	local ta = rates.torque_acceleration
	rates.torque_acceleration = vector.create(f32(ta.x + angular(1)), f32(ta.y + angular(2)), f32(ta.z + angular(3)))
	rates.cool_down = 0
end

return m
