--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/anti_flip.rs (коммит 2e16697)
--
-- Complete TU3 Toolkit_AntiFlipTorque 82D94190, distinct from heading/manual.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph
local cross, dot3, normalize = vector_mod.cross, vector_mod.dot3, vector_mod.normalize

type F4 = { number }

local anti_flip = {}

export type AntiFlipSettings = {
	axis_96_response: point_graph.PointGraph, -- +1832/+1864
	axis_64_response: point_graph.PointGraph, -- +1912/+1944
	normal_threshold: F4, -- live 830BD350
}

export type AntiFlipInput = {
	flags_2468: number,
	balance: number, -- +2720
	axis_96: F4,
	axis_64: F4,
	projection_axis_544: F4,
}

function anti_flip.calculate(s: AntiFlipSettings, i: AntiFlipInput): F4
	if bit32.btest(i.flags_2468, 0x2000_0000) then
		return { 0.0, 0.0, 0.0, 0.0 }
	end
	local function project(axis: F4): F4
		local d = dot3(i.projection_axis_544, axis)
		local v = {}
		for n = 1, 4 do
			v[n] = f32(axis[n] - f32(i.projection_axis_544[n] * d))
		end
		return normalize(v, s.normal_threshold)
	end
	local a = project(i.axis_96)
	local b = project(i.axis_64)
	local function angle(axis: F4, projected: F4): number
		local d = dot3(axis, projected)
		d = if 0.0 > d then 0.0 else d
		d = if 1.0 < d then 1.0 else d
		return f32(trigonometry.acos(d) * from_bits(0x3f22_f983))
	end
	local sign_a = if dot3(i.axis_64, cross(i.axis_96, a)) >= 0.0 then 1.0 else -1.0
	local sign_b = if dot3(i.axis_96, cross(i.axis_64, b)) >= 0.0 then 1.0 else -1.0
	local b_strength = f32(PointGraph.evaluate(s.axis_64_response, angle(i.axis_64, b)) * sign_b)
	local a_strength = f32(f32(PointGraph.evaluate(s.axis_96_response, angle(i.axis_96, a)) * sign_a) * (if i.balance == 0.0 then 1.0 else 0.0))
	local out = {}
	for n = 1, 4 do
		out[n] = mul_add(i.axis_64[n], a_strength, f32(i.axis_96[n] * b_strength))
	end
	return out
end

return anti_flip
