--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/triangle_closest.rs (коммит 2e16697)
--
-- TU3 triangle closest-feature calculation82ADE8B8.

local rt = require("../../rt")
local triangle_query = require("./triangle_query")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, madd, sub = triangle_query.dot, triangle_query.madd, triangle_query.sub

local triangle_closest = {}

-- pub(super) struct ClosestTrianglePoint
export type ClosestTrianglePoint = {
	point: vector,
	-- Vertex0..2, edge AB/AC/BC3..5, face6, as used by82ADEB70.
	region: number, -- u32
	u: number,
	v: number,
}

-- pub(super) fn closest(point: Vector3, vertices: [Vector3; 3]) -> ClosestTrianglePoint
function triangle_closest.closest(point: vector, vertices: { vector }): ClosestTrianglePoint
	local origin, b, c = vertices[1], vertices[2], vertices[3]
	local edge_b = sub(b, origin)
	local edge_c = sub(c, origin)
	local toward_origin = sub(origin, point)
	local bb = dot(edge_b, edge_b)
	local cc = dot(edge_c, edge_c)
	local bc = dot(edge_b, edge_c)
	local bp = dot(edge_b, toward_origin)
	local cp = dot(edge_c, toward_origin)
	local determinant = mul_add(cc, bb, -f32(bc * bc))
	local u_numerator = mul_add(cp, bc, -f32(bp * cc))
	local v_numerator = mul_add(bp, bc, -f32(cp * bb))
	local opposite_length_squared = f32(mul_add(-bc, 2.0, bb) + cc)
	local feature
	if determinant < from_bits(0x0020_0000) then
		if bb > cc then
			feature = if bb > opposite_length_squared then 0 else 2
		elseif cc > opposite_length_squared then
			feature = 1
		else
			feature = 2
		end
	elseif f32(u_numerator + v_numerator) > determinant then
		if u_numerator < 0.0 then
			feature = if f32(cp + cc) < f32(bp + bc) then 1 else 2
		elseif v_numerator < 0.0 then
			feature = if f32(bp + bb) < f32(cp + bc) then 0 else 2
		else
			feature = 2
		end
	elseif u_numerator < 0.0 then
		feature = if -cp > 0.0 then 1 else 0
	elseif v_numerator < 0.0 then
		feature = if -bp > 0.0 then 0 else 1
	else
		feature = 3
	end

	local u, v, region
	if feature == 0 then
		if not (bp < 0.0) then
			u, v, region = 0.0, 0.0, 0
		elseif not (-bp < bb) then
			u, v, region = 1.0, 0.0, 1
		else
			u, v, region = -f32(bp / bb), 0.0, 3
		end
	elseif feature == 1 then
		if not (cp < 0.0) then
			u, v, region = 0.0, 0.0, 0
		elseif not (-cp < cc) then
			u, v, region = 0.0, 1.0, 2
		else
			u, v, region = 0.0, -f32(cp / cc), 4
		end
	elseif feature == 2 then
		local numerator = f32(f32(f32(cp + cc) - bc) - bp)
		if not (numerator > 0.0) then
			u, v, region = 0.0, 1.0, 2
		elseif not (numerator < opposite_length_squared) then
			u, v, region = 1.0, 0.0, 1
		else
			local w = f32(numerator / opposite_length_squared)
			u, v, region = w, f32(1.0 - w), 5
		end
	else
		local inverse = f32(1.0 / determinant)
		u, v, region = f32(inverse * u_numerator), f32(inverse * v_numerator), 6
	end
	return {
		point = madd(edge_c, v, madd(edge_b, u, origin)),
		region = region,
		u = u,
		v = v,
	}
end

return triangle_closest
