--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/primitive_query.rs (коммит 2e16697)
--
-- Physics/world primitive query 8277B720 and moving-volume/triangle dispatch
-- 8277BC58. Geometry lives in typed host-owned records; only the recovered
-- kernels' GP and feature scratch boundaries use native word layouts.
--
-- ROBLOX: подмодули box_box_sat, geometry (primitive_geometry.rs) и
-- triangle_box_sat лежат отдельными файлами рядом; переэкспорт
-- ContactPrimitive / transform_triangle_volume / triangle_from_volume
-- повторён ниже, потому что Rust публикует их через этот модуль.

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local projection = require("./projection")
local box_feature = require("./box_feature")
local feature = require("./feature")
local triangle_feature = require("./triangle_feature")
local dispatch = require("./dispatch")
local triangle_box_sat = require("./triangle_box_sat")
local geometry = require("./primitive_geometry")
local fixup = require("../collision/fixup")
local sphere_triangle = require("../collision/sphere_triangle")
local world_contact_mod = require("../collision/world_contact")

local f32 = rt.f32
local from_bits = rt.from_bits
local load, dot, sub, scale, inverse_length = prism_math.load, prism_math.dot, prism_math.sub, prism_math.scale, prism_math.inverse_length
local bits = prism_math.bits
local PrimitiveKind = projection.PrimitiveKind
local lanes, pack, xyz = geometry.lanes, geometry.pack, geometry.xyz

local primitive_query = {}

-- pub use geometry::{ContactPrimitive, transform_triangle_volume, triangle_from_volume};
primitive_query.transform_triangle_volume = geometry.transform_triangle_volume
primitive_query.triangle_from_volume = geometry.triangle_from_volume
export type ContactPrimitive = geometry.ContactPrimitive

-- pub struct PrimitiveContactManifold
export type PrimitiveContactManifold = {
	-- World primitive B toward moving primitive A, as expected by the solver.
	normal: vector,
	-- Native prism order is retained, including coincident points.
	points: { fixup.ContactPair }, -- [ContactPair; 16]
	count: number,
}

local ZERO = vector.create(0, 0, 0)

-- pub(super) fn maximum(gp: &[u32; 48], kind: PrimitiveKind, mode: u32, direction: [u32; 4]) -> MaximumFeature
function primitive_query.maximum(gp: { number }, kind: number, mode: number, direction: { number }): { number }
	local result = rt.zeros(144)
	if kind == PrimitiveKind.Sphere then
		-- Complete sphere callback82ADD7E0: center, point type, header0.
		rt.copy_range(result, 136, gp, 0, 4)
		result[141] = 0
		result[1] = 0
	elseif kind == PrimitiveKind.Capsule then
		feature.capsule_maximum_feature(gp, direction, result, rt.zeros(16))
	elseif kind == PrimitiveKind.Triangle then
		triangle_feature.triangle_maximum_feature(gp, mode, direction, result)
	else
		box_feature.box_maximum_feature(gp, mode, direction, result, rt.zeros(4))
	end
	return result
end

-- fn contact_points(a, a_kind, b, b_kind, triangle, separation: f32, initial_normal: [u32; 4], limit: f32, settings) -> Option<PrimitiveContactManifold>
local function contact_points(
	a: { number },
	a_kind: number,
	b: { number },
	b_kind: number,
	triangle: sphere_triangle.Triangle,
	separation: number,
	initial_normal: { number },
	limit: number,
	settings: world_contact_mod.WorldContactSettings
): PrimitiveContactManifold?
	local fat_a = from_bits(a[33])
	local fat_b = from_bits(b[33])
	if separation > f32(f32(fat_b + limit) + fat_a) then
		return nil
	end
	local feature_a = primitive_query.maximum(a, a_kind, 1, initial_normal)
	local feature_b = primitive_query.maximum(b, b_kind, 0, rt.flip_sign_bits(initial_normal))
	local prism = rt.zeros(136)
	if dispatch.find_feature_intersection_prism(prism, feature_a, feature_b, initial_normal) == 0 then
		return nil
	end
	local count = prism[133]
	local normal = {
		from_bits(initial_normal[1]),
		from_bits(initial_normal[2]),
		from_bits(initial_normal[3]),
		from_bits(initial_normal[4]),
	}
	if count == 1 then
		local delta = sub(load(prism, 64), load(prism, 0))
		local squared = dot(delta, delta)
		local inverse = inverse_length(squared)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
		-- This world-query gate compares length. The general Volume query
		-- has a different squared-distance gate and publication sequence.
		if length > from_bits(0x3400_0000) then
			rt.copy_into(prism, 128, bits(scale(delta, inverse)))
			prism[134] = 1
		end
	end
	if prism[134] ~= 0 then
		local direction = rt.slice(prism, 128, 132)
		local ai = rt.zeros(12)
		local bi = rt.zeros(12)
		projection.project_direction(a, a_kind, direction, ai)
		projection.project_direction(b, b_kind, direction, bi)
		local forward = f32(from_bits(ai[1]) - from_bits(bi[5]))
		local reverse = f32(from_bits(bi[1]) - from_bits(ai[5]))
		local flip = forward > reverse
		local refined = if flip then forward else reverse
		if refined >= separation then
			local words = if flip then rt.flip_sign_bits(direction) else direction
			normal = { from_bits(words[1]), from_bits(words[2]), from_bits(words[3]), from_bits(words[4]) }
		end
	end
	local points: { fixup.ContactPair } = {}
	for i = 1, 16 do
		points[i] = { a = ZERO, b = ZERO }
	end
	for i = 0, count - 1 do
		points[i + 1].a = xyz(load(prism, 4 * i))
		points[i + 1].b = xyz(load(prism, 64 + 4 * i))
	end
	local pair_normal = xyz(normal)
	-- ROBLOX: &mut points[..count] — первые count пар (те же таблицы, правки видны).
	local active = table.move(points, 1, count, 1, {})
	local accepted
	accepted, pair_normal = fixup.fix_up_triangle(triangle.feature, pair_normal, active, {
		reverse = true,
		edge_cos_bend_normal_threshold = settings.edge_cos_bend_normal_threshold,
		convexity_epsilon = settings.convexity_epsilon,
		is_object = settings.is_object,
	})
	if not accepted then
		return nil
	end
	local normal4 = lanes(pair_normal, 0.0)
	local a_offset = scale(normal4, fat_a)
	local b_offset = scale(normal4, fat_b)
	for i = 1, count do
		local point = points[i]
		-- Separate multiply and add/subtract in8277BA50..BA60, after fixup.
		local pa = lanes(point.a, 1.0)
		point.a = xyz({ f32(pa[1] + a_offset[1]), f32(pa[2] + a_offset[2]), f32(pa[3] + a_offset[3]), f32(pa[4] + a_offset[4]) })
		point.b = xyz(sub(lanes(point.b, 1.0), b_offset))
	end
	return {
		normal = xyz({ -normal4[1], -normal4[2], -normal4[3], -normal4[4] }),
		points = points,
		count = count,
	}
end

-- Full moving sphere/capsule/triangle/rounded-box query against a world
-- triangle. The caller retains native world-triangle then moving-volume order.
-- pub fn primitive_triangle_world_contacts(primitive, triangle, velocity, settings) -> Option<PrimitiveContactManifold>
function primitive_query.primitive_triangle_world_contacts(
	primitive: ContactPrimitive,
	triangle: sphere_triangle.Triangle,
	velocity: vector,
	settings: world_contact_mod.WorldContactSettings
): PrimitiveContactManifold?
	local limit = world_contact_mod.world_separation_limit(
		velocity,
		triangle.feature.normal,
		settings.volume_padding,
		settings.maximum_separating_distance
	)
	local a, a_kind = pack(primitive)
	local b, b_kind = pack({ kind = "Triangle", triangle = triangle })
	local separation: { number }, normal: { number } = {}, {}
	if a_kind == PrimitiveKind.Box then
		-- Reversed specialized entry82ACE968 calls triangle/box then flips
		-- every sign bit. Native pair direction always points A toward B.
		local s, n = triangle_box_sat.triangle_box(b, a)
		separation, normal = s, rt.flip_sign_bits(n)
	else
		separation, normal = projection.best_separating_direction(a, a_kind, b, b_kind)
	end
	return contact_points(a, a_kind, b, b_kind, triangle, from_bits(separation[1]), normal :: { number }, limit, settings)
end

return primitive_query
