--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/manual/controller.rs (коммит 2e16697)
--
-- CalcManualEffect 82C047F0 control/scalar response and output construction.
-- The native angle-between-vectors measurement remains a required dependency.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local trigonometry = require("../../trigonometry")
local angle = require("./angle")
local settings_mod = require("./settings")
local state_mod = require("./state")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph
local ManualState = state_mod.ManualState

type F4 = { number }

local controller = {}

export type ManualInput = {
	-- ProcessedPhysIn+2720 and +2620.
	balance: number,
	flipped_controls: number,
	-- +2664, +2616 and +2768. Noise time is independent of manual elapsed.
	procedural_noise_time: number,
	absolute_speed: number,
	animation_noise: number,
	-- +2604; this controller does not replace it with a fixed 1/60.
	timestep: number,
	-- The explicit CalcManualEffect argument; Ground callers pass false.
	powersliding: boolean,
	-- Processed2468 bit29 selects BrakeTiltAngle and correction-force gates.
	braking: boolean,
	-- Processed2472 bits27 and26, respectively. Physical axle identities are
	-- not assumed here; the signed balance gates are preserved directly.
	positive_balance_contact: boolean,
	negative_balance_contact: boolean,
	-- Processed2468 bit20 reverses the point-selection balance sign.
	reversed_point_selection: boolean,
	-- Reference frame from board+292, matrix+752: first and third columns.
	reference_x: F4,
	reference_z: F4,
	-- Deck part6 transform's z-axis from 82585CB0, not an animation pose.
	deck_z: F4,
	-- Processed effective transform third column+224 and ground velocity+416.
	velocity_frame_z: F4,
	-- Legacy field name: this is Processed416, NOT angular velocity720.
	-- Native82C04C88 projects it into the effective frame;82C04E60..EC4
	-- emits -400 times this same translational velocity for correction.
	angular_velocity_world: F4,
	-- Front/back truck drive-frame translations (7840+48 and7904+48).
	-- 82C0B9C0 steering rotates the bases and preserves these translations.
	correction_point_7888: F4,
	correction_point_7952: F4,
}

-- Exact 8296EC98 dependency: degeneracy gates, normalization, acos and signed
-- cross-product selection. There is deliberately no host atan2/acos fallback.
-- ROBLOX: трейт -> таблица с методом angle_between, возвращающим (значение) или (nil, ошибка).
export type ManualAngleMeasurement = {
	angle_between: (self: any, deck_z: F4, reference_z: F4, reference_x: F4) -> (number?, any),
}

-- ROBLOX: enum ManualError<E> -> { kind = "Angle" | "Measurement", error = ... }.
export type ManualError = { kind: string, error: any }

export type ManualEffect = {
	-- Native result+0, applied with ApplyAngularDisplacementToDeck.
	angular_displacement: F4,
	-- Result+16/+32 are explicitly zeroed by this function.
	force_world: F4,
	force_point_body: F4,
	-- Result+48/+64, plus result+80/+81 status bytes.
	corrective_force_world: F4,
	corrective_point_body: F4,
	correction_active: boolean,
	opposing_motion_without_correction: boolean,
}

local function clamp_symmetric(value: number, bound: number): number
	local lower = -bound
	local lower_clamped = if f32(lower - value) >= 0.0 then lower else value
	return if f32(bound - lower_clamped) >= 0.0 then lower_clamped else bound
end

local function apply_correction(effect: ManualEffect, input: ManualInput, mode: settings_mod.ManualMode, target: number, measured: number)
	local frame = input.velocity_frame_z
	local velocity = input.angular_velocity_world
	local local_z = mul_add(frame[3], velocity[3], mul_add(frame[2], velocity[2], f32(frame[1] * velocity[1])))
	if not input.braking or not (0.0 > f32(local_z * input.balance)) then
		return
	end
	if not mode.corrective_force_enabled then
		effect.opposing_motion_without_correction = true
		return
	end
	if not (math.abs(local_z) > mode.correction_angular_speed_threshold) then
		return
	end
	local radians_to_degrees = from_bits(0x4265_2ee1)
	local error_degrees = f32(f32(target * radians_to_degrees) - f32(measured * radians_to_degrees))
	if not (math.abs(error_degrees) < 1.0) then
		return
	end
	local alternate = if input.reversed_point_selection then input.balance < 0.0 else input.balance > 0.0
	effect.corrective_point_body = table.clone(if alternate then input.correction_point_7888 else input.correction_point_7952)
	local out = {}
	for i = 1, 4 do
		out[i] = f32(f32(velocity[i] * -1.0) * 400.0)
	end
	effect.corrective_force_world = out
	effect.correction_active = true
end

-- An unavailable measurement/conversion aborts the tick. Already executed
-- scalar-state writes remain visible, but no effect is returned for publication.
-- ROBLOX: Result<ManualEffect, ManualError> -> (effect) или (nil, ManualError).
function controller.calculate(
	state: state_mod.ManualState,
	settings: settings_mod.ManualSettings,
	mode: settings_mod.ManualMode,
	input: ManualInput,
	geometry: ManualAngleMeasurement
): (ManualEffect?, ManualError?)
	local effect: ManualEffect = {
		angular_displacement = { 0.0, 0.0, 0.0, 0.0 },
		force_world = { 0.0, 0.0, 0.0, 0.0 },
		force_point_body = { 0.0, 0.0, 0.0, 0.0 },
		corrective_force_world = { 0.0, 0.0, 0.0, 0.0 },
		corrective_point_body = { 0.0, 0.0, 0.0, 0.0 },
		correction_active = false,
		opposing_motion_without_correction = false,
	}
	local output_scale = 1.0
	if input.balance == 0.0 then
		ManualState.reset(state)
	else
		-- ROBLOX: оператор ? -> ранний возврат ошибки.
		local failure: ManualError? = nil
		local function norm(value: number): number
			local v, err = angle.normalize(value)
			if v == nil then
				failure = { kind = "Angle", error = err }
				error(failure)
			end
			return v
		end
		local ok, err = pcall(function()
			local gains = if input.powersliding then settings.powerslide else settings.manual
			local scaled_balance = f32(input.balance * input.flipped_controls)
			local sign = if scaled_balance > 0.0 then 1.0 else -1.0
			local signed_target = f32(mul_add(math.abs(scaled_balance), 0.75, 0.25) * sign)
			local started = if state.elapsed == 0.0 then 0.0 else 1.0
			local degrees_to_radians = from_bits(0x3c8e_fa35)
			local base_angle = norm(f32(f32(settings.maximum_tilt_degrees * signed_target) * degrees_to_radians))
			local target
			if input.braking then
				target = norm(f32(f32(settings.brake_tilt_degrees * signed_target) * degrees_to_radians))
			else
				local phase = f32(f32(input.procedural_noise_time * settings.procedural_noise_frequency) * from_bits(0x40c9_0fdb))
				local noise = f32(trigonometry.sin(phase) * settings.procedural_noise_scale)
				local speed_scale = PointGraph.evaluate(settings.noise_vs_speed, input.absolute_speed)
				local animated = f32(input.animation_noise * settings.animation_noise_scale)
				local disturbance = mul_add(animated, input.flipped_controls, noise)
				local noise_angle = norm(f32(speed_scale * disturbance))
				target = norm(f32(noise_angle + base_angle))
			end
			if state.elapsed == 0.0 then
				state.angular_correction = norm(f32(settings.start_torque_scale * target))
			end
			state.target_angle = target
			local measured_raw, merr = geometry:angle_between(input.deck_z, input.reference_z, input.reference_x)
			if measured_raw == nil then
				failure = { kind = "Measurement", error = merr }
				error(failure)
			end
			local measured = norm(measured_raw)
			local angle_change = f32(measured - state.measured_angle)
			state.measured_angle = measured
			local error_value = clamp_symmetric(norm(f32(target - measured)), settings.maximum_angle_error)
			local weighted_error = f32(error_value * from_bits(0x3d4c_cccd))
			state.filtered_angle_error = mul_add(state.filtered_angle_error, from_bits(0x3f73_3333), weighted_error)
			local derivative = clamp_symmetric(f32(f32(angle_change * started) * gains.derivative), settings.derivative_limit)
			local wheel_scale = if input.positive_balance_contact ~= input.negative_balance_contact then 0.5 else 1.0
			local wrong_contact = (not input.positive_balance_contact and input.balance > 0.0)
				or (not input.negative_balance_contact and input.balance < 0.0)
			if wrong_contact then
				state.angular_correction = f32(f32(settings.torque_bleed_without_contact * state.angular_correction) * wheel_scale)
				output_scale = f32(settings.torque_scale_without_contact * wheel_scale)
			else
				state.angular_correction = f32(f32(f32(state.angular_correction + derivative) + f32(state.filtered_angle_error * gains.integral)) + f32(error_value * gains.proportional))
			end
			apply_correction(effect, input, mode, target, measured)
			state.elapsed = f32(input.timestep + state.elapsed)
		end)
		if not ok then
			if failure ~= nil then
				return nil, failure
			end
			error(err, 0)
		end
	end
	local correction = f32(state.angular_correction * output_scale)
	local rx = input.reference_x
	effect.angular_displacement = { f32(-rx[1] * correction), f32(-rx[2] * correction), f32(-rx[3] * correction), f32(-rx[4] * correction) }
	return effect, nil
end

return controller
