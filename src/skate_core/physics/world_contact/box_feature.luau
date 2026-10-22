--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/box_feature.rs (коммит 2e16697)

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local arithmetic = require("./arithmetic")
local feature_mod = require("./feature")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate
local initialize_feature_segment = feature_mod.initialize_feature_segment

local box_feature = {}

type V = { number }

-- const OTHER: [[usize; 2]; 3] = [[1, 2], [0, 2], [0, 1]]; // 83044248
local OTHER = { { 1, 2 }, { 0, 2 }, { 0, 1 } }
-- const SIGNS: [[f32; 2]; 4] = [[1.0, 1.0], [1.0, -1.0], [-1.0, -1.0], [-1.0, 1.0]]; //83044260
local SIGNS = { { 1.0, 1.0 }, { 1.0, -1.0 }, { -1.0, -1.0 }, { -1.0, 1.0 } }

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
local function bits(v: V): { number }
	return { to_bits(v[1]), to_bits(v[2]), to_bits(v[3]), to_bits(v[4]) }
end
local function dot(a: V, b: V): number
	return arithmetic.dot({ a[1], a[2], a[3] }, { b[1], b[2], b[3] })
end
local function scale(a: V, b: number): V
	return { f32(a[1] * b), f32(a[2] * b), f32(a[3] * b), f32(a[4] * b) }
end
local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function madd(a: V, b: number, c: V): V
	return { mul_add(a[1], b, c[1]), mul_add(a[2], b, c[2]), mul_add(a[3], b, c[3]), mul_add(a[4], b, c[4]) }
end
local function neg(a: V): V
	return { -a[1], -a[2], -a[3], -a[4] }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

-- fn plane(axis: V, direction: V, mode: u32) -> V
local function plane(axis: V, direction: V, mode: number): V
	local result = if mode ~= 0 then cross(axis, direction) else cross(direction, axis)
	local squared = dot(result, result)
	if squared > from_bits(0x3400_0000) then
		local r = estimate(squared)
		for _ = 1, 2 do
			r = mul_add(f32(r * 0.5), mul_add(-squared, f32(r * r), 1.0), r)
		end
		result = scale(result, r)
	end
	return result
end

-- fn face(center, axes: [V; 3], half: [f32; 3], fixed: usize, mode: u32, direction: V, output: &mut MaximumFeature)
-- ROBLOX: fixed, u, v — номера осей как в Rust (с нуля); axes/half с индекса 1.
local function face(center: V, axes: { V }, half: { number }, fixed: number, mode: number, direction: V, output: { number })
	local sign = if dot(axes[fixed + 1], direction) > 0.0 then 1.0 else -1.0
	local face_center = madd(axes[fixed + 1], f32(half[fixed + 1] * sign), center)
	local winding_sign = if fixed == 1 then -sign else sign
	local u, v = OTHER[fixed + 1][1], OTHER[fixed + 1][2]
	local positive_u = scale(axes[u + 1], half[u + 1])
	local negative_u = scale(axes[u + 1], -half[u + 1])
	local positive_v = scale(axes[v + 1], half[v + 1])
	local negative_v = scale(axes[v + 1], -half[v + 1])
	local p = plane(axes[v + 1], direction, mode)
	local q = plane(axes[u + 1], direction, mode)
	local len_u = f32(half[u + 1] * 2.0)
	local len_v = f32(half[v + 1] * 2.0)
	local points = {
		add(add(face_center, positive_u), positive_v),
		add(add(face_center, positive_u), negative_v),
		add(add(face_center, negative_u), negative_v),
		add(add(face_center, negative_u), positive_v),
	}
	local negative_axis_u = neg(axes[u + 1])
	local negative_axis_v = neg(axes[v + 1])
	local indices, directions, planes, lengths
	-- u32::from(winding_sign < 0.0) == mode
	if (if winding_sign < 0.0 then 1 else 0) == mode then
		indices = { 0, 1, 2, 3 }
		directions = { negative_axis_v, negative_axis_u, axes[v + 1], axes[u + 1] }
		planes = { neg(p), neg(q), p, q }
		lengths = { len_v, len_u, len_v, len_u }
	else
		indices = { 0, 3, 2, 1 }
		directions = { negative_axis_u, negative_axis_v, axes[u + 1], axes[v + 1] }
		planes = { neg(q), neg(p), q, p }
		lengths = { len_u, len_v, len_u, len_v }
	end
	for i = 0, 3 do
		local offset = 4 + i * 16
		store(output, offset, points[indices[i + 1] + 1])
		store(output, offset + 4, directions[i + 1])
		store(output, offset + 8, planes[i + 1])
		rt.fill(output, offset + 12, offset + 16, to_bits(lengths[i + 1]))
	end
	store(output, 132, scale(axes[fixed + 1], -winding_sign))
	output[141] = 4
end

-- Complete native box maximum-feature callback82AD7A98. Face winding uses the
-- full integer mode. `incoming_edge_plane` is VMX v60 at entry, copied only in
-- the edge branch without initialization by the native function.
-- pub fn box_maximum_feature(gp: &[u32; 48], mode: u32, direction: [u32; 4], output: &mut MaximumFeature, incoming_edge_plane: [u32; 4])
function box_feature.box_maximum_feature(
	gp: { number },
	mode: number,
	direction_bits: { number },
	output: { number },
	incoming_edge_plane: { number }
)
	local center = load(gp, 0)
	local axes = { load(gp, 4), load(gp, 8), load(gp, 12) }
	local half = { from_bits(gp[29]), from_bits(gp[30]), from_bits(gp[31]) }
	local direction = { from_bits(direction_bits[1]), from_bits(direction_bits[2]), from_bits(direction_bits[3]), from_bits(direction_bits[4]) }
	local small = 0
	local small_axis = 0
	local large_axis = 0
	for i = 0, 2 do
		if math.abs(dot(direction, axes[i + 1])) < from_bits(0x3e4c_cccd) then
			small += 1
			small_axis = i
		else
			large_axis = i
		end
	end
	if small == 2 then
		face(center, axes, half, large_axis, mode, direction, output)
	elseif small == 1 then
		local u, v = OTHER[small_axis + 1][1], OTHER[small_axis + 1][2]
		local best: V = { 0.0, 0.0, 0.0, 0.0 }
		local score = 0.0
		for i, sign in SIGNS do
			local point = madd(
				axes[v + 1],
				f32(half[v + 1] * sign[2]),
				madd(axes[u + 1], f32(half[u + 1] * sign[1]), center)
			)
			local projected = dot(point, direction)
			if i == 1 or projected > score then
				best = point
				score = projected
			end
		end
		local negative = sub(best, scale(axes[small_axis + 1], half[small_axis + 1]))
		local positive = madd(axes[small_axis + 1], half[small_axis + 1], best)
		local segment = rt.zeros(16)
		rt.copy_into(segment, 8, incoming_edge_plane)
		initialize_feature_segment(segment, bits(negative), bits(positive))
		rt.copy_into(output, 4, segment)
		output[141] = 1
	else
		local best: V = { 0.0, 0.0, 0.0, 0.0 }
		local score = 0.0
		for i = 0, 7 do
			local sign = if i > 3 then 1.0 else -1.0
			local pair = SIGNS[(i % 4) + 1]
			local point = madd(
				axes[3],
				f32(half[3] * pair[2]),
				madd(axes[2], f32(half[2] * pair[1]), madd(axes[1], f32(half[1] * sign), center))
			)
			local projected = dot(point, direction)
			if i == 0 or projected > score then
				best = point
				score = projected
			end
		end
		store(output, 136, best)
		output[141] = 0
	end
	output[1] = 0
end

return box_feature
