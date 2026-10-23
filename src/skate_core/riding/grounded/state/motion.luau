--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/motion.rs (коммит 2e16697)
--
-- Physical Ground entry82D37604..82D378A8 and future-deck82D38630 math.
-- These operate on actual board rates/force records. Skeleton publication is
-- separate because prediction moves its animation target, not the board.

local rt = require("../../../../rt")
local force_queue = require("../../../physics/force_queue")
local native_arithmetic = require("../../../physics/native_arithmetic")
local gcm = require("../../ground_correction_math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot_product = gcm.dot_product

type F4 = { number }
type Vector3 = vector

local motion = {}

local function xyz(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end
local function words(v: Vector3): F4
	return { v.x, v.y, v.z, 0.0 }
end
local function reciprocal(value: number): number
	local r = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		r = mul_add(r, mul_add(-value, r, 1.0), r)
	end
	return r
end

-- Projection is applied directly to deck angular velocity, before speed seed.
function motion.entry_angular_velocity(normal: F4, angular: F4): Vector3
	local speed = dot_product(normal, angular)
	return vector.create(f32(normal[1] * speed), f32(normal[2] * speed), f32(normal[3] * speed))
end

-- Board+260 is the smaller absolute longitudinal speed before/after normal
-- rejection. The source fsel retains the raw value on an unordered compare.
function motion.entry_target_speed(velocity: Vector3, normal: F4, forward: F4): number
	local v = words(velocity)
	local along_normal = dot_product(v, normal)
	local tangent = {}
	for i = 1, 4 do
		tangent[i] = f32(v[i] - f32(normal[i] * along_normal))
	end
	local raw = math.abs(dot_product(v, forward))
	local planar = math.abs(dot_product(tangent, forward))
	return if f32(raw - planar) >= 0.0 then planar else raw
end

-- Exact tag19 producer. Gravity and normal velocity are not added here.
function motion.landing_on_deck_force(physical_velocity: F4, animation_velocity: F4, axis: F4, mass: number, strength: number, point_y: number): any
	local delta = {}
	for i = 1, 4 do
		delta[i] = f32(animation_velocity[i] - physical_velocity[i])
	end
	local projected = dot_product(delta, axis)
	local step_inverse = reciprocal(from_bits(0x3c88_8889))
	local force = {}
	for i = 1, 4 do
		force[i] = f32(f32(f32(f32(delta[i] - f32(axis[i] * projected)) * strength) * mass) * step_inverse)
	end
	return { tag = 19, force_world = xyz(force), point_body = vector.create(0.0, point_y, 0.0) }
end

-- Complete displacement calculation in PredictFutureDeck. Force summation
-- preserves queue order; normal rejection occurs after the first dt/mass.
-- Returns None when the source deliberately preserves both skeleton targets.
function motion.future_deck_displacement(forces: any, mass: number, dt: number, normal: F4, pushing: boolean, manual_correction: boolean): Vector3?
	if pushing or manual_correction then
		return nil
	end
	local sum = { 0.0, 0.0, 0.0, 0.0 }
	for _, force in force_queue.BoardForceQueue.entries(forces) do
		local v = words(force.force_world)
		for i = 1, 4 do
			sum[i] = f32(sum[i] + v[i])
		end
	end
	local scale = f32(reciprocal(mass) * dt)
	local delta = {}
	for i = 1, 4 do
		delta[i] = f32(sum[i] * scale)
	end
	local projection = dot_product(delta, normal)
	local out = {}
	for i = 1, 3 do
		out[i] = f32(f32(delta[i] - f32(normal[i] * projection)) * dt)
	end
	return vector.create(out[1], out[2], out[3])
end

return motion
