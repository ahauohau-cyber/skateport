--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/runtime.rs (коммит 2e16697)
--
-- Mandatory engine-facing effects used by TU3 PhysicsAir.
-- ROBLOX: trait -> тип таблицы с методами; вызов через двоеточие
-- (runtime:update_air_collision()). Реализации по умолчанию нет: адаптер
-- движка обязан предоставить каждый метод.

local data = require("./data")
local jump_velocity = require("./jump_velocity")

type Vector4 = data.Vector4

local runtime = {}

-- Mutations of the 272-byte trajectory launch record recovered at
-- `0x82D33448`, `0x82BE33D0`, and `0x82D34570`.
export type PhysicsAirLaunchInfo = {
	set_start_velocity: (self: any, velocity: Vector4) -> (),
	centre_of_mass_animation_position: (self: any) -> Vector4,
	set_trajectory_start_position_override: (self: any, position: Vector4) -> (),
	set_board_position_override: (self: any, position: Vector4) -> (),
	cone_angles: (self: any) -> { number },
	set_cone_angles: (self: any, angles: { number }) -> (),
	set_player_jumped: (self: any, jumped: boolean) -> (),
	set_use_trajectory_start_position_override: (self: any, enabled: boolean) -> (),
	set_trajectory_count: (self: any, count: number) -> (),
}

-- Every external call/read made by the recovered PhysicsAir methods. There is
-- deliberately no no-op/default implementation: an engine adapter must bind
-- each stock-owned object before this state can be scheduled.
-- ROBLOX: PhysicsAirRuntime: PhysicsAirMath -> методы PhysicsAirMath тоже здесь.
export type PhysicsAirRuntime = jump_velocity.PhysicsAirMath & {
	set_air_collision_update_enabled: (self: any, enabled: boolean) -> (),
	set_skeleton_collision_state: (self: any, state: number) -> (),
	set_skeleton_inverse_kinematics_enabled: (self: any, enabled: boolean) -> (),
	enable_board_angular_drive_only: (self: any) -> (),
	set_footplant_flag_240: (self: any, value: boolean) -> (),
	reset_footplants: (self: any) -> (),
	board_transform_height: (self: any) -> number,
	request_skeleton_heading_update: (self: any) -> (),

	update_air_collision: (self: any) -> (),
	trajectory_query_just_started: (self: any) -> boolean,
	construct_trajectory_launch_info: (self: any) -> any,
	fill_skeleton_launch_info: (self: any, info: any) -> (),
	launch_trajectory: (self: any, info: any) -> (),
	update_trajectory_selector: (self: any) -> (),
	selector_landing_normal: (self: any) -> Vector4?,
	selector_centre_of_mass_trajectory_ready: (self: any) -> boolean,

	-- `AngleBetweenVectors` (`0x8296EBB0`), including its unresolved VMX
	-- normalization behavior. The caller performs the recovered angle wrap.
	angle_between_vectors: (self: any, left: Vector4, right: Vector4) -> number,
	-- Return the completed canonical fields: UpdateSkateboard reads the newly
	-- filtered collision normal1216, after82D8DBD8, not the entry snapshot.
	update_reckoning_air_states: (self: any, landing_normal: Vector4, normal_blend: number, body_spin: number, body_flip: number) -> data.PhysicsAirReckoningFields,
	update_known_air_skeleton: (self: any, trajectory_position: Vector4) -> (),
	update_animated_skateboard_skeleton: (self: any, argument: boolean) -> (),

	update_board_steering_tilt: (self: any, tilt: number) -> (),
	-- `Toolkit_CalcCollisionForce` (`0x82D944E8`). The adapter supplies its
	-- bound settings and complete live ProcessedPhysIn; PhysicsAir only passes
	-- the reference normal and receives the point-force record.
	-- ROBLOX: force: &mut AirBoardForce -> таблица, поля пишутся на месте.
	calculate_air_collision_force: (self: any, reference_normal: Vector4, force: data.AirBoardForce) -> boolean,
	enqueue_board_force: (self: any, tag: number, force: data.AirBoardForce) -> (),
	set_board_velocity: (self: any, velocity: Vector4) -> (),
	enable_skateboard_error_on_skeleton: (self: any) -> (),

	board_body_velocity: (self: any) -> Vector4,
	check_for_air_wipeout: (self: any, argument: boolean) -> (),
}

return runtime
