--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/data.rs (коммит 2e16697)
--
-- Persistent state and direct inputs for TU3 `PhysState_KnownAir`.
-- ROBLOX: Vector4 = [f32; 4] -> таблица из 4 чисел; enum GrindFootBody -> строка.

local point_graph = require("../../point_graph")

type PointGraph = point_graph.PointGraph

local data = {}

export type Vector4 = { number }

-- The 64-byte trajectory copied by `FillPhysOut` at `0x82D36A78`.
export type KnownAirTrajectory = {
	position: Vector4,
	velocity: Vector4,
	acceleration: Vector4,
	scalar_48: number,
	word_52: number,
	word_56: number,
	word_60: number,
}

-- Winning trajectory result at selector+1680. The collision frame lies at
-- result+128, outside the copied 64-byte trajectory at result+144.
export type KnownAirPrediction = {
	trajectory: KnownAirTrajectory,
	-- Winning PredictionResults+48, distinct from request horizon at +192.
	collision_time_48: number,
	collision_frame_128: number,
}

-- Fields owned by the KnownAir object at native offsets +64..+216.
-- Construction remains caller-owned because Enter does not initialize every
-- field before `InitTrajectoryInfo` and the selector helpers run.
export type KnownAirState = {
	landing_normal_64: Vector4,
	landing_heading_80: Vector4,
	trajectory_apex_96: Vector4,
	collision_position_112: Vector4,
	selector_vector_128: Vector4,
	trajectory_follow_offset_144: Vector4,
	target_com_position_160: Vector4,
	collision_normal_speed_176: number,
	time_in_state_180: number,
	start_y_184: number,
	max_y_188: number,
	com_max_y_192: number,
	collision_time_196: number,
	time_to_apex_200: number,
	body_flip_target_speed_204: number,
	reached_apex_208: boolean,
	landing_heading_valid_209: boolean,
	start_flipped_210: boolean,
	body_flipping_211: boolean,
	grind_air_adjust_activated_212: boolean,
	targeting_grind_213: boolean,
	trajectory_index_216: number,
}

-- Direct ProcessedPhysIn fields consumed by KnownAir.
export type KnownAirFrame = {
	start_flip_reference_96: Vector4,
	alternate_head_target_112: Vector4,
	velocity_400: Vector4,
	ground_normal_464: Vector4,
	start_height_484: number,
	skater_up_544: Vector4,
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	flags_2480: number,
	flags_2484: number,
	flags_2488: number,
	next_physics_state_2500: number,
	delta_time_2604: number,
	forward_speed_2612: number,
	body_spin_input_2640: number,
	selector_landing_normal_2656: Vector4,
}

-- Cached `physics_airstates/default.xml` values used by this state. Values
-- must come from the stock collection adapter; no retail defaults live here.
export type KnownAirSettings = {
	-- Settings +160; x at +176, y at +208.
	max_heading_adjust_vs_up_y_160: PointGraph,
	-- Settings +240; x at +256, y at +288.
	landing_speed_scalar_vs_ground_normal_y_240: PointGraph,
	-- Attribute hash `AA79C93673533C5B`; its recovered name remains unknown.
	flip_start_collision_time_vs_normal_y: PointGraph,
	trajectory_error_blend_away_time_384: number,
	min_target_heading_velocity_420: number,
	min_auto_body_speed_424: number,
	max_spin_speed_428: number,
	frames_for_grind_air_assist_436: number,
	body_flip_min_grab_time_fraction_456: number,
	-- `physics_reckoning/FlipScalar`, hash `978CE73B0EFE76C8`.
	flip_scalar: number,
}

-- Fields read through ProcessedPhysIn+2548 and its selected physics mode.
export type KnownAirModeSettings = {
	upside_down_falling_wipeout_enabled_2: boolean,
	perfect_body_flips_28: boolean,
	body_spin_speed_limit_56: number,
}

export type KnownAirWipeoutSettings = {
	air_falling_min_up_y_260: number,
	air_falling_max_angle_264: number,
}

-- Direct Reckoning fields read or cleared by KnownAir.
export type KnownAirReckoningFields = {
	landing_normal_1152: Vector4,
	heading_axis_1200: Vector4,
	body_spin_angle_1568: number,
	body_spin_speed_1572: number,
}

-- Direct writes to the wipeout request object at +35, +116, and +200.
export type KnownAirWipeoutRequest = {
	requested_35: boolean,
	scalar_116: number,
	counter_200: number,
}

-- Six skeleton bodies disabled, in this exact native order, while the grind
-- air adjustment owns the feet.
export type GrindFootBody = "Body3152" | "Body3156" | "Body3160" | "Body3168" | "Body3172" | "Body3176"

-- Trajectory packet passed to the three recovered footplant updates.
export type KnownAirFootplantInput = {
	trajectory: KnownAirTrajectory,
	remaining_collision_time: number,
	collision_position: Vector4,
	landing_normal: Vector4,
}

-- Native transform at Reckoning+816, interpreted only by the required math
-- adapter because Xenon lane order remains part of that contract.
export type AffineTransform = { vectors: { Vector4 } }

-- Stable inputs/outputs around the unresolved VMX geometry in `0x82D35998`.
export type RestoreVelocityGeometry = {
	tangential_velocity: Vector4,
	landing_speed_curve_input: number,
	-- Source clamped to [0, 1] by the two native `fsel` operations.
	landing_speed_blend_source: number,
}

-- Fields written by `FillPhysOut` (`0x82D36880`). The two conditional fields
-- retain their previous value when flags+2468 bit 3 is clear.
export type KnownAirOutput = {
	trajectory_apex_0: Vector4,
	collision_position_16: Vector4,
	landing_normal_32: Vector4,
	selector_vector_48: Vector4,
	trajectory_position_64: Vector4,
	landing_heading_80: Vector4,
	selector_com_position_96: Vector4,
	landing_normal_copy_144: Vector4,
	locked_trajectory_velocity_160: Vector4,
	time_in_state_176: number,
	collision_time_180: number,
	time_until_collision_184: number,
	collision_normal_speed_188: number,
	time_to_apex_196: number,
	jump_height_200: number,
	trajectory_index_220: number,
	selected_trajectory_240: KnownAirTrajectory,
	trajectory_plane_samples_336: { number }, -- [f32; 25]
	reached_apex_436: boolean,
	known_air_valid_437: boolean,
	locked_trajectory_velocity_valid_452: boolean,
}

return data
