--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/conditions.rs (коммит 2e16697)
--
-- ActionGraph condition leaves recovered from Skate 3 TU3.
-- Physical values are published by their real producers. An absent producer
-- is an integration error, never an implicit ground state or neutral speed.

local rt = require("../../rt")
local trigonometry = require("../trigonometry")
local intents = require("./intents")
local name = require("../animation/skeleton_input/name")

local f32 = rt.f32

local conditions = {}

-- ROBLOX: enum Comparison -> строки.
export type Comparison = "None" | "Equal" | "NotEqual" | "Greater" | "Less" | "GreaterEqual" | "LessEqual" | "GreaterAbsolute"

export type NumericCondition = { comparison: Comparison, threshold: number, absolute: boolean }

local NumericCondition = {}
conditions.NumericCondition = NumericCondition

-- NumericCondition::Compare 82C12AB8. The bge/ble branches test the
-- absence of LT/GT, including unordered inputs; do not change to >=/<=.
function NumericCondition.matches(self: NumericCondition, value: number): boolean
	if self.absolute then
		value = math.abs(value)
	end
	local c, t = self.comparison, self.threshold
	if c == "None" then
		return false
	elseif c == "Equal" then
		return value == t
	elseif c == "NotEqual" then
		return value ~= t
	elseif c == "Greater" then
		return value > t
	elseif c == "Less" then
		return value < t
	elseif c == "GreaterEqual" then
		return not (value < t)
	elseif c == "LessEqual" then
		return not (value > t)
	end
	return math.abs(value) > t
end

export type SpeedInputs = {
	-- PhysOut skateboard+164/+168/+192, respectively.
	speed: number,
	forward_speed: number,
	speed_and_slope: number,
}

export type PhysicalStateInputs = {
	-- PhysOut filtered-state+0/+80/+8, respectively.
	category: number,
	grinding: boolean,
	grind_name: string,
}

export type PushBrakeInputs = {
	-- Y of ground-output+80, used by 82BA5150. Its producer must be supplied;
	-- this is not interchangeable with deck up or a selected contact normal.
	ground_axis_y: number,
	-- PhysOut skeleton+598.
	skeleton_disables_push_brake: boolean,
	-- Selected global collection 316, layout+1844.
	maximum_ground_angle_degrees: number,
}

local PushBrakeInputs = {}
conditions.PushBrakeInputs = PushBrakeInputs

local DEGREES = rt.from_bits(0x42652EE1)

-- Complete scalar result of DisablePushBrake 82BA5150. The inverse-sine
-- estimate retains the explicitly documented numerical validation boundary.
function PushBrakeInputs.disabled(self: PushBrakeInputs): boolean
	local degrees = f32(trigonometry.asin(self.ground_axis_y) * DEGREES)
	return f32(90.0 - degrees) > self.maximum_ground_angle_degrees or self.skeleton_disables_push_brake
end

export type ConditionInputs = {
	speeds: SpeedInputs?,
	physical_state: PhysicalStateInputs?,
	-- PhysOut miscellaneous+128, read by 82BA15F8.
	time_since_last_input: number?,
	-- Actor stance accessors 82BA4C30/82BA4C78, through component+1804.
	mirrored: boolean?,
	riding_fakie: boolean?,
	push_brake: PushBrakeInputs?,
}

function conditions.default_inputs(): ConditionInputs
	return {}
end

-- ROBLOX: enum ActionCondition -> { kind = ..., поля варианта }:
--   HasIntent { name, numeric }, TimeSinceLastInput { numeric },
--   Speed { along_skate_z, numeric }, SpeedAndSlope { numeric },
--   FilteredState { expected }, Grinding { name? }, Mirrored, RidingFakie,
--   DisablePushBrake, CurrentState { name, target? }.
export type ActionCondition = {
	kind: string,
	name: string?,
	numeric: NumericCondition?,
	along_skate_z: boolean?,
	expected: number?,
	target: number?,
}

local ActionCondition = {}
conditions.ActionCondition = ActionCondition

-- ROBLOX: Result<bool, &'static str> -> ошибка через rt.raise.
-- parents: Vec<Option<usize>> -> таблица, None -> false.
function ActionCondition.evaluate(self: ActionCondition, input: ConditionInputs, action_intents: intents.IntentMap, current: number?, parents: { number | false }): boolean
	local kind = self.kind
	if kind == "HasIntent" then
		local value = intents.IntentMap.get(action_intents, self.name :: string)
		if value == nil then
			return false
		end
		-- HasAGIntent 82BA0EA8 distinguishes presence-only from numeric.
		local numeric = self.numeric :: NumericCondition
		return numeric.comparison == "None" or NumericCondition.matches(numeric, value)
	elseif kind == "TimeSinceLastInput" then
		local t = input.time_since_last_input
		if t == nil then
			rt.raise("TimeSinceLastInput needs PhysOut miscellaneous+128")
		end
		return NumericCondition.matches(self.numeric :: NumericCondition, t :: number)
	elseif kind == "Speed" then
		local speeds = input.speeds
		if speeds == nil then
			rt.raise("PhysicsSpeedCompare needs skateboard output")
		end
		local s = speeds :: SpeedInputs
		return NumericCondition.matches(self.numeric :: NumericCondition, if self.along_skate_z then s.forward_speed else s.speed)
	elseif kind == "SpeedAndSlope" then
		local speeds = input.speeds
		if speeds == nil then
			rt.raise("PhysicsSpeedAndSlopeCompare needs skateboard output+192")
		end
		return NumericCondition.matches(self.numeric :: NumericCondition, (speeds :: SpeedInputs).speed_and_slope)
	elseif kind == "FilteredState" then
		local st = input.physical_state
		if st == nil then
			rt.raise("PhysFilteredState needs filtered physical state")
		end
		return (st :: PhysicalStateInputs).category == self.expected
	elseif kind == "Grinding" then
		local st = input.physical_state
		if st == nil then
			rt.raise("IsGrinding needs filtered physical state")
		end
		local state = st :: PhysicalStateInputs
		if not state.grinding then
			return false
		end
		if self.name == nil then
			return true
		end
		-- 824714D0 compares the five encoded words, including the
		-- case/truncation semantics already used by skeleton attributes.
		local a, b = name.encode(self.name :: string), name.encode(state.grind_name)
		for i = 1, 5 do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	elseif kind == "Mirrored" then
		if input.mirrored == nil then
			rt.raise("IsMirrored needs the motion-graph stance owner")
		end
		return input.mirrored :: boolean
	elseif kind == "RidingFakie" then
		if input.riding_fakie == nil then
			rt.raise("IsRidingFakie needs the motion-graph stance owner")
		end
		return input.riding_fakie :: boolean
	elseif kind == "DisablePushBrake" then
		local pb = input.push_brake
		if pb == nil then
			rt.raise("DisablePushBrake needs ground/skeleton outputs and stock angle")
		end
		return PushBrakeInputs.disabled(pb :: PushBrakeInputs)
	end
	-- CurrentState: 82C13820 includes the current state itself, then its ancestors.
	local target = self.target
	if target ~= nil then
		local cursor = current
		while cursor ~= nil do
			if cursor == target then
				return true
			end
			local p = parents[cursor + 1]
			cursor = if p == false then nil else p :: number
		end
	end
	return false
end

return conditions
