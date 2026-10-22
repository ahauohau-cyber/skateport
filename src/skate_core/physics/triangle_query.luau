--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/triangle_query.rs (коммит 2e16697)
--
-- Native triangle segment queries used by wheel probes and camera sweeps.
-- Thin test82AC7858 and dispatcher82ADF5D8, TU3. The world owns candidate
-- storage; these routines retain the source winding, tolerances and arithmetic.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local triangle_query = {}

-- pub struct TriangleLineHit
export type TriangleLineHit = {
	position: vector,
	normal: vector,
	fraction: number,
	-- Native result48.xy: weights for vertices1 and2; z is penetration data.
	volume_parameter: { number }, -- [f32; 3]
}

local TriangleLineHit = {}
triangle_query.TriangleLineHit = TriangleLineHit

-- ROBLOX: замена неявного копирования Copy-структуры.
function TriangleLineHit.copy(hit: TriangleLineHit): TriangleLineHit
	return {
		position = hit.position,
		normal = hit.normal,
		fraction = hit.fraction,
		volume_parameter = { hit.volume_parameter[1], hit.volume_parameter[2], hit.volume_parameter[3] },
	}
end

-- ROBLOX: `*result = hit` — переписать поля таблицы result.
function TriangleLineHit.assign(target: TriangleLineHit, source: TriangleLineHit)
	target.position = source.position
	target.normal = source.normal
	target.fraction = source.fraction
	target.volume_parameter = { source.volume_parameter[1], source.volume_parameter[2], source.volume_parameter[3] }
end

-- pub(super) fn dot(a: Vector3, b: Vector3) -> f32
function triangle_query.dot(a: vector, b: vector): number
	return native_arithmetic.dot3({ a.x, a.y, a.z, 0.0 }, { b.x, b.y, b.z, 0.0 })
end

-- pub(super) fn sub(a: Vector3, b: Vector3) -> Vector3
function triangle_query.sub(a: vector, b: vector): vector
	return vector.create(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- pub(super) fn scale(v: Vector3, scale: f32) -> Vector3
function triangle_query.scale(v: vector, scale: number): vector
	return vector.create(v.x * scale, v.y * scale, v.z * scale)
end

-- pub(super) fn madd(a: Vector3, scale: f32, b: Vector3) -> Vector3
function triangle_query.madd(a: vector, scale: number, b: vector): vector
	return vector.create(mul_add(a.x, scale, b.x), mul_add(a.y, scale, b.y), mul_add(a.z, scale, b.z))
end

-- pub(super) fn cross(a: Vector3, b: Vector3) -> Vector3
function triangle_query.cross(a: vector, b: vector): vector
	return vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
end

-- pub(super) fn inverse_length(squared: f32) -> f32
function triangle_query.inverse_length(squared: number): number
	local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, 2 do
		inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
	end
	return inverse
end

local dot, sub, scale, madd, cross, inverse_length =
	triangle_query.dot,
	triangle_query.sub,
	triangle_query.scale,
	triangle_query.madd,
	triangle_query.cross,
	triangle_query.inverse_length

-- Complete zero-total-radius branch. `direction` is end minus start, not a
-- normalized ray. TU3 accepts a small margin beyond both segment endpoints;
-- do not clamp its returned fraction or replace the determinant tolerance.
-- pub fn thin_triangle(start, direction, vertices: [Vector3; 3]) -> Option<TriangleLineHit>
function triangle_query.thin_triangle(start: vector, direction: vector, vertices: { vector }): TriangleLineHit?
	local a, b, c = vertices[1], vertices[2], vertices[3]
	local ac = sub(c, a)
	local ab = sub(b, a)
	local perpendicular = cross(direction, ac)
	local determinant = dot(ab, perpendicular)
	if not (determinant > from_bits(0x322b_cc77)) then
		return nil
	end
	local from_a = sub(start, a)
	local lower = f32(determinant * from_bits(0xb727_c5ac))
	local upper = f32(determinant - lower)
	local u = dot(from_a, perpendicular)
	if u < lower or u > upper then
		return nil
	end
	perpendicular = cross(from_a, ab)
	local v = dot(direction, perpendicular)
	if v < lower or f32(v + u) > upper then
		return nil
	end
	local distance = dot(ac, perpendicular)
	if distance < lower or distance > upper then
		return nil
	end
	local inverse = f32(1.0 / determinant)
	local fraction = f32(distance * inverse)
	-- Dispatcher82ADF61C..688 recomputes and normalizes this winding with
	-- two refinements; it does not use the Volume's cached contact normal.
	local normal = cross(sub(a, b), sub(a, c))
	return {
		position = madd(direction, fraction, start),
		normal = scale(normal, inverse_length(dot(normal, normal))),
		fraction = fraction,
		volume_parameter = { f32(u * inverse), f32(v * inverse), 0.0 },
	}
end

-- TU3 dispatcher82ADF5D8. The rounded query uses the sum of the two radii,
-- then shifts its center hit back by the query radius. As in the native output
-- structure, fields not written by a branch retain the caller's values.
-- pub fn triangle_segment(result: &mut TriangleLineHit, start, direction, vertices, line_radius: f32, triangle_fatness: f32) -> bool
function triangle_query.triangle_segment(
	result: TriangleLineHit,
	start: vector,
	direction: vector,
	vertices: { vector },
	line_radius: number,
	triangle_fatness: number
): boolean
	local radius = f32(line_radius + triangle_fatness)
	if radius == 0.0 then
		local hit = triangle_query.thin_triangle(start, direction, vertices)
		if hit ~= nil then
			TriangleLineHit.assign(result, hit)
			return true
		end
		return false
	end
	local normal = cross(sub(vertices[1], vertices[2]), sub(vertices[1], vertices[3]))
	result.normal = scale(normal, inverse_length(dot(normal, normal)))
	-- ROBLOX: triangle_sweep сам подключает этот модуль, поэтому здесь он
	-- подключается в момент вызова — иначе require зациклится.
	local triangle_sweep = (require :: any)("./triangle_sweep")
	if triangle_sweep.sweep(result, start, direction, vertices, radius) then
		result.position = sub(result.position, scale(result.normal, line_radius))
		return true
	else
		return false
	end
end

return triangle_query
