--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/primitive_geometry.rs (коммит 2e16697)
-- В Rust это подмодуль primitive_query (`#[path = "primitive_geometry.rs"] pub(super) mod geometry`).

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local prism_math = require("./prism_math")
local projection = require("./projection")
local sphere_triangle = require("../collision/sphere_triangle")
local math_mod = require("../../math")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate
local dot, sub, scale, madd, cross, reciprocal =
	prism_math.dot, prism_math.sub, prism_math.scale, prism_math.madd, prism_math.cross, prism_math.reciprocal
local PrimitiveKind = projection.PrimitiveKind

local primitive_geometry = {}

type V = { number }

-- World-space board geometry. Capsule axes and box basis columns are the
-- transformed native volume axes; shape radii are applied after feature fixup.
-- pub enum ContactPrimitive { Sphere(Sphere), Capsule {..}, Triangle(Triangle), RoundedBox {..} }
-- ROBLOX: enum с данными -> таблица с полем kind:
--   { kind = "Sphere", sphere = Sphere }
--   { kind = "Capsule", center, axis, half_length, radius }
--   { kind = "Triangle", triangle = Triangle }
--   { kind = "RoundedBox", center, basis, half_extents, radius }
export type ContactPrimitive = {
	kind: string,
	sphere: sphere_triangle.Sphere?,
	triangle: sphere_triangle.Triangle?,
	center: vector?,
	axis: vector?,
	half_length: number?,
	basis: math_mod.Basis3?,
	half_extents: vector?,
	radius: number?,
}

-- pub(in super::super) fn lanes(v: Vector3, w: f32) -> V
function primitive_geometry.lanes(v: vector, w: number): V
	return { v.x, v.y, v.z, w }
end
local lanes = primitive_geometry.lanes

-- pub(in super::super) fn xyz(v: V) -> Vector3
function primitive_geometry.xyz(v: V): vector
	return vector.create(v[1], v[2], v[3])
end
local xyz = primitive_geometry.xyz

-- fn put(out: &mut [u32], offset: usize, v: V)
local function put(out: { number }, offset: number, v: V)
	out[offset + 1] = to_bits(v[1])
	out[offset + 2] = to_bits(v[2])
	out[offset + 3] = to_bits(v[3])
	out[offset + 4] = to_bits(v[4])
end

-- fn refined_inverse(squared: f32) -> f32
local function refined_inverse(squared: number): number
	local seed = estimate(squared)
	return mul_add(f32(seed * 0.5), mul_add(-squared, f32(seed * seed), 1.0), seed)
end

-- Authored triangle Volume initialization and CreateGPInstance geometry
-- (82AC75B8, 82ADE468). The normal cache's dirty bit is cleared before copying
-- the Volume flags to GP flags; all other flags and edge cosines copy directly.
-- This constructor recomputes authored geometry. A cached native GPTriangle can
-- instead be passed directly as ContactPrimitive::Triangle.
-- pub fn triangle_from_volume(vertices: [Vector3; 3], fatness: f32, edge_cosines: [f32; 3], volume_flags: u32) -> Triangle
function primitive_geometry.triangle_from_volume(
	vertices: { vector },
	fatness: number,
	edge_cosines: { number },
	volume_flags: number
): sphere_triangle.Triangle
	local points = { lanes(vertices[1], 1.0), lanes(vertices[2], 1.0), lanes(vertices[3], 1.0) }
	local raw_normal = cross(sub(points[2], points[1]), sub(points[3], points[1]))
	local squared = dot(raw_normal, raw_normal)
	local normal = if squared > from_bits(0x3400_0000) then scale(raw_normal, refined_inverse(squared)) else raw_normal
	local raw_edges = {
		sub(points[3], points[1]),
		sub(points[2], points[3]),
		sub(points[1], points[2]),
	}
	local inverse = {
		refined_inverse(dot(raw_edges[1], raw_edges[1])),
		refined_inverse(dot(raw_edges[2], raw_edges[2])),
		refined_inverse(dot(raw_edges[3], raw_edges[3])),
	}
	return {
		vertices = { vertices[1], vertices[2], vertices[3] },
		feature = {
			normal = xyz(normal),
			edges = {
				xyz(scale(raw_edges[1], inverse[1])),
				xyz(scale(raw_edges[2], inverse[2])),
				xyz(scale(raw_edges[3], inverse[3])),
			},
			flags = bit32.band(volume_flags, bit32.bnot(2)),
			edge_cosines = { edge_cosines[1], edge_cosines[2], edge_cosines[3] },
		},
		-- 82ADE66C..: lengths are the twice-refined reciprocal of the refined
		-- inverse length, not squared length multiplied by inverse length.
		edge_lengths = { reciprocal(inverse[1]), reciprocal(inverse[2]), reciprocal(inverse[3]) },
		fatness = fatness,
	}
end

-- TriangleVolume::CreateGPInstance with a rigid Volume-to-world transform.
-- Source order computes the local normal first, transforms it without a new
-- normalization, and then builds directions and lengths from world vertices.
-- pub fn transform_triangle_volume(vertices, fatness, edge_cosines, volume_flags, basis: Basis3, translation: Vector3) -> Triangle
function primitive_geometry.transform_triangle_volume(
	vertices: { vector },
	fatness: number,
	edge_cosines: { number },
	volume_flags: number,
	basis: math_mod.Basis3,
	translation: vector
): sphere_triangle.Triangle
	local local_triangle = primitive_geometry.triangle_from_volume(vertices, fatness, edge_cosines, volume_flags)
	local c = basis.columns
	local axes = {
		{ c[1][1], c[1][2], c[1][3], 0.0 },
		{ c[2][1], c[2][2], c[2][3], 0.0 },
		{ c[3][1], c[3][2], c[3][3], 0.0 },
	}
	local world_vertices = {}
	for i, v in vertices do
		world_vertices[i] = xyz(madd(axes[3], v.z, madd(axes[2], v.y, madd(axes[1], v.x, lanes(translation, 1.0)))))
	end
	local n = local_triangle.feature.normal
	local normal = xyz(madd(axes[3], n.z, madd(axes[2], n.y, scale(axes[1], n.x))))
	local result = primitive_geometry.triangle_from_volume(world_vertices, fatness, edge_cosines, volume_flags)
	result.feature.normal = normal
	return result
end

-- pub(in super::super) fn pack(shape: ContactPrimitive) -> ([u32; 48], PrimitiveKind)
function primitive_geometry.pack(shape: ContactPrimitive): ({ number }, number)
	local gp = rt.zeros(48)
	local kind, radius, counts, id
	if shape.kind == "Sphere" then
		local sphere = shape.sphere :: sphere_triangle.Sphere
		put(gp, 0, lanes(sphere.center, 1.0))
		kind, radius, counts, id = PrimitiveKind.Sphere, sphere.radius, 0, 1
	elseif shape.kind == "Capsule" then
		put(gp, 0, lanes(shape.center :: vector, 1.0))
		put(gp, 16, lanes(shape.axis :: vector, 0.0))
		gp[29] = to_bits(shape.half_length :: number)
		kind, radius, counts, id = PrimitiveKind.Capsule, shape.radius :: number, 0x0001_0000, 2
	elseif shape.kind == "Triangle" then
		local triangle = shape.triangle :: sphere_triangle.Triangle
		put(gp, 0, lanes(triangle.vertices[1], 1.0))
		put(gp, 4, lanes(triangle.feature.normal, 0.0))
		put(gp, 8, lanes(triangle.vertices[2], 1.0))
		put(gp, 12, lanes(triangle.vertices[3], 1.0))
		for i = 0, 2 do
			put(gp, 16 + i * 4, lanes(triangle.feature.edges[i + 1], 0.0))
			gp[28 + i + 1] = to_bits(triangle.edge_lengths[i + 1])
			gp[38 + i + 1] = to_bits(triangle.feature.edge_cosines[i + 1])
		end
		gp[38] = triangle.feature.flags
		kind, radius, counts, id = PrimitiveKind.Triangle, triangle.fatness, 0x0103_0000, 3
	else
		-- RoundedBox
		put(gp, 0, lanes(shape.center :: vector, 1.0))
		local half_extents = shape.half_extents :: vector
		local half = { half_extents.x, half_extents.y, half_extents.z }
		local basis = shape.basis :: math_mod.Basis3
		for i = 0, 2 do
			local v = basis.columns[i + 1]
			local axis = { v[1], v[2], v[3], 0.0 }
			put(gp, 4 + i * 4, axis)
			put(gp, 16 + i * 4, axis)
			gp[28 + i + 1] = to_bits(half[i + 1])
		end
		kind, radius, counts, id = PrimitiveKind.Box, shape.radius :: number, 0x0303_0000, 4
	end
	gp[33] = to_bits(radius)
	gp[36] = counts
	gp[37] = id
	return gp, kind
end

return primitive_geometry
