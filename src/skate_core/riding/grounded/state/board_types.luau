--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/board_types.rs (коммит 2e16697)
--
-- Typed boundaries for `PhysicsGround::UpdateSkateboard` (`82D38800`).
-- ROBLOX: структуры ввода/настроек в Luau — таблицы с теми же полями, что в Rust;
-- здесь перечислены только типы с поведением и enum стадий.

type F4 = { number }
type Vector3 = vector

local board_types = {}

-- Contiguous local record copied from board-body +8032 through +8084 before
-- the `82D93DF0` call. The names deliberately retain offsets where semantics
-- have not been independently recovered.
export type GroundContactFrame = {
	vector_8032: F4,
	vector_8048: F4,
	vector_8064: F4,
	word_8080: number,
	flag_8084: boolean,
	scalar_2752: number,
	scalar_2756: number,
}

-- Values used to construct both `82D931E8` calls in their native caller.
export type GroundForceFrame = {
	argument_1_2752: number,
	processed_2776: number,
	processed_2780: number,
	previous_state_scalar_56: number,
	ground_scalar_1216: number,
	ground_scalar_1232: number,
	ground_scalar_1236: number,
	ground_scalar_1240: number,
	balance_2720: number,
	surface_speed_2656: number,
	axis_384: F4,
	velocity_400: F4,
	axis_544: F4,
}

export type GroundContactResponse = {
	active_2731: boolean,
	tag_16_force: { tag: number, force_world: Vector3, point_body: Vector3 },
	vector_2688: F4,
	scalar_2704: number,
	animated_board_2708: boolean,
}

export type CollisionForceResponse = {
	force_2528: F4,
	point_2544: F4,
	vector_2592: F4,
}

local CollisionForceResponse = {}
board_types.CollisionForceResponse = CollisionForceResponse

function CollisionForceResponse.tagged_force(self: CollisionForceResponse): { tag: number, force_world: Vector3, point_body: Vector3 }
	return {
		tag = 15,
		force_world = vector.create(self.force_2528[1], self.force_2528[2], self.force_2528[3]),
		point_body = vector.create(self.point_2544[1], self.point_2544[2], self.point_2544[3]),
	}
end

-- ROBLOX: enum GroundBoardStage -> строки с теми же именами.
board_types.GroundBoardStage = {
	CenterOfMassHeight = "CenterOfMassHeight",
	SetWheelMaterials = "SetWheelMaterials",
	ContactResponse = "ContactResponse",
	UpdateBodyAccumulator = "UpdateBodyAccumulator",
	SetAnimatedVelocity = "SetAnimatedVelocity",
	WriteProcessedVelocity = "WriteProcessedVelocity",
	BuildAnimatedPose = "BuildAnimatedPose",
	PublishAnimatedPose = "PublishAnimatedPose",
	UpdateExternalPlayer = "UpdateExternalPlayer",
	CommitExternalPlayer = "CommitExternalPlayer",
	FinalizeAnimatedBoard = "FinalizeAnimatedBoard",
	CollisionForce = "CollisionForce",
	ApplyCollisionVector = "ApplyCollisionVector",
	CollisionProjection = "CollisionProjection",
	ManualEffect = "ManualEffect",
	PushForceSquared = "PushForceSquared",
	AntiFlipNudge = "AntiFlipNudge",
	ApplyCollisionDecay = "ApplyCollisionDecay",
	ApplyStraighten = "ApplyStraighten",
	ApplyHeading = "ApplyHeading",
	ApplyAntiFlip = "ApplyAntiFlip",
	ApplyManual = "ApplyManual",
	HangUps = "HangUps",
	HalfpipeWheelCatch = "HalfpipeWheelCatch",
	Pinning = "Pinning",
	StrongForceSquared = "StrongForceSquared",
}

-- ROBLOX: enum GroundBoardError<E> ->
--   { kind = "Service", stage = строка, source = E } | { kind = "Manual", error = ManualError } | { kind = "Drag", error = строка }.

-- Engine/numerical operations whose bodies do not yet exist in readable core
-- code. Every operation is mandatory on the branch where native code calls it.
-- ROBLOX: трейт GroundBoardServices (+ ManualAngleMeasurement, AntiFlipNudgeMath,
-- HangUpServices, HalfpipeWheelCatchServices, PinningServices) -> одна таблица
-- методов; каждый возвращает (значение, ошибка):
--   center_of_mass_height_82d38838() -> f32
--   set_contact_wheel_materials()
--   contact_response_82d93df0(frame, previous_vector_2688) -> GroundContactResponse
--   update_body_accumulator_82d389dc()
--   set_animated_velocity_82c04168(velocity)
--   write_processed_velocity_400(velocity)
--   build_animated_pose_82d33448() -> pose
--   publish_animated_pose_82be33d0(pose)
--   update_external_player_82d67848(pose, velocity)
--   commit_external_player_82d68800()
--   finalize_animated_board_sk83_na_f_01a4()
--   collision_force_82d944e8(ground_vector_1216) -> CollisionForceResponse?
--   collision_force_dot_velocity_82d38e18(force, velocity_400) -> f32
--   apply_vector_82c07000(vector)
--   apply_angular_displacement_82c075b8(vector)
--   angle_between(deck_z, reference_z, reference_x) -> f32
--   dot3(left, right) -> f32; scale_to_magnitude(vector, squared, magnitude) -> F4
--   build_hang_force() -> F4; apply_hang_force(F4); detect_hung_up_geometry() -> bool; request_wipeout()
--   angular_displacement() -> F4; apply_angular_displacement(F4)
--   pin_to_captured_position(x, z)

return board_types
