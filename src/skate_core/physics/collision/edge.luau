--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/edge.rs (коммит 2e16697)
--
-- TU3 EdgeCosTest / EdgeCosTestFull, 82AD2860 / 82AD2928.

local arithmetic = require("./arithmetic")

local dot, cross, normalize, sub, scale, neg =
	arithmetic.dot, arithmetic.cross, arithmetic.normalize, arithmetic.sub, arithmetic.scale, arithmetic.neg

local edge = {}

-- pub(super) fn edge_cos_test(edge, face, normal: Vector3, cosine: f32, convex: bool, two_sided: bool) -> bool
function edge.edge_cos_test(
	edge_direction: vector,
	face: vector,
	normal: vector,
	cosine: number,
	convex: boolean,
	two_sided: boolean
): boolean
	if dot(normal, cross(edge_direction, face)) < 0.0 then
		return true
	end
	if not convex and not two_sided then
		return false
	end
	local projected = normalize(sub(normal, scale(edge_direction, dot(normal, edge_direction))), 2)
	return dot(projected, if convex then face else neg(face)) >= cosine
end

return edge
