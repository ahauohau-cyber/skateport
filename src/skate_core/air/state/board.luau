--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/board.rs (коммит 2e16697)
--
-- TU3 PhysicsAir board update (`0x82D34AB0`).

local data = require("./data")
local jump_velocity = require("./jump_velocity")

local board = {}

local AIR_COLLISION_FORCE_TAG = 15

function board.update_skateboard(state: data.PhysicsAirState, frame: data.PhysicsAirFrame, reckoning: data.PhysicsAirReckoningFields, runtime: any)
	runtime:update_board_steering_tilt(0.0)

	local force = data.AirBoardForce.ZERO()
	local collision_force_created = runtime:calculate_air_collision_force(reckoning.collision_reference_normal_1216, force)
	if collision_force_created then
		runtime:enqueue_board_force(AIR_COLLISION_FORCE_TAG, force)
		return
	end

	if not state.use_centre_of_mass_velocity and frame.frames_since_jump_correction_2576 < 12 then
		local velocity = jump_velocity.calculate_velocity_from_jump(frame, frame.frames_since_jump_correction_2576, runtime)
		runtime:set_board_velocity(velocity)
	end
end

return board
