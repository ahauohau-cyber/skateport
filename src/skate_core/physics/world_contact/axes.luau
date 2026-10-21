--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/axes.rs (коммит 2e16697)

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local arithmetic = require("./arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate

local axes = {}

type V = { number }

-- fn load(gp: &[u32; 48], offset: usize) -> V
local function load(gp: { number }, offset: number): V
	return { from_bits(gp[offset + 1]), from_bits(gp[offset + 2]), from_bits(gp[offset + 3]), from_bits(gp[offset + 4]) }
end
local function bits(v: V): { number }
	return { to_bits(v[1]), to_bits(v[2]), to_bits(v[3]), to_bits(v[4]) }
end
-- fn sub(a: V, b: V) -> V
local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
-- fn cross(a: V, b: V) -> V
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end
-- fn dot(a: V) -> f32
local function dot(a: V): number
	return arithmetic.dot({ a[1], a[2], a[3] }, { a[1], a[2], a[3] })
end
-- fn inverse_length(squared: f32) -> f32
local function inverse_length(squared: number): number
	local r = estimate(squared)
	for _ = 1, 2 do
		r = mul_add(f32(r * 0.5), mul_add(-squared, f32(r * r), 1.0), r)
	end
	return r
end
-- fn normalized(a: V, squared: f32) -> V
local function normalized(a: V, squared: number): V
	local reciprocal = inverse_length(squared)
	return { f32(a[1] * reciprocal), f32(a[2] * reciprocal), f32(a[3] * reciprocal), f32(a[4] * reciprocal) }
end
-- fn length(a: V) -> f32
local function length(a: V): number
	local squared = dot(a)
	if squared == 0.0 then
		return 0.0
	end
	return f32(squared * inverse_length(squared))
end

-- fn append(candidate: V, output: &mut [[u32; 4]; 16], count: &mut usize)
-- ROBLOX: возвращает новый count.
local function append(candidate: V, output: { { number } }, count: number): number
	output[count + 1] = bits(candidate)
	if length(candidate) > from_bits(0x3400_0000) then
		output[count + 1] = bits(normalized(candidate, dot(candidate)))
		count += 1
	end
	return count
end

-- Complete TU3 82ACEA30 candidate producer. GP records are the native 192-byte
-- representation: origin +0, normals +16/+32/+48, edges +64 onward, counts
-- bytes +140/+141. All four output lanes and speculative rejected stores are
-- preserved. Returns zero when the native function returns null.
-- pub fn separating_axis_candidates(a: &[u32; 48], b: &[u32; 48], output: &mut [[u32; 4]; 16]) -> usize
function axes.separating_axis_candidates(a: { number }, b: { number }, output: { { number } }): number
	local count = 0
	for _, gp in { a, b } do
		local normals = bit32.rshift(gp[36], 24)
		if normals >= 1 and normals <= 3 then
			for index = normals, 1, -1 do
				output[count + 1] = rt.slice(gp, index * 4, index * 4 + 4)
				count += 1
			end
		end
	end
	local ae = bit32.band(bit32.rshift(a[36], 16), 255)
	local be = bit32.band(bit32.rshift(b[36], 16), 255)
	assert(ae <= 3 and be <= 3, "native GP contains at most three edges")
	for i = 0, ae - 1 do
		for j = 0, be - 1 do
			local candidate = cross(load(a, 16 + 4 * i), load(b, 16 + 4 * j))
			local length_squared = dot(candidate)
			output[count + 1] = bits(candidate)
			if length_squared > from_bits(0x3a83_126f) then
				output[count + 1] = bits(normalized(candidate, length_squared))
				count += 1
			end
		end
	end
	if ae == 1 and be == 1 then
		local edge_a = load(a, 16)
		local edge_b = load(b, 16)
		local perpendicular = cross(edge_a, edge_b)
		if length(perpendicular) > from_bits(0x3400_0000) then
			-- Unlike the edge-pair loop, these two secondary directions are
			-- unconditionally normalized once the common perpendicular passes.
			for _, edge in { edge_a, edge_b } do
				local candidate = cross(edge, perpendicular)
				output[count + 1] = bits(normalized(candidate, dot(candidate)))
				count += 1
			end
		end
	end
	if count ~= 0 then
		return count
	end
	local delta = sub(load(a, 0), load(b, 0))
	if ae == 1 and be == 1 then
		local edge = load(a, 16)
		count = append(cross(cross(delta, edge), edge), output, count)
	end
	if ae + be == 1 then
		local edge = if ae ~= 0 then load(a, 16) else load(b, 16)
		count = append(cross(cross(delta, edge), edge), output, count)
	end
	if count ~= 0 then
		return count
	end
	count = append(delta, output, count)
	return count
end

return axes
