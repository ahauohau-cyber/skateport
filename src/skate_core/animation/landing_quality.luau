--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/landing_quality.rs (коммит 2e16697)
--
-- Original TU3 PhysicsConditioner::CalcLandingQuality, 0x82DE61D0.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local native_arithmetic = require("../physics/native_arithmetic")
local board_motion_output = require("../physics/board_motion_output")

local f32 = rt.f32
local mul_add = rt.mul_add
local evaluate = point_graph.PointGraph.evaluate

local landing_quality = {}

export type Settings = { twist_spin: point_graph.PointGraph, side_speed: point_graph.PointGraph }

export type Input = {
	-- PhysicsConditioner +144 and +148, after its filtered-state update.
	previous_filtered_state: number,
	filtered_state: number,
	-- PhysOut_Collision +32. Do not substitute a predicted landing normal.
	ground_normal: { number },
	-- PhysOut_SkateboardMotion +80 and +273.
	deck_velocity: { number },
	flipped: boolean,
	-- PhysOut_SkateboardReckoning +32: physical deck PART world Z from
	-- 82C02AD8/82C02B1C. This is not the conditioned Reckoning ground frame.
	reckoning_forward: { number },
	-- PhysOut_Air +204.
	air_spin: number,
}

-- Reset values are explicitly written by 0x82DE3F38.
export type Output = {
	landing_adjust_80: number,
	sideways_speed_84: number,
	forward_speed_88: number,
	spin_92: number,
	landing_type_96: number,
	landing_data_167: boolean,
}

local function dot(a: { number }, b: { number }): number
	return native_arithmetic.dot3(a, b)
end
local function scale(a: { number }, b: number): { number }
	return { f32(a[1] * b), f32(a[2] * b), f32(a[3] * b), f32(a[4] * b) }
end
local function planar(a: { number }, normal: { number }): { number }
	local projected = scale(normal, dot(normal, a))
	return { f32(a[1] - projected[1]), f32(a[2] - projected[2]), f32(a[3] - projected[3]), f32(a[4] - projected[4]) }
end
local function cross(a: { number }, b: { number }): { number }
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end
local function length(a: { number }): number
	local square = dot(a, a)
	local value = f32(square * board_motion_output.inverse_length_squared(square, 2))
	return if square == 0.0 then 0.0 else value
end
local function reciprocal(value: number): number
	local estimate = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		estimate = mul_add(estimate, mul_add(-estimate, value, 1.0), estimate)
	end
	return estimate
end
local function upper_one(value: number): number
	return if f32(1.0 - value) >= -0.0 then value else 1.0
end

local Output = {}
landing_quality.Output = Output

function Output.default(): Output
	return { landing_adjust_80 = 0.0, sideways_speed_84 = 0.0, forward_speed_88 = 0.0, spin_92 = 0.0, landing_type_96 = 0, landing_data_167 = false }
end

local K_3727c5ac = rt.from_bits(0x3727c5ac)
local F01 = f32(0.1)
local F014 = f32(0.14492753)
local F0101 = f32(0.1010101)
local F02 = f32(0.2)
local F03 = f32(0.3)
local F005 = f32(0.05)

-- Nonlanding frames preserve every field, including the valid-data latch.
function Output.update(self: Output, input: Input, settings: Settings)
	if input.previous_filtered_state == 1 or input.filtered_state ~= 1 then
		return
	end
	local velocity = planar(input.deck_velocity, input.ground_normal)
	local forward = planar(input.reckoning_forward, input.ground_normal)
	local speed = length(velocity)
	local forward_length = length(forward)
	local forward_speed = math.abs(dot(velocity, forward))
	local side_speed = math.abs(dot(cross(forward, input.ground_normal), input.deck_velocity))
	local kind = 0
	local spin = 0.0
	if f32(forward_length * speed) < K_3727c5ac then
		forward_speed = 0.0
		side_speed = 0.0
	else
		local normalized_velocity = scale(velocity, reciprocal(speed))
		local normalized_forward = scale(forward, reciprocal(forward_length))
		local orientation = cross(normalized_forward, normalized_velocity)[2]
		if input.flipped then
			orientation = -orientation
		end
		local angular_speed = -input.air_spin
		local spin_input = f32(f32(math.abs(angular_speed) - F01) * F014)
		local spin_curve = evaluate(settings.twist_spin, upper_one(spin_input))
		local side_input = f32(f32(side_speed - F01) * F0101)
		local side_curve = evaluate(settings.side_speed, upper_one(side_input))
		if speed >= 2.0 then
			local heading = if input.flipped then scale(normalized_forward, -1.0) else normalized_forward
			local toward = dot(heading, normalized_velocity) >= 0.0
			local magnitude
			if math.abs(angular_speed) <= F01 then
				kind = 1
				magnitude = side_curve
			else
				local product = f32(angular_speed * orientation)
				kind = if (toward and product <= 0.0) or (not toward and product > 0.0) then 2 else 1
				magnitude = if f32(spin_curve - side_curve) >= -0.0 then spin_curve else side_curve
			end
			spin = if angular_speed >= -0.0 then magnitude else -magnitude
			if math.abs(orientation) < F02 and (kind ~= 2 or not (math.abs(spin) > F03)) then
				kind = if math.abs(orientation) >= F005 then 3 else 0
				spin = 0.0
			end
		end
	end
	self.landing_adjust_80 = spin
	self.sideways_speed_84 = side_speed
	self.forward_speed_88 = forward_speed
	self.spin_92 = spin
	self.landing_type_96 = kind
	self.landing_data_167 = true
end

return landing_quality
