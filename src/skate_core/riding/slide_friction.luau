--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/slide_friction.rs (коммит 2e16697)
--
-- Complete TU3 Toolkit_CalcSlideFriction 82D92970; Ground force tag 1.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph
local clamp, dot3 = vector_mod.clamp, vector_mod.dot3

type F4 = { number }

local slide_friction = {}

export type SlideFrictionSettings = {
	angle_response: point_graph.PointGraph, -- +196/+260 (16 точек)
	speed_response: point_graph.PointGraph, -- +324/+356
	time_response: point_graph.PointGraph, -- +388/+452 (16 точек)
	scalar_516: number,
	heading_time_limit: number, -- surface +236
	friction: number, -- surface +240
}

export type SlideFrictionInput = {
	heading_time: number,
	normal: F4, -- Processed +464
	velocity: F4, -- +400
	side_axis: F4, -- +64
	surface_speed: number, -- +2656
	scalar_2764: number,
}

function slide_friction.calculate(s: SlideFrictionSettings, i: SlideFrictionInput): { number }
	-- VMX min/max select the second argument on unordered comparisons.
	local y = if -1.0 > i.normal[2] then -1.0 else i.normal[2]
	y = if 1.0 < y then 1.0 else y
	local angle = clamp(f32(trigonometry.acos(y) * from_bits(0x3f22_f983)), 0.0, 1.0)
	angle = f32(1.0 - PointGraph.evaluate(s.angle_response, angle))
	local speed = f32(1.0 - PointGraph.evaluate(s.speed_response, f32(i.surface_speed * f32(0.1))))
	local time = PointGraph.evaluate(s.time_response, f32(clamp(i.heading_time, 0.0, s.heading_time_limit) / s.heading_time_limit))
	local blend = mul_add(f32(1.0 - s.scalar_516), i.scalar_2764, s.scalar_516)
	local response = if f32(angle - speed) >= 0.0 then angle else speed
	local scalar = -f32(f32(f32(time * blend) * response) * s.friction)
	local normal_speed = dot3(i.velocity, i.normal)
	local tangent = {}
	for n = 1, 4 do
		tangent[n] = f32(i.velocity[n] - f32(i.normal[n] * normal_speed))
	end
	local side_speed = dot3(tangent, i.side_axis)
	local output = table.create(8, 0.0)
	for n = 1, 4 do
		output[n] = f32(f32(i.side_axis[n] * side_speed) * scalar)
	end
	return output
end

return slide_friction
