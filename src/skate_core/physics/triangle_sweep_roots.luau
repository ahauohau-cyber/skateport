--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/triangle_sweep_roots.rs (коммит 2e16697)
--
-- Vertex/edge roots in TU3's triangle feature walk:82ADDB48/82ADA3E0.

local rt = require("../../rt")
local triangle_query = require("./triangle_query")

local f32 = rt.f32
local mul_add = rt.mul_add
local cross, dot, sub = triangle_query.cross, triangle_query.dot, triangle_query.sub

local triangle_sweep_roots = {}

-- pub(super) struct Fraction { numerator: f32, denominator: f32 }
export type Fraction = {
	numerator: number,
	denominator: number,
}

local Fraction = {}
triangle_sweep_roots.Fraction = Fraction

-- pub fn value(self) -> f32
function Fraction.value(self: Fraction): number
	return f32(self.numerator / self.denominator)
end

-- pub fn before(self, other: Self) -> bool
function Fraction.before(self: Fraction, other: Fraction): boolean
	return f32(self.numerator * other.denominator) < f32(other.numerator * self.denominator)
end

-- pub(super) enum Root { Away, Miss, Hit(Fraction) }
-- ROBLOX: enum с данными -> таблица { kind = "Away" | "Miss" | "Hit", fraction = Fraction? }.
export type Root = {
	kind: string,
	fraction: Fraction?,
}

local AWAY: Root = { kind = "Away" }
local MISS: Root = { kind = "Miss" }
triangle_sweep_roots.AWAY = AWAY
triangle_sweep_roots.MISS = MISS

local function hit(numerator: number, denominator: number): Root
	return { kind = "Hit", fraction = { numerator = numerator, denominator = denominator } }
end

-- pub(super) fn sphere(start, delta, center: Vector3, radius: f32) -> Root
function triangle_sweep_roots.sphere(start: vector, delta: vector, center: vector, radius: number): Root
	local toward_center = sub(center, start)
	local radius_squared = f32(radius * radius)
	if dot(toward_center, toward_center) < radius_squared then
		return hit(0.0, 1.0)
	end
	local approach = dot(toward_center, delta)
	if not (approach > 0.0) then
		return AWAY
	end
	local delta_squared = dot(delta, delta)
	local perpendicular = cross(toward_center, delta)
	local discriminant = mul_add(delta_squared, radius_squared, -dot(perpendicular, perpendicular))
	if discriminant < 0.0 then
		return MISS
	end
	local overrun = f32(approach - delta_squared)
	if overrun > 0.0 and f32(overrun * overrun) > discriminant then
		return MISS
	end
	return hit(f32(approach - f32(math.sqrt(discriminant))), delta_squared)
end

-- pub(super) fn cylinder(start, delta, origin, edge: Vector3, radius: f32) -> Root
function triangle_sweep_roots.cylinder(start: vector, delta: vector, origin: vector, edge: vector, radius: number): Root
	local perpendicular = cross(sub(origin, start), edge)
	local distance_squared = dot(perpendicular, perpendicular)
	local radius_squared = f32(f32(dot(edge, edge) * radius) * radius)
	if distance_squared < radius_squared then
		return hit(0.0, 1.0)
	end
	local delta_perpendicular = cross(delta, edge)
	local approach = dot(perpendicular, delta_perpendicular)
	if not (approach > 0.0) then
		return AWAY
	end
	local delta_squared = dot(delta_perpendicular, delta_perpendicular)
	local residual = mul_add(approach, approach, -f32(delta_squared * distance_squared))
	local discriminant = mul_add(delta_squared, radius_squared, residual)
	if discriminant < 0.0 then
		return MISS
	end
	local overrun = f32(approach - delta_squared)
	-- Cylinder rejects equality here; the sphere helper uses strict greater.
	if not (overrun < 0.0) and not (f32(overrun * overrun) < discriminant) then
		return MISS
	end
	return hit(f32(approach - f32(math.sqrt(discriminant))), delta_squared)
end

return triangle_sweep_roots
