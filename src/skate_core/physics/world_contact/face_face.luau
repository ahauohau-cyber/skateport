--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/face_face.rs (коммит 2e16697)
-- В Rust это подмодуль dispatch (`#[path = "face_face.rs"] mod face_face`).

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local face_edge = require("./face_edge")

local f32 = rt.f32
local mul_add = rt.mul_add
local load, dot, sub, scale, madd, inverse_length =
	prism_math.load, prism_math.dot, prism_math.sub, prism_math.scale, prism_math.madd, prism_math.inverse_length
local bits = prism_math.bits
local intersect_feature_corner_edge = face_edge.intersect_feature_corner_edge
local MIN_POSITIVE = rt.F32_MIN_POSITIVE
local F32_MAX = rt.F32_MAX

local face_face = {}

type V = { number }

local OUTSIDE_A = 0x4000_0000
local OUTSIDE_B = 0x2000_0000

-- fn vertex(feature: &MaximumFeature, index: usize) -> V
local function vertex(feature: { number }, index: number): V
	return load(feature, 4 + index * 16)
end

-- fn plane_distance(feature: &MaximumFeature, edge: usize, point: V) -> f32
local function plane_distance(feature: { number }, edge: number, point: V): number
	return dot(load(feature, 12 + edge * 16), sub(point, vertex(feature, edge)))
end

-- fn project_to_face(face: &MaximumFeature, point: V) -> V
local function project_to_face(face: { number }, point: V): V
	local normal = load(face, 132)
	return madd(normal, dot(normal, sub(vertex(face, 0), point)), point)
end

-- fn append(output: &mut FeaturePrism, a: V, b: V)
local function append(output: { number }, a: V, b: V)
	local offset = output[133] * 4
	assert(offset < 64, "feature prism point capacity exceeded")
	rt.copy_into(output, offset, bits(a))
	rt.copy_into(output, 64 + offset, bits(b))
	output[133] += 1
end

-- General convex-face branch at 82ACE3D8, after specialized paths decline.
-- Retains native candidate order: B vertices, edge crossings, then A vertices.
-- Plane-touching vertices/crossings are included without deduplication here.
-- pub(super) fn intersect(output: &mut FeaturePrism, a: &mut MaximumFeature, b: &mut MaximumFeature) -> u32
function face_face.intersect(output: { number }, a: { number }, b: { number }): number
	local a_count, b_count = a[141], b[141]
	-- ROBLOX: masks[k] из Rust лежит в masks[k + 1].
	local masks = rt.zeros(8)
	local nearest_corner = 0
	local nearest_edge = 0
	local edge_is_a = false
	local largest_minimum = -F32_MAX
	output[133] = 0

	for edge = 0, a_count - 1 do
		local previous = b_count - 1
		local previous_distance = plane_distance(a, edge, vertex(b, previous))
		local minimum = previous_distance
		local minimum_corner = previous
		for corner = 0, b_count - 1 do
			local distance = plane_distance(a, edge, vertex(b, corner))
			if distance < minimum then
				minimum = distance
				minimum_corner = corner
			end
			if distance > 0.0 then
				masks[corner + 1] = bit32.bor(masks[corner + 1], OUTSIDE_B)
			end
			if not (f32(distance * previous_distance) > 0.0) then
				masks[previous + 1] = bit32.bor(masks[previous + 1], bit32.lshift(1, edge))
			end
			previous = corner
			previous_distance = distance
		end
		if minimum > largest_minimum then
			largest_minimum = minimum
			nearest_corner = minimum_corner
			nearest_edge = edge
			edge_is_a = true
		end
	end

	for corner = 0, b_count - 1 do
		if bit32.band(masks[corner + 1], OUTSIDE_B) == 0 then
			local point = vertex(b, corner)
			append(output, project_to_face(a, point), point)
		end
	end
	-- Containment is an early return; it must not duplicate all of A's vertices
	-- when coincident faces have already contributed every B vertex.
	if output[133] == b_count then
		return 1
	end

	for edge = 0, b_count - 1 do
		local previous = a_count - 1
		local previous_distance = plane_distance(b, edge, vertex(a, previous))
		local minimum = previous_distance
		local minimum_corner = previous
		for corner = 0, a_count - 1 do
			local distance = plane_distance(b, edge, vertex(a, corner))
			if distance < minimum then
				minimum = distance
				minimum_corner = corner
			end
			if distance > 0.0 then
				masks[corner + 1] = bit32.bor(masks[corner + 1], OUTSIDE_A)
			end
			local difference = f32(previous_distance - distance)
			if
				not (f32(distance * previous_distance) > 0.0)
				and bit32.band(masks[edge + 1], bit32.lshift(1, previous)) ~= 0
				and math.abs(difference) > MIN_POSITIVE
			then
				local inverse_difference = f32(1.0 / difference)
				local origin = vertex(a, previous)
				local direction = load(a, 8 + previous * 16)
				local length = load(a, 16 + previous * 16)
				local point = {}
				for lane = 1, 4 do
					local numerator = f32(length[lane] * previous_distance)
					local along = f32(inverse_difference * numerator)
					point[lane] = mul_add(direction[lane], along, origin[lane])
				end
				append(output, point, project_to_face(b, point))
			end
			previous = corner
			previous_distance = distance
		end
		if minimum > largest_minimum then
			largest_minimum = minimum
			nearest_corner = minimum_corner
			nearest_edge = edge
			edge_is_a = false
		end
	end
	for corner = 0, a_count - 1 do
		if bit32.band(masks[corner + 1], OUTSIDE_A) == 0 then
			local point = vertex(a, corner)
			append(output, point, project_to_face(b, point))
		end
	end
	if output[133] == 0 then
		if edge_is_a then
			output[133] = intersect_feature_corner_edge(output, b, a, nearest_corner, nearest_edge, false)
		else
			output[133] = intersect_feature_corner_edge(output, a, b, nearest_corner, nearest_edge, true)
		end
		local delta = sub(load(output, 64), load(output, 0))
		local squared = dot(delta, delta)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse_length(squared))
		if length > MIN_POSITIVE then
			rt.copy_into(output, 128, bits(scale(delta, f32(1.0 / length))))
			output[134] = 1
		end
	end
	return 1
end

return face_face
