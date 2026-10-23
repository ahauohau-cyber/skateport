--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/lifecycle.rs (коммит 2e16697)
--
-- Ground Enter `82D37538` and Exit `82D37B20` lifecycle order.

local rt = require("../../../../rt")
local force_queue = require("../../../physics/force_queue")
local pumping_state = require("../../pumping/state")
local speed_wobble = require("../../speed_wobble")
local drag = require("../drag")
local manual_entry = require("../manual_entry")
local data = require("./data")

local from_bits = rt.from_bits

local lifecycle = {}

export type GroundEnterInput = {
	previous_category_2516: number,
	previous_state_2504: number,
	powerslide_exit_scale: number,
	manual_ground: manual_entry.ManualGroundInput,
}

-- ROBLOX: enum GroundEnterStage / GroundExitStage -> строки.
lifecycle.GroundEnterStage = {
	SetBoardStandard = "SetBoardStandard",
	InitializeSkeleton = "InitializeSkeleton",
	SetCollisionState = "SetCollisionState",
	ResetExternalObjects = "ResetExternalObjects",
	InitializeBoardSpeed = "InitializeBoardSpeed",
	EnterManual = "EnterManual",
	EnterFromAir = "EnterFromAir",
	BuildLandingOnDeckForce = "BuildLandingOnDeckForce",
	SetControllerMode = "SetControllerMode",
}
lifecycle.GroundExitStage = { SetWheelMaterials = "SetWheelMaterials", RestoreAnimatedBoardVelocity = "RestoreAnimatedBoardVelocity" }
local EnterStage = lifecycle.GroundEnterStage
local ExitStage = lifecycle.GroundExitStage

-- ROBLOX: enum GroundEnterError -> { kind = "Service" | "ManualProjection", stage, source }.
-- GroundExitError -> { kind = "Drag", error } | { kind = "Service", stage, source }.

export type GroundEnterResult = { landing_force_attempted: boolean, landing_force_queued: boolean }

local function enter_call(stage: string, value: any, err: any): any
	if err ~= nil then
		rt.raise({ kind = "Service", stage = stage, source = err })
	end
	return value
end

-- Runs every verified Ground entry operation in native order. The service
-- boundaries are unresolved engine/numerical functions, not optional hooks.
-- components: { pumping, speed_wobble, manual, force_queue }.
-- services: set_board_standard_82c03af8, initialize_ground_skeleton,
--   set_collision_state_82d911a8(state), reset_ground_external_objects,
--   initialize_board_speed_82d375d0, enter_from_air_82bf2f18,
--   landing_on_deck_force() -> QueuedPointForce, set_controller_mode_one.
function lifecycle.enter(state: data.PhysicsGroundState, components: any, input: GroundEnterInput, bodies: any, projection: any, services: any): (GroundEnterResult?, any)
	return rt.catch(function(): GroundEnterResult
		enter_call(EnterStage.SetBoardStandard, services:set_board_standard_82c03af8())
		enter_call(EnterStage.InitializeSkeleton, services:initialize_ground_skeleton())
		enter_call(EnterStage.SetCollisionState, services:set_collision_state_82d911a8(6))

		state.word_2560 = 0
		state.word_2564 = 0
		state.flag_2708 = false
		state.controls_latched_2725 = false
		state.captured_position_valid_2726 = false
		state.was_pinning_2728 = false
		state.flag_2731 = false
		state.manual_correction_2732 = false
		state.manual_opposition_2733 = false

		enter_call(EnterStage.ResetExternalObjects, services:reset_ground_external_objects())
		enter_call(EnterStage.InitializeBoardSpeed, services:initialize_board_speed_82d375d0())
		speed_wobble.SpeedWobbleState.reset(components.speed_wobble)
		local ok, perr = manual_entry.enter_ground(components.manual, input.previous_category_2516, input.powerslide_exit_scale, input.manual_ground, bodies, projection)
		if not ok then
			rt.raise({ kind = "ManualProjection", stage = EnterStage.EnterManual, source = perr })
		end

		if input.previous_category_2516 == 200 then
			enter_call(EnterStage.EnterFromAir, services:enter_from_air_82bf2f18())
		end
		local result = { landing_force_attempted = false, landing_force_queued = false }
		if input.previous_state_2504 == 503 then
			local force = table.clone(enter_call(EnterStage.BuildLandingOnDeckForce, services:landing_on_deck_force()))
			force.tag = 19
			result.landing_force_attempted = true
			result.landing_force_queued = force_queue.BoardForceQueue.append(components.force_queue, force)
		end

		state.straighten_scale_2672 = if input.previous_state_2504 == 101 then from_bits(0x3e23_d70a) else 1.0
		pumping_state.PumpingState.reset(components.pumping)
		enter_call(EnterStage.SetControllerMode, services:set_controller_mode_one())

		state.steering_push_scalar_2640 = 1.0
		state.steering_damped_turn_2644 = 0.0
		state.elapsed_2648 = 0.0
		state.collision_countdown_2652 = 0.0
		state.vector_2592 = { 0.0, 0.0, 0.0, 0.0 }
		state.vector_2608 = { 0.0, 0.0, 0.0, 0.0 }
		state.anti_flip_torque_2624 = { 0.0, 0.0, 0.0, 0.0 }
		state.hang_detection_frames_2740 = 0
		state.hang_force_frames_2744 = 0
		state.hung_wipeout_frames_2748 = 0
		state.anti_flip_nudge_frames_2752 = 0
		state.flag_2721 = false
		state.anti_flip_nudge_applied_2723 = false
		state.push_suppressed_2730 = false
		return result
	end)
end

-- services: set_default_wheel_materials(), restore_animated_board_velocity(vector_2688).
function lifecycle.exit(state: data.PhysicsGroundState, pumping: pumping_state.PumpingState, inertias: any, services: any): (boolean?, any)
	return rt.catch(function(): boolean
		state.steering_damped_turn_2644 = 0.0
		state.steering_push_scalar_2640 = 1.0
		pumping_state.PumpingState.reset(pumping)
		local ok, derr = drag.BodyInertias.set_linear_drag(inertias, 0.0, drag.DragSelection.AllParts)
		if not ok then
			rt.raise({ kind = "Drag", error = derr })
		end
		local _, e1 = services:set_default_wheel_materials()
		if e1 ~= nil then
			rt.raise({ kind = "Service", stage = ExitStage.SetWheelMaterials, source = e1 })
		end
		if state.flag_2708 then
			local _, e2 = services:restore_animated_board_velocity(state.vector_2688)
			if e2 ~= nil then
				rt.raise({ kind = "Service", stage = ExitStage.RestoreAnimatedBoardVelocity, source = e2 })
			end
		end
		return true
	end)
end

return lifecycle
