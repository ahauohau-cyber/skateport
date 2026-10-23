--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces.rs (коммит 2e16697)
--
-- TU3 grind force leaves. Their inputs belong to the retained grind manager;
-- contact admission and lifecycle are separate from these force calculations.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел (Rust v[1] -> v[2]); Option -> значение или nil.
-- Приватные sub/scale/length/reciprocal открыты подмодулям через поле parent.
-- TODO: подмодули post (нужен player::wipeout) и reckoning (нужен
-- air::reckoning) будут добавлены, когда их зависимости будут портированы.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local board_motion_output = require("./board_motion_output")
local point_graph = require("../point_graph")
local slide = require("@self/slide")
local release = require("@self/release")
local noise = require("@self/noise")
local launch = require("@self/launch")
local orientation = require("@self/orientation")
local support = require("@self/support")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate

export type V = { number }

local grind_forces = {}
grind_forces.slide = slide
grind_forces.release = release
grind_forces.noise = noise
grind_forces.launch = launch
grind_forces.orientation = orientation
grind_forces.support = support

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function length(v: V): number
	local square = dot3(v, v)
	if square == 0.0 then
		return 0.0
	end
	return f32(square * board_motion_output.inverse_length_squared(square, 2))
end
local function reciprocal(value: number): number
	-- ROBLOX: value.recip() -> f32(1 / value).
	local inverse = f32(1.0 / value)
	for _ = 1, 2 do
		local correction = mul_add(-inverse, value, 1.0)
		inverse = mul_add(inverse, correction, inverse)
	end
	return inverse
end
grind_forces.sub = sub
grind_forces.scale = scale
grind_forces.length = length
grind_forces.reciprocal = reciprocal

-- 82D3FA18, called by the 50-50 update82D41D70 with800,0,.07.
-- Returns a force at the deck origin; None means no accumulator call.
function grind_forces.lateral_pin(
	board: { V },
	point: V,
	across: V,
	velocity: V,
	strength: number,
	forward_offset: number,
	up_offset: number,
	forward_selected: boolean,
	slope_multiplier: number
): V?
	local direction = if forward_selected then board[3] else scale(board[3], -1.0)
	local reference = {}
	for i = 1, 4 do
		reference[i] = f32(mul_add(direction[i], forward_offset, board[4][i]) - f32(board[2][i] * up_offset))
	end
	local force = scale(across, f32(dot3(sub(point, reference), across) * strength))
	local len = length(force)
	if not (len > 0.0) then
		return nil
	end
	local axis = scale(force, reciprocal(len))
	local damping = scale(axis, f32(f32(strength * from_bits(0x3e08_3127)) * dot3(velocity, axis)))
	return scale(sub(force, damping), slope_multiplier)
end

-- 82D3FD88 after its native surface/material selection. It damps velocity in
-- the plane perpendicular to the grind normal, including the along-rail lane.
function grind_forces.friction(
	velocity: V,
	grind_normal: V,
	support_: V,
	time_multiplier: number,
	flagged_surface: boolean,
	surface_multiplier: number,
	geometry_kind: number,
	strengths: { number }
): V
	local tangent_velocity = sub(velocity, scale(grind_normal, dot3(velocity, grind_normal)))
	local speed = length(tangent_velocity)
	if speed <= f32(0.001) then
		return { 0.0, 0.0, 0.0, 0.0 }
	end
	local strength = strengths[if geometry_kind == 0 then 1 elseif geometry_kind == 1 then 2 else 3]
	local load = rt.fmax(support_[2], 0.0)
	local surface_flag_multiplier = if flagged_surface then f32(1.9) else 1.0
	local multiplier = f32(load / speed)
	multiplier = f32(multiplier * time_multiplier)
	multiplier = f32(multiplier * surface_flag_multiplier)
	multiplier = f32(multiplier * surface_multiplier)
	multiplier = f32(multiplier * strength)
	multiplier = f32(multiplier * from_bits(0xbef5_c28f))
	return scale(tangent_velocity, multiplier)
end

-- 82D3FD88 skips the accumulator call at or below its planar-speed threshold.
function grind_forces.friction_applies(velocity: V, normal: V): boolean
	local planar = sub(velocity, scale(normal, dot3(velocity, normal)))
	return length(planar) > f32(0.001)
end

-- 82D3FD88's material switch. S3 adds material13 to S2's material2 case.
function grind_forces.material_multiplier(material: number): number
	if material == 2 or material == 13 then
		return f32(1.7)
	elseif material == 3 then
		return f32(2.6)
	elseif material == 4 then
		return f32(0.6)
	elseif material == 5 then
		return 4.0
	elseif material == 6 then
		return 5.0
	end
	return f32(1.3)
end

-- 82D3FA18: gravity relief bypasses the authored PinVsSlope four-point graph.
function grind_forces.pin_slope(normal: V, upmost_normal: V, gravity_relief: number, pin_vs_slope: point_graph.PointGraph): number
	if gravity_relief > 0.0 then
		return 1.0
	end
	return evaluate(pin_vs_slope, dot3(normal, upmost_normal))
end

launch.parent = grind_forces
orientation.parent = grind_forces

return grind_forces
