--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/triangle_sweep_walk.rs (коммит 2e16697)
--
-- Five-step vertex/edge region walk82ADF008..82ADF5BC.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local triangle_query = require("./triangle_query")
local roots = require("./triangle_sweep_roots")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, madd, scale, sub = triangle_query.dot, triangle_query.madd, triangle_query.scale, triangle_query.sub
local Fraction = roots.Fraction

-- ROBLOX: MIN_RECIPROCAL и add живут в triangle_sweep, который сам подключает
-- этот модуль. Чтобы не было цикла require, повторяем их здесь (те же значения).
-- triangle_sweep::MIN_RECIPROCAL = f32::from_bits(0x0020_0000)
local MIN_RECIPROCAL = from_bits(0x0020_0000)
-- triangle_sweep::add
local function add(a: vector, b: vector): vector
	return vector.create(a.x + b.x, a.y + b.y, a.z + b.z)
end

local triangle_sweep_walk = {}

-- fn replaces(hit: Option<Fraction>, candidate: Fraction) -> bool
local function replaces(hit: roots.Fraction?, candidate: roots.Fraction): boolean
	return candidate.denominator > MIN_RECIPROCAL
		and candidate.numerator > 0.0
		and (hit == nil or not Fraction.before(hit, candidate))
end

-- fn advance_fraction(result: &mut TriangleLineHit, fraction: f32)
local function advance_fraction(result: triangle_query.TriangleLineHit, fraction: number)
	result.fraction = mul_add(f32(1.0 - result.fraction), fraction, result.fraction)
end

-- fn inverse_radius(radius: f32) -> f32
local function inverse_radius(radius: number): number
	local inverse = native_arithmetic.reciprocal_estimate(radius)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, radius, 1.0), inverse)
	end
	return inverse
end

-- pub(super) fn walk(result: &mut TriangleLineHit, start, delta, vertices, closest, radius) -> bool
function triangle_sweep_walk.walk(
	result: triangle_query.TriangleLineHit,
	start: vector,
	delta: vector,
	vertices: { vector },
	closest: any,
	radius: number
): boolean
	local region: number = closest.region
	local vertex: vector = closest.point
	for _ = 1, 5 do
		local fraction
		if region <= 2 then
			local hit: roots.Fraction?
			local root = roots.sphere(start, delta, vertex, radius)
			if root.kind == "Away" then
				return false
			elseif root.kind == "Miss" then
				hit = nil
			else
				hit = root.fraction
			end
			local adjacent
			if region == 0 then
				adjacent = { sub(vertices[2], vertices[1]), sub(vertices[3], vertices[1]) }
			elseif region == 1 then
				adjacent = { sub(vertices[1], vertices[2]), sub(vertices[3], vertices[2]) }
			else
				adjacent = { sub(vertices[1], vertices[3]), sub(vertices[2], vertices[3]) }
			end
			local next_region = region
			-- ROBLOX: enumerate() даёт index с нуля.
			for k, edge in adjacent do
				local index = k - 1
				local candidate = {
					numerator = dot(sub(vertex, start), edge),
					denominator = dot(delta, edge),
				}
				if replaces(hit, candidate) then
					hit = candidate
					next_region = (region + (if index == 0 then 6 else 9)) // 2
				end
			end
			if hit == nil then
				return false
			end
			fraction = Fraction.value(hit)
			if next_region <= 2 then
				advance_fraction(result, fraction)
				result.position = madd(delta, fraction, start)
				result.normal = scale(sub(result.position, vertex), inverse_radius(radius))
				result.volume_parameter = {
					if region == 1 then 1.0 else 0.0,
					if region == 2 then 1.0 else 0.0,
					0.0,
				}
				return true
			end
			region = next_region
		else
			-- match region { 3 => (v0, v1 - v0), 4 => (v0, v2 - v0), _ => (v1, v2 - v1) }
			local origin = if region == 3 or region == 4 then vertices[1] else vertices[2]
			local edge = if region == 3
				then sub(vertices[2], vertices[1])
				elseif region == 4 then sub(vertices[3], vertices[1])
				else sub(vertices[3], vertices[2])
			vertex = origin
			local hit: roots.Fraction?
			local root = roots.cylinder(start, delta, origin, edge, radius)
			if root.kind == "Away" then
				return false
			elseif root.kind == "Miss" then
				hit = nil
			else
				hit = root.fraction
			end
			local finish = add(origin, edge)
			local forward = {
				numerator = dot(sub(finish, start), edge),
				denominator = dot(delta, edge),
			}
			local backward = {
				numerator = dot(sub(start, origin), edge),
				denominator = -forward.denominator,
			}
			if replaces(hit, forward) then
				hit = forward
				vertex = finish
				region = region // 2
			elseif replaces(hit, backward) then
				hit = backward
				region = (region - 3) // 2
			end
			if hit == nil then
				return false
			end
			fraction = Fraction.value(hit)
			if region > 2 then
				advance_fraction(result, fraction)
				result.position = madd(delta, fraction, start)
				local along_edge = f32(dot(sub(result.position, origin), edge) * f32(1.0 / dot(edge, edge)))
				local nearest = madd(edge, along_edge, origin)
				result.normal = scale(sub(result.position, nearest), inverse_radius(radius))
				if region == 3 then
					result.volume_parameter = { along_edge, 0.0, 0.0 }
				elseif region == 4 then
					result.volume_parameter = { 0.0, along_edge, 0.0 }
				else
					result.volume_parameter = { f32(1.0 - along_edge), along_edge, 0.0 }
				end
				return true
			end
		end
		advance_fraction(result, fraction)
		start = madd(delta, fraction, start)
		delta = scale(delta, f32(1.0 - fraction))
		if fraction > 1.0 then
			return false
		end
	end
	-- The source returns success after its fifth transition. Position/normal/
	-- parameters have not been written by the walk on this path; preserve them.
	return true
end

return triangle_sweep_walk
