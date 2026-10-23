--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/types.rs (коммит 2e16697)
--
-- ROBLOX: RawVector ([u32; 4]) -> таблица из 4 слов; RawMatrix -> 4 строки.
-- ROBLOX: u8/u32/i32 -> число Luau; Option -> значение или nil.
-- ROBLOX: Rust-структуры здесь Copy. Векторы считаются неизменяемыми (их не
-- правят по элементу), а составные записи при копировании клонируются
-- через types.copy (глубокая копия), где Rust делает копию значения.

local air_output = require("./air_output")
local pose_output = require("./pose_output")
local grind_input = require("./grind_input")
local grind_output = require("./grind_output")
local actor_packet = require("../../animation/output/actor_packet")
local animation_packet = require("../../input/animation_packet")

local types = {}

export type RawVector = { number }
export type RawMatrix = { { number } }
type ExternalPhysicsInput = actor_packet.ExternalPhysicsInput
type AnimationPacketFields = animation_packet.AnimationPacketFields

local function z4(): RawVector
	return { 0, 0, 0, 0 }
end
local function zm(): RawMatrix
	return { z4(), z4(), z4(), z4() }
end

-- ROBLOX: копия Copy-значения (глубокая копия таблиц).
local function copy<T>(value: T): T
	local v: any = value
	if type(v) ~= "table" then
		return v
	end
	local result = {}
	for k, item in v do
		result[k] = copy(item)
	end
	return (result :: any) :: T
end
types.copy = copy

export type ProbeFields = {
	vectors_16_32_48: { RawVector },
	words_64_68: { number },
	bytes_72_73: { number },
	vector_80: RawVector,
	words_96_100: { number },
	byte_104: number,
}

local ProbeFields = {}
types.ProbeFields = ProbeFields
function ProbeFields.default(): ProbeFields
	return {
		vectors_16_32_48 = { z4(), z4(), z4() },
		words_64_68 = { 0, 0 },
		bytes_72_73 = { 0, 0 },
		vector_80 = z4(),
		words_96_100 = { 0, 0 },
		byte_104 = 0,
	}
end

export type LineTestFields = {
	position: RawVector,
	normal: RawVector,
	surface: number,
	-- The native byte is copied in full; conditionals test it for nonzero.
	valid: number,
}

local LineTestFields = {}
types.LineTestFields = LineTestFields
function LineTestFields.default(): LineTestFields
	return { position = z4(), normal = z4(), surface = 0, valid = 0 }
end

export type StateVariantFields = {
	-- Byte +60 of the object referenced by the variant block's +4 pointer.
	surface_override_enabled_60: number,
}

local StateVariantFields = {}
types.StateVariantFields = StateVariantFields
function StateVariantFields.default(): StateVariantFields
	return { surface_override_enabled_60 = 0 }
end

-- Reset82DE53F0 copies the template initialized by82DE3BE8:
-- every represented word and byte in this subset initially equals zero.
export type CurrentStateFields = {
	identifier_8: number,
	category_12: number,
	state_16: number,
	surface_height_32: number,
	-- BipedGround Fill82D32D38, independent of State40.
	counter_36: number,
	skitch_value_40: number,
	flag_61: number,
	flag_66: number,
	flag_69: number,
	flag_74: number,
	signed_ground_step_84: number,
}

local CurrentStateFields = {}
types.CurrentStateFields = CurrentStateFields
function CurrentStateFields.default(): CurrentStateFields
	return {
		identifier_8 = 0,
		category_12 = 0,
		state_16 = 0,
		surface_height_32 = 0,
		counter_36 = 0,
		skitch_value_40 = 0,
		flag_61 = 0,
		flag_66 = 0,
		flag_69 = 0,
		flag_74 = 0,
		signed_ground_step_84 = 0,
	}
end

export type SkateboardMotionFields = {
	vector_64: RawVector,
	vector_80: RawVector,
	vector_96: RawVector,
	vector_128: RawVector,
	vector_144: RawVector,
	scalar_160: number,
	scalar_164: number,
	scalar_168: number,
	scalar_172: number,
}

local SkateboardMotionFields = {}
types.SkateboardMotionFields = SkateboardMotionFields
function SkateboardMotionFields.default(): SkateboardMotionFields
	return {
		vector_64 = z4(),
		vector_80 = z4(),
		vector_96 = z4(),
		vector_128 = z4(),
		vector_144 = z4(),
		scalar_160 = 0,
		scalar_164 = 0,
		scalar_168 = 0,
		scalar_172 = 0,
	}
end

export type SystemReckoningFields = {
	-- Physical COM velocity from Skeleton16176 (82BE1D84/94).
	-- Restored r28 at82DB49B0 is16, not128.
	vector_16: RawVector,
	vector_64: RawVector,
	vector_96: RawVector,
	vector_144: RawVector,
	flag_164: number,
}

local SystemReckoningFields = {}
types.SystemReckoningFields = SystemReckoningFields
function SystemReckoningFields.default(): SystemReckoningFields
	return { vector_16 = z4(), vector_64 = z4(), vector_96 = z4(), vector_144 = z4(), flag_164 = 0 }
end

export type GroundOutputFields = {
	-- State503 Fill82D4E090..E0C8.
	landing_half_turns_312: number,
	hippy_jumping_322: number,
	hippy_takeoff_323: number,
	vector_64: RawVector,
	-- Board Fill82C03318: wheel-contact normal (not Motion80 velocity).
	vector_80: RawVector,
	-- Host storage for Motion273, NOT native Ground273. Common82DB7598
	-- publishes Processed2468 bit20; keep this distinct from the normal.
	flag_273: number,
	vector_96: RawVector,
	vector_128: RawVector,
	scalar_276: number,
	scalar_292: number,
	scalar_296: number,
	flag_317: number,
	flag_318: number,
}

local GroundOutputFields = {}
types.GroundOutputFields = GroundOutputFields
function GroundOutputFields.default(): GroundOutputFields
	return {
		landing_half_turns_312 = 0,
		hippy_jumping_322 = 0,
		hippy_takeoff_323 = 0,
		vector_64 = z4(),
		vector_80 = z4(),
		flag_273 = 0,
		vector_96 = z4(),
		vector_128 = z4(),
		scalar_276 = 0,
		scalar_292 = 0,
		scalar_296 = 0,
		flag_317 = 0,
		flag_318 = 0,
	}
end

export type CollisionOutputFields = {
	wheel_count_0: number,
	-- Board Fill surface vote, consumed by 82DB8120 in riding states.
	surface_type_16: number,
	-- SkeletonCollision Fill82BD60C8: +4064/+4068/+4081.
	surface_height_208: number,
	-- SkeletonCollision::Fill82BD60C8, consumed by bail scoring/audio packets.
	body_response_196: number,
	force_response_200: number,
	contact_region_response_80: { number },
	flag_214: number,
	flag_217: number,
	scalar_28: number,
	-- Offboard landing manager82D79498; reset82DE3290 clears this position.
	vector_48: RawVector,
	predicted_position_64: RawVector,
	flag_215: number,
	flag_216: number,
	wheel_contact_3296_3299: { number },
	flag_3472: number,
	flag_3475: number,
	flag_3477: number,
	flag_3478: number,
	flag_3479: number,
	flag_3480: number,
	flag_3481: number,
	-- Offboard landing manager82D7948C; reset82DE32E4 clears availability.
	flag_3482: number,
	flag_3483: number,
}

local CollisionOutputFields = {}
types.CollisionOutputFields = CollisionOutputFields
function CollisionOutputFields.default(): CollisionOutputFields
	return {
		wheel_count_0 = 0,
		surface_type_16 = 0,
		surface_height_208 = 0,
		body_response_196 = 0,
		force_response_200 = 0,
		contact_region_response_80 = table.create(8, 0),
		flag_214 = 0,
		flag_217 = 0,
		scalar_28 = 0,
		vector_48 = z4(),
		predicted_position_64 = z4(),
		flag_215 = 0,
		flag_216 = 0,
		wheel_contact_3296_3299 = { 0, 0, 0, 0 },
		flag_3472 = 0,
		flag_3475 = 0,
		flag_3477 = 0,
		flag_3478 = 0,
		flag_3479 = 0,
		flag_3480 = 0,
		flag_3481 = 0,
		flag_3482 = 0,
		flag_3483 = 0,
	}
end

export type PhysicsOutputFields = {
	flag_32: number,
	-- Physics+16. This native record is only48bytes long.
	vector_16: RawVector,
}

local PhysicsOutputFields = {}
types.PhysicsOutputFields = PhysicsOutputFields
function PhysicsOutputFields.default(): PhysicsOutputFields
	return { flag_32 = 0, vector_16 = z4() }
end

export type OffBoardOutputFields = {
	-- BipedGround Fill82D32D38 and shared Feet Fill82D785F8.
	kind_88: number,
	scalar_112: number,
	distance_116: number,
	flags_306_307: { number },
	flag_329: number,
	flag_330: number,
	flag_334: number,
	-- Common ProcessOutput82DB724C..7258 from the shared Biped720/716.
	cadence_phase_80: number,
	locomotion_state_84: number,
	-- SkateboardController FillPhysOut82D76D20 orientation outputs +36/+40.
	angle_36: number,
	angle_40: number,
	-- Reset82DE40C0; Biped trajectory publication writes the duration here.
	trajectory_time_120: number,
	-- Reset82DE4170; BipedAir Fill82D30324 publishes trajectory availability.
	trajectory_valid_331: number,
	scalar_32: number,
	flag_304: number,
	-- Common ProcessOutput82DB76F4: Processed2480 bit19, not grab-object304.
	flag_308: number,
	flag_311: number,
	-- SkateboardController82D76D88: state448 is FREE/HIDING/RETURNING.
	free_board_312: number,
	-- 82D76DA0: physical RETURNING state, distinct from animation activity323.
	returning_board_313: number,
	flag_314: number,
	flag_315: number,
	flag_316: number,
	-- OffBoard reset82DE4138 clears this. LandingOnDeckManager Fill82D79420
	-- publishes manager260 && !manager258; only Biped/LandingOnDeck state
	-- outputs call that producer. Ordinary Ground retains the reset value.
	hippy_hurdling_317: number,
	flag_318: number,
	dropping_board_322: number,
	-- 82D76ED4: state448 is HIDING.
	hiding_board_321: number,
	flag_319: number,
	retrieving_board_323: number,
	-- 82D76F68: retrieving animation OR retrieve pulse while RETURNING.
	flag_324: number,
	flag_328: number,
	vector_64: RawVector,
	-- BipedAir Fill82D30300: distinct from the on-board Air output block.
	scalar_92: number,
	vector_96: RawVector,
	word_144: number,
	scalar_148: number,
	scalar_152: number,
	scalar_156: number,
	vector_160: RawVector,
	vector_176: RawVector,
	vector_192: RawVector,
	vector_208: RawVector,
	vector_224: RawVector,
	vector_240: RawVector,
	flag_320: number,
}

local OffBoardOutputFields = {}
types.OffBoardOutputFields = OffBoardOutputFields
function OffBoardOutputFields.default(): OffBoardOutputFields
	return {
		kind_88 = 0,
		scalar_112 = 0,
		distance_116 = 0,
		flags_306_307 = { 0, 0 },
		flag_329 = 0,
		flag_330 = 0,
		flag_334 = 0,
		cadence_phase_80 = 0,
		locomotion_state_84 = 0,
		angle_36 = 0,
		angle_40 = 0,
		trajectory_time_120 = 0,
		trajectory_valid_331 = 0,
		scalar_32 = 0,
		flag_304 = 0,
		flag_308 = 0,
		flag_311 = 0,
		free_board_312 = 0,
		returning_board_313 = 0,
		flag_314 = 0,
		flag_315 = 0,
		flag_316 = 0,
		hippy_hurdling_317 = 0,
		flag_318 = 0,
		dropping_board_322 = 0,
		hiding_board_321 = 0,
		flag_319 = 0,
		retrieving_board_323 = 0,
		flag_324 = 0,
		flag_328 = 0,
		vector_64 = z4(),
		scalar_92 = 0,
		vector_96 = z4(),
		word_144 = 0,
		scalar_148 = 0,
		scalar_152 = 0,
		scalar_156 = 0,
		vector_160 = z4(),
		vector_176 = z4(),
		vector_192 = z4(),
		vector_208 = z4(),
		vector_224 = z4(),
		vector_240 = z4(),
		flag_320 = 0,
	}
end

export type PhysicalPlayerInput = {
	-- SkateboardReckoning+176; restored r29 at82DB4994 is176.
	board_reckoning_side_176: RawVector,
	skateboard: SkateboardMotionFields,
	air: air_output.AirOutputFields,
	physics: PhysicsOutputFields,
	grinds: grind_output.GrindOutputFields,
	skeleton: pose_output.SkeletonOutputFields,
	animation: pose_output.AnimationOutputFields,
	scoring: pose_output.ScoringOutputFields,
	-- Present only when Teleporting702 publishes a ready reset target.
	-- ROBLOX: player::teleport_state::Output -> any (модуль портируется отдельно).
	teleport_output: any?,
	collision: CollisionOutputFields,
	state: CurrentStateFields,
	ground: GroundOutputFields,
	reckoning: SystemReckoningFields,
	filtered_state_0: number,
	off_board: OffBoardOutputFields,
	-- `player+1896 -> +0 -> +24 -> +16`, before the variant override.
	surface_default_mode: number,
	-- Player component +1832, word +1876; source bit 28 is consumed.
	component_1832_word_1876: number,
}

local PhysicalPlayerInput = {}
types.PhysicalPlayerInput = PhysicalPlayerInput
function PhysicalPlayerInput.default(): PhysicalPlayerInput
	return {
		board_reckoning_side_176 = z4(),
		skateboard = SkateboardMotionFields.default(),
		air = air_output.AirOutputFields.default(),
		physics = PhysicsOutputFields.default(),
		grinds = grind_output.GrindOutputFields.default(),
		skeleton = pose_output.SkeletonOutputFields.default(),
		animation = pose_output.AnimationOutputFields.default(),
		scoring = pose_output.ScoringOutputFields.default(),
		teleport_output = nil,
		collision = CollisionOutputFields.default(),
		state = CurrentStateFields.default(),
		ground = GroundOutputFields.default(),
		reckoning = SystemReckoningFields.default(),
		filtered_state_0 = 0,
		off_board = OffBoardOutputFields.default(),
		surface_default_mode = 0,
		component_1832_word_1876 = 0,
	}
end

-- ROBLOX: ссылки &'a -> обычные ссылки на таблицы.
export type AnimationInputPacket = {
	publication: AnimationPacketFields,
	external_physics_10512: ExternalPhysicsInput,
	flag_10369: number,
	flag_10370: number,
	flag_10373: number,
	suppress_transition_10376: number,
	use_external_physics_10688: number,
	external_physics_flag_10689: number,
	flag_10786: number,
	flag_10787: number,
	force_braking_10796: number,
	vector_10816: RawVector,
	vector_10832: RawVector,
	vector_10848: RawVector,
	vector_10864: RawVector,
	vector_10880: RawVector,
	vector_10896: RawVector,
	scalar_10912: number,
	scalar_10916: number,
	state_variant_10928: number,
	flags_10932: number,
}

-- ROBLOX: enum NativeReferenceBase -> строки "Player" / "SurfaceSelector".
export type NativeReferenceBase = "Player" | "SurfaceSelector"

export type NativeRelativeReference = {
	base: NativeReferenceBase,
	offset: number,
}

export type PlayerInputState = {
	manager_1856_counter_320: number,
	manager_1852_flag_256: number,
	manager_1852_vector_176: RawVector,
	flags_1296: number,
	grounded_frames_1300: number,
	state_count_1312: number,
	update_count_1316: number,
	spin_same_direction_frames_1324: number,
	frames_since_teleport_1328: number,
	-- ProcessOutput82DB78A8 keeps a dismount request alive for three outputs.
	dismount_request_frames_1332: number,
	state_value_1336: number,
	state_timer_1344: number,
	time_since_last_input_1348: number,
	time_on_ground_1352: number,
	signed_ground_time_1356: number,
	previous_spin_input_1360: number,
	previous_crouch_1364: number,
	time_off_board_1368: number,
	skitch_value_1372: number,
	skitch_timer_1376: number,
	ground_timer_1380: number,
	secondary_ground_timer_1384: number,
	probe: ProbeFields,
	queued_vector_1280: RawVector,
	external_physics_cache_1008: ExternalPhysicsInput,
	prepared_jump_velocity_1184: RawVector,
	previous_ground_position_1200: RawVector,
	current_ground_position_1216: RawVector,
	ground_delta_1232: RawVector,
	damped_ground_delta_1248: RawVector,
	state_variants_1408: { StateVariantFields },
	hips_line_test_1488: LineTestFields,
	left_line_test_1536: LineTestFields,
	right_line_test_1584: LineTestFields,
	-- Number at player +1304 used to gate the ground-history filter.
	ground_history_frames_1304: number,
}

local PlayerInputState = {}
types.PlayerInputState = PlayerInputState

-- ROBLOX: impl Default for PlayerInputState.
function PlayerInputState.default(): PlayerInputState
	local variants = {}
	for i = 1, 5 do
		variants[i] = StateVariantFields.default()
	end
	return {
		manager_1856_counter_320 = 0,
		manager_1852_flag_256 = 0,
		manager_1852_vector_176 = z4(),
		flags_1296 = 0,
		grounded_frames_1300 = 0,
		state_count_1312 = 0,
		update_count_1316 = 0,
		spin_same_direction_frames_1324 = 0,
		frames_since_teleport_1328 = 0,
		dismount_request_frames_1332 = 0,
		state_value_1336 = 0,
		state_timer_1344 = 0.0,
		time_since_last_input_1348 = 0.0,
		time_on_ground_1352 = 0.0,
		signed_ground_time_1356 = 0.0,
		previous_spin_input_1360 = 0.0,
		previous_crouch_1364 = 0.0,
		time_off_board_1368 = 0.0,
		skitch_value_1372 = 0,
		skitch_timer_1376 = 0.0,
		ground_timer_1380 = 0.0,
		secondary_ground_timer_1384 = 0.0,
		probe = ProbeFields.default(),
		queued_vector_1280 = z4(),
		external_physics_cache_1008 = types.empty_external_physics(),
		prepared_jump_velocity_1184 = z4(),
		previous_ground_position_1200 = z4(),
		current_ground_position_1216 = z4(),
		ground_delta_1232 = z4(),
		damped_ground_delta_1248 = z4(),
		state_variants_1408 = variants,
		hips_line_test_1488 = LineTestFields.default(),
		left_line_test_1536 = LineTestFields.default(),
		right_line_test_1584 = LineTestFields.default(),
		ground_history_frames_1304 = 0,
	}
end

export type ProcessedPhysicsInput = {
	effective_anim_transform_192: RawMatrix,
	vectors_400_416: { RawVector },
	vectors_464_480_496_512_528: { RawVector },
	vectors_544_560_592_608: { RawVector },
	vectors_624_640_656_672: { RawVector },
	prepared_jump_704: RawVector,
	-- Skeleton::ProcessData82BD8E70..8EA8, after ordered animation attributes.
	collision_pose_error_736: RawVector,
	animation_com_to_deck_752: RawVector,
	animation_com_to_deck_delta_768: RawVector,
	vectors_720_784_800_816_832_864: { RawVector },
	vectors_880_896_912_928_944: { RawVector },
	line_tests_960_1008_1056: { LineTestFields },
	grind: grind_input.GrindInvestigationFields,
	vector_1520: RawVector,
	matrix_1536: RawMatrix,
	byte_1600: number,
	external_physics_1616: ExternalPhysicsInput,
	probe_1792: ProbeFields,
	-- Actual grab-spline publication payloads; flags2480 bits22/21 carry readiness.
	grab_records_1888_2176: { { number } },
	-- Interactable identity published by82D740F8; bit20 carries validity.
	object_2464: number,
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	flags_2480: number,
	flags_2484: number,
	flags_2488: number,
	state_identifier_2496: number,
	state_2504: number,
	state_2508: number,
	category_2512: number,
	category_2516: number,
	player_state_value_2520: number,
	filtered_state_2524: number,
	state_variant_index_2528: number,
	grind_words_2532_2536: { number },
	surface_mode_2540: number,
	surface_primary_ref_2544: NativeRelativeReference?,
	state_variant_ref_2548: NativeRelativeReference?,
	surface_secondary_ref_2552: NativeRelativeReference?,
	wheel_count_2556: number,
	state_count_2564: number,
	update_count_2568: number,
	spin_same_direction_frames_2580: number,
	frames_since_teleport_2584: number,
	skitch_value_2592: number,
	left_surface_2596: number,
	right_surface_2600: number,
	timestep_2604: number,
	scalar_2612: number,
	-- PrepareBoardToolkit82C01744: signed speed times its ordered travel sign.
	scalar_2616: number,
	transition_2636: number,
	-- Skeleton82BDD008: BodySpin plus the actual grind-air adjustment result.
	-- Read only with flags2484bit15; Reset82BFA394 clears it each input tick.
	grind_adjusted_body_spin_2644: number,
	-- Reset82BFA2D0 writes original literal822F8B40, -9.8.
	gravity_2648: number,
	scalar_2652: number,
	scalar_2656: number,
	state_timer_2664: number,
	scalar_2668: number,
	-- Written by Skeleton::ProcessData before the post-skeleton suffix.
	spin_input_2672: number,
	scalar_2696: number,
	scalar_2700: number,
	scalar_2736: number,
	time_since_last_input_2748: number,
	time_on_ground_2752: number,
	signed_ground_time_2756: number,
	truck_tightness_2760: number,
	scalar_2764: number,
	-- Current minus preceding authored board forward-axis Y,82BD8E20.
	board_at_y_delta_2768: number,
	air_scalar_2772: number,
	-- Written by Skeleton::ProcessData before crouch-delta publication.
	crouch_2776: number,
	crouch_delta_2780: number,
	off_board_scalar_2832: number,
	time_off_board_2836: number,
	ground_timer_2848: number,
	secondary_ground_timer_2852: number,
	collision_scalar_2924: number,
	actor_query_2948: number,
	actor_query_2952: number,
}

-- Immutable publication of the completed physical-input phase for one tick.
-- The mutable record remains private to the input producer; selectors and
-- later phases consume this value object so they cannot observe a half-written
-- packet.
-- ROBLOX: u64 tick -> число Luau.
export type ProcessedPhysicsSnapshot = {
	tick: number,
	input: ProcessedPhysicsInput,
}

local ProcessedPhysicsSnapshot = {}
types.ProcessedPhysicsSnapshot = ProcessedPhysicsSnapshot

-- ROBLOX: Rust копирует input по значению -> глубокая копия.
function ProcessedPhysicsSnapshot.new(tick: number, input: ProcessedPhysicsInput): ProcessedPhysicsSnapshot
	return { tick = tick, input = copy(input) }
end

local function zv(n: number): { RawVector }
	local result: { RawVector } = table.create(n) :: any
	for i = 1, n do
		result[i] = z4()
	end
	return result
end

local ProcessedPhysicsInput = {}
types.ProcessedPhysicsInput = ProcessedPhysicsInput

-- ROBLOX: impl Default for ProcessedPhysicsInput.
function ProcessedPhysicsInput.default(): ProcessedPhysicsInput
	return {
		effective_anim_transform_192 = zm(),
		vectors_400_416 = zv(2),
		vectors_464_480_496_512_528 = zv(5),
		vectors_544_560_592_608 = zv(4),
		vectors_624_640_656_672 = zv(4),
		prepared_jump_704 = z4(),
		collision_pose_error_736 = z4(),
		animation_com_to_deck_752 = z4(),
		animation_com_to_deck_delta_768 = z4(),
		vectors_720_784_800_816_832_864 = zv(6),
		vectors_880_896_912_928_944 = zv(5),
		line_tests_960_1008_1056 = { LineTestFields.default(), LineTestFields.default(), LineTestFields.default() },
		grind = grind_input.GrindInvestigationFields.default(),
		vector_1520 = z4(),
		matrix_1536 = zm(),
		byte_1600 = 0,
		external_physics_1616 = types.empty_external_physics(),
		probe_1792 = ProbeFields.default(),
		grab_records_1888_2176 = { table.create(72, 0), table.create(72, 0) },
		object_2464 = 0,
		flags_2468 = 0,
		flags_2472 = 0,
		flags_2476 = 0,
		flags_2480 = 0,
		flags_2484 = 0,
		flags_2488 = 0,
		state_identifier_2496 = 0,
		state_2504 = 0,
		state_2508 = 0,
		category_2512 = 0,
		category_2516 = 0,
		player_state_value_2520 = 0,
		filtered_state_2524 = 0,
		state_variant_index_2528 = 0,
		grind_words_2532_2536 = { 0, 0 },
		surface_mode_2540 = 0,
		surface_primary_ref_2544 = nil,
		state_variant_ref_2548 = nil,
		surface_secondary_ref_2552 = nil,
		wheel_count_2556 = 0,
		state_count_2564 = 0,
		update_count_2568 = 0,
		spin_same_direction_frames_2580 = 0,
		frames_since_teleport_2584 = 0,
		skitch_value_2592 = 0,
		left_surface_2596 = 0,
		right_surface_2600 = 0,
		timestep_2604 = 0.0,
		scalar_2612 = 0.0,
		scalar_2616 = 0.0,
		transition_2636 = 0.0,
		grind_adjusted_body_spin_2644 = 0.0,
		gravity_2648 = 0.0,
		scalar_2652 = 0.0,
		scalar_2656 = 0.0,
		state_timer_2664 = 0.0,
		scalar_2668 = 0.0,
		spin_input_2672 = 0.0,
		scalar_2696 = 0.0,
		scalar_2700 = 0.0,
		scalar_2736 = 0.0,
		time_since_last_input_2748 = 0.0,
		time_on_ground_2752 = 0.0,
		signed_ground_time_2756 = 0.0,
		truck_tightness_2760 = 0.0,
		scalar_2764 = 0.0,
		board_at_y_delta_2768 = 0.0,
		air_scalar_2772 = 0.0,
		crouch_2776 = 0.0,
		crouch_delta_2780 = 0.0,
		off_board_scalar_2832 = 0.0,
		time_off_board_2836 = 0.0,
		ground_timer_2848 = 0.0,
		secondary_ground_timer_2852 = 0.0,
		collision_scalar_2924 = 0.0,
		actor_query_2948 = 0,
		actor_query_2952 = 0,
	}
end

-- ROBLOX: pub(crate) fn empty_external_physics.
function types.empty_external_physics(): ExternalPhysicsInput
	local vectors: { RawVector } = table.create(10) :: any
	for i = 1, 10 do
		vectors[i] = z4()
	end
	return { vectors = vectors, flags = 0 }
end

return types
