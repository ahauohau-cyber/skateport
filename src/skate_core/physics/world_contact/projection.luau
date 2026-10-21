--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/projection.rs (коммит 2e16697)

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")
local axes = require("./axes")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local dot, scale, vector = arithmetic.dot, arithmetic.scale, arithmetic.vector

local projection = {}

-- Verified GP dispatch IDs from mapped TU3 table 82FD5870. Cylinder (5) and
-- invalid (0) are outside the board primitive set and have no fallback here.
-- pub enum PrimitiveKind { Sphere, Capsule, Triangle, Box }
-- ROBLOX: варианты без данных -> числа в порядке объявления.
local PrimitiveKind = {
	Sphere = 0,
	Capsule = 1,
	Triangle = 2,
	Box = 3,
}
projection.PrimitiveKind = PrimitiveKind

-- fn project(gp, kind, direction: [u32; 4], output: &mut [u32; 12], batch: bool)
local function project(gp: { number }, kind: number, direction_bits: { number }, output: { number }, batch: boolean)
	local direction = vector(direction_bits, 0)
	local center = dot(vector(gp, 0), direction)
	local min, max = 0.0, 0.0
	if kind == PrimitiveKind.Sphere then
		min, max = center, center
	elseif kind == PrimitiveKind.Capsule then
		local radius = f32(math.abs(dot(vector(gp, 16), direction)) * from_bits(gp[29]))
		min, max = f32(center - radius), f32(center + radius)
	elseif kind == PrimitiveKind.Triangle then
		local second = dot(vector(gp, 8), direction)
		local third = dot(vector(gp, 12), direction)
		-- VMX min/max select the second operand on unordered or equal.
		local lo = if center < second then center else second
		local hi = if center > second then center else second
		min = if lo < third then lo else third
		max = if hi > third then hi else third
	else
		local extent = {}
		for i = 0, 2 do
			local axis = vector(gp, 4 + i * 4)
			local half = from_bits(gp[28 + i + 1])
			if batch then
				extent[i + 1] = math.abs(dot(scale(axis, half), direction))
			else
				extent[i + 1] = math.abs(f32(dot(axis, direction) * half))
			end
		end
		local radius = f32(f32(extent[1] + extent[2]) + extent[3])
		min, max = f32(center - radius), f32(center + radius)
	end
	rt.fill(output, 0, 4, to_bits(min :: number))
	rt.fill(output, 4, 8, to_bits(max :: number))
end

-- Full single-direction GP interval callbacks: sphere82ADD800,
-- capsule82AD99C8, triangle82ADE3B8, box82AD8508. Output is the native48-byte
-- interval; the last16bytes are untouched. Radius/padding is handled by caller.
-- pub fn project_direction(gp: &[u32; 48], kind, direction: [u32; 4], output: &mut [u32; 12])
function projection.project_direction(gp: { number }, kind: number, direction: { number }, output: { number })
	project(gp, kind, direction, output, false)
end

-- Full batch GP callbacks: sphere82ADD820, capsule82AD9A88,
-- triangle82ADE400, box82AD86B0. Box batch scales the axes *before* dot products;
-- its single callback scales the dot products instead. Preserve that difference.
-- pub fn project_directions(gp, kind, directions: &[[u32; 4]], output: &mut [[u32; 12]])
-- ROBLOX: срез directions -> таблица и явная длина count.
function projection.project_directions(gp: { number }, kind: number, directions: { { number } }, count: number, output: { { number } })
	assert(#output >= count)
	for i = 1, count do
		project(gp, kind, directions[i], output[i], true)
	end
end

-- Complete generic82ACF070 plus recovered GP batch callbacks for board shapes.
-- Specialized triangle/box82ACF950 and box/box82ACF448 dispatch entries must
-- still be selected by the caller; this function is only the generic entry.
-- Returns (broadcast separation, oriented four-lane axis).
-- pub fn best_separating_direction(a, a_kind, b, b_kind) -> ([u32; 4], [u32; 4])
function projection.best_separating_direction(a: { number }, a_kind: number, b: { number }, b_kind: number): ({ number }, { number })
	local directions = {}
	for i = 1, 16 do
		directions[i] = rt.zeros(4)
	end
	local count = axes.separating_axis_candidates(a, b, directions)
	if count == 0 then
		directions[1] = { 0, 0, to_bits(1.0), 0 }
		count = 1
	end
	local a_intervals, b_intervals = {}, {}
	for i = 1, 16 do
		a_intervals[i] = rt.zeros(12)
		b_intervals[i] = rt.zeros(12)
	end
	projection.project_directions(a, a_kind, directions, count, a_intervals)
	projection.project_directions(b, b_kind, directions, count, b_intervals)
	local selected = 0
	local best = 0.0
	local flip = false
	for index = 0, count - 1 do
		local forward = f32(from_bits(a_intervals[index + 1][1]) - from_bits(b_intervals[index + 1][5]))
		local reverse = f32(from_bits(b_intervals[index + 1][1]) - from_bits(a_intervals[index + 1][5]))
		-- fcmpu followed by ble (!gt): unordered selects reverse without flip.
		local separation, reversed
		if forward > reverse then
			separation, reversed = forward, true
		else
			separation, reversed = reverse, false
		end
		if index == 0 or separation > best then
			best = separation
			selected = index
			flip = reversed
		end
	end
	local normal = directions[selected + 1]
	if flip then
		normal = rt.flip_sign_bits(normal)
	end
	local b_bits = to_bits(best)
	return { b_bits, b_bits, b_bits, b_bits }, normal
end

return projection
