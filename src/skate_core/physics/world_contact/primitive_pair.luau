--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/primitive_pair.rs (коммит 2e16697)
--
-- Simulation GP-pair contact query, original Skate 3 TU3 82AD43A8.
--
-- 8277A508 calls this after its pair-culling bitmap and bounds checks, including
-- the same-assembly branch at 8277B2C0. This is not PrimitivePairIntersect
-- 82AD3CD8: that query has a squared-distance gate and different publication.
-- Host geometry is already transformed into world space. Native GP dispatch,
-- feature/prism order, normal refinement and radius application are retained.

local rt = require("../../../rt")
local prism_math = require("./prism_math")
local projection = require("./projection")
local dispatch = require("./dispatch")
local box_box_sat = require("./box_box_sat")
local triangle_box_sat = require("./triangle_box_sat")
local geometry = require("./primitive_geometry")
local primitive_query = require("./primitive_query")
local fixup = require("../collision/fixup")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local load, dot, sub, scale, inverse_length = prism_math.load, prism_math.dot, prism_math.sub, prism_math.scale, prism_math.inverse_length
local bits = prism_math.bits
local PrimitiveKind = projection.PrimitiveKind
local pack, xyz = geometry.pack, geometry.xyz
local maximum = primitive_query.maximum

local primitive_pair = {}

-- pub struct PrimitivePairSettings
export type PrimitivePairSettings = {
	-- Volume-record +112 for A/B in 8277A508, separate from shape fatness.
	padding_a: number,
	padding_b: number,
	-- Batch job +36, passed by 8277AB70; added after both volume paddings.
	additional_padding: number,
	-- Native f2/f3 of 82AD43A8, used only for triangle feature correction.
	edge_cos_bend_normal_threshold: number,
	convexity_epsilon: number,
}

local PrimitivePairSettings = {}
primitive_pair.PrimitivePairSettings = PrimitivePairSettings

-- Original skater/skater batch settings. SerializedAssembly::Create
-- 82DC3AE4/82DC3B84 stores 82165A00 into every volume's padding (+112).
-- Island::InitWorld 82765544 initializes additionalPadding to zero;
-- 82DC1848 -> 82DC19E8 -> 8277B2A4 passes it to this query. The triangle
-- constants are loaded by 8277ABEC..AC1C and forwarded at 8277A7DC..7EC.
-- pub const fn skater_self_collision() -> Self
function PrimitivePairSettings.skater_self_collision(): PrimitivePairSettings
	return {
		padding_a = from_bits(0x3D4C_CCCD),
		padding_b = from_bits(0x3D4C_CCCD),
		additional_padding = 0.0,
		edge_cos_bend_normal_threshold = from_bits(0x3F7F_BE77),
		convexity_epsilon = from_bits(0x3C23_D70A),
	}
end

-- Exact non-cylinder entries of original dispatch table 82FD56F0.
-- fn separating_direction(a, a_kind, b, b_kind) -> (f32, [u32; 4])
local function separating_direction(a: { number }, a_kind: number, b: { number }, b_kind: number): (number, { number })
	local separation: { number }, direction: { number } = {}, {}
	if a_kind == PrimitiveKind.Sphere and b_kind == PrimitiveKind.Sphere then
		-- Specialized 82ACE9C0. The generic no-edge fallback is Z, so it
		-- cannot substitute for this center-to-center sphere-pair axis.
		local delta = sub(load(b, 0), load(a, 0))
		local squared = dot(delta, delta)
		local inverse = inverse_length(squared)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
		local l = to_bits(length)
		separation, direction = { l, l, l, l }, bits(scale(delta, inverse))
	elseif a_kind == PrimitiveKind.Box and b_kind == PrimitiveKind.Box then
		separation, direction = box_box_sat.box_box(a, b)
	elseif a_kind == PrimitiveKind.Triangle and b_kind == PrimitiveKind.Box then
		separation, direction = triangle_box_sat.triangle_box(a, b)
	elseif a_kind == PrimitiveKind.Box and b_kind == PrimitiveKind.Triangle then
		local s, normal = triangle_box_sat.triangle_box(b, a)
		separation, direction = s, rt.flip_sign_bits(normal)
	else
		separation, direction = projection.best_separating_direction(a, a_kind, b, b_kind)
	end
	return from_bits(separation[1]), direction :: { number }
end

-- Contacts between two simulation volumes. The normal points from B toward A;
-- `points[i].a/b` belong to the corresponding input volume. Positive geometric
-- gaps inside the native padding are retained for the solver to classify.
-- pub fn primitive_pair_contacts(primitive_a, primitive_b, settings) -> Option<PrimitiveContactManifold>
function primitive_pair.primitive_pair_contacts(
	primitive_a: geometry.ContactPrimitive,
	primitive_b: geometry.ContactPrimitive,
	settings: PrimitivePairSettings
): primitive_query.PrimitiveContactManifold?
	local a, a_kind = pack(primitive_a)
	local b, b_kind = pack(primitive_b)
	local separation, initial_normal = separating_direction(a, a_kind, b, b_kind)
	-- 8277A720..744 computes the pair padding before 82AD43F8..4414 adds
	-- geometric fatness, preserving all four scalar additions in order.
	local limit = f32(f32(settings.padding_b + settings.padding_a) + settings.additional_padding)
	local fat_a = from_bits(a[33])
	local fat_b = from_bits(b[33])
	if separation > f32(f32(fat_b + limit) + fat_a) then
		return nil
	end
	local feature_a = maximum(a, a_kind, 1, initial_normal)
	local feature_b = maximum(b, b_kind, 0, rt.flip_sign_bits(initial_normal))
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
		-- 82AD44B0..4540 compares *length*, not squared length. The source
		-- computes both reciprocal-square-root refinements before selecting
		-- zero length for a zero squared distance.
		local delta = sub(load(prism, 64), load(prism, 0))
		local squared = dot(delta, delta)
		local inverse = inverse_length(squared)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
		if length > from_bits(0x3400_0000) then
			rt.copy_into(prism, 128, bits(scale(delta, inverse)))
			prism[134] = 1
		end
	end
	if prism[134] ~= 0 then
		local direction = rt.slice(prism, 128, 132)
		local interval_a = rt.zeros(12)
		local interval_b = rt.zeros(12)
		projection.project_direction(a, a_kind, direction, interval_a)
		projection.project_direction(b, b_kind, direction, interval_b)
		local forward = f32(from_bits(interval_a[1]) - from_bits(interval_b[5]))
		local reverse = f32(from_bits(interval_b[1]) - from_bits(interval_a[5]))
		local flip = forward > reverse
		local refined = if flip then forward else reverse
		if refined >= separation then
			local words = if flip then rt.flip_sign_bits(direction) else direction
			normal = { from_bits(words[1]), from_bits(words[2]), from_bits(words[3]), from_bits(words[4]) }
		end
	end
	local zero = vector.create(0, 0, 0)
	local points: { fixup.ContactPair } = {}
	for i = 1, 16 do
		points[i] = { a = zero, b = zero }
	end
	for i = 0, count - 1 do
		points[i + 1].a = xyz(load(prism, 4 * i))
		points[i + 1].b = xyz(load(prism, 64 + 4 * i))
	end
	-- General GP query corrects either triangle, A first. The skater-specific
	-- world query corrects only B and supplies a different is_object argument.
	local pair_normal = xyz(normal)
	local active = table.move(points, 1, count, 1, {})
	for _, item in { { primitive_a, false }, { primitive_b, true } } do
		local primitive: geometry.ContactPrimitive, reverse: boolean = item[1] :: any, item[2] :: any
		if primitive.kind == "Triangle" then
			local triangle = primitive.triangle :: any
			local accepted
			accepted, pair_normal = fixup.fix_up_triangle(triangle.feature, pair_normal, active, {
				reverse = reverse,
				edge_cos_bend_normal_threshold = settings.edge_cos_bend_normal_threshold,
				convexity_epsilon = settings.convexity_epsilon,
				is_object = false,
			})
			if not accepted then
				return nil
			end
		end
	end
	local direction = { pair_normal.x, pair_normal.y, pair_normal.z, normal[4] }
	local offset_a = scale(direction, fat_a)
	local offset_b = scale(direction, fat_b)
	for i = 1, count do
		local point = points[i]
		-- 82AD46EC..4724 multiplies before adding/subtracting, not fused.
		point.a = vector.create(point.a.x + offset_a[1], point.a.y + offset_a[2], point.a.z + offset_a[3])
		point.b = vector.create(point.b.x - offset_b[1], point.b.y - offset_b[2], point.b.z - offset_b[3])
	end
	return {
		normal = vector.create(-pair_normal.x, -pair_normal.y, -pair_normal.z),
		points = points,
		count = count,
	}
end

return primitive_pair
