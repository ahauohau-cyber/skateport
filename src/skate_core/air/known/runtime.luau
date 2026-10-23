--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/runtime.rs (коммит 2e16697)
--
-- Mandatory engine and Xenon-math boundaries for TU3 KnownAir.
-- ROBLOX: trait -> тип таблицы с методами (вызов через двоеточие);
-- кортежи -> несколько возвращаемых значений; &mut KnownAirTrajectory ->
-- таблица, меняется на месте. Реализаций по умолчанию нет.

local data = require("./data")

type Vector4 = data.Vector4

local runtime = {}

-- Xenon operations whose exact estimate/refinement, lane, or angle behavior
-- is observable in the recovered routines. There is deliberately no default
-- implementation or scalar substitute.
export type KnownAirMath = {
	-- `vmsum3fp128` including its native rounding and lane behavior.
	dot3: (self: any, left: Vector4, right: Vector4) -> number,
	-- The `vrefp` reciprocal refinement sequence used for finite differences.
	divide_vector_by_scalar: (self: any, vector: Vector4, scalar: number) -> Vector4,
	-- The two `vrsqrtefp128` refinements, zero selection, and returned length.
	normalize_safe_with_length: (self: any, vector: Vector4) -> (Vector4, number),
	-- `0x8286CD88`, including its native orientation and degeneracy behavior.
	signed_angle_about_axis: (self: any, from: Vector4, to: Vector4, axis: Vector4) -> number,
	-- `0x8258DB98` exactly; callers retain every observed invocation.
	wrap_angle_8258db98: (self: any, angle: number) -> number,
	-- VMX geometry at `0x82D35A0C..0x82D35B78`.
	restore_velocity_geometry_82d35998: (self: any, trajectory_velocity: Vector4, ground_normal: Vector4) -> data.RestoreVelocityGeometry,
	-- Affine point transform at `0x82D36AE4..0x82D36B30`.
	transform_point_82d36880: (self: any, transform: data.AffineTransform, point: Vector4) -> Vector4,
}

-- Every external call and direct engine-owned object mutation performed by
-- the recovered KnownAir routines. Implementers must bind all methods.
export type KnownAirRuntime = KnownAirMath & {
	enable_board_angular_drive_only: (self: any) -> (),
	set_air_collision_update_enabled: (self: any, enabled: boolean) -> (),
	set_skeleton_collision_state: (self: any, state: number) -> (),
	set_skeleton_physics_truck_tilt_enabled: (self: any, enabled: boolean) -> (),
	set_skeleton_inverse_kinematics_enabled: (self: any, enabled: boolean) -> (),
	reset_reckoning_flipping: (self: any) -> (),
	set_footplant_flag_240: (self: any, value: boolean) -> (),
	reset_footplants: (self: any) -> (),
	board_transform_height: (self: any) -> number,
	skeleton_com_position: (self: any) -> Vector4,

	selector_targeting_grind: (self: any) -> boolean,
	start_grind_air_adjust_from_selector: (self: any) -> (),
	selector_closest_trajectory_point: (self: any, skeleton_com: Vector4, zero: Vector4) -> (number, Vector4),
	selected_prediction: (self: any) -> data.KnownAirPrediction,
	-- Selector+2704, distinct from the winning result trajectory at +1680.
	selector_trajectory_2704: (self: any) -> data.KnownAirTrajectory,
	selector_contact_position: (self: any) -> Vector4,
	selector_vector_2848: (self: any) -> Vector4,
	selector_com_position_2784: (self: any) -> Vector4,
	highest_trajectory_position: (self: any, trajectory: data.KnownAirTrajectory) -> (Vector4, number),
	selector_has_just_changed: (self: any) -> boolean,
	reset_trajectory_selector: (self: any) -> (),

	begin_reckoning_body_flip: (self: any, side: boolean) -> (),
	update_air_collision: (self: any) -> (),
	grind_air_adjust_started: (self: any) -> boolean,
	set_grind_air_adjust_started: (self: any, value: boolean) -> (),
	set_grind_air_adjust_activated: (self: any, value: boolean) -> (),
	grind_air_adjust_adjusting: (self: any) -> boolean,
	disable_grind_foot_collision: (self: any, body: data.GrindFootBody) -> (),
	update_reckoning_air_states: (self: any, landing_normal: Vector4, alignment_weight: number, body_spin_speed: number, body_flip_speed: number) -> (),
	update_known_air_skeleton: (self: any, target_com_position: Vector4) -> (),
	set_skeleton_add_skateboard_error: (self: any, value: boolean) -> (),
	set_head_tracking_target: (self: any, target: Vector4, valid: boolean) -> (),
	update_board_steering_tilt: (self: any, tilt: number) -> (),

	shift_footplant_trajectory_to_index: (self: any, trajectory: data.KnownAirTrajectory, index: number) -> (),
	update_footplant_prediction: (self: any, input: data.KnownAirFootplantInput) -> (),
	update_footplant_lock: (self: any, input: data.KnownAirFootplantInput) -> (),
	update_footplant_pose: (self: any, input: data.KnownAirFootplantInput) -> (),

	board_body_velocity: (self: any) -> Vector4,
	set_board_velocity: (self: any, velocity: Vector4) -> (),
	board_forward_axis: (self: any) -> Vector4,
	check_for_air_wipeout: (self: any, use_com: boolean) -> (),
	reckoning_com_transform_816: (self: any) -> data.AffineTransform,
}

return runtime
