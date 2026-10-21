--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/fixup.rs (коммит 2e16697)
--
-- Complete TU3 FixUpTriangleResult (82AD3130), including 82AD2CB0,
-- 82AD2E00 and contact-point reprojection (82AD2BF0).
--
-- ROBLOX: параметр `normal: &mut Vector3` -> функция возвращает новый normal
-- вторым значением (vector неизменяемый). `contacts: &mut [ContactPair]` —
-- таблица, меняется на месте, как в Rust.
-- Номера рёбер и вершин остаются как в Rust (0, 1, 2); при обращении к
-- массиву прибавляем 1.

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")
local edge_mod = require("./edge")

local f32 = rt.f32
local from_bits = rt.from_bits
local has_bits = rt.has_bits
local dot, cross, normalize, sub, scale, neg, madd, inverse_length_squared =
	arithmetic.dot,
	arithmetic.cross,
	arithmetic.normalize,
	arithmetic.sub,
	arithmetic.scale,
	arithmetic.neg,
	arithmetic.madd,
	arithmetic.inverse_length_squared
local edge_cos_test = edge_mod.edge_cos_test

local fixup = {}

-- pub enum TriangleRegion { Face, Edge0, Edge1, Vertex1, Edge2, Vertex0, Vertex2 }
-- ROBLOX: варианты без данных -> числа в порядке объявления.
local TriangleRegion = {
	Face = 0,
	Edge0 = 1,
	Edge1 = 2,
	Vertex1 = 3,
	Edge2 = 4,
	Vertex0 = 5,
	Vertex2 = 6,
}
fixup.TriangleRegion = TriangleRegion

-- Native GPTriangle fields +16, +64..96, +148 and +152..160.
-- Direction order is native +64, +80, +96. Adjacency cosine indices
-- refer to the reversed direction order; these arrays are not interchangeable.
export type TriangleFeature = {
	normal: vector,
	edges: { vector }, -- [Vector3; 3]
	flags: number, -- u32
	edge_cosines: { number }, -- [f32; 3]
}

local TriangleFeature = {}
fixup.TriangleFeature = TriangleFeature

TriangleFeature.ONE_SIDED = 0x10
TriangleFeature.USE_EDGE_COSINES = 0x100

-- pub const fn edge_convex(self, edge: usize) -> bool
function TriangleFeature.edge_convex(self: TriangleFeature, edge: number): boolean
	return has_bits(self.flags, bit32.lshift(0x20, edge))
end

-- pub const fn vertex_disabled(self, vertex: usize) -> bool
function TriangleFeature.vertex_disabled(self: TriangleFeature, vertex: number): boolean
	return has_bits(self.flags, bit32.lshift(0x200, vertex))
end

-- ComputeTriangleFeatureTypeFromNormal (82AD2A50), taking the normalized
-- in-plane direction produced by FixUpTriangleResult.
-- pub fn classify(self, direction: Vector3) -> TriangleRegion
function TriangleFeature.classify(self: TriangleFeature, direction: vector): number
	local a = dot(direction, self.edges[1])
	local b = dot(direction, self.edges[2])
	local c = dot(direction, self.edges[3])
	local t = from_bits(0x3D4C_CCCD)
	if a > t and b < -t then
		return TriangleRegion.Vertex2
	elseif b > t and c < -t then
		return TriangleRegion.Vertex1
	elseif c > t and a < -t then
		return TriangleRegion.Vertex0
	elseif a > -c and -b >= a then
		return TriangleRegion.Edge2
	elseif b > -a and -c >= b then
		return TriangleRegion.Edge1
	elseif c > -b and -a >= c then
		return TriangleRegion.Edge0
	else
		return TriangleRegion.Face
	end
end

-- pub struct ContactPair { a: Vector3, b: Vector3 }
export type ContactPair = {
	a: vector,
	b: vector,
}

local ContactPair = {}
fixup.ContactPair = ContactPair

-- ROBLOX: замена неявного копирования Copy-структуры.
function ContactPair.copy(pair: ContactPair): ContactPair
	return { a = pair.a, b = pair.b }
end

-- pub struct TriangleFixup
export type TriangleFixup = {
	-- Whether the triangle is the other side of the pair. This flips the
	-- input for classification and chooses which contact points to project.
	reverse: boolean,
	edge_cos_bend_normal_threshold: number,
	convexity_epsilon: number,
	-- Native r9 flag: relaxes disabled vertices and near-flat edge handling.
	is_object: boolean,
}

-- fn bend(normal: &mut Vector3, contacts: &mut [ContactPair], direction: Vector3, reverse: bool)
-- ROBLOX: возвращает новый normal.
local function bend(_normal: vector, contacts: { ContactPair }, direction: vector, reverse: boolean): vector
	local normal = if reverse then neg(direction) else direction
	for _, pair in contacts do
		if reverse then
			pair.b = madd(direction, dot(sub(pair.b, pair.a), direction), pair.a)
		else
			pair.a = madd(direction, dot(sub(pair.a, pair.b), direction), pair.b)
		end
	end
	return normal
end

-- ROBLOX: (cosine - 1.0) as f64 сравнивается с этой f64-константой.
local OBJECT_FLAT_EPSILON = rt.f64_from_bits(0x3EE4_F8B5, 0x88E3_68F1)

-- fn one_sided_edge(t, edge: usize, projection: f32, normal: &mut Vector3, contacts, s) -> bool
-- ROBLOX: возвращает (принят, normal).
local function one_sided_edge(
	t: TriangleFeature,
	edge: number,
	projection: number,
	normal: vector,
	contacts: { ContactPair },
	s: TriangleFixup
): (boolean, vector)
	local cosine = t.edge_cosines[edge + 1]
	-- Scalar fadds, not an epsilon comparison on a vector dot product.
	if
		TriangleFeature.edge_convex(t, edge)
		or (s.is_object and math.abs(f32(cosine - 1.0)) < OBJECT_FLAT_EPSILON)
	then
		return f32(projection + s.convexity_epsilon) >= cosine, normal
	end
	if cosine > s.edge_cos_bend_normal_threshold or cosine <= from_bits(0x3A83_126F) then
		return false, normal
	end
	local squared = f32(1.0 - f32(cosine * cosine))
	local threshold = if squared == 0.0 then 0.0 else f32(squared * inverse_length_squared(squared, 2))
	if projection > threshold then
		return true, bend(normal, contacts, t.normal, s.reverse)
	else
		return false, normal
	end
end

-- Returns native acceptance. A successful fixup can change both the normal
-- and one side of every contact pair. Pair count is capped at native capacity.
-- pub fn fix_up_triangle(triangle, normal: &mut Vector3, contacts: &mut [ContactPair], settings) -> bool
-- ROBLOX: возвращает (принят, normal).
function fixup.fix_up_triangle(
	triangle: TriangleFeature,
	normal: vector,
	contacts: { ContactPair },
	settings: TriangleFixup
): (boolean, vector)
	assert(#contacts <= 16, "assertion failed: contacts.len() <= 16")
	local toward = if settings.reverse then neg(normal) else normal
	local projection = dot(toward, triangle.normal)
	local face_tolerance = from_bits(0x3F7F_F62B)
	local region
	if math.abs(projection) < face_tolerance then
		region = TriangleFeature.classify(triangle, normalize(sub(toward, scale(triangle.normal, projection)), 2))
	else
		region = TriangleRegion.Face
	end
	local one_sided = has_bits(triangle.flags, TriangleFeature.ONE_SIDED)
	local edge: number? = nil
	if region == TriangleRegion.Edge0 then
		edge = 0
	elseif region == TriangleRegion.Edge1 then
		edge = 1
	elseif region == TriangleRegion.Edge2 then
		edge = 2
	end
	local vertex: number? = nil
	if region == TriangleRegion.Vertex0 then
		vertex = 0
	elseif region == TriangleRegion.Vertex1 then
		vertex = 1
	elseif region == TriangleRegion.Vertex2 then
		vertex = 2
	end
	if not has_bits(triangle.flags, TriangleFeature.USE_EDGE_COSINES) then
		if region == TriangleRegion.Face then
			return not one_sided or projection > 0.0, normal
		end
		if one_sided then
			if projection > face_tolerance then
				return true, normal
			end
			if projection < 0.0 then
				return false, normal
			end
		elseif math.abs(projection) > face_tolerance then
			return true, normal
		end
		-- edge.map(edge_convex).unwrap_or_else(|| !vertex_disabled(vertex.unwrap()))
		if edge ~= nil then
			return TriangleFeature.edge_convex(triangle, edge), normal
		end
		assert(vertex ~= nil, "called `Option::unwrap()` on a `None` value")
		return not TriangleFeature.vertex_disabled(triangle, vertex), normal
	end
	if region == TriangleRegion.Face then
		return not one_sided or projection > 0.0, normal
	end
	if edge ~= nil then
		if not one_sided then
			local signed = if TriangleFeature.edge_convex(triangle, edge) then projection else -projection
			return signed >= triangle.edge_cosines[edge + 1], normal
		end
		return one_sided_edge(triangle, edge, projection, normal, contacts, settings)
	end
	assert(vertex ~= nil, "called `Option::unwrap()` on a `None` value")
	-- Native vertex adjacency: (edge2,edge0), (edge0,edge1), (edge1,edge2).
	local first = (vertex + 2) % 3
	local second = vertex
	if not one_sided then
		if TriangleFeature.vertex_disabled(triangle, vertex) then
			return false, normal
		end
		-- [first, second].into_iter().all(...) — останавливается на первом false.
		for _, i in { first, second } do
			if
				not edge_cos_test(
					neg(triangle.edges[2 - i + 1]),
					triangle.normal,
					toward,
					triangle.edge_cosines[i + 1],
					TriangleFeature.edge_convex(triangle, i),
					true
				)
			then
				return false, normal
			end
		end
		return true, normal
	end
	local disabled = TriangleFeature.vertex_disabled(triangle, vertex) and not settings.is_object
	if projection > 0.0 and disabled then
		-- TU3-only recovery for a disabled vertex bordering exactly one convex
		-- edge. Skate 2's corresponding routine does not have this path.
		local first_convex = TriangleFeature.edge_convex(triangle, first)
		local second_convex = TriangleFeature.edge_convex(triangle, second)
		local chosen
		if first_convex and not second_convex then
			chosen = second
		elseif not first_convex and second_convex then
			chosen = first
		else
			return false, normal
		end
		local cosine = triangle.edge_cosines[chosen + 1]
		if not (cosine <= from_bits(0x3F78_51EC) and cosine > from_bits(0x3A83_126F)) then
			return false, normal
		end
		local other = if chosen == second then first else second
		local direction = triangle.edges[2 - other + 1]
		local bent = normalize(cross(cross(direction, toward), direction), 1)
		return true, bend(normal, contacts, bent, settings.reverse)
	end
	if disabled then
		return false, normal
	end
	for _, i in { first, second } do
		if
			not edge_cos_test(
				neg(triangle.edges[2 - i + 1]),
				triangle.normal,
				toward,
				triangle.edge_cosines[i + 1],
				TriangleFeature.edge_convex(triangle, i),
				false
			)
		then
			return false, normal
		end
	end
	return true, normal
end

return fixup
