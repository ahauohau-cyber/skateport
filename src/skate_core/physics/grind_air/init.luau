--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air.rs (коммит 2e16697)
--
-- Original S3 82D71138/82D34FE8/82D712E0, with persistent native histories.
-- Independent PC arithmetic; not a bit-exact Xenon emulation claim.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел; Frame — 4 таких вектора.
-- Массивы с нулевой индексацией в Rust (headings[kind]) -> [kind + 1].
-- Подмодули (`use super::*`) получают этот модуль через поле parent.
-- Result<Option<Adjustment>, String> -> Adjustment, nil или rt.raise(строка).

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local trigonometry = require("../trigonometry")
local angles = require("@self/angles")
local pose = require("@self/pose")
local prediction = require("@self/prediction")
local selection = require("@self/selection")
local targets = require("@self/targets")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax

export type V = { number }
export type Frame = { V }

local grind_air = {}
grind_air.angles = angles
grind_air.pose = pose
grind_air.prediction = prediction
grind_air.selection = selection
grind_air.targets = targets
grind_air.DeckDimensions = targets.DeckDimensions
grind_air.Settings = targets.Settings
export type PoseInput = pose.PoseInput
export type Settings = targets.Settings
export type DeckDimensions = targets.DeckDimensions

function grind_air.zero(): V
	return { 0.0, 0.0, 0.0, 0.0 }
end
local zero = grind_air.zero
grind_air.UP = table.freeze({ 0.0, 1.0, 0.0, 0.0 })
grind_air.DEG = from_bits(0x3c8e_fa35)
grind_air.RAD = from_bits(0x4265_2ee1)
grind_air.PI = from_bits(0x4049_0fdb)
grind_air.TAU = from_bits(0x40c9_0fdb)
local TAU = grind_air.TAU

export type Target = {
	edge: { start: V, ["end"]: V, owner: number },
	primitive_flags: number,
	orientation: any, -- LandingOrientation
}
export type Input = {
	active: boolean,
	board: Frame,
	velocity: V,
	angular_velocity: V,
	up: V,
	timestep: number,
	flags_2468: number,
	flags_2472: number,
	flags_2480: number,
	flags_2484: number,
}
export type Adjustment = { axis: V, offset: V, angles: V }

export type GrindAir = {
	target: Target?,
	offset_delta: V,
	offset: V,
	angle_delta: V,
	angles: V,
	selected_kind: number?,
	-- Native array is initialized once, not cleared on each prediction.
	headings: { number },
}

-- helpers (fn dot/sub/add/scale/madd/cross/inverse_length/reciprocal/length/unit/limited/wrap/signed_angle)
function grind_air.dot(a: V, b: V): number
	return native_arithmetic.dot3(a, b)
end
local dot = grind_air.dot
function grind_air.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local sub = grind_air.sub
function grind_air.add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local add = grind_air.add
function grind_air.scale(v: V, s: number): V
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end
local scale = grind_air.scale
function grind_air.madd(v: V, s: number, a: V): V
	return { mul_add(v[1], s, a[1]), mul_add(v[2], s, a[2]), mul_add(v[3], s, a[3]), mul_add(v[4], s, a[4]) }
end
function grind_air.cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end
local cross = grind_air.cross
function grind_air.inverse_length(square: number): number
	local r = native_arithmetic.reciprocal_square_root_estimate(square)
	for _ = 1, 2 do
		r = mul_add(f32(r * 0.5), mul_add(-square, f32(r * r), 1.0), r)
	end
	return r
end
local inverse_length = grind_air.inverse_length
function grind_air.reciprocal(value: number): number
	local r = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		r = mul_add(r, mul_add(-r, value, 1.0), r)
	end
	return r
end
local reciprocal = grind_air.reciprocal
function grind_air.length(v: V): number
	local s = dot(v, v)
	if s == 0.0 then
		return 0.0
	end
	return f32(s * inverse_length(s))
end
local length = grind_air.length
function grind_air.unit(v: V): V
	local s = dot(v, v)
	local r = inverse_length(s)
	local magnitude = if s == 0.0 then 0.0 else f32(s * r)
	if magnitude > from_bits(0x3586_37bd) then
		return scale(v, r)
	end
	return zero()
end
local unit = grind_air.unit
function grind_air.limited(v: V, maximum: number): V
	local magnitude = length(v)
	if magnitude > maximum then
		return scale(v, f32(maximum * reciprocal(magnitude)))
	end
	return v
end
local limited = grind_air.limited
function grind_air.wrap(angle: number): number
	local turns = f32(angle * from_bits(0x3e22_f983))
	local fraction = f32(turns - math.floor(turns))
	return f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * TAU)
end
-- 8296EC98: one refinement, positive full-turn signed angle then8258DB98 wrap.
function grind_air.signed_angle(a: V, b: V, axis: V): number
	local aa = dot(a, a)
	local bb = dot(b, b)
	if not (aa > from_bits(0x38d1_b717) and bb > from_bits(0x38d1_b717)) then
		return 0.0
	end
	local function normalize(v: V, square: number): V
		local r = native_arithmetic.reciprocal_square_root_estimate(square)
		return scale(v, mul_add(f32(r * 0.5), mul_add(-square, f32(r * r), 1.0), r))
	end
	local na = normalize(a, aa)
	local nb = normalize(b, bb)
	local angle = trigonometry.acos(fmin(fmax(dot(na, nb), -1.0), 1.0))
	return grind_air.wrap(if dot(cross(na, nb), axis) < 0.0 then f32(TAU - angle) else angle)
end

local GrindAir = {}
grind_air.GrindAir = GrindAir

-- ROBLOX: impl Default for GrindAir.
function GrindAir.default(): GrindAir
	return {
		target = nil,
		offset_delta = zero(),
		offset = zero(),
		angle_delta = zero(),
		angles = zero(),
		selected_kind = nil,
		headings = table.create(12, 0.0),
	}
end

-- 82D34FE8. Started/activated latches are owned by the existing KnownAir caller.
function GrindAir.start(self: GrindAir, target: Target)
	self.target = target
	self.offset_delta = zero()
	self.offset = zero()
	self.angle_delta = zero()
	self.angles = zero()
	self.selected_kind = nil
end

function GrindAir.update(self: GrindAir, input: Input, settings: Settings): Adjustment?
	if not input.active then
		return nil
	end
	if bit32.btest(input.flags_2480, 0x0400_0000) or bit32.btest(input.flags_2472, 0x8000) or bit32.btest(input.flags_2468, 8) then
		self.offset = zero()
		self.angles = zero()
		return nil
	end
	local target = self.target
	if target == nil then
		rt.raise("Active GrindAirAdjust has no selected primitive")
		return nil
	end
	targets.Settings.validate(settings)
	local rail = unit(sub(target.edge["end"], target.edge.start))
	local normal = unit(cross(rail, cross(input.up, rail)))
	local samples = prediction.project(input, settings, rail, normal, self.headings)
	local contacts = selection.contacts(samples, settings.frames, target.edge.start, rail, normal)
	local kind = selection.choose(contacts, self.headings, settings, bit32.btest(input.flags_2484, 0x0020_0000), self.selected_kind)
	if kind == nil then
		return nil
	end
	self.selected_kind = kind
	local probe = targets.CONTACTS[kind + 1]
	local time = contacts.times[probe + 1]
	-- 82D72610, per-frame and total displacement are separately bounded.
	self.offset_delta = limited(add(self.offset_delta, scale(contacts.corrections[probe + 1], reciprocal(time))), settings.max_delta)
	self.offset = limited(add(self.offset, self.offset_delta), settings.max_offset)
	angles.update(self, input, settings, target, samples, rail, normal, kind, time)
	return { axis = rail, offset = self.offset, angles = self.angles }
end

angles.parent = grind_air
pose.parent = grind_air
prediction.parent = grind_air
selection.parent = grind_air
targets.parent = grind_air

return grind_air
