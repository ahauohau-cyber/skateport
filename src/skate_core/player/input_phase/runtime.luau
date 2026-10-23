--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/runtime.rs (коммит 2e16697)
--
-- ROBLOX: trait InputPhaseServices -> таблица с методами (services:method(...)).
-- Ошибка сервиса — rt.raise(e) внутри метода; здесь она оборачивается в
-- InputPhaseError { kind = "Service", value = e } и пробрасывается дальше
-- через rt.raise. Вызывающий ловит ошибку через rt.catch.
-- ROBLOX: Result<(), InputPhaseError<E>> -> обычный возврат или rt.raise.

local rt = require("../../../rt")
local publication = require("./publication")
local types = require("./types")
local motion_math = require("./motion_math")

local f32 = rt.f32

type AnimationInputPacket = types.AnimationInputPacket
type PhysicalPlayerInput = types.PhysicalPlayerInput
type PlayerInputState = types.PlayerInputState
type ProcessedPhysicsInput = types.ProcessedPhysicsInput
type RawVector = types.RawVector

local replace_bool = publication.replace_bool
local replace_byte = publication.replace_byte
local transfer_bit = publication.transfer_bit

local runtime = {}

local FIXED_FRAME_STEP = rt.from_bits(0x3c888889)

-- Mandatory boundaries called by TU3 `PhysicalPlayerHiLOD::Input`.
--
-- Inlined motion calculations execute directly in this module. Services own
-- only separate physical subsystems and host data access.
export type InputPhaseServices = {
	update_pre_input_manager_82d81610: (self: any, player: PlayerInputState, physical: PhysicalPlayerInput) -> (),
	reset_processed_input_82bf9ef0: (self: any, output: ProcessedPhysicsInput) -> (),
	actor_query_slot_56: (self: any) -> number,
	actor_query_slot_44: (self: any) -> number,
	reset_player_probe_82d7a330: (self: any, player: PlayerInputState, physical: PhysicalPlayerInput) -> (),
	check_teleport_82db88c8: (self: any, player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput) -> (),
	actor_input_available_slot_4: (self: any) -> boolean,
	transition_action_825903c8: (self: any) -> number,
	calculate_ground_position_82c02840: (self: any, physical: PhysicalPlayerInput) -> RawVector,
	prepare_board_toolkit_82c013f0: (self: any, player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput) -> (),
	process_skeleton_82bd8918: (self: any, packet: AnimationInputPacket, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput) -> (),
	update_grind_manager_82d8a828: (self: any, player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput) -> (),
}

-- ROBLOX: enum InputPhaseError<E> { Service(E), InvalidStateVariant(u32) }.
-- Native dereferences a null +2548 pointer when this packet value is >4.
export type InputPhaseError = { kind: "Service", value: any } | { kind: "InvalidStateVariant", value: number }

local InputPhaseError = {}
runtime.InputPhaseError = InputPhaseError
function InputPhaseError.Service(e: any): InputPhaseError
	return { kind = "Service", value = e }
end
function InputPhaseError.InvalidStateVariant(index: number): InputPhaseError
	return { kind = "InvalidStateVariant", value = index }
end

-- Pre-reset observations retained by82DB4048 across CheckTeleport.
export type InputContinuation = {
	captured_state: number,
	captured_category: number,
}

-- ROBLOX: `.map_err(InputPhaseError::Service)?` -> вызов метода в rt.catch
-- и rt.raise(InputPhaseError.Service(e)) при ошибке.
local function service(services: any, method: string, ...: any): any
	local value, err = rt.catch(services[method], services, ...)
	if err ~= nil then
		rt.raise(InputPhaseError.Service(err))
	end
	return value
end

local function xenon_fsel(test: number, nonnegative: number, negative: number): number
	return if test >= -0.0 then nonnegative else negative
end

local function native_nonnegative_decrement(value: number): number
	local decremented = rt.wrapping_sub_u32(value, 1)
	-- ROBLOX: decremented.overflowing_add(0x8000_0000).1 — перенос есть,
	-- когда decremented >= 0x8000_0000.
	if decremented + 0x80000000 > 0xffffffff then
		return 0
	end
	return decremented
end

local function publish_transition(packet: AnimationInputPacket, output: ProcessedPhysicsInput, services: any)
	if not service(services, "actor_input_available_slot_4") then
		return
	end
	if packet.suppress_transition_10376 ~= 0 then
		output.transition_2636 = 0.0
	else
		local value = service(services, "transition_action_825903c8")
		local lower = xenon_fsel(f32(-1.0 - value), -1.0, value)
		output.transition_2636 = xenon_fsel(f32(1.0 - lower), lower, 1.0)
	end
end

local function update_signed_ground_time(player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput)
	local previous = player.signed_ground_time_1356
	player.signed_ground_time_1356 = if physical.state.signed_ground_step_84 ~= 0
		then f32(xenon_fsel(previous, previous, 0.0) + FIXED_FRAME_STEP)
		else f32(xenon_fsel(previous, 0.0, previous) - FIXED_FRAME_STEP)
	output.signed_ground_time_2756 = player.signed_ground_time_1356
end

local function update_time_on_ground(player: PlayerInputState, captured_category: number, output: ProcessedPhysicsInput)
	if captured_category == 100 then
		output.flags_2472 = bit32.bor(output.flags_2472, bit32.lshift(1, 13))
		player.grounded_frames_1300 = rt.wrapping_add_u32(player.grounded_frames_1300, 1)
		player.time_on_ground_1352 = f32(player.time_on_ground_1352 + output.timestep_2604)
		player.flags_1296 = replace_bool(player.flags_1296, 31, rt.to_i32(player.grounded_frames_1300) > 6)
	else
		player.time_on_ground_1352 = 0.0
		player.grounded_frames_1300 = 0
	end
	output.time_on_ground_2752 = player.time_on_ground_1352
end

local function update_timers(player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput)
	if physical.state.state_16 == 104 then
		player.skitch_timer_1376 = 2.0
		player.skitch_value_1372 = physical.state.skitch_value_40
	end
	if player.skitch_timer_1376 > 0.0 then
		player.skitch_timer_1376 = f32(player.skitch_timer_1376 - output.timestep_2604)
		output.skitch_value_2592 = player.skitch_value_1372
	end
	if physical.ground.scalar_292 > 0.0 then
		player.ground_timer_1380 = physical.ground.scalar_292
	end
	if player.ground_timer_1380 > 0.0 then
		player.ground_timer_1380 = f32(player.ground_timer_1380 - output.timestep_2604)
		output.ground_timer_2848 = player.ground_timer_1380
		output.skitch_value_2592 = player.skitch_value_1372
	end
	if physical.ground.scalar_296 > 0.0 then
		player.secondary_ground_timer_1384 = physical.ground.scalar_296
	end
	if player.secondary_ground_timer_1384 > 0.0 then
		player.secondary_ground_timer_1384 = f32(player.secondary_ground_timer_1384 - output.timestep_2604)
		output.secondary_ground_timer_2852 = player.secondary_ground_timer_1384
	end
end

local function update_ground_position(
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	captured_category: number,
	output: ProcessedPhysicsInput,
	services: any
)
	if captured_category == 500 then
		player.current_ground_position_1216 = physical.skeleton.anim_to_world_11920[4]
		player.time_off_board_1368 = f32(player.time_off_board_1368 + FIXED_FRAME_STEP)
	else
		player.current_ground_position_1216 = service(services, "calculate_ground_position_82c02840", physical)
		player.time_off_board_1368 = 0.0
	end
	output.time_off_board_2836 = player.time_off_board_1368
end

local function update_ground_history(player: PlayerInputState, captured_category: number, output: ProcessedPhysicsInput)
	if captured_category ~= 200 and captured_category ~= 600 and player.ground_history_frames_1304 > 0 then
		local previous = player.previous_ground_position_1200
		player.previous_ground_position_1200 = player.current_ground_position_1216
		if output.frames_since_teleport_2584 > 1 then
			local result = motion_math.ground_history({
				previous_position = previous,
				current_position = player.current_ground_position_1216,
				previous_filtered_delta = player.damped_ground_delta_1248,
				timestep_bits = rt.to_bits(output.timestep_2604),
			})
			player.ground_delta_1232 = result.delta
			player.damped_ground_delta_1248 = result.filtered_delta
		end
	end
end

local function publish_ground_history(player: PlayerInputState, output: ProcessedPhysicsInput)
	output.vectors_464_480_496_512_528[2] = player.previous_ground_position_1200
	output.vectors_464_480_496_512_528[3] = player.current_ground_position_1216
	output.vectors_464_480_496_512_528[4] = player.damped_ground_delta_1248
end

local function publish_post_skeleton(player: PlayerInputState, physical: PhysicalPlayerInput, output: ProcessedPhysicsInput)
	if bit32.band(output.flags_2472, bit32.lshift(1, 21)) ~= 0 then
		output.flags_2472 = replace_byte(output.flags_2472, 21, physical.state.flag_66)
	end
	local skitch_or_ground_window = player.skitch_timer_1376 > 0.0
		or (bit32.band(output.flags_2476, bit32.lshift(1, 22)) ~= 0 and physical.ground.scalar_276 >= 0.0)
	output.flags_2476 = replace_bool(output.flags_2476, 3, skitch_or_ground_window)
	player.time_since_last_input_1348 = if bit32.band(output.flags_2472, bit32.lshift(1, 23)) ~= 0
		then f32(player.time_since_last_input_1348 + output.timestep_2604)
		else 0.0
	output.time_since_last_input_2748 = player.time_since_last_input_1348

	if bit32.band(output.flags_2468, bit32.lshift(1, 21)) ~= 0 then
		player.prepared_jump_velocity_1184 = output.vectors_400_416[2]
	else
		player.prepared_jump_velocity_1184 = motion_math.prepared_jump_velocity({
			skateboard_vector = output.vectors_400_416[2],
			previous_velocity = player.prepared_jump_velocity_1184,
		})
	end

	player.spin_same_direction_frames_1324 = if f32(output.spin_input_2672 * player.previous_spin_input_1360) <= 0.0
		then 0
		else rt.wrapping_add_u32(player.spin_same_direction_frames_1324, 1)
	player.previous_spin_input_1360 = output.spin_input_2672
	output.spin_same_direction_frames_2580 = player.spin_same_direction_frames_1324
	output.prepared_jump_704 = player.prepared_jump_velocity_1184
	output.crouch_delta_2780 = f32(output.crouch_2776 - player.previous_crouch_1364)
	player.previous_crouch_1364 = output.crouch_2776
end

-- 82DB4048 through CheckTeleport82DB42DC. Complete the physical reset
-- continuation before calling finish_input; captured fields must survive it.
function runtime.start_input(
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	packet: AnimationInputPacket,
	output: ProcessedPhysicsInput,
	services: any
): InputContinuation
	local captured_state = physical.state.state_16
	player.manager_1856_counter_320 = native_nonnegative_decrement(player.manager_1856_counter_320)
	service(services, "update_pre_input_manager_82d81610", player, physical)
	player.manager_1852_flag_256 = 0
	local captured_category = physical.state.category_12
	service(services, "reset_processed_input_82bf9ef0", output)

	publication.publish_player_flags(player, output)
	output.actor_query_2948 = service(services, "actor_query_slot_56")
	output.actor_query_2952 = service(services, "actor_query_slot_44")
	publication.publish_force_braking(player, physical, packet, output)
	-- ROBLOX: Copy-структура -> копия таблицы.
	output.probe_1792 = types.copy(player.probe)
	service(services, "reset_player_probe_82d7a330", player, physical)
	publication.publish_collision_prefix(player, physical, output)
	publication.publish_animation_packet(packet, output)

	output.state_identifier_2496 = physical.state.identifier_8
	service(services, "check_teleport_82db88c8", player, physical, output)
	return { captured_state = captured_state, captured_category = captured_category }
end

-- 82DB42F0 through82DB5570, after any reset/normal-setup continuation.
function runtime.finish_input(
	continuation: InputContinuation,
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	packet: AnimationInputPacket,
	output: ProcessedPhysicsInput,
	services: any
)
	local captured_state, captured_category = continuation.captured_state, continuation.captured_category
	output.flags_2472 = transfer_bit(output.flags_2472, 10, player.flags_1296, 29)
	publish_transition(packet, output, services)
	update_signed_ground_time(player, physical, output)
	update_time_on_ground(player, captured_category, output)

	local invalid = publication.select_surface(player, packet, physical.surface_default_mode, output)
	if invalid ~= nil then
		rt.raise(InputPhaseError.InvalidStateVariant(invalid))
	end
	output.flags_2476 = replace_byte(output.flags_2476, 2, packet.flag_10370)
	publication.publish_external_physics(player, packet, output)
	publication.publish_state_prefix(player, physical, packet, captured_state, output)
	publication.publish_physical_outputs(physical, packet, output)
	update_timers(player, physical, output)
	update_ground_position(player, physical, captured_category, output, services)

	output.effective_anim_transform_192 =
		publication.effective_animation_transform(physical.skeleton.anim_to_world_11920, output.flags_2476)
	update_ground_history(player, captured_category, output)
	publish_ground_history(player, output)
	service(services, "prepare_board_toolkit_82c013f0", player, physical, output)
	publication.publish_line_tests(player, output)
	service(services, "process_skeleton_82bd8918", packet, physical, output)
	publish_post_skeleton(player, physical, output)
	service(services, "update_grind_manager_82d8a828", player, physical, output)
end

-- Complete recovered TU3 PhysicalPlayerHiLOD::Input82DB4048.
-- The split also lets a host release subsystem borrows at CheckTeleport.
function runtime.process_input(
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	packet: AnimationInputPacket,
	output: ProcessedPhysicsInput,
	services: any
)
	local continuation = runtime.start_input(player, physical, packet, output, services)
	runtime.finish_input(continuation, player, physical, packet, output, services)
end

return runtime
