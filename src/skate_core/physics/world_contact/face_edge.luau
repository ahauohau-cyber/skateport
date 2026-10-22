--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/face_edge.rs (коммит 2e16697)

local rt = require("../../../rt")
local prism_math = require("./prism_math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local load, dot, sub, madd = prism_math.load, prism_math.dot, prism_math.sub, prism_math.madd
local wrapping_add_u32, wrapping_sub_u32 = rt.wrapping_add_u32, rt.wrapping_sub_u32
local MIN_POSITIVE = rt.F32_MIN_POSITIVE

local face_edge = {}

type V = { number }

-- fn store(output: &mut FeaturePrism, offset: usize, point: V)
local function store(output: { number }, offset: number, point: V)
	rt.copy_into(output, offset, prism_math.bits(point))
end

-- fn end(feature: &MaximumFeature, edge: usize) -> V
local function end_point(feature: { number }, edge: number): V
	local origin = load(feature, 4 + edge * 16)
	local direction = load(feature, 8 + edge * 16)
	local length = load(feature, 16 + edge * 16)
	return {
		mul_add(direction[1], length[1], origin[1]),
		mul_add(direction[2], length[2], origin[2]),
		mul_add(direction[3], length[3], origin[3]),
		mul_add(direction[4], length[4], origin[4]),
	}
end

-- Complete TU3 82ACCA28 corner/edge fallback. Returns one or two point pairs;
-- the caller writes the prism count. Both feature headers are replaced here.
-- pub fn intersect_feature_corner_edge(output, a: &mut MaximumFeature, b: &mut MaximumFeature, corner: usize, edge: usize, a_is_first: bool) -> u32
function face_edge.intersect_feature_corner_edge(
	output: { number },
	a: { number },
	b: { number },
	corner: number,
	edge: number,
	a_is_first: boolean
): number
	local ao, bo
	if a_is_first then
		ao, bo = 0, 64
	else
		ao, bo = 64, 0
	end
	local previous = if corner ~= 0 then corner - 1 else a[141] - 1
	-- ROBLOX: в Rust `a[140] as usize - 1` при нуле — паника переполнения; здесь previous < 0.
	assert(corner < 8 and edge < 8 and previous >= 0 and previous < 8)
	local bd = load(b, 8 + edge * 16)
	local selected = previous
	local function nearly_parallel(index: number): boolean
		return from_bits(0x3d4c_cccd) > math.abs(dot(load(a, 12 + index * 16), bd))
	end
	local parallel
	if nearly_parallel(previous) then
		parallel = true
	else
		selected = corner
		parallel = nearly_parallel(corner)
	end
	local b_origin = load(b, 4 + edge * 16)
	if not parallel then
		a[1] = corner * 2 + 1
		b[1] = (edge + 1) * 2
		local origin = load(a, 4 + corner * 16)
		local position = dot(bd, sub(origin, b_origin))
		if position < MIN_POSITIVE then
			b[1] = wrapping_sub_u32(b[1], 1)
			position = 0.0
		else
			local length = load(b, 16 + edge * 16)
			if position > length[1] and position > length[2] and position > length[3] and position > length[4] then
				b[1] = wrapping_add_u32(b[1], 1)
				position = length[1]
			end
		end
		store(output, ao, origin)
		store(output, bo, madd(bd, position, b_origin))
		return 1
	end
	a[1] = (selected + 1) * 2
	b[1] = (edge + 1) * 2
	local a_origin = load(a, 4 + selected * 16)
	local ad = load(a, 8 + selected * 16)
	local distance = dot(ad, sub(b_origin, a_origin))
	if distance < MIN_POSITIVE then
		store(output, ao, a_origin)
		store(output, bo, b_origin)
		a[1] = wrapping_sub_u32(a[1], 1)
		b[1] = wrapping_sub_u32(b[1], 1)
		return 1
	end
	local al = load(a, 16 + selected * 16)
	local bl = load(b, 16 + edge * 16)
	local all_short = true
	for i = 1, 4 do
		if not (MIN_POSITIVE > f32(f32(al[i] + bl[i]) - distance)) then
			all_short = false
			break
		end
	end
	if all_short then
		store(output, ao, end_point(a, selected))
		store(output, bo, end_point(b, edge))
		a[1] = wrapping_add_u32(a[1], 1)
		b[1] = wrapping_add_u32(b[1], 1)
		return 1
	end
	local function all_below(lengths: V): boolean
		for i = 1, 4 do
			if not (MIN_POSITIVE > f32(lengths[i] - distance)) then
				return false
			end
		end
		return true
	end
	if all_below(al) then
		store(output, ao, end_point(a, selected))
		store(output, bo, sub(b_origin, {
			f32(bd[1] * f32(al[1] - distance)),
			f32(bd[2] * f32(al[2] - distance)),
			f32(bd[3] * f32(al[3] - distance)),
			f32(bd[4] * f32(al[4] - distance)),
		}))
	else
		store(output, ao, madd(ad, distance, a_origin))
		store(output, bo, b_origin)
	end
	if all_below(bl) then
		store(output, ao + 4, sub(a_origin, {
			f32(ad[1] * f32(bl[1] - distance)),
			f32(ad[2] * f32(bl[2] - distance)),
			f32(ad[3] * f32(bl[3] - distance)),
			f32(ad[4] * f32(bl[4] - distance)),
		}))
		store(output, bo + 4, end_point(b, edge))
	else
		store(output, ao + 4, a_origin)
		store(output, bo + 4, madd(bd, distance, b_origin))
	end
	return 2
end

return face_edge
