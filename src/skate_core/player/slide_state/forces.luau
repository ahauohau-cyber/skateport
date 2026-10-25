--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/slide_state/forces.rs (коммит 2e16697)
--
-- Full non-launch arithmetic82D3AB14..AE4C and point force82D925E0.
-- Uses independent PC arithmetic with the original refinement/operation order.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел; Vector3 -> Luau vector.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local board_motion_output = require("../../physics/board_motion_output")
local force_queue = require("../../physics/force_queue")
local point_graph = require("../../point_graph")
local collision_response = require("../../riding/collision_response")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local inverse_length_squared = board_motion_output.inverse_length_squared
local evaluate = point_graph.PointGraph.evaluate

type V = { number }
type PointGraph = point_graph.PointGraph

local forces = {}

export type SlideSettings = {
	input_remap: PointGraph,
	remap_vs_speed: PointGraph,
	force_vs_angle: PointGraph,
	force_vs_speed: PointGraph,
	softest_wheel_force: number,
	softest_wheel_spin: number,
	angular_force: number,
	force_y_offset: number,
}

export type SlideSurface = {
	speed_to_force: PointGraph,
	yaw_strength: number,
	yaw_damping: number,
}

export type SlideInput = {
	velocity: V,
	normal: V,
	side: V,
	effective_forward: V,
	reference_forward: V,
	angular_velocity: V,
	absolute_speed: number,
	surface_speed: number,
	slide: number,
	elapsed: number,
	wheel_hardness: number,
}

local function dot(a: V, b: V): number
	return native_arithmetic.dot3(a, b)
end

local function scale(v: V, s: number): V
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end

local function madd(v: V, s: number, b: V): V
	return { mul_add(v[1], s, b[1]), mul_add(v[2], s, b[2]), mul_add(v[3], s, b[3]), mul_add(v[4], s, b[4]) }
end

local function reject(v: V, n: V): V
	local d = dot(v, n)
	return {
		f32(v[1] - f32(n[1] * d)),
		f32(v[2] - f32(n[2] * d)),
		f32(v[3] - f32(n[3] * d)),
		f32(v[4] - f32(n[4] * d)),
	}
end

local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

local function normalize(v: V): V
	return scale(v, inverse_length_squared(dot(v, v), 2))
end

local function normalize_safe(v: V): V
	local d = dot(v, v)
	local inv = inverse_length_squared(d, 2)
	local length = if d == 0.0 then 0.0 else f32(d * inv)
	if length > rt.from_bits(0x358637bd) then
		return scale(v, inv)
	else
		return { 0.0, 0.0, 0.0, 0.0 }
	end
end

local function fsel(v: number, a: number, b: number): number
	return if v >= -0.0 then a else b
end

local function xyz(v: V): vector
	return vector.create(v[1], v[2], v[3])
end

-- The source does not add a zero-velocity normalization fallback here.
-- Retain that branch behavior rather than manufacturing a desired direction.
function forces.angular_correction(s: SlideSettings, surface: SlideSurface, p: SlideInput): V
	local remap = evaluate(s.input_remap, math.abs(p.slide))
	local age = f32(p.elapsed - 0.5)
	age = fsel(-age, 0.0, age)
	age = fsel(f32(1.0 - age), age, 1.0)
	local weight = f32(evaluate(s.remap_vs_speed, p.surface_speed) * age)
	local pi = rt.from_bits(0x40490fdb)
	local signed = fsel(p.slide, remap, -remap)
	local angle = mul_add(f32(p.slide * pi), f32(1.0 - weight), f32(f32(signed * pi) * weight))
	local velocity = normalize(p.velocity)
	local side = normalize(cross(p.normal, velocity))
	local desired = madd(velocity, trigonometry.cos(angle), scale(side, trigonometry.sin(angle)))
	local err = cross(p.reference_forward, desired)
	if dot(p.reference_forward, desired) < 0.0 then
		err = if err[2] < 0.0 then { -p.normal[1], -p.normal[2], -p.normal[3], -p.normal[4] } else p.normal
	end
	local strength = f32(mul_add(f32(1.0 - s.softest_wheel_spin), p.wheel_hardness, s.softest_wheel_spin) * surface.yaw_strength)
	local displacement = scale(madd(err, strength, scale(p.angular_velocity, surface.yaw_damping)), s.angular_force)
	return scale(p.normal, dot(displacement, p.normal))
end

-- 82D925E0 rejects normal velocity, measures the authored slip angle and adds
-- its signed sideways response.82E0A4E8 normalizes before its rejection again.
function forces.sliding_force(s: SlideSettings, surface: SlideSurface, p: SlideInput): force_queue.QueuedPointForce
	local tangent = reject(p.velocity, p.normal)
	local lateral = scale(p.side, dot(tangent, p.side))
	local response = evaluate(surface.speed_to_force, p.absolute_speed)
	-- Original ble is !GT, so unordered follows the <= branch too.
	local hardness = if response > 0.0 then p.wheel_hardness else 1.0
	local strength = f32(mul_add(f32(1.0 - s.softest_wheel_force), hardness, s.softest_wheel_force) * response)
	local side = normalize_safe(cross(p.normal, p.velocity))
	local longitudinal = reject(scale(lateral, strength), normalize_safe(side))
	local angle = if f32(dot(p.velocity, p.velocity) * dot(p.effective_forward, p.effective_forward)) > rt.from_bits(0x37800000)
		then collision_response.signed_angle(
			xyz(reject(p.velocity, p.normal)),
			xyz(reject(p.effective_forward, p.normal)),
			xyz(p.normal)
		)
		else 0.0
	local turns = f32(angle * rt.from_bits(0x3e22f983))
	local fraction = f32(turns - math.floor(turns))
	local wrapped = f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * rt.from_bits(0x40c90fdb))
	local degrees = f32(wrapped * rt.from_bits(0x42652ee1))
	local sign = if degrees > 0.0 then 1.0 else -1.0
	local angular = scale(scale(side, evaluate(s.force_vs_angle, math.abs(degrees))), evaluate(s.force_vs_speed, p.surface_speed))
	local force = madd(angular, sign, longitudinal)
	-- bge skips negation for unordered as well as nonnegative.
	local y = if dot(force, p.velocity) < 0.0 then -s.force_y_offset else s.force_y_offset
	return {
		tag = 9,
		force_world = xyz(force),
		point_body = vector.create(0.0, y, 0.0),
	}
end

return forces
