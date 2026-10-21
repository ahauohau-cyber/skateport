--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/sphere_triangle.rs (коммит 2e16697)
--
-- Sphere/triangle execution path of PrimitivePairIntersect (82AD3CD8).
-- Both primitive orders, two-sided geometry, finite edges, vertices, fatness,
-- separating-direction refinement and complete triangle fixups are preserved.
--
-- ROBLOX: Option<T> -> значение или nil. Номера рёбер/вершин — как в Rust
-- (с нуля); к массивам обращаемся с +1.

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")
local fixup = require("./fixup")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot, cross, sub, scale, neg, madd, inverse_length_squared =
	arithmetic.dot,
	arithmetic.cross,
	arithmetic.sub,
	arithmetic.scale,
	arithmetic.neg,
	arithmetic.madd,
	arithmetic.inverse_length_squared
local fix_up_triangle = fixup.fix_up_triangle
local ContactPair = fixup.ContactPair

local sphere_triangle = {}

-- pub struct Sphere { center: Vector3, radius: f32 }
export type Sphere = {
	center: vector,
	radius: number,
}

-- A world-space GPTriangle. Normal, unit directions and lengths are produced
-- by the native collision-geometry loader; rendering normals are not suitable.
export type Triangle = {
	vertices: { vector }, -- [Vector3; 3]
	feature: fixup.TriangleFeature,
	edge_lengths: { number }, -- [f32; 3]
	fatness: number,
}

export type SphereTrianglePair = {
	separating_direction: vector,
	separating_distance: number,
	-- Pair normal points from primitive A toward primitive B. The downstream
	-- physics contact producer owns its conversion to solver normal convention.
	normal: vector,
	points: fixup.ContactPair,
	distance: number,
	triangle_region: number, -- u32
}

-- pub(super) struct SphereTrianglePrism
export type SphereTrianglePrism = {
	separating_direction: vector,
	separating_distance: number,
	normal: vector,
	raw_points: fixup.ContactPair,
	triangle_region: number,
}

-- fn min(a: f32, b: f32) -> f32
local function min(a: number, b: number): number
	return if a < b then a else b
end

-- fn max(a: f32, b: f32) -> f32
local function max(a: number, b: number): number
	return if a > b then a else b
end

-- fn interval_gaps(sphere, triangle, direction, triangle_is_a) -> (f32, f32)
local function interval_gaps(sphere: Sphere, triangle: Triangle, direction: vector, triangle_is_a: boolean): (number, number)
	-- 82ADD800 / 82ADE3B8. GP intervals exclude primitive fatness.
	local s = dot(direction, sphere.center)
	local p = {
		dot(direction, triangle.vertices[1]),
		dot(direction, triangle.vertices[2]),
		dot(direction, triangle.vertices[3]),
	}
	local lo = min(min(p[1], p[2]), p[3])
	local hi = max(max(p[1], p[2]), p[3])
	if triangle_is_a then
		return f32(lo - s), f32(s - hi)
	else
		return f32(s - hi), f32(lo - s)
	end
end

-- fn point_face(point, t, axis, triangle_is_a) -> (Vector3, u32)
local function point_face(point: vector, t: Triangle, axis: vector, triangle_is_a: boolean): (vector, number)
	-- The sphere contributes no axes or edges (82ACEA30), so the selected
	-- direction is the triangle face normal. Thus GetMaximumFeature's face
	-- branch is the complete reachable branch for this primitive pair.
	local query = if triangle_is_a then axis else neg(axis)
	local same = (dot(query, t.feature.normal) < 0.0) == triangle_is_a
	local indices = if same then { 0, 1, 2 } else { 2, 1, 0 }
	local vertices = if same then { 0, 2, 1 } else { 0, 1, 2 }
	local region = if same then 8 else 0
	local projected = madd(axis, dot(axis, sub(t.vertices[1], point)), point)
	local best = 0
	local violation = 0.0
	local planes = {}
	for k, i in indices do
		local direction = if same then t.feature.edges[i + 1] else neg(t.feature.edges[i + 1])
		local plane = cross(direction, axis)
		local squared = dot(plane, plane)
		-- Feature::BuildEdgePlanes (82AC6F88): one refinement and select-zero.
		-- CRT initializer 82F837D8 copies 8212BF78 into 830BDD40. The mapped
		-- image alone contains zero here; live TU3 uses 0x34000000.
		planes[k] = scale(plane, if squared > from_bits(0x3400_0000) then inverse_length_squared(squared, 1) else 0.0)
	end
	for i = 0, 2 do
		local d = dot(planes[i + 1], sub(projected, t.vertices[vertices[i + 1] + 1]))
		if i == 0 or d > violation then
			best = i
			violation = d
		end
	end
	if violation > 0.0 then
		projected = sub(projected, scale(planes[best + 1], violation))
		local i = indices[best + 1]
		local base = t.vertices[vertices[best + 1] + 1]
		local direction = if same then t.feature.edges[i + 1] else neg(t.feature.edges[i + 1])
		local along = dot(sub(projected, base), direction)
		local p, r
		if along < 0.0 then
			p, r = base, 1
		elseif along > t.edge_lengths[i + 1] then
			p, r = madd(direction, t.edge_lengths[i + 1], base), 3
		else
			p, r = madd(direction, along, base), 2
		end
		projected = p
		region += best * 2 + r
	end
	return projected, region
end

-- Shared SAT/features/prism work. The two native callers have different
-- single-point refinement gates and publish their results in different order.
-- pub(super) fn build_prism(...) -> Option<SphereTrianglePrism>
function sphere_triangle.build_prism(
	sphere: Sphere,
	triangle: Triangle,
	minimum_separating_distance: number,
	triangle_is_a: boolean,
	contact_query: boolean
): SphereTrianglePrism?
	local axis = triangle.feature.normal
	local a, b = interval_gaps(sphere, triangle, axis, triangle_is_a)
	-- 82ACF070 chooses the second gap on ties.
	local separating_direction, separating_distance
	if a > b then
		separating_direction, separating_distance = neg(axis), a
	else
		separating_direction, separating_distance = axis, b
	end
	local fat_a, fat_b
	if triangle_is_a then
		fat_a, fat_b = triangle.fatness, sphere.radius
	else
		fat_a, fat_b = sphere.radius, triangle.fatness
	end
	if separating_distance > f32(f32(fat_b + minimum_separating_distance) + fat_a) then
		return nil
	end
	local face_point, triangle_region = point_face(sphere.center, triangle, separating_direction, triangle_is_a)
	local raw_points: fixup.ContactPair
	if triangle_is_a then
		raw_points = { a = face_point, b = sphere.center }
	else
		raw_points = { a = sphere.center, b = face_point }
	end
	local delta = sub(raw_points.b, raw_points.a)
	local squared = dot(delta, delta)
	local inverse_length = inverse_length_squared(squared, 2)
	local gate
	if contact_query then
		-- 8277B830..B8A8 tests the refined LENGTH, whereas 82AD3CD8 tests
		-- squared length. Both compare against the literal 821408EC.
		gate = if squared == 0.0 then 0.0 else f32(squared * inverse_length)
	else
		gate = squared
	end
	local normal = separating_direction
	if gate > from_bits(0x3400_0000) then
		local candidate = scale(delta, inverse_length)
		local ca, cb = interval_gaps(sphere, triangle, candidate, triangle_is_a)
		local maximum = if ca > cb then ca else cb
		if separating_distance <= maximum then
			normal = if ca > cb then neg(candidate) else candidate
		end
	end
	return {
		separating_direction = separating_direction,
		separating_distance = separating_distance,
		normal = normal,
		raw_points = raw_points,
		triangle_region = triangle_region,
	}
end

-- Native pair query on already-built GP primitives. `triangle_is_a` selects
-- primitive order. An accepted candidate can have positive distance: filtering
-- candidate contacts belongs to the caller, just as in TU3.
-- pub fn intersect_sphere_triangle(...) -> Option<SphereTrianglePair>
function sphere_triangle.intersect_sphere_triangle(
	sphere: Sphere,
	triangle: Triangle,
	minimum_separating_distance: number,
	triangle_is_a: boolean
): SphereTrianglePair?
	local prism = sphere_triangle.build_prism(sphere, triangle, minimum_separating_distance, triangle_is_a, false)
	if prism == nil then
		return nil
	end
	local separating_direction = prism.separating_direction
	local separating_distance = prism.separating_distance
	local normal = prism.normal
	local raw_points = prism.raw_points
	local triangle_region = prism.triangle_region
	local fat_a, fat_b
	if triangle_is_a then
		fat_a, fat_b = triangle.fatness, sphere.radius
	else
		fat_a, fat_b = sphere.radius, triangle.fatness
	end
	local points: fixup.ContactPair = {
		a = madd(normal, fat_a, raw_points.a),
		b = sub(raw_points.b, scale(normal, fat_b)),
	}
	local distance = dot(sub(points.b, points.a), normal)
	-- 82AD40C0..4308 publishes points/fatness/distances BEFORE fixup. The
	-- fixup's reprojection edits its local prism; TU3 does not recopy those
	-- points into this result. Only the result normal is shared with fixup.
	local settings: fixup.TriangleFixup = {
		reverse = not triangle_is_a,
		edge_cos_bend_normal_threshold = -1.0,
		convexity_epsilon = 0.0,
		is_object = false,
	}
	-- ROBLOX: &mut [raw_points] — временный массив с копией пары.
	local accepted
	accepted, normal = fix_up_triangle(triangle.feature, normal, { ContactPair.copy(raw_points) }, settings)
	if not accepted then
		return nil
	end
	return {
		separating_direction = separating_direction,
		separating_distance = separating_distance,
		normal = normal,
		points = points,
		distance = distance,
		triangle_region = triangle_region,
	}
end

return sphere_triangle
