--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/triangle_sweep.rs (коммит 2e16697)
--
-- Rounded triangle query82ADEB70: bounds, face, overlap, then feature walk.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local triangle_closest = require("./triangle_closest")
local triangle_query = require("./triangle_query")
local triangle_sweep_walk = require("./triangle_sweep_walk")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local closest = triangle_closest.closest
local cross, dot, madd, scale, sub =
	triangle_query.cross, triangle_query.dot, triangle_query.madd, triangle_query.scale, triangle_query.sub

local triangle_sweep = {}

-- Literal8212BF74, also used by closest-feature and walk denominator gates.
-- pub(super) const MIN_RECIPROCAL: f32
triangle_sweep.MIN_RECIPROCAL = from_bits(0x0020_0000)
local MIN_RECIPROCAL = triangle_sweep.MIN_RECIPROCAL

-- pub(super) fn add(a: Vector3, b: Vector3) -> Vector3
function triangle_sweep.add(a: vector, b: vector): vector
	return vector.create(a.x + b.x, a.y + b.y, a.z + b.z)
end
local add = triangle_sweep.add

-- fn l1(v: Vector3) -> f32
local function l1(v: vector): number
	return f32(f32(math.abs(v.y) + math.abs(v.z)) + math.abs(v.x))
end

-- pub(super) fn sweep(result: &mut TriangleLineHit, start, mut delta, vertices, radius: f32) -> bool
function triangle_sweep.sweep(
	result: triangle_query.TriangleLineHit,
	start: vector,
	delta: vector,
	vertices: { vector },
	radius: number
): boolean
	result.fraction = 0.0
	local a, b, c = vertices[1], vertices[2], vertices[3]
	local ab = sub(b, a)
	local ac = sub(c, a)
	local from_a = sub(start, a)
	local cross_ac = cross(delta, ac)
	local determinant = dot(ab, cross_ac)
	local side = 1.0
	if determinant < 0.0 then
		side = -1.0
		determinant = -determinant
	end
	if f32(dot(result.normal, from_a) * side) < -radius then
		return false
	end
	local u = f32(dot(from_a, cross_ac) * side)
	-- This TU3 body uses the L1 sum, not the SDK's vector magnitude bound.
	local u_margin = f32(l1(cross_ac) * radius)
	if u < -u_margin or u > f32(u_margin + determinant) then
		return false
	end
	local cross_ab = cross(ab, delta)
	local v = f32(dot(from_a, cross_ab) * side)
	local v_margin = f32(l1(cross_ab) * radius)
	if
		v < -v_margin
		or v > f32(v_margin + determinant)
		or f32(v + u) > f32(f32(u_margin + v_margin) + determinant)
	then
		return false
	end
	if determinant > MIN_RECIPROCAL then
		local offset = sub(from_a, scale(result.normal, f32(side * radius)))
		local distance = -f32(dot(offset, cross(ac, ab)) * side)
		if distance > determinant then
			return false
		end
		if not (distance < 0.0) then
			local inverse = f32(1.0 / determinant)
			result.fraction = f32(inverse * distance)
			local face_u = f32(dot(offset, cross_ac) * side)
			if not (face_u < 0.0) and not (face_u > determinant) then
				local face_v = f32(dot(offset, cross_ab) * side)
				if not (face_v < 0.0) and not (f32(face_v + face_u) > determinant) then
					result.position = madd(delta, result.fraction, start)
					result.normal = scale(result.normal, side)
					result.volume_parameter = { f32(inverse * face_u), f32(inverse * face_v), 0.0 }
					return true
				end
			end
			from_a = madd(delta, result.fraction, from_a)
			delta = scale(delta, f32(1.0 - result.fraction))
		end
	end
	local moved_start = add(from_a, a)
	local feature = closest(moved_start, vertices)
	local separation = sub(moved_start, feature.point)
	local squared = dot(separation, separation)
	local penetration = mul_add(radius, radius, -squared)
	if penetration > 0.0 then
		result.position = moved_start
		if squared > 0.0 then
			local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
			inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
			result.normal = scale(separation, inverse)
		end
		result.volume_parameter = { feature.u, feature.v, penetration }
		return true
	end
	if feature.region == 6 then
		result.position = moved_start
		-- 82ADEFA0 compares the absolute determinant retained in f1; it has
		-- already been negated by82ADEC30 for a reverse-facing query.
		if determinant < 0.0 then
			result.normal = scale(result.normal, -1.0)
		end
		result.volume_parameter = { feature.u, feature.v, 0.0 }
		return true
	end
	return triangle_sweep_walk.walk(result, moved_start, delta, vertices, feature, radius)
end

return triangle_sweep
