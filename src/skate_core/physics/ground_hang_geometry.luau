--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/ground_hang_geometry.rs (коммит 2e16697)
--
-- Geometry actually observed by Ground::ManageHangUps82D39510.
-- The caller reads only query completion, geometry kind104 and flag29 from
-- 82C20C08; unrelated grind surface classifications are not used in this path.

local rt = require("../../rt")
local bmo = require("./board_motion_output")
local board_world = require("./board_world")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, inverse_length_squared = bmo.dot, bmo.inverse_length_squared

type Vector3 = vector

local ground_hang_geometry = {}

export type HangGeometryInput = {
	-- Processed1312,1328 and1232, respectively.
	edge_start: Vector3,
	edge_end: Vector3,
	reference_point: Vector3,
}

export type HangLine = { start: Vector3, ["end"]: Vector3, radius: number }

local function cross(a: Vector3, b: Vector3): Vector3
	return vector.create(mul_add(-a.z, b.y, f32(a.y * b.z)), mul_add(-a.x, b.z, f32(a.z * b.x)), mul_add(-a.y, b.x, f32(a.x * b.y)))
end
local function add(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x + b.x), f32(a.y + b.y), f32(a.z + b.z))
end
local function sub(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end
local function scale(a: Vector3, k: number): Vector3
	return vector.create(f32(a.x * k), f32(a.y * k), f32(a.z * k))
end
local function madd(a: Vector3, k: number, b: Vector3): Vector3
	return vector.create(mul_add(a.x, k, b.x), mul_add(a.y, k, b.y), mul_add(a.z, k, b.z))
end
local function normalize_or_retain(v: Vector3): (Vector3, number)
	local square = dot(v, v)
	local inverse = inverse_length_squared(square, 2)
	local length = if square == 0.0 then 0.0 else f32(square * inverse)
	return (if length > from_bits(0x3586_37bd) then scale(v, inverse) else v), length
end

-- /// Full six-line branch82C20728 used by82D397A0. Input's optional seventh
-- /// line byte is zeroed by82C20530 and never set by this ground caller.
-- ROBLOX: Option<[HangLine; 6]> -> массив или nil.
function ground_hang_geometry.hang_lines(input: HangGeometryInput, deck_center_to_truck: number): { HangLine }?
	local delta = sub(input.edge_end, input.edge_start)
	local first = cross(vector.create(0.0, 1.0, 0.0), delta)
	local raw_up = cross(delta, first)
	local up, length = normalize_or_retain(raw_up)
	local direction = normalize_or_retain(delta)
	if length < from_bits(0x3727_c5ac) then
		return nil
	end
	local on_edge = madd(direction, dot(sub(input.reference_point, input.edge_start), direction), input.edge_start)
	-- Preserve the native pair of subtractions rather than canceling them.
	local center = sub(input.reference_point, sub(input.reference_point, on_edge))
	local side = cross(up, direction)
	local short_up = scale(up, f32(0.04))
	local near_side = scale(side, f32(0.09))
	local far_side = scale(side, deck_center_to_truck)
	local far_up = scale(up, f32(deck_center_to_truck * from_bits(0x3f87_ae14)))
	local last_up = scale(up, f32(0.09))
	local function line(c: Vector3, u: Vector3, radius: number): HangLine
		return { start = add(c, u), ["end"] = sub(c, u), radius = radius }
	end
	return {
		line(add(center, near_side), short_up, 0.0),
		line(sub(center, near_side), short_up, 0.0),
		line(add(center, far_side), far_up, 0.0),
		line(sub(center, far_side), far_up, 0.0),
		line(center, short_up, 0.0),
		line(add(center, last_up), near_side, f32(0.001)),
	}
end

-- ROBLOX: [Option<f32>; 6] -> массив, где отсутствие — false.
function ground_hang_geometry.hung_classification(hits: { number | false }): boolean
	if (hits[1] ~= false and hits[2] ~= false) or hits[5] ~= false then
		return false
	end
	local kind
	if hits[1] ~= false then
		kind = if hits[3] ~= false and (hits[3] :: number) < f32(0.65) then 2 else 1
	elseif hits[2] ~= false then
		kind = if hits[4] ~= false and (hits[4] :: number) < f32(0.65) then 2 else 1
	else
		kind = 0
	end
	return kind ~= 2
end

-- /// 82C20ED4..82C20F84 and Ground's82D397EC..82D39810. We execute all six
-- /// native queries, then use the exact two classification fields read by Ground.
-- ROBLOX: Result<bool, &str> -> (bool?, ошибка?), как BoardWorld.query_swept_line.
function ground_hang_geometry.detect_hung_geometry(world: any, input: HangGeometryInput, deck_center_to_truck: number): (boolean?, string?)
	local lines = ground_hang_geometry.hang_lines(input, deck_center_to_truck)
	if lines == nil then
		return false, nil
	end
	local fractions: { number | false } = table.create(6, false)
	for i, line in lines do
		local hit, err = board_world.BoardWorld.query_swept_line(world, line.start, line["end"], line.radius)
		if err ~= nil then
			return nil, err
		end
		fractions[i] = if hit ~= nil then hit.geometry.fraction else false
	end
	return ground_hang_geometry.hung_classification(fractions), nil
end

return ground_hang_geometry
