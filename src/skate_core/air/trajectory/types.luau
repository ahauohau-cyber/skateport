--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/types.rs (коммит 2e16697)
--
-- Launch data82D33448/82BE33D0 and the source-owned caller observations.
-- ROBLOX: struct -> таблица; Copy -> types.clone_launch_info при изменении копии.

local m = require("./math")
local point_graph = require("../../point_graph")

type Vector = m.Vector
type Transform = m.Transform
type PointGraph = point_graph.PointGraph

local types = {}

export type LaunchInfo = {
	reckoning_transform: Transform, -- 0=Reckoning816
	reckoning_inverse: Transform, -- 64=Reckoning944
	start_velocity: Vector, -- 128=Processed400 m/s
	com_velocity: Vector, -- 144=Processed704 m/s
	skeleton_vector_160: Vector, -- 160=Skeleton16208
	skeleton_vector_176: Vector, -- 176=Skeleton16240
	board_position: Vector, -- 192=Processed112 metres
	animation_com_position: Vector, -- 208=Processed592 metres
	start_position_override: Vector, -- 224 metres
	board_position_override: Vector, -- 240 metres
	cone_angle_x: number, -- 256 degrees
	cone_angle_z: number, -- 260 degrees
	timestep: number, -- 264 seconds
	player_jumped: boolean, -- 268
	use_position_override: boolean, -- 269
	trajectory_count: number, -- 270 GetLaunchInfo selects1 or7
}

local LaunchInfo = {}
types.LaunchInfo = LaunchInfo

-- Original ctor82D33448; Fill must supply current physical observations.
-- ROBLOX: impl Default for LaunchInfo.
function LaunchInfo.default(): LaunchInfo
	return {
		reckoning_transform = m.identity(),
		reckoning_inverse = m.identity(),
		start_velocity = m.zero(),
		com_velocity = m.zero(),
		skeleton_vector_160 = m.zero(),
		skeleton_vector_176 = m.zero(),
		board_position = m.zero(),
		animation_com_position = m.zero(),
		start_position_override = m.zero(),
		board_position_override = m.zero(),
		cone_angle_x = 0.0,
		cone_angle_z = 0.0,
		timestep = 0.0,
		player_jumped = false,
		use_position_override = false,
		trajectory_count = 0,
	}
end

-- ROBLOX: Copy. Поля-векторы только читаются или заменяются целиком,
-- поэтому достаточно поверхностной копии.
function LaunchInfo.clone(self: LaunchInfo): LaunchInfo
	return table.clone(self)
end

export type SelectorInput = {
	gravity: Vector, -- PhysicsWorld32 m/s^2
	ground_normal: Vector, -- Processed464
	contact_position: Vector, -- 496 metres
	heading_direction: Vector, -- 512
	reference_up: Vector, -- 544
	board_vertical_velocity: number, -- 404 m/s
	directional_input: number, -- 2636
	previous_physics_state: number, -- 2504
	flags_2472: number,
	flags_2476: number,
	offboard_flags_1776: number,
	grind_lock_distance: number, -- active physics_mode80 metres
}

-- Stock skater collection values; offsets refer to physics_trajectory unless stated.
export type SelectorSettings = {
	cone_x: number, -- 576 degrees, Skeleton GetLaunchInfo
	cone_z: number, -- 568 degrees, Skeleton GetLaunchInfo
	trajectory_max_time: number, -- 428 seconds
	trajectory_max_drop: number, -- 63673FB6DA092B7E metres
	trajectory_error_start: number, -- 432
	trajectory_error_end: number, -- 436
	speed_factor_min: number, -- 440 m/s
	speed_factor_max: number, -- 444 m/s
	cone_angle_z_vs_speed: PointGraph, -- 304
	cone_x_second_pass: number, -- 572 degrees
	cone_z_second_pass: number, -- 564 degrees
	landing_time_bonus: PointGraph, -- 0 x16/y48
	landing_com_scalar_vs_slope: PointGraph, -- 80 x96/y128
	landing_force_scalar: PointGraph, -- 240
	grind_penalty_vs_distance: PointGraph, -- 160 x176/y208
	score_middle_bonus: number, -- 468
	score_landing_force: number, -- 472
	score_landing_direction: number, -- 476
	score_transition: number, -- 456
	surface_unrideable_score: number, -- 460
	surface_dont_align_score: number, -- 464
	natural_air_off_verts_scalar: number, -- 484
	minimum_valid_time: number, -- 488 seconds
	minimum_time_after_apex: number, -- 492 seconds
	minimum_normal_delta_second_pass: number, -- 496 radians
	maximum_trajectory_adjust: number, -- 500
	wall_ride_test_distance: number, -- 416 metres
	wall_ride_minimum_height: number, -- 420 metres
	wall_ride_angle_allow_landing: number, -- 424
	wall_ride_height_score: number, -- 452
	wall_ride_boost: PointGraph, -- 368 x384/y400
	wall_ride_normal_dot_limit: number, -- physics global188/layout248
	displacement_vs_speed: PointGraph, -- physics_reckoning544
	displacement_vs_ground_normal: PointGraph, -- physics_reckoning608
	trajectory_radius: number, -- physics_reckoning C6710942E297D587 metres
	trajectory_displacement: number, -- physics_reckoning runtime attribute
	minimum_trajectory_frames: number, -- physics_reckoning runtime attribute
	vert_jump_align_factor: number, -- 0B42DFBB7F7756A0
	vert_jump_align_max_ground_normal_y: number, -- 94923D136EA2DA37
	vert_jump_align_min_direction_y: number, -- 58BFC8D41216C7EE
	vert_jump_align_max_angle: number, -- 723FF102068622CF
}

return types
