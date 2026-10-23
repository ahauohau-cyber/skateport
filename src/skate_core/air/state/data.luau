--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/data.rs (коммит 2e16697)
--
-- Persistent fields and direct inputs used by TU3 `PhysState_PhysicsAir`.
-- ROBLOX: Vector4 = [f32; 4] -> таблица из 4 чисел; Option<f32> -> число или nil.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")

local data = {}

export type Vector4 = { number }

-- Native trajectory storage at PhysicsAir+80.
export type AirTrajectory = {
	position: Vector4,
	velocity: Vector4,
	acceleration: Vector4,
	-- Native trajectory +48. Both recovered initializers write -1.0.
	scalar_48: number,
}

-- Fields owned by the TU3 PhysicsAir object. Enter preserves prior trajectory
-- storage when COM mode is not selected; construct once and retain this owner.
export type PhysicsAirState = {
	-- PhysicsAir+80.
	centre_of_mass_trajectory: AirTrajectory,
	-- PhysicsAir+144.
	landing_normal: Vector4,
	-- PhysicsAir+160.
	time_in_state: number,
	-- PhysicsAir+164/+168.
	start_y: number,
	max_y: number,
	-- PhysicsAir+172/+173/+174.
	reached_apex: boolean,
	use_centre_of_mass_velocity: boolean,
	-- The producer is selector+9662. A more specific stock name is unresolved.
	selector_latch_174: boolean,
	-- PhysicsAir+176, decremented as a signed wrapping integer.
	trajectory_query_countdown: number,
}

local PhysicsAirState = {}
data.PhysicsAirState = PhysicsAirState

-- Original constructor82D341D0: zero vectors80/96/112, -1 at128,
-- up144, zero160/164/168 and172..176. Entry is a separate operation.
-- ROBLOX: impl Default for PhysicsAirState.
function PhysicsAirState.default(): PhysicsAirState
	return {
		centre_of_mass_trajectory = {
			position = { 0.0, 0.0, 0.0, 0.0 },
			velocity = { 0.0, 0.0, 0.0, 0.0 },
			acceleration = { 0.0, 0.0, 0.0, 0.0 },
			scalar_48 = -1.0,
		},
		landing_normal = { 0.0, 1.0, 0.0, 0.0 },
		time_in_state = 0.0,
		start_y = 0.0,
		max_y = 0.0,
		reached_apex = false,
		use_centre_of_mass_velocity = false,
		selector_latch_174 = false,
		trajectory_query_countdown = 0,
	}
end

-- Direct ProcessedPhysIn values consumed by the recovered methods.
export type PhysicsAirFrame = {
	current_velocity_400: Vector4,
	-- Y lane of the all-states ground position, read directly at +500.
	ground_position_y_500: number,
	trajectory_position_592: Vector4,
	trajectory_velocity_608: Vector4,
	jump_velocity_848: Vector4,
	flags_2468: number,
	previous_physics_state_2504: number,
	previous_physics_category_2516: number,
	frames_since_jump_correction_2576: number,
	delta_time_2604: number,
	body_spin_input_2640: number,
	gravity_y_2648: number,
	state_timer_2664: number,
}

-- Cached collection values read at PhysicsAir settings +320..+444.
-- No retail defaults are embedded; the stock vault adapter must provide them.
export type PhysicsAirSettings = {
	-- PointGraph x at +320 and y at +352.
	body_spin_over_time_320: point_graph.PointGraph,
	landing_normal_blend_388: number,
	body_spin_scale_428: number,
	landing_normal_angle_limit_444: number,
}

-- Reckoning fields read directly by PhysicsAir, apart from the full
-- `Reckoning::UpdateAirStates` effect exposed by the runtime interface.
export type PhysicsAirReckoningFields = {
	current_landing_normal_1152: Vector4,
	collision_reference_normal_1216: Vector4,
	body_spin_angle_1568: number,
	body_spin_speed_1572: number,
}

-- Native zero-initialized point-force record passed to `0x82D944E8`.
export type AirBoardForce = {
	force_world: Vector4,
	point_board_local: Vector4,
}

local AirBoardForce = {}
data.AirBoardForce = AirBoardForce

-- ROBLOX: pub const ZERO -> функция, возвращающая новую запись.
function AirBoardForce.ZERO(): AirBoardForce
	return { force_world = { 0.0, 0.0, 0.0, 0.0 }, point_board_local = { 0.0, 0.0, 0.0, 0.0 } }
end

-- Writes performed by `FillPhysOut` (`0x82D34E90`). `scalar_184_write` is
-- `None` when native code leaves the existing PhysOut field untouched.
export type PhysicsAirOutput = {
	is_at_apex: boolean,
	jump_height: number,
	landing_normal: Vector4,
	scalar_184_write: number?,
}

local _ = rt
return data
