--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/collision_response.rs (коммит 2e16697)
--
-- Complete collision response calculation, TU3 82D944E8 and its angle helpers.

local rt = require("../../rt")
local board_ground = require("../physics/board_ground")
local bmo = require("../physics/board_motion_output")
local native_arithmetic = require("../physics/native_arithmetic")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, inverse_length_squared, length = bmo.dot, bmo.inverse_length_squared, bmo.length
local angle_between = board_ground.angle_between
local PointGraph = point_graph.PointGraph

type Vector3 = vector
type F4 = { number }

local collision_response_mod = {}

export type CollisionResponseSettings = {
	maximum_velocity_delta: number,
	force_y_offset: number,
	force_scalar: number,
	target_displacement_velocity: number,
	torque_vs_angle: point_graph.PointGraph,
}

export type CollisionResponsePhysical = {
	flags_2472: number,
	-- Processed736,416,448,544 and Ground1216 respectively.
	collision_displacement: F4,
	velocity: F4,
	forward: F4,
	up: F4,
	ground_normal: F4,
	-- Processed2604 and2660.
	time_step: number,
	mass: number,
}

export type CollisionResponse = {
	-- Native return value. False after the delta threshold still writes all
	-- three outputs, including the target velocity and angular correction.
	applied: boolean,
	force: F4,
	point: F4,
	angular_displacement: F4,
	target_velocity: F4,
}

local function xyz(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end

local function scale(v: Vector3, k: number): Vector3
	return vector.create(f32(v.x * k), f32(v.y * k), f32(v.z * k))
end

local function map(v: F4, k: number): F4
	return { f32(v[1] * k), f32(v[2] * k), f32(v[3] * k), f32(v[4] * k) }
end

local function reciprocal_refined(value: number): number
	local estimate = native_arithmetic.reciprocal_estimate(value)
	local first = mul_add(estimate, mul_add(-estimate, value, 1.0), estimate)
	return mul_add(first, mul_add(-first, value, 1.0), first)
end

local PI = from_bits(0x4049_0fdb)
local TAU = from_bits(0x40c9_0fdb)

-- 8296EC98, one-refinement normalization and signed cross about supplied up.
function collision_response_mod.signed_angle(a: Vector3, b: Vector3, up: Vector3): number
	local a_squared = dot(a, a)
	local b_squared = dot(b, b)
	if not (a_squared > f32(0.0001) and b_squared > f32(0.0001)) then
		return 0.0
	end
	local angle = angle_between(a, b)
	a = scale(a, inverse_length_squared(a_squared, 1))
	b = scale(b, inverse_length_squared(b_squared, 1))
	local cross = vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
	if dot(cross, up) < 0.0 then
		return f32(TAU - angle)
	end
	return angle
end
local signed_angle = collision_response_mod.signed_angle

-- 8258DB98 scalar truncation, fused wrap subtraction, then single range repair.
local function wrap_angle(angle: number): number
	if angle < -PI or not (angle < PI) then
		local turns = rt.float_as_i32(f32(angle * from_bits(0x3e22_f983)))
		angle = mul_add(-f32(turns), TAU, angle)
		if not (angle < PI) then
			angle = f32(angle - TAU)
		elseif angle < -PI then
			angle = f32(angle + TAU)
		end
	end
	return angle
end

-- None represents the two early returns which write no outputs. The native
-- late false return must remain distinguishable from them.
-- pub fn collision_response(settings, input) -> Option<CollisionResponse>
function collision_response_mod.collision_response(
	settings: CollisionResponseSettings,
	input: CollisionResponsePhysical
): CollisionResponse?
	if bit32.band(input.flags_2472, 0x20000) == 0 then
		return nil
	end
	local projection = dot(xyz(input.collision_displacement), xyz(input.ground_normal))
	local displaced = {}
	for i = 1, 4 do
		displaced[i] = f32(input.collision_displacement[i] - f32(input.ground_normal[i] * projection))
	end
	local distance = length(xyz(displaced))
	if distance < from_bits(0x3780_0000) then
		return nil
	end
	local inverse_distance = f32(1.0 / distance) -- scalar fdivs, not vector estimate.
	local direction = map(displaced, inverse_distance)
	local speed_toward = dot(xyz(input.velocity), xyz(direction))
	local tangent, target_velocity, delta = {}, {}, {}
	for i = 1, 4 do
		tangent[i] = f32(input.velocity[i] - f32(direction[i] * speed_toward))
	end
	for i = 1, 4 do
		target_velocity[i] = mul_add(direction[i], settings.target_displacement_velocity, tangent[i])
		delta[i] = f32(f32(target_velocity[i] - input.velocity[i]) * settings.force_scalar)
	end
	if speed_toward > settings.target_displacement_velocity then
		delta = { 0.0, 0.0, 0.0, 0.0 }
	end
	local magnitude = length(xyz(delta))
	local inverse_dt = reciprocal_refined(input.time_step)
	local force = {}
	for i = 1, 4 do
		force[i] = f32(f32(delta[i] * input.mass) * inverse_dt)
	end
	local applied = magnitude >= f32(0.01)
	if applied then
		local clamp = if magnitude <= settings.maximum_velocity_delta
			then 1.0
			else f32(settings.maximum_velocity_delta / magnitude)
		force = map(force, clamp)
	else
		force = { 0.0, 0.0, 0.0, 0.0 }
	end
	local angle = wrap_angle(signed_angle(xyz(input.forward), xyz(direction), xyz(input.up)))
	local torque = PointGraph.evaluate(settings.torque_vs_angle, f32(math.abs(angle) * from_bits(0x3ea2_f983)))
	local signed = if angle >= 0.0 then torque else -torque
	return {
		applied = applied,
		force = force,
		point = { 0.0, settings.force_y_offset, 0.0, 0.0 },
		angular_displacement = map(input.up, signed),
		target_velocity = target_velocity,
	}
end

return collision_response_mod
