--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/balance.rs (коммит 2e16697)
--
-- S3 TU3 GrindBalance: 82D86318, 82D86808, 82D86C88; constructor82D8A318.
-- S2 counterparts82DD2168/82DD64D8/82DD26C0 corroborate field identities.
-- Keep these three stages in that order, after geometry correction and before
-- engagement. Independent PC arithmetic is not bit-exact Xenon emulation.
-- ROBLOX: Option<&BalanceContact> -> таблица или nil; &mut BalanceVectors ->
-- поля таблицы меняются на месте; &mut u32 -> ячейка { value = }.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")
local admission = require("./admission")
local grind_surface = require("../../air/trajectory/grind_surface")
local point_graph = require("../../point_graph")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate
local EntryKind = admission.EntryKind
local GeometryType = grind_surface.GeometryType

type V = { number }

local balance = {}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end

export type BalanceState = {
	elapsed: number,
	exit_angle_degrees: number,
	entry_delay: number,
	frames_away: number,
	-- Unrotated normal retained by82D86318, not the exit-lean output normal.
	previous_normal: V,
	exit_direction: V,
}

local BalanceState = {}
balance.BalanceState = BalanceState

-- 82D8A4BC..82D8A4EC; original vectors82139A20 and82139A10.
-- ROBLOX: impl Default for BalanceState.
function BalanceState.default(): BalanceState
	return {
		elapsed = 0.0,
		exit_angle_degrees = 0.0,
		entry_delay = 2.0,
		frames_away = 21,
		previous_normal = { 0.0, 1.0, 0.0, 0.0 },
		exit_direction = { 1.0, 0.0, 0.0, 0.0 },
	}
end

-- A valid, geometry-corrected investigation, never a synthesized surface.
export type BalanceContact = {
	surface: grind_surface.GrindSurface,
	-- Investigation+0; distinct from travel-directed investigation+32.
	primitive_direction: V,
	directed_grind_direction: V,
	kind: number,
	entry_kind: number,
}

export type TargetUpInput = {
	category: number,
	-- Processed+2504, NOT current state+2508.
	previous_state: number,
	board_up: V,
}

export type ExitLeanInput = {
	category: number,
	-- Processed+2508, unlike TargetUpInput::previous_state.
	current_state: number,
	-- Processed+2536; value2 freezes the elapsed-time increment.
	grind_substate: number,
	timestep: number,
}

-- Investigation+48/+64, deliberately without a fabricated default.
export type BalanceVectors = { grind_normal: V, target_up: V }

export type ForceExitProbe = { start: V, ["end"]: V }
export type ForceExitHit = { normal: V }

local function magnitude(value: V): number
	return arithmetic.square_root(dot3(value, value))
end

local function blend(a: V, a_weight: number, b: V, b_weight: number): V
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(a[i], a_weight, f32(b[i] * b_weight))
	end
	return out
end

local function negate(value: V): V
	return { -value[1], -value[2], -value[3], -value[4] }
end

local function retain_side(previous: V, side: V): V
	if dot3(previous, side) > 0.0 then
		return side
	end
	return negate(side)
end

-- 82C1E220 and82D86BC0..C70: quaternion half-angle rotation, not a
-- Rodrigues replacement with a different operation order.
local function rotate(axis: V, value: V, angle: number): V
	local sin, cos = trigonometry.sin_cos(f32(angle * 0.5))
	local q = scale(axis, sin)
	local first_cross = cross(q, value)
	local intermediate = table.create(4) :: any
	for i = 1, 4 do
		intermediate[i] = mul_add(value[i], cos, first_cross[i])
	end
	local second_cross = cross(q, intermediate)
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(second_cross[i], 2.0, value[i])
	end
	return out
end

-- ROBLOX: приватные fn rotate/negate открыты для переноса Rust-тестов.
balance.rotate = rotate
balance.negate = negate

-- 82D86318. None is the native invalid-candidate no-write branch.
function BalanceState.update_target_up(self: BalanceState, input: TargetUpInput, contact: BalanceContact?, vectors: BalanceVectors)
	if contact == nil then
		return
	end
	local surface = contact.surface
	local normal
	if input.category ~= 400 then
		normal = input.board_up
	elseif input.previous_state == 402 or input.previous_state == 404 then
		normal = blend(self.previous_normal, f32(0.85), surface.upmost_normal, from_bits(0x3e19_9998))
	else
		normal = blend(self.previous_normal, f32(0.925), surface.tilted_upmost_normal, from_bits(0x3d99_9998))
	end
	local direction = contact.directed_grind_direction
	local projected = cross(cross(direction, normal), direction)
	local length = magnitude(projected)
	vectors.grind_normal = if length <= f32(0.001) then surface.upmost_normal else scale(projected, arithmetic.reciprocal(length))
	self.previous_normal = vectors.grind_normal

	local target = blend(input.board_up, f32(0.8), surface.upmost_normal, from_bits(0x3e4c_cccc))
	-- Unlike the projected-normal and rotation-axis branches, the original
	-- has NO zero-length fallback here. Do not silently invent one.
	vectors.target_up = scale(target, arithmetic.reciprocal(magnitude(target)))
	local alignment = fmin(fmax(dot3(vectors.grind_normal, vectors.target_up), -1.0), 1.0)
	local max_angle = from_bits(0x3e7a_35dd)
	if trigonometry.acos(alignment) > max_angle then
		local axis = cross(vectors.grind_normal, vectors.target_up)
		local axis_length = magnitude(axis)
		if axis_length <= f32(0.001) then
			vectors.target_up = vectors.grind_normal
		else
			vectors.target_up = rotate(scale(axis, arithmetic.reciprocal(axis_length)), vectors.grind_normal, max_angle)
		end
	end
end

-- 82D86808. Returns investigation+396 even without a valid candidate.
-- Graph is physics_grinds.ExitLeanAngleVsTime, eight X at+16/Y at+48.
function BalanceState.update_exit_lean(
	self: BalanceState,
	input: ExitLeanInput,
	contact: BalanceContact?,
	exit_lean_angle_vs_time: point_graph.PointGraph,
	vectors: BalanceVectors
): number
	local active = input.category == 400 or input.current_state == 701 or contact ~= nil
	-- ROBLOX: i32::wrapping_add(1).
	self.frames_away = if active then 0 else rt.to_i32(self.frames_away + 1)
	local droppable = false
	if contact ~= nil then
		if contact.kind == 2 then
			droppable = active and contact.surface.kind ~= GeometryType.ThinRail
		else
			droppable = contact.surface.kind == GeometryType.Ledge
		end
	end
	local started = false
	-- 82D86880..94's carry/sign sequence implements a signed >20 test.
	if self.frames_away > 20 then
		self.exit_angle_degrees = 0.0
		self.elapsed = 0.0
		self.entry_delay = 2.0
	elseif self.elapsed > 0.0 or (active and droppable and contact ~= nil) then
		if self.elapsed == 0.0 then
			-- Only a real contact can start the timer in this branch.
			if contact ~= nil then
				if contact.entry_kind == EntryKind.RideFromBelow then
					self.entry_delay = f32(0.8)
				elseif contact.entry_kind == EntryKind.RideIntoCoping then
					self.entry_delay = f32(0.1)
				else
					self.entry_delay = 2.0
				end
			end
			started = true
		end
		if input.grind_substate ~= 2 then
			self.elapsed = f32(input.timestep + self.elapsed)
		end
	end
	if self.elapsed <= 0.0 then
		return self.exit_angle_degrees
	end
	local time = f32(self.elapsed - self.entry_delay)
	self.exit_angle_degrees = if time <= 0.0 then 0.0 else evaluate(exit_lean_angle_vs_time, time)
	if contact ~= nil then
		local surface = contact.surface
		if surface.kind == GeometryType.ThinRail then
			self.exit_direction = retain_side(self.exit_direction, cross(surface.upmost_normal, contact.primitive_direction))
		elseif started then
			self.exit_direction = surface.high_side
		else
			self.exit_direction = retain_side(self.exit_direction, surface.high_side)
		end
		if self.exit_angle_degrees > 0.0 then
			local direction = contact.directed_grind_direction
			local axis = if cross(direction, self.exit_direction)[2] > 0.0 then direction else negate(direction)
			local radians = f32(self.exit_angle_degrees * from_bits(0x3c8e_fa35))
			-- Both outputs rotate; previous_normal deliberately does not.
			vectors.target_up = rotate(axis, vectors.target_up, radians)
			vectors.grind_normal = rotate(axis, vectors.grind_normal, radians)
		end
	end
	return self.exit_angle_degrees
end

-- 82D86C88. The callback must execute the real thin nearest world-line
-- query82E0AAD0, retaining its filtering and endpoint/edge tolerances.
-- No query is issued outside (15,28]. Errors are not collision misses.
-- Updates only investigation+412 bit31, and leaves flags intact on error.
-- ROBLOX: investigation_flags: &mut u32 -> ячейка { value = };
-- world_line(probe) -> ForceExitHit? ; ошибка колбэка — rt.raise (проходит насквозь).
function BalanceState.update_force_exit(
	self: BalanceState,
	primitive_location: V,
	investigation_flags: { value: number },
	world_line: (ForceExitProbe) -> ForceExitHit?
)
	local force_exit
	if self.exit_angle_degrees > 28.0 then
		force_exit = true
	elseif self.exit_angle_degrees > 15.0 then
		local start = sub(primitive_location, scale(self.exit_direction, f32(0.1)))
		local end_ = add(start, { 0.0, -5.0, 0.0, 0.0 })
		local hit = world_line({ start = start, ["end"] = end_ })
		if hit ~= nil then
			force_exit = dot3(self.exit_direction, hit.normal) > -f32(0.1)
		else
			force_exit = true
		end
	else
		force_exit = false
	end
	investigation_flags.value = bit32.bor(bit32.band(investigation_flags.value, 0x7fff_ffff), if force_exit then 0x8000_0000 else 0)
end

return balance
