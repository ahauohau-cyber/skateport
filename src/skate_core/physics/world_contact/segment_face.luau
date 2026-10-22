--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/segment_face.rs (коммит 2e16697)

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local face_clip = require("./face_clip")
local point_feature = require("./point_feature")

local f32 = rt.f32
local from_bits = rt.from_bits
local load, dot, sub, madd, cross, normalized, inverse_length =
	prism_math.load,
	prism_math.dot,
	prism_math.sub,
	prism_math.madd,
	prism_math.cross,
	prism_math.normalized,
	prism_math.inverse_length
local bits = prism_math.bits
local clamp_point_to_feature = face_clip.clamp_point_to_feature
local clip_segment_to_feature = face_clip.clip_segment_to_feature
local closest_feature_segment = point_feature.closest_feature_segment
local wrapping_add_u32, wrapping_sub_u32 = rt.wrapping_add_u32, rt.wrapping_sub_u32
local MIN_POSITIVE = rt.F32_MIN_POSITIVE

local segment_face = {}

type V = { number }

local function store(output: { number }, offset: number, point: V)
	rt.copy_into(output, offset, bits(point))
end

local function floats(words: { number }): V
	return { from_bits(words[1]), from_bits(words[2]), from_bits(words[3]), from_bits(words[4]) }
end

-- Complete TU3 82ACC5F0 segment/face prism and its interval/edge-clamp callees.
-- Keeps the normal correction flag, feature tags and both output-pointer orders.
-- pub fn intersect_segment_face(output, face: &mut MaximumFeature, segment: &mut MaximumFeature, normal_bits: [u32; 4], face_is_a: bool) -> u32
function segment_face.intersect_segment_face(
	output: { number },
	face: { number },
	segment: { number },
	normal_bits: { number },
	face_is_a: boolean
): number
	local fo, so
	if face_is_a then
		fo, so = 0, 64
	else
		fo, so = 64, 0
	end
	local interval = { 0, 0 }
	-- The native caller explicitly zeroes both scratch vectors before clipping.
	local outside = rt.zeros(8)
	local inside = clip_segment_to_feature(face, segment, normal_bits, interval, outside)
	local normal = floats(normal_bits)
	local origin = load(segment, 4)
	local direction = load(segment, 8)
	local face_origin = load(face, 4)
	local low = from_bits(interval[1])
	local high = from_bits(interval[2])
	if inside ~= 0 then
		output[133] = 2
		local face_normal = load(face, 132)
		for k, distance in { low, high } do
			local i = k - 1
			local p = madd(direction, distance, origin)
			store(output, so + i * 4, p)
			local t = f32(dot(sub(face_origin, p), face_normal) / dot(normal, face_normal))
			store(output, fo + i * 4, madd(normal, t, p))
		end
		return 1
	end
	local span = f32(high - low)
	if span > from_bits(0x3a83_126f) then
		output[133] = 2
		local outside_origin = load(outside, 0)
		local outside_plane = load(outside, 4)
		local projected = madd(normal, dot(normal, sub(face_origin, origin)), origin)
		projected = madd(outside_plane, dot(outside_plane, sub(outside_origin, projected)), projected)
		local first_point = madd(direction, low, projected)
		local second_point = madd(direction, span, first_point)
		local first = bits(first_point)
		local second = bits(second_point)
		local first_code = clamp_point_to_feature(face, normal_bits, first)
		local second_code = clamp_point_to_feature(face, normal_bits, second)
		-- face[0].wrapping_add(first_code.max(second_code) & !1)
		face[1] = wrapping_add_u32(face[1], bit32.band(math.max(first_code, second_code), bit32.bnot(1)))
		rt.copy_into(output, fo, first)
		rt.copy_into(output, fo + 4, second)
		closest_feature_segment(rt.slice(segment, 4, 20), first)
		closest_feature_segment(rt.slice(segment, 4, 20), second)
		rt.copy_into(output, so, first)
		rt.copy_into(output, so + 4, second)
		local delta = sub(load(output, fo), floats(first))
		local squared = dot(delta, delta)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse_length(squared))
		if length > MIN_POSITIVE then
			output[134] = 1
			store(output, 128, normalized(cross(direction, cross(delta, direction))))
		end
	else
		output[133] = 1
		local p0 = madd(direction, low, origin)
		local p = bits(madd(normal, dot(normal, sub(face_origin, p0)), p0))
		local code = clamp_point_to_feature(face, normal_bits, p)
		face[1] = wrapping_add_u32(face[1], code)
		rt.copy_into(output, fo, p)
		local region = closest_feature_segment(rt.slice(segment, 4, 20), p)
		segment[1] = wrapping_add_u32(wrapping_sub_u32(segment[1], region), 2)
		rt.copy_into(output, so, p)
	end
	return 1
end

return segment_face
