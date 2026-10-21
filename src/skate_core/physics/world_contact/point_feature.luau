--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/point_feature.rs (коммит 2e16697)

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local wrapping_add_u32 = rt.wrapping_add_u32

local point_feature = {}

-- fn load(words: &[u32], offset: usize) -> [f32; 4]
local function load(words: { number }, offset: number): { number }
	return {
		from_bits(words[offset + 1]),
		from_bits(words[offset + 2]),
		from_bits(words[offset + 3]),
		from_bits(words[offset + 4]),
	}
end

-- fn dot3(a: [f32; 4], b: [f32; 4]) -> f32
local function dot3(a: { number }, b: { number }): number
	return arithmetic.dot({ a[1], a[2], a[3] }, { b[1], b[2], b[3] })
end

-- Complete TU3 82AC6EE8. Region codes are before=1, interior=2, after=3.
-- The upper-end comparison tests all four length lanes; equality is interior.
-- pub fn closest_feature_segment(segment: &[u32; 16], point: &mut [u32; 4]) -> u32
-- ROBLOX: point — таблица из 4 слов, меняется на месте.
function point_feature.closest_feature_segment(segment: { number }, point: { number }): number
	local origin = load(segment, 0)
	local direction = load(segment, 4)
	local p = { from_bits(point[1]), from_bits(point[2]), from_bits(point[3]), from_bits(point[4]) }
	local along = dot3({ f32(p[1] - origin[1]), f32(p[2] - origin[2]), f32(p[3] - origin[3]), f32(p[4] - origin[4]) }, direction)
	if 0.0 > along then
		for i = 1, 4 do
			point[i] = segment[i]
		end
		return 1
	end
	local length = load(segment, 12)
	local after = along > length[1] and along > length[2] and along > length[3] and along > length[4]
	for i = 1, 4 do
		point[i] = to_bits(mul_add(direction[i], if after then length[i] else along, origin[i]))
	end
	return if after then 3 else 2
end

-- Complete TU3 82ACC160 point/face helper. `face_is_a` selects its two native
-- destination pointers within the prism; normal and untouched records survive.
-- The face header receives the selected edge index and segment-region code.
-- pub fn intersect_point_face(output: &mut FeaturePrism, face: &mut MaximumFeature, point: &MaximumFeature, normal: [u32; 4], face_is_a: bool) -> u32
function point_feature.intersect_point_face(
	output: { number },
	face: { number },
	point: { number },
	normal_bits: { number },
	face_is_a: boolean
): number
	output[133] = 1
	local p = load(point, 136)
	local normal = { from_bits(normal_bits[1]), from_bits(normal_bits[2]), from_bits(normal_bits[3]), from_bits(normal_bits[4]) }
	local origin = load(face, 4)
	local distance =
		dot3(normal, { f32(origin[1] - p[1]), f32(origin[2] - p[2]), f32(origin[3] - p[3]), f32(origin[4] - p[4]) })
	local projected = {
		mul_add(normal[1], distance, p[1]),
		mul_add(normal[2], distance, p[2]),
		mul_add(normal[3], distance, p[3]),
		mul_add(normal[4], distance, p[4]),
	}
	if rt.to_i32(face[141]) > 0 then
		local count = face[141]
		assert(count <= 8, "native maximum-feature storage exceeded")
		local selected = 0
		local worst = 0.0
		for edge = 0, count - 1 do
			local start = load(face, 4 + edge * 16)
			local plane = load(face, 12 + edge * 16)
			local value = dot3(plane, {
				f32(projected[1] - start[1]),
				f32(projected[2] - start[2]),
				f32(projected[3] - start[3]),
				f32(projected[4] - start[4]),
			})
			if edge == 0 or value > worst then
				worst = value
				selected = edge
			end
		end
		if worst > 0.0 then
			local plane = load(face, 12 + selected * 16)
			local projected_bits = {}
			for i = 1, 4 do
				projected_bits[i] = to_bits(f32(projected[i] - f32(plane[i] * worst)))
			end
			local segment = rt.slice(face, 4 + selected * 16, 20 + selected * 16)
			local region = point_feature.closest_feature_segment(segment, projected_bits)
			face[1] = wrapping_add_u32(face[1], selected * 2 + region)
			projected = {
				from_bits(projected_bits[1]),
				from_bits(projected_bits[2]),
				from_bits(projected_bits[3]),
				from_bits(projected_bits[4]),
			}
		end
	end
	local face_offset, point_offset
	if face_is_a then
		face_offset, point_offset = 0, 64
	else
		face_offset, point_offset = 64, 0
	end
	rt.copy_into(output, face_offset, { to_bits(projected[1]), to_bits(projected[2]), to_bits(projected[3]), to_bits(projected[4]) })
	rt.copy_range(output, point_offset, point, 136, 140)
	return 1
end

return point_feature
