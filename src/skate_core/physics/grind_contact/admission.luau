--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/admission.rs (коммит 2e16697)
--
-- S3 82D886B8, paired with S2 IsEntryAngleAcuteEnough 82DDA748.
-- Test each family/contact before arbitration, retaining its entry kind.
-- ROBLOX: enum EntryKind (repr u32) -> числа (EntryKind.RideFromAbove и т.д.);
-- within_approach_angle берётся из родителя через поле parent.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate

type V = { number }

local admission = {}
admission.parent = (nil :: any)

admission.EntryKind = table.freeze({
	RideFromAbove = 0,
	RideFromBelow = 1,
	RideIntoCoping = 2,
	StayInGrind = 3,
	ChangeGrind = 4,
	AirToGrind = 5,
	DropIn = 6,
})
local EntryKind = admission.EntryKind
export type EntryKind = number

export type Decision = { kind: number, allowed: boolean }

export type Admission = {
	category: number,
	-- The current processed state2508, not the requested/previous state.
	state: number,
	speed: number,
	velocity: V,
	-- physics_grinds/DVEntryThreshScalarVsSinSlope, X480/Y496.
	threshold_vs_slope: point_graph.PointGraph,
}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

local function slope_sine(tangent: V, velocity: V, dead_zone: number): number
	local transverse = sub(velocity, scale(tangent, dot3(velocity, tangent)))
	local length = arithmetic.square_root(dot3(transverse, transverse))
	if length <= dead_zone then
		return 0.0
	end
	return f32(arithmetic.reciprocal(length) * transverse[2])
end

-- S3 82D861D8 / S2 CalcApproachSlopeSine 82DDA1A8.
-- This is the vertical component of normalized cross-rail velocity, not
-- rail incline or the board's forward/rail angle.
function admission.approach_slope_sine(tangent: V, velocity: V): number
	return slope_sine(tangent, velocity, f32(0.01))
end

-- S3 82D860F8 uses a smaller dead zone for coping and engagement.
function admission.engagement_slope_sine(tangent: V, velocity: V): number
	return slope_sine(tangent, velocity, f32(0.001))
end

local AdmissionImpl = {}
admission.Admission = AdmissionImpl

function AdmissionImpl.test(self: Admission, requested_state: number, tangent: V, allows_drop_in: boolean): Decision
	local kind
	if self.category == 400 or self.state == 701 then
		if self.state == requested_state or (requested_state == 402 and self.state == 404) then
			kind = EntryKind.StayInGrind
		else
			kind = EntryKind.ChangeGrind
		end
	elseif self.category == 100 then
		if allows_drop_in and self.speed < f32(1.45) then
			kind = EntryKind.DropIn
		else
			local slope = admission.approach_slope_sine(tangent, self.velocity)
			if slope > f32(0.96) then
				kind = EntryKind.RideIntoCoping
			elseif slope > 0.25 then
				kind = EntryKind.RideFromBelow
			else
				kind = EntryKind.RideFromAbove
			end
		end
	else
		kind = EntryKind.AirToGrind
	end
	local within = admission.parent.within_approach_angle
	local allowed
	if kind == EntryKind.RideFromAbove then
		allowed = within(tangent, self.velocity, 17.0)
	elseif kind == EntryKind.StayInGrind then
		allowed = within(tangent, self.velocity, 90.0)
	elseif kind == EntryKind.ChangeGrind then
		allowed = within(tangent, self.velocity, 24.0)
	elseif kind == EntryKind.AirToGrind or kind == EntryKind.DropIn then
		allowed = true
	else
		-- RideFromBelow | RideIntoCoping
		local square_speed = dot3(self.velocity, self.velocity)
		local transverse = sub(scale(tangent, dot3(self.velocity, tangent)), self.velocity)
		local square_transverse = dot3(transverse, transverse)
		local ratio = if square_speed <= f32(0.002) then 1.0 else arithmetic.square_root(f32(square_transverse / square_speed))
		local slope = admission.approach_slope_sine(tangent, self.velocity)
		local multiplier = evaluate(self.threshold_vs_slope, slope)
		local limit = f32(mul_add(f32(1.0 - ratio), f32(2.4), f32(2.8)) * multiplier)
		allowed = square_transverse < f32(limit * limit)
	end
	return { kind = kind, allowed = allowed }
end

return admission
