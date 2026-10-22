--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/dispatch.rs (коммит 2e16697)

local rt = require("../../../rt")
local point_feature = require("./point_feature")
local segment_prism = require("./segment_prism")
local segment_face = require("./segment_face")
local face_face = require("./face_face")
local face_specialized = require("./face_specialized")

local wrapping_add_u32, wrapping_sub_u32 = rt.wrapping_add_u32, rt.wrapping_sub_u32
local closest_feature_segment = point_feature.closest_feature_segment
local intersect_point_face = point_feature.intersect_point_face
local intersect_feature_segments = segment_prism.intersect_feature_segments
local intersect_segment_face = segment_face.intersect_segment_face

local dispatch = {}

-- fn segment_point(output, segment: &mut MaximumFeature, point: &MaximumFeature, segment_is_a: bool) -> u32
local function segment_point(output: { number }, segment: { number }, point: { number }, segment_is_a: boolean): number
	output[133] = 1
	rt.copy_range(output, 0, point, 136, 140)
	rt.copy_range(output, 64, point, 136, 140)
	local offset = if segment_is_a then 0 else 64
	-- ROBLOX: &mut output[offset..offset + 4] — копируем срез, вызываем, пишем обратно.
	local target = rt.slice(output, offset, offset + 4)
	local region = closest_feature_segment(rt.slice(segment, 4, 20), target)
	rt.copy_into(output, offset, target)
	segment[1] = wrapping_add_u32(wrapping_sub_u32(segment[1], region), 2)
	return 1
end

-- TU3 82ACE190, FindFeatureIntersectionPrism. Features contain a point (zero
-- edges), segment (one), or convex face. Both feature tags may be updated by
-- closest-feature selection. The caller owns the initial normal/override flag;
-- they change only when the recovered helpers explicitly correct the normal.
--
-- Numerical helpers retain the core's current host arithmetic approximation;
-- this source port has not been compared with a Skate 3 hardware capture.
-- pub fn find_feature_intersection_prism(output: &mut FeaturePrism, a: &mut MaximumFeature, b: &mut MaximumFeature, normal: [u32; 4]) -> u32
function dispatch.find_feature_intersection_prism(output: { number }, a: { number }, b: { number }, normal: { number }): number
	local a_edges, b_edges = a[141], b[141]
	assert(a_edges <= 8 and b_edges <= 8, "maximum-feature storage exceeded")
	if a_edges == 0 and b_edges == 0 then
		output[133] = 1
		rt.copy_range(output, 0, a, 136, 140)
		rt.copy_range(output, 64, b, 136, 140)
		return 1
	elseif a_edges == 1 and b_edges == 0 then
		return segment_point(output, a, b, true)
	elseif a_edges == 0 and b_edges == 1 then
		return segment_point(output, b, a, false)
	elseif a_edges == 0 then
		return intersect_point_face(output, b, a, normal, false)
	elseif b_edges == 0 then
		return intersect_point_face(output, a, b, normal, true)
	elseif a_edges == 1 and b_edges == 1 then
		return intersect_feature_segments(output, a, b, normal, true)
	elseif a_edges == 1 then
		return intersect_segment_face(output, b, a, normal, false)
	elseif b_edges == 1 then
		return intersect_segment_face(output, a, b, normal, true)
	elseif a_edges == 4 and b_edges == 3 then
		if face_specialized.quad_triangle(output, a, b, normal, true) ~= 0 then
			return 1
		end
	elseif a_edges == 3 and b_edges == 4 then
		if face_specialized.quad_triangle(output, b, a, normal, false) ~= 0 then
			return 1
		end
	elseif a_edges == 4 and b_edges == 4 then
		if face_specialized.quad_quad(output, a, b, normal) ~= 0 then
			return 1
		end
	end
	return face_face.intersect(output, a, b)
end

return dispatch
