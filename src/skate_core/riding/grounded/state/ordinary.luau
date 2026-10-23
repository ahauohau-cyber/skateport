--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/ordinary.rs (коммит 2e16697)
--
-- Ordinary (non-animated, non-collision-response) `82D38800` path.

local rt = require("../../../../rt")
local force_queue = require("../../../physics/force_queue")
local manual_controller = require("../../../physics/manual/controller")
local anti_flip = require("../../anti_flip")
local ground_force = require("../../ground_force")
local heading = require("../../heading")
local pumping = require("../../pumping")
local slide_friction = require("../../slide_friction")
local speed_model = require("../../speed_model")
local straighten = require("../../straighten")
local propulsion = require("../propulsion")
local drag = require("../drag")
local board_types = require("./board_types")
local corrections = require("./corrections")
local data = require("./data")

local f32 = rt.f32
local Stage = board_types.GroundBoardStage
local Q = force_queue.BoardForceQueue

type F4 = { number }

local ordinary = {}

export type OrdinaryGroundResult = {
	manual_correction: boolean,
	terminal_force_tag: number,
	terminal_force_queued: boolean,
	speed_model_reset: boolean,
}

local function service(stage: string, value: any, err: any): any
	if err ~= nil then
		rt.raise({ kind = "Service", stage = stage, source = err })
	end
	return value
end
ordinary.service = service

local function first_balance_selector(value: number): number
	if value <= 0.0 then
		return if value >= -0.0 then 1.0 else 2.0
	end
	return 0.0
end

local function second_balance_selector(value: number): number
	local nonnegative = if value <= 0.0 then 1.0 else 2.0
	return if value >= -0.0 then nonnegative else 0.0
end

local function force_record(tag: number, value: { number }): any
	return {
		tag = tag,
		force_world = vector.create(value[1], value[2], value[3]),
		point_body = vector.create(value[5], value[6], value[7]),
	}
end

local function vector4(v: vector): F4
	return { v.x, v.y, v.z, 0.0 }
end

local function ground_forces(settings: any, frame: board_types.GroundForceFrame): ({ number }, { number })
	local side_scalar = 0.0
	if frame.processed_2776 == 0.0 or frame.processed_2780 < 0.0 then
		local value = f32(frame.ground_scalar_1232 * frame.previous_state_scalar_56)
		side_scalar = if -value >= 0.0 then 0.0 else value
	end
	local function common(application_z: number, argument_3: number, argument_4: number): any
		return {
			argument_1 = frame.argument_1_2752,
			application_z = application_z,
			argument_3 = argument_3,
			argument_4 = argument_4,
			balance = frame.balance_2720,
			surface_speed = frame.surface_speed_2656,
			axis_384 = frame.axis_384,
			velocity_400 = frame.velocity_400,
			axis_544 = frame.axis_544,
		}
	end
	local first = ground_force.calculate(settings, common(frame.ground_scalar_1216, side_scalar, first_balance_selector(frame.balance_2720)))
	local second = ground_force.calculate(settings, common(-frame.ground_scalar_1240, f32(frame.ground_scalar_1236 * side_scalar), second_balance_selector(frame.balance_2720)))
	return first, second
end

local function apply_body_vectors(state: data.PhysicsGroundState, collision_scale: number, timestep: number, straightened: F4, heading_value: F4, anti_flip_value: F4, manual: F4, services: any)
	if state.collision_countdown_2652 > 0.0 then
		state.collision_countdown_2652 = f32(state.collision_countdown_2652 - timestep)
		local v = state.vector_2592
		state.vector_2592 = { f32(v[1] * collision_scale), f32(v[2] * collision_scale), f32(v[3] * collision_scale), f32(v[4] * collision_scale) }
		service(Stage.ApplyCollisionDecay, services:apply_vector_82c07000(state.vector_2592))
	end
	service(Stage.ApplyStraighten, services:apply_vector_82c07000(straightened))
	service(Stage.ApplyHeading, services:apply_vector_82c07000(heading_value))
	service(Stage.ApplyAntiFlip, services:apply_angular_displacement_82c075b8(anti_flip_value))
	service(Stage.ApplyManual, services:apply_angular_displacement_82c075b8(manual))
end

local function update_speed_model_reset(sm: any, threshold: number, brake: vector, push: vector, pump: { number }, services: any): boolean
	local combined = {
		f32(f32(push.x + brake.x) + pump[1]),
		f32(f32(push.y + brake.y) + pump[2]),
		f32(f32(push.z + brake.z) + pump[3]),
		pump[4],
	}
	local squared = service(Stage.StrongForceSquared, services:dot3(combined, combined))
	if squared > threshold then
		sm.flags_1360 = bit32.bor(sm.flags_1360, 0x8000_0000)
		return true
	end
	return false
end

local function correction(stage: string, ok: any, err: any)
	if err ~= nil then
		rt.raise({ kind = "Service", stage = stage, source = err })
	end
end

-- pub(super) fn update(...) -> Result<OrdinaryGroundResult, GroundBoardError>
-- ROBLOX: ошибки поднимаются rt.raise; ловит board.update.
function ordinary.update(state: data.PhysicsGroundState, components: any, settings: any, input: any, contact_force: any, services: any): OrdinaryGroundResult
	local suppressed = { value = 0 }
	local prop = propulsion.calculate(input.propulsion, settings.propulsion, suppressed)
	state.push_suppressed_2730 = suppressed.value ~= 0

	local ground_a, ground_b = ground_forces(settings.ground_force, input.ground_force)
	input.speed_model.manual_state_276 = components.manual.angular_correction
	local speed_force = speed_model.update(components.speed_model, settings.speed_model, input.speed_model)
	input.slide_friction.heading_time = state.elapsed_2648
	-- Both helpers read wheel hardness from ProcessedPhysIn+2764
	-- (82D92AAC / 82D92B80), supplied by the animation profile.
	local slide_force = slide_friction.calculate(settings.slide_friction, input.slide_friction)
	local pump_force = pumping.calculate(input.pump_force)
	input.straighten.heading_time = state.elapsed_2648
	local s = straighten.calculate(settings.straighten, input.straighten)
	local k = state.straighten_scale_2672
	local scaled_straighten = { f32(s[1] * k), f32(s[2] * k), f32(s[3] * k), f32(s[4] * k) }
	local heading_value = heading.calculate(settings.heading, input.heading, components.heading_previous)
	local anti_flip_value = anti_flip.calculate(settings.anti_flip, input.anti_flip)
	state.anti_flip_torque_2624 = anti_flip_value

	input.manual.powersliding = false
	local manual, merr = manual_controller.calculate(components.manual, settings.manual, settings.manual_mode, input.manual, services)
	if manual == nil then
		rt.raise({ kind = "Manual", error = merr })
	end
	local m = manual :: manual_controller.ManualEffect
	state.manual_correction_2732 = m.correction_active
	state.manual_opposition_2733 = m.opposing_motion_without_correction
	local drag_value = drag.GroundDragInput.calculate(input.ground_drag, settings.linear_drag)

	local terminal_queued
	if m.correction_active then
		local submission = propulsion.GroundPropulsion.submit(prop, m, components.force_queue)
		assert(submission.kind == "ManualCorrection", "unreachable")
		terminal_queued = submission.queued
	else
		local p = vector4(prop.push.vector)
		local push_squared = service(Stage.PushForceSquared, services:dot3(p, p))
		if push_squared > 1.0 then
			state.flag_2721 = true
		end
		correction(Stage.AntiFlipNudge, corrections.update_anti_flip_nudge(state, input.anti_flip_nudge, components.force_queue, services))
		if input.contact_time_2756 < settings.ground_force_contact_time_limit then
			Q.append(components.force_queue, force_record(4, ground_a))
			Q.append(components.force_queue, force_record(5, ground_b))
		end
		local submission = propulsion.GroundPropulsion.submit(prop, m, components.force_queue)
		assert(submission.kind == "BrakingAndPush", "unreachable")
		apply_body_vectors(state, settings.collision_response_scale, input.propulsion.timestep, scaled_straighten, heading_value, anti_flip_value, m.angular_displacement, services)
		if bit32.band(input.trajectory_state_1776_bits, 0x8000_0000) == 0 then
			Q.append(components.force_queue, force_record(6, speed_force))
		end
		Q.append(components.force_queue, force_record(1, slide_force))
		Q.append(components.force_queue, force_record(8, pump_force))
		local cf = table.clone(contact_force)
		cf.tag = 16
		terminal_queued = Q.append(components.force_queue, cf)
	end

	local ok, derr = drag.BodyInertias.apply_ground_drag(components.inertias, drag_value)
	if not ok then
		rt.raise({ kind = "Drag", error = derr })
	end
	local reset = update_speed_model_reset(components.speed_model, settings.speed_model_reset_force_squared, prop.braking.force_world, prop.push.vector, pump_force, services)
	correction(Stage.HangUps, corrections.manage_hang_ups(state, input.hang_up, services))
	correction(Stage.HalfpipeWheelCatch, corrections.manage_halfpipe_wheel_catches(input.halfpipe_wheel_catch, services))
	correction(Stage.Pinning, corrections.consider_pinning(state, input.pinning, services))
	return {
		manual_correction = m.correction_active,
		terminal_force_tag = if m.correction_active then 7 else 16,
		terminal_force_queued = terminal_queued,
		speed_model_reset = reset,
	}
end

return ordinary
