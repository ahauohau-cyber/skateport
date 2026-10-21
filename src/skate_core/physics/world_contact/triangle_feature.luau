--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/triangle_feature.rs (коммит 2e16697)

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local arithmetic = require("./arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate

local triangle_feature = {}

type V = { number }

local function load(words: { number }, offset: number): V
	return {
		from_bits(words[offset + 1]),
		from_bits(words[offset + 2]),
		from_bits(words[offset + 3]),
		from_bits(words[offset + 4]),
	}
end
local function store(words: { number }, offset: number, v: V)
	words[offset + 1] = to_bits(v[1])
	words[offset + 2] = to_bits(v[2])
	words[offset + 3] = to_bits(v[3])
	words[offset + 4] = to_bits(v[4])
end
local function dot(a: V, b: V): number
	return arithmetic.dot({ a[1], a[2], a[3] }, { b[1], b[2], b[3] })
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

-- fn segment(out: &mut MaximumFeature, index: usize, point: V, edge: V, length: u32)
local function segment(out: { number }, index: number, point: V, edge: V, length: number)
	local offset = 4 + index * 16
	store(out, offset, point)
	store(out, offset + 4, edge)
	rt.fill(out, offset + 12, offset + 16, length)
end

-- Complete82AC6F88. Only edge plane vectors are changed. Mode0 negates the
-- incoming direction before crossing, preserving the native arithmetic order.
-- pub fn build_feature_edge_planes(feature: &mut MaximumFeature, mode: u32, direction: [u32; 4])
function triangle_feature.build_feature_edge_planes(feature: { number }, mode: number, direction: { number })
	local count = rt.to_i32(feature[141])
	if count <= 0 then
		return
	end
	assert(count <= 8, "native feature storage holds at most eight segments")
	local normal = {}
	for i = 1, 4 do
		local x = from_bits(direction[i])
		normal[i] = if mode == 0 then -x else x
	end
	for i = 0, count - 1 do
		local offset = 4 + i * 16
		local edge = load(feature, offset + 4)
		local plane = cross(edge, normal)
		local squared = dot(plane, plane)
		local r = estimate(squared)
		r = mul_add(f32(r * 0.5), mul_add(-squared, f32(r * r), 1.0), r)
		local scale = if squared > from_bits(0x3400_0000) then r else 0.0
		store(feature, offset + 8, { f32(plane[1] * scale), f32(plane[2] * scale), f32(plane[3] * scale), f32(plane[4] * scale) })
	end
end

-- Full triangle maximum-feature callback82ADDD68, including near-tangent
-- edge/vertex branches. Header word0 is preserved outside the face branch.
-- pub fn triangle_maximum_feature(gp: &[u32; 48], mode: u32, direction: [u32; 4], out: &mut MaximumFeature)
function triangle_feature.triangle_maximum_feature(gp: { number }, mode: number, direction: { number }, out: { number })
	local normal = load(gp, 4)
	local query = { from_bits(direction[1]), from_bits(direction[2]), from_bits(direction[3]), from_bits(direction[4]) }
	local projected = dot(query, normal)
	local points = { load(gp, 0), load(gp, 8), load(gp, 12) }
	local edges = { load(gp, 16), load(gp, 20), load(gp, 24) }
	if math.abs(projected) > from_bits(0x3f73_3333) then
		if (if projected < 0.0 then 1 else 0) == mode then
			for i, point in { 0, 2, 1 } do
				local k = i - 1
				segment(out, k, points[point + 1], edges[k + 1], gp[28 + k + 1])
			end
			out[1] = 8
		else
			for i, point in { 0, 1, 2 } do
				local k = i - 1
				local e = edges[2 - k + 1]
				segment(out, k, points[point + 1], { -e[1], -e[2], -e[3], -e[4] }, gp[30 - k + 1])
			end
			out[1] = 0
		end
		store(out, 132, normal)
		out[141] = 3
	else
		local p = { dot(query, points[1]), dot(query, points[2]), dot(query, points[3]) }
		local e = { math.abs(dot(query, edges[1])), math.abs(dot(query, edges[2])), math.abs(dot(query, edges[3])) }
		local threshold = from_bits(0x3d4c_cccd)
		local point, edge
		if p[1] > p[2] and p[1] > p[3] then
			point = 0
			if threshold > e[1] and e[3] > e[1] then
				edge = 0
			elseif threshold > e[3] then
				edge = 2
			end
		elseif p[2] > p[3] then
			point = 1
			if threshold > e[2] and e[3] > e[2] then
				edge = 1
			elseif threshold > e[3] then
				edge = 2
			end
		else
			point = 2
			if threshold > e[1] and e[2] > e[1] then
				edge = 0
			elseif threshold > e[2] then
				edge = 1
			end
		end
		if edge ~= nil then
			-- points[[0, 2, 1][edge]]
			local vertex = ({ 0, 2, 1 })[edge + 1]
			segment(out, 0, points[vertex + 1], edges[edge + 1], gp[28 + edge + 1])
			out[141] = 1
		else
			store(out, 136, points[point + 1])
			out[141] = 0
		end
	end
	triangle_feature.build_feature_edge_planes(out, mode, direction)
end

return triangle_feature
