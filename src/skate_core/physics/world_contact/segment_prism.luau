--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/segment_prism.rs (коммит 2e16697)

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local point_feature = require("./point_feature")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local load, dot, sub, scale, madd, cross, normalized, reciprocal =
	prism_math.load,
	prism_math.dot,
	prism_math.sub,
	prism_math.scale,
	prism_math.madd,
	prism_math.cross,
	prism_math.normalized,
	prism_math.reciprocal
local bits = prism_math.bits
local closest_feature_segment = point_feature.closest_feature_segment
local wrapping_add_u32, wrapping_sub_u32 = rt.wrapping_add_u32, rt.wrapping_sub_u32

local segment_prism = {}

type V = { number }

local function store(output: { number }, offset: number, point: V)
	rt.copy_into(output, offset, bits(point))
end

-- fn endpoint(feature: &mut MaximumFeature, start: bool) -> V
local function endpoint(feature: { number }, start: boolean): V
	feature[1] = if start then wrapping_sub_u32(feature[1], 1) else wrapping_add_u32(feature[1], 1)
	local origin = load(feature, 4)
	if start then
		return origin
	end
	local direction = load(feature, 8)
	local length = load(feature, 16)
	return {
		mul_add(direction[1], length[1], origin[1]),
		mul_add(direction[2], length[2], origin[2]),
		mul_add(direction[3], length[3], origin[3]),
		mul_add(direction[4], length[4], origin[4]),
	}
end

-- Complete TU3 82ACBAD0 segment/segment prism, including the parallel overlap
-- and disjoint endpoint branches. Normal/flags and untouched point slots survive.
-- `a_is_first` represents the helper's two independently supplied output pointers.
-- pub fn intersect_feature_segments(output, a: &mut MaximumFeature, b: &mut MaximumFeature, normal: [u32; 4], a_is_first: bool) -> u32
function segment_prism.intersect_feature_segments(
	output: { number },
	a: { number },
	b: { number },
	normal_bits: { number },
	a_is_first: boolean
): number
	local ao, bo
	if a_is_first then
		ao, bo = 0, 64
	else
		ao, bo = 64, 0
	end
	local ad = load(a, 8)
	local bd = load(b, 8)
	local start_a = load(a, 4)
	local start_b = load(b, 4)
	local perpendicular = cross(ad, bd)
	if dot(perpendicular, perpendicular) > from_bits(0x3400_0000) then
		local plane = cross(normalized(perpendicular), bd)
		local along = f32(dot(sub(start_b, start_a), plane) / dot(ad, plane))
		if along < 0.0 then
			along = 0.0
		end
		local length = load(a, 16)
		if along > length[1] and along > length[2] and along > length[3] and along > length[4] then
			along = length[1]
		end
		output[133] = 1
		local point = bits(madd(ad, along, start_a))
		local region = closest_feature_segment(rt.slice(b, 4, 20), point)
		b[1] = wrapping_add_u32(wrapping_sub_u32(b[1], region), 2)
		rt.copy_into(output, bo, point)
		region = closest_feature_segment(rt.slice(a, 4, 20), point)
		a[1] = wrapping_add_u32(wrapping_sub_u32(a[1], region), 2)
		rt.copy_into(output, ao, point)
		return 1
	end
	local normal = { from_bits(normal_bits[1]), from_bits(normal_bits[2]), from_bits(normal_bits[3]), from_bits(normal_bits[4]) }
	local axis = if math.abs(dot(normal, ad)) < math.abs(dot(normal, bd)) then ad else bd
	local al = load(a, 16)
	local bl = load(b, 16)
	local end_a, end_b = {}, {}
	for i = 1, 4 do
		end_a[i] = mul_add(ad[i], al[i], start_a[i])
		end_b[i] = mul_add(bd[i], bl[i], start_b[i])
	end
	local a0 = dot(axis, start_a)
	local b0 = dot(axis, start_b)
	local a1 = dot(axis, end_a)
	local b1 = dot(axis, end_b)
	-- Native compare/select ordering also specifies unordered/equal operands.
	local amin, amax
	if a1 > a0 then
		amin, amax = a0, a1
	else
		amin, amax = a1, a0
	end
	local bmin, bmax
	if b1 > b0 then
		bmin, bmax = b0, b1
	else
		bmin, bmax = b1, b0
	end
	local low = if amin > bmin then amin else bmin
	local high = if bmax > amax then amax else bmax
	if high > low then
		local ap = normalized(cross(cross(normal, ad), ad))
		local bp = normalized(cross(cross(normal, bd), bd))
		for k, along in { low, high } do
			local index = k - 1
			local anchor = scale(axis, along)
			for _, item in { { ao, start_a, ad, ap }, { bo, start_b, bd, bp } } do
				local offset: number, origin: V, direction: V, plane: V = item[1] :: any, item[2] :: any, item[3] :: any, item[4] :: any
				local inverse = reciprocal(dot(normal, plane))
				local distance = f32(inverse * dot(sub(origin, anchor), plane))
				local projected = madd(normal, distance, anchor)
				projected = madd(direction, dot(sub(projected, origin), direction), origin)
				store(output, offset + index * 4, projected)
			end
		end
		output[133] = 2
	else
		output[133] = 1
		local a_start, b_start
		if bmin > amin then
			a_start, b_start = a0 > a1, b0 < b1
		else
			a_start, b_start = a0 < a1, b0 > b1
		end
		store(output, ao, endpoint(a, a_start))
		store(output, bo, endpoint(b, b_start))
	end
	return 1
end

return segment_prism
