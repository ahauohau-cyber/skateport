--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/straighten.rs (коммит 2e16697)
--
-- Complete TU3 Toolkit_CalcStraightenOutTorque 82D92B60.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local PointGraph = point_graph.PointGraph
local clamp, cross, dot3 = vector_mod.clamp, vector_mod.cross, vector_mod.dot3

type F4 = { number }

local straighten = {}

export type StraightenSettings = {
	time_response: point_graph.PointGraph, -- settings +768/+832 (16 точек)
	opposite_turn_limit: number, -- +896
	time_scalar: number, -- +900
	heading_time_limit: number, -- surface +236
	strength: number, -- surface +232
}

export type StraightenInput = {
	heading_time: number,
	scalar_2764: number,
	turn: number, -- +2676
	forward: F4, -- +352
	velocity: F4, -- +400
	normal: F4, -- +464
}

local function map(v: F4, s: number): F4
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end

function straighten.calculate(s: StraightenSettings, i: StraightenInput): F4
	local limit = f32(mul_add(f32(1.0 - s.time_scalar), i.scalar_2764, s.time_scalar) * s.heading_time_limit)
	local strength = f32(PointGraph.evaluate(s.time_response, f32(clamp(i.heading_time, 0.0, limit) / limit)) * s.strength)
	local forward = if dot3(i.forward, i.velocity) < 0.0 then { -i.forward[1], -i.forward[2], -i.forward[3], -i.forward[4] } else i.forward
	local error = dot3(cross(forward, i.velocity), i.normal)
	local output = map(i.normal, f32(error * strength))
	if f32(i.turn * error) < 0.0 then
		local scale = f32(1.0 - f32(clamp(math.abs(i.turn), 0.0, s.opposite_turn_limit) / s.opposite_turn_limit))
		output = map(output, scale)
	end
	return output
end

return straighten
