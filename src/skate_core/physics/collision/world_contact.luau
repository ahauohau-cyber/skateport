--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/world_contact.rs (коммит 2e16697)
--
-- Physics/world pair query 8277B720, called by triangle dispatch 8277BC58.
-- This is distinct from the general Volume query (82AD3CD8).

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")
local fixup = require("./fixup")
local sphere_triangle = require("./sphere_triangle")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot, sub, scale, neg = arithmetic.dot, arithmetic.sub, arithmetic.scale, arithmetic.neg
local fix_up_triangle = fixup.fix_up_triangle
local ContactPair = fixup.ContactPair
local build_prism = sphere_triangle.build_prism

local world_contact = {}

export type WorldContactSettings = {
	-- Per-volume padding at cached primitive +112, excluding its radius.
	volume_padding: number,
	-- Query settings +0. Bounds the approaching velocity's prediction.
	maximum_separating_distance: number,
	-- Query settings +4 and +8, passed directly to triangle fixup.
	edge_cos_bend_normal_threshold: number,
	convexity_epsilon: number,
	-- World-query context byte +61, forwarded to TU3 vertex handling.
	is_object: boolean,
}

export type WorldContact = {
	-- B (world) toward A (moving primitive), ready for contact construction.
	normal: vector,
	points: fixup.ContactPair,
}

-- 8277BF0C..BF8C. The original predicts using the literal 1/60, independent
-- of the simulation timestep. Do not replace it with a caller's frame dt.
-- pub fn world_separation_limit(velocity, triangle_normal, padding: f32, maximum: f32) -> f32
function world_contact.world_separation_limit(velocity: vector, triangle_normal: vector, padding: number, maximum: number): number
	local approach = dot(neg(triangle_normal), scale(velocity, from_bits(0x3C88_8889)))
	local positive = if -approach >= 0.0 then 0.0 else approach
	local limited = if f32(maximum - positive) >= 0.0 then positive else maximum
	return f32(limited + padding)
end

-- Complete sphere branch of the physics/world pair query. Input GP geometry
-- is in world space; world broad phase, exclusion tables and duplicate-contact
-- buffering remain the producer's responsibilities.
-- pub fn sphere_triangle_world_contact(sphere, triangle, velocity, settings) -> Option<WorldContact>
function world_contact.sphere_triangle_world_contact(
	sphere: sphere_triangle.Sphere,
	triangle: sphere_triangle.Triangle,
	velocity: vector,
	settings: WorldContactSettings
): WorldContact?
	local separation = world_contact.world_separation_limit(
		velocity,
		triangle.feature.normal,
		settings.volume_padding,
		settings.maximum_separating_distance
	)
	local prism = build_prism(sphere, triangle, separation, false, true)
	if prism == nil then
		return nil
	end
	local normal = prism.normal
	-- ROBLOX: let mut points = [prism.raw_points] — копия пары в массиве.
	local points = { ContactPair.copy(prism.raw_points) }
	local accepted
	accepted, normal = fix_up_triangle(triangle.feature, normal, points, {
		reverse = true,
		edge_cos_bend_normal_threshold = settings.edge_cos_bend_normal_threshold,
		convexity_epsilon = settings.convexity_epsilon,
		is_object = settings.is_object,
	})
	if not accepted then
		return nil
	end
	-- 8277B9E0..BA7C: fixup precedes publication. Both fatness operations
	-- use separate multiply and add/subtract (the Volume query uses an FMA).
	local a = scale(normal, sphere.radius)
	return {
		normal = neg(normal),
		points = {
			a = vector.create(points[1].a.x + a.x, points[1].a.y + a.y, points[1].a.z + a.z),
			b = sub(points[1].b, scale(normal, triangle.fatness)),
		},
	}
end

return world_contact
