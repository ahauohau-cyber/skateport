--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/manager.rs (коммит 2e16697)
--
-- Manager leaves recovered from original TU3, independent of host storage.
-- ROBLOX: &mut u32 / &mut f32 -> ячейка { value = }.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")
local admission = require("./admission")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate

type V = { number }

local manager = {}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

-- 82D87460, after CalcNormalizedGrindDir82D37048.
function manager.directed_tangent(start: V, end_: V, velocity: V, previous: V): V
	local delta = sub(end_, start)
	local direction = scale(delta, arithmetic.reciprocal(arithmetic.square_root(dot3(delta, delta))))
	local speed = dot3(direction, velocity)
	if speed < 0.0 then
		direction = scale(direction, -1.0)
	end
	if math.abs(speed) < f32(0.1) and dot3(previous, direction) < -f32(0.9) then
		direction = scale(direction, -1.0)
	end
	return direction
end

export type GeometryInput = {
	valid: boolean,
	family: number,
	current_state: number,
	category: number,
	air_frames: number,
	geometry_kind: number,
	geometry_flags: number,
	far_points: { V },
	upmost: V,
	high_side: V,
	point: V,
	direction: V,
	board_position: V,
	board_forward: V,
	velocity: V,
	deck_to_truck: number,
	previous_exit_angle: number,
	previous_exit_direction: V,
	flags: number,
}

export type GeometryOutput = { valid: boolean, family: number, flags: number }

-- 82D883E0: height DIFFERENCE chooses the high-side sample, not two positive heights.
local function is_backslash(i: GeometryInput): boolean
	if i.family ~= 2 or i.current_state == 402 or bit32.btest(i.geometry_flags, 0x8000_0000) then
		return false
	end
	local offsets = { sub(i.far_points[1], i.point), sub(i.far_points[2], i.point) }
	local heights = { dot3(offsets[1], i.upmost), dot3(offsets[2], i.upmost) }
	if math.abs(f32(heights[1] - heights[2])) <= f32(i.deck_to_truck * f32(0.1)) then
		return false
	end
	local high = if heights[1] > heights[2] then offsets[1] else offsets[2]
	return dot3(sub(i.board_position, i.point), high) > 0.0
end

-- 82D880D0, with the retained one-truck exclusion owned by the investigator.
-- ROBLOX: avoid_five_o_frames: &mut u32 -> ячейка { value = }.
function manager.tweak_geometry(i: GeometryInput, avoid_five_o_frames: { value: number }): GeometryOutput
	local o: GeometryOutput = { valid = i.valid, family = i.family, flags = i.flags }
	if
		i.geometry_kind == 3
		or (i.family == 2 and bit32.btest(i.geometry_flags, 0x1000_0000) and i.category ~= 400 and i.air_frames < 20)
		or (i.family == 1 and bit32.btest(i.geometry_flags, 0x1000_0000))
	then
		o.valid = false
	end
	if o.valid and is_backslash(i) then
		o.family = 4
	end
	if o.valid and i.previous_exit_angle > 0.0 and i.geometry_kind ~= 2 and dot3(i.previous_exit_direction, i.high_side) < 0.0 then
		o.valid = false
	end
	if o.valid and i.geometry_kind ~= 0 then
		local transverse = sub(scale(i.direction, dot3(i.direction, i.velocity)), i.velocity)
		transverse[2] = 0.0
		if dot3(transverse, transverse) > 12.25 and dot3(i.velocity, i.high_side) < 0.0 then
			o.valid = false
		end
	end
	-- Source executes this branch even if an earlier check rejected validity.
	if o.family == 3 and i.geometry_kind == 2 then
		if rt.to_i32(avoid_five_o_frames.value) > 0 then
			o.valid = false
		else
			local hanging = if bit32.btest(o.flags, 0x2000_0000) then scale(i.board_forward, -1.0) else i.board_forward
			if dot3(hanging, i.high_side) > 0.0 then
				local vertical = dot3(hanging, i.upmost)
				o.flags = bit32.bor(bit32.band(o.flags, bit32.bnot(0x1000_0000)), if vertical < f32(0.19) then 0x1000_0000 else 0)
				if vertical < 0.0 then
					o.valid = false
					avoid_five_o_frames.value = 30
				end
			end
		end
	end
	return o
end

-- 82D8ACF0 / S2 ManageCopingAssistance82DDBC48. Update, then decrement, even
-- on the activation frame. FrictionVsTime is a different pre-update producer.
-- ROBLOX: timer: &mut f32 -> ячейка { value = }.
function manager.gravity_relief(
	timer: { value: number },
	valid: boolean,
	category: number,
	tangent: V,
	velocity: V,
	dt: number,
	vertical: point_graph.PointGraph,
	linear: point_graph.PointGraph
): number
	if valid and category == 100 and admission.engagement_slope_sine(tangent, velocity) > f32(0.85) then
		timer.value = f32(evaluate(vertical, velocity[2]) * evaluate(linear, math.abs(dot3(tangent, velocity))))
	end
	local next = f32(timer.value - dt)
	timer.value = if -next >= 0.0 then 0.0 else next
	return timer.value
end

export type JumpGeometry = {
	geometry_kind: number,
	high_side: V,
	normal: V,
	direction: V,
	upmost: V,
	point: V,
}

export type Jumper = {
	launched: boolean,
	cooldown: number,
	family: number,
	energy: number,
	geometry: JumpGeometry,
}

local Jumper = {}
manager.Jumper = Jumper

-- 82D8A318; original vector constants82139A10/82139A20 checked in memory.
-- ROBLOX: impl Default for Jumper.
function Jumper.default(): Jumper
	return {
		launched = false,
		cooldown = 0,
		family = 3,
		energy = 1.0,
		geometry = {
			geometry_kind = 0,
			high_side = { 1.0, 0.0, 0.0, 0.0 },
			normal = { 0.0, 1.0, 0.0, 0.0 },
			direction = { 1.0, 0.0, 0.0, 0.0 },
			upmost = { 0.0, 1.0, 0.0, 0.0 },
			point = { 0.0, 0.0, 0.0, 0.0 },
		},
	}
end

-- 82D739D8: invalid investigation retains geometry. Return a flag to OR,
-- not a replacement for the complete processed flags2476 word.
-- ROBLOX: Option<JumpGeometry> -> таблица или nil; u32::MAX -> 0xFFFFFFFF.
function Jumper.update(self: Jumper, geometry: JumpGeometry?, published_family: number): number
	self.launched = false
	local next = rt.wrapping_sub_u32(self.cooldown, 1)
	self.cooldown = if rt.to_i32(next) < 0 then 0 else next
	if geometry ~= nil then
		self.geometry = geometry
	end
	if published_family ~= 0xFFFF_FFFF then
		self.family = published_family
	end
	local energy = f32(self.energy + f32(0.0035))
	self.energy = if f32(1.0 - energy) >= 0.0 then energy else 1.0
	return if self.cooldown > 0 then 0x0200_0000 else 0
end

return manager
