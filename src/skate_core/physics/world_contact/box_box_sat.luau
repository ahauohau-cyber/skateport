--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/box_box_sat.rs (коммит 2e16697)
-- В Rust это подмодуль primitive_query (`#[path = "box_box_sat.rs"] pub(super) mod box_box_sat`).

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local prism_math = require("./prism_math")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate
local load, dot, scale, cross = prism_math.load, prism_math.dot, prism_math.scale, prism_math.cross

local box_box_sat = {}

-- TU3 82ACF448. Unlike the triangle/box entry, edge crosses use the raw
-- reciprocal-square-root estimate without refinement. The last cross is
-- repeated to fill its final four-candidate batch; equal scores retain the
-- earlier axis. Shape fatness is excluded from these intervals.
-- pub(in super::super) fn box_box(a: &[u32; 48], b: &[u32; 48]) -> ([u32; 4], [u32; 4])
function box_box_sat.box_box(a: { number }, b: { number }): ({ number }, { number })
	-- ROBLOX: axes[k] из Rust лежит в axes[k + 1].
	local axes = {}
	for i = 0, 2 do
		axes[i + 1] = load(a, 12 - i * 4)
		axes[3 + i + 1] = load(b, 12 - i * 4)
	end
	for edge_a = 0, 2 do
		for edge_b = 0, 2 do
			local axis = cross(load(a, 16 + edge_a * 4), load(b, 16 + edge_b * 4))
			axes[6 + edge_a * 3 + edge_b + 1] = scale(axis, estimate(dot(axis, axis)))
		end
	end
	axes[16] = axes[15]
	local scaled_a, scaled_b = {}, {}
	for i = 0, 2 do
		scaled_a[i + 1] = scale(load(a, 4 + i * 4), from_bits(a[28 + i + 1]))
		scaled_b[i + 1] = scale(load(b, 4 + i * 4), from_bits(b[28 + i + 1]))
	end
	local best = 0.0
	local selected = axes[1]
	local selected_sign = 1.0
	for k, axis in axes do
		local index = k - 1
		local a_center = dot(load(a, 0), axis)
		local b_center = dot(load(b, 0), axis)
		local a_radius = f32(
			f32(math.abs(dot(scaled_a[1], axis)) + math.abs(dot(scaled_a[2], axis))) + math.abs(dot(scaled_a[3], axis))
		)
		local b_radius = f32(
			f32(math.abs(dot(scaled_b[1], axis)) + math.abs(dot(scaled_b[2], axis))) + math.abs(dot(scaled_b[3], axis))
		)
		local forward = f32(f32(a_center - a_radius) - f32(b_center + b_radius))
		local reverse = f32(f32(b_center - b_radius) - f32(a_center + a_radius))
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

return box_box_sat
