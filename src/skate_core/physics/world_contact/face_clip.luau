--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/face_clip.rs (коммит 2e16697)

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local point_feature = require("./point_feature")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local load, dot, sub, scale, cross, normalized =
	prism_math.load, prism_math.dot, prism_math.sub, prism_math.scale, prism_math.cross, prism_math.normalized
local closest_feature_segment = point_feature.closest_feature_segment

local face_clip = {}

local function floats(words: { number }): { number }
	return { from_bits(words[1]), from_bits(words[2]), from_bits(words[3]), from_bits(words[4]) }
end

-- Complete TU3 82ACC298. Projects an exterior point onto the selected edge;
-- returns its edge/region code without modifying the feature header itself.
-- pub fn clamp_point_to_feature(face: &MaximumFeature, normal: [u32; 4], point: &mut [u32; 4]) -> u32
function face_clip.clamp_point_to_feature(face: { number }, normal_bits: { number }, point: { number }): number
	local normal = floats(normal_bits)
	local p = floats(point)
	local count = math.max(rt.to_i32(face[141]), 0)
	assert(count <= 8, "native maximum-feature storage exceeded")
	local selected = 0
	local minimum = 0.0
	local selected_plane = { 0.0, 0.0, 0.0, 0.0 }
	for edge = 0, count - 1 do
		local plane = cross(normal, load(face, 8 + edge * 16))
		if dot(plane, plane) > from_bits(0x3400_0000) then
			plane = normalized(plane)
		end
		local value = dot(plane, sub(p, load(face, 4 + edge * 16)))
		if edge == 0 or minimum > value then
			minimum = value
			selected = edge
			selected_plane = plane
		end
	end
	if 0.0 > minimum then
		local moved = sub(p, scale(selected_plane, minimum))
		for i = 1, 4 do
			point[i] = to_bits(moved[i])
		end
		return closest_feature_segment(rt.slice(face, 4 + selected * 16, 20 + selected * 16), point) + selected * 2
	else
		return 0
	end
end

-- Complete TU3 82ACC400 interval clipping. `interval` stores the two scalar
-- limits; `outside` stores the last rejecting edge origin and normalized plane.
-- Those vectors are preserved unless a near-parallel exterior edge writes them.
-- pub fn clip_segment_to_feature(face, segment, normal: [u32; 4], interval: &mut [u32; 2], outside: &mut [u32; 8]) -> u32
function face_clip.clip_segment_to_feature(
	face: { number },
	segment: { number },
	normal_bits: { number },
	interval: { number },
	outside: { number }
): number
	interval[1] = 0
	-- lfs/stfs quiet an input signalling NaN in the scalar length field.
	local length_word = segment[17]
	local length_value = from_bits(length_word)
	interval[2] = if length_value ~= length_value then bit32.bor(length_word, 0x0040_0000) else length_word
	local normal = floats(normal_bits)
	local count = math.max(rt.to_i32(face[141]), 0)
	assert(count <= 8, "native maximum-feature storage exceeded")
	local rejected = false
	for edge = 0, count - 1 do
		local plane = cross(normal, load(face, 8 + edge * 16))
		local squared = dot(plane, plane)
		local length = if squared == 0.0 then 0.0 else f32(squared * prism_math.inverse_length(squared))
		if length < from_bits(0x3a83_126f) then
			continue
		end
		plane = normalized(plane)
		local origin = load(face, 4 + edge * 16)
		local denominator = dot(load(segment, 8), plane)
		local numerator = dot(sub(origin, load(segment, 4)), plane)
		if math.abs(denominator) < from_bits(0x3d4c_cccd) then
			if numerator > 0.0 then
				rejected = true
				rt.copy_range(outside, 0, face, 4 + edge * 16, 8 + edge * 16)
				rt.copy_into(outside, 4, prism_math.bits(plane))
			end
		else
			local position = f32(numerator / denominator)
			if denominator > 0.0 then
				if position > from_bits(interval[1]) then
					interval[1] = to_bits(position)
				end
				if from_bits(interval[1]) > from_bits(interval[2]) then
					interval[1] = interval[2]
					return 0
				end
			else
				if position < from_bits(interval[2]) then
					interval[2] = to_bits(position)
				end
				if from_bits(interval[2]) < from_bits(interval[1]) then
					interval[2] = interval[1]
					return 0
				end
			end
		end
	end
	return if rejected then 0 else 1
end

return face_clip
