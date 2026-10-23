--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/board.rs (коммит 2e16697)
--
-- Branch composition of `PhysicsGround::UpdateSkateboard` (`82D38800`).

local rt = require("../../../../rt")
local force_queue = require("../../../physics/force_queue")
local speed_wobble = require("../../speed_wobble")
local steering = require("../../steering")
local drag = require("../drag")
local board_types = require("./board_types")
local data = require("./data")
local ordinary = require("./ordinary")

local Stage = board_types.GroundBoardStage
local service = ordinary.service

local board = {}

-- ROBLOX: enum GroundBoardOutcome ->
--   { kind = "Animated" } | { kind = "Collision", tag_15_queued = bool } | { kind = "Ordinary", result = OrdinaryGroundResult }.

local function animated(state: data.PhysicsGroundState, components: any, services: any): any
	service(Stage.SetAnimatedVelocity, services:set_animated_velocity_82c04168(state.vector_2688))
	service(Stage.WriteProcessedVelocity, services:write_processed_velocity_400(state.vector_2688))
	local ok, derr = drag.BodyInertias.set_linear_drag(components.inertias, 0.0, drag.DragSelection.AllParts)
	if not ok then
		rt.raise({ kind = "Drag", error = derr })
	end
	local pose = service(Stage.BuildAnimatedPose, services:build_animated_pose_82d33448())
	service(Stage.PublishAnimatedPose, services:publish_animated_pose_82be33d0(pose))
	service(Stage.UpdateExternalPlayer, services:update_external_player_82d67848(pose, state.vector_2688))
	service(Stage.CommitExternalPlayer, services:commit_external_player_82d68800())
	service(Stage.FinalizeAnimatedBoard, services:finalize_animated_board_sk83_na_f_01a4())
	state.flag_2720 = true
	return { kind = "Animated" }
end

-- Runs the native steering/contact branch prefix, then exactly one of the
-- animated, collision-response, or ordinary grounded paths.
-- ROBLOX: Result<GroundBoardOutcome, GroundBoardError> -> (outcome) или (nil, ошибка).
-- components: { speed_wobble, truck_steering, speed_model, manual,
--   heading_previous = { value }, force_queue, inertias }.
-- &mut на поля состояния steering -> ячейки, записываются обратно сразу после вызова.
function board.update(state: data.PhysicsGroundState, components: any, settings: any, input: any, services: any): (any, any)
	return rt.catch(function(): any
		local push_cell = { value = state.steering_push_scalar_2640 }
		local turn_cell = { value = state.steering_damped_turn_2644 }
		local tilt = steering.calculate_tilt(settings.steering, input.steering, push_cell, turn_cell)
		state.steering_push_scalar_2640 = push_cell.value
		state.steering_damped_turn_2644 = turn_cell.value
		input.speed_wobble.tilt = tilt
		input.speed_wobble.center_of_mass_height = service(Stage.CenterOfMassHeight, services:center_of_mass_height_82d38838())
		tilt = speed_wobble.calculate(components.speed_wobble, settings.speed_wobble, input.speed_wobble)
		steering.TruckSteeringState.update(components.truck_steering, tilt, settings.steering.tilt_blending, input.truck_flags_2468, input.truck_flags_2472)

		service(Stage.SetWheelMaterials, services:set_contact_wheel_materials())
		local contact = service(Stage.ContactResponse, services:contact_response_82d93df0(input.contact, state.vector_2688))
		state.flag_2731 = contact.active_2731
		state.vector_2688 = contact.vector_2688
		state.scalar_2704 = contact.scalar_2704
		state.flag_2708 = contact.animated_board_2708
		state.flag_2720 = false

		service(Stage.UpdateBodyAccumulator, services:update_body_accumulator_82d389dc())
		if state.flag_2708 then
			return animated(state, components, services)
		end

		local collision = service(Stage.CollisionForce, services:collision_force_82d944e8(input.ground_vector_1216))
		if collision ~= nil then
			state.collision_force_2528 = collision.force_2528
			state.collision_point_2544 = collision.point_2544
			state.vector_2592 = collision.vector_2592
			state.collision_countdown_2652 = settings.collision_response_duration
			service(Stage.ApplyCollisionVector, services:apply_vector_82c07000(collision.vector_2592))
			components.speed_model.flags_1360 = bit32.bor(components.speed_model.flags_1360, 0x8000_0000)
			local queued = force_queue.BoardForceQueue.append(components.force_queue, board_types.CollisionForceResponse.tagged_force(collision))
			local projection = service(Stage.CollisionProjection, services:collision_force_dot_velocity_82d38e18(collision.force_2528, input.ground_force.velocity_400))
			state.flag_2722 = projection < -0.75
			return { kind = "Collision", tag_15_queued = queued }
		end

		local result = ordinary.update(state, components, settings, input, contact.tag_16_force, services)
		return { kind = "Ordinary", result = result }
	end)
end

return board
