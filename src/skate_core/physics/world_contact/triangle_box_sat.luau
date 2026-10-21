--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/triangle_box_sat.rs (коммит 2e16697)
-- В Rust это подмодуль primitive_query (`#[path = "triangle_box_sat.rs"] pub(super) mod triangle_box_sat`).

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local prism_math = require("./prism_math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate
local load, dot, scale, cross = prism_math.load, prism_math.dot, prism_math.scale, prism_math.cross

local triangle_box_sat = {}

-- fn minimum(a: f32, b: f32) -> f32
local function minimum(a: number, b: number): number
	return if a < b then a else b
end
-- fn maximum(a: f32, b: f32) -> f32
local function maximum(a: number, b: number): number
	return if a > b then a else b
end

-- TU3 82ACF950. Triangle normal first, then box Z/Y/X and all nine edge
-- crosses. Cross axes receive exactly one reciprocal-square-root refinement;
-- there is no small-cross rejection or normalization fallback in this entry.
-- pub(in super::super) fn triangle_box(triangle: &[u32; 48], box_shape: &[u32; 48]) -> ([u32; 4], [u32; 4])
function triangle_box_sat.triangle_box(triangle: { number }, box_shape: { number }): ({ number }, { number })
	local axes = {}
	axes[1] = load(triangle, 4)
	for i = 0, 2 do
		axes[1 + i + 1] = load(box_shape, 12 - i * 4)
	end
	for edge = 0, 2 do
		for box_edge = 0, 2 do
			local axis = cross(load(triangle, 16 + edge * 4), load(box_shape, 16 + box_edge * 4))
			local squared = dot(axis, axis)
			local seed = estimate(squared)
			local inverse = mul_add(f32(seed * 0.5), mul_add(-squared, f32(seed * seed), 1.0), seed)
			axes[4 + edge * 3 + box_edge + 1] = scale(axis, inverse)
		end
	end
	local scaled_box = {}
	for i = 0, 2 do
		scaled_box[i + 1] = scale(load(box_shape, 4 + i * 4), from_bits(box_shape[28 + i + 1]))
	end
	local best = 0.0
	local selected = axes[1]
	local selected_sign = 1.0
	for k, axis in axes do
		local index = k - 1
		local p0 = dot(load(triangle, 0), axis)
		local p1 = dot(load(triangle, 8), axis)
		local p2 = dot(load(triangle, 12), axis)
		-- The source compares vertices 1 and 2, then combines vertex 0.
		local low = minimum(p0, minimum(p1, p2))
		local high = maximum(p0, maximum(p1, p2))
		local center = dot(load(box_shape, 0), axis)
		local radius = f32(
			f32(math.abs(dot(scaled_box[1], axis)) + math.abs(dot(scaled_box[2], axis)))
				+ math.abs(dot(scaled_box[3], axis))
		)
		local forward = f32(low - f32(center + radius))
		local reverse = f32(f32(center - radius) - high)
		local separation, sign
		if forward > reverse then
			separation, sign = forward, -1.0
		else
			separation, sign = reverse, 1.0
		end
		if index == 0 or separation > best then
			best = separation
			selected = axis
			selected_sign = sign
		end
	end
	local best_bits = to_bits(best)
	return { best_bits, best_bits, best_bits, best_bits }, prism_math.bits(scale(selected, selected_sign))
end

return triangle_box_sat
