--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/publication.rs (коммит 2e16697)
--
-- ROBLOX: `&mut u32` для replace_byte/replace_bool/transfer_bit -> функции
-- возвращают новое слово (word = replace_byte(word, ...)).
-- ROBLOX: Result<(), u32> -> (true) или (false, index).

local rt = require("../../../rt")
local animation_packet = require("../../input/animation_packet")
local actor_packet = require("../../animation/output/actor_packet")
local types = require("./types")

type AnimationInputPacket = types.AnimationInputPacket
type PhysicalPlayerInput = types.PhysicalPlayerInput
type PlayerInputState = types.PlayerInputState
type ProcessedPhysicsInput = types.ProcessedPhysicsInput
type RawMatrix = types.RawMatrix

local copy = types.copy

local publication = {}

local function bit(n: number): number
	return bit32.lshift(1, n)
end

function publication.replace_byte(word: number, b: number, source: number): number
	return bit32.bor(bit32.band(word, bit32.bnot(bit(b))), bit32.lshift(bit32.band(source, 1), b))
end

function publication.replace_bool(word: number, b: number, source: boolean): number
	return bit32.bor(bit32.band(word, bit32.bnot(bit(b))), bit32.lshift(if source then 1 else 0, b))
end

function publication.transfer_bit(word: number, b: number, source: number, source_bit: number): number
	return bit32.bor(bit32.band(word, bit32.bnot(bit(b))), bit32.lshift(bit32.band(bit32.rshift(source, source_bit), 1), b))
end

local replace_byte = publication.replace_byte
local replace_bool = publication.replace_bool
local transfer_bit = publication.transfer_bit

function publication.publish_player_flags(player: PlayerInputState, out: ProcessedPhysicsInput)
	out.flags_2472 = transfer_bit(out.flags_2472, 14, player.flags_1296, 27)
	out.flags_2488 = transfer_bit(out.flags_2488, 26, player.flags_1296, 20)
	out.vectors_880_896_912_928_944[4] = player.queued_vector_1280
	out.flags_2488 = transfer_bit(out.flags_2488, 22, player.flags_1296, 18)
	out.flags_2480 = transfer_bit(out.flags_2480, 16, player.flags_1296, 17)
	player.queued_vector_1280 = { 0, 0, 0, 0 }
	player.flags_1296 = bit32.band(player.flags_1296, bit32.bnot(bit(20)))
end

function publication.publish_force_braking(
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	packet: AnimationInputPacket,
	out: ProcessedPhysicsInput
)
	local force = packet.force_braking_10796 ~= 0
		and rt.to_i32(player.state_count_1312) > 5
		and physical.skateboard.scalar_160 < rt.from_bits(0x3dcccccd)
		and physical.state.state_16 == 100
		and rt.to_i32(physical.collision.wheel_count_0) > 2
	out.flags_2476 = replace_bool(out.flags_2476, 24, force)
end

function publication.publish_collision_prefix(player: PlayerInputState, physical: PhysicalPlayerInput, out: ProcessedPhysicsInput)
	out.flags_2484 = replace_byte(out.flags_2484, 26, physical.collision.flag_215)
	out.flags_2484 = replace_byte(out.flags_2484, 22, physical.collision.flag_216)
	out.vectors_720_784_800_816_832_864[6] = player.manager_1852_vector_176
end

function publication.publish_animation_packet(packet: AnimationInputPacket, out: ProcessedPhysicsInput)
	local fields: animation_packet.ProcessedPacketFields = {
		flags_2468 = out.flags_2468,
		flags_2476 = out.flags_2476,
		timestep = out.timestep_2604,
		scalar_2668 = out.scalar_2668,
		vector_1520 = out.vector_1520,
		matrix_1536 = out.matrix_1536,
		byte_1600 = out.byte_1600,
		truck_tightness = out.truck_tightness_2760,
		scalar_2764 = out.scalar_2764,
	}
	animation_packet.publish(packet.publication, fields)
	out.flags_2468 = fields.flags_2468
	out.flags_2476 = fields.flags_2476
	out.timestep_2604 = fields.timestep
	out.scalar_2668 = fields.scalar_2668
	out.vector_1520 = fields.vector_1520
	out.matrix_1536 = fields.matrix_1536
	out.byte_1600 = fields.byte_1600
	out.truck_tightness_2760 = fields.truck_tightness
	out.scalar_2764 = fields.scalar_2764
end

local function select_surface_mode(requested: number, out: ProcessedPhysicsInput)
	local mode = if requested >= 1 and requested <= 5 then requested elseif requested == 6 then 3 else 1
	local primary, secondary
	if mode == 1 then
		primary, secondary = 24, 104
	elseif mode == 2 then
		primary, secondary = 40, 116
	elseif mode == 3 then
		primary, secondary = 56, 128
	elseif mode == 4 then
		primary, secondary = 72, 140
	elseif mode == 5 then
		primary, secondary = 88, 152
	else
		error("surface mode normalization is exhaustive")
	end
	out.surface_mode_2540 = mode
	out.surface_primary_ref_2544 = { base = "SurfaceSelector", offset = primary }
	out.surface_secondary_ref_2552 = { base = "SurfaceSelector", offset = secondary }
end

-- ROBLOX: Result<(), u32> -> возвращает nil при успехе или индекс-ошибку.
function publication.select_surface(
	player: PlayerInputState,
	packet: AnimationInputPacket,
	surface_default_mode: number,
	out: ProcessedPhysicsInput
): number?
	local index = packet.state_variant_10928
	-- ROBLOX: .get(index as usize) -> индекс + 1, вне диапазона -> nil.
	local variant = player.state_variants_1408[index + 1]
	if variant == nil then
		out.state_variant_index_2528 = index
		return index
	end
	-- ROBLOX: index здесь < 5, поэтому `as u16` ничего не обрезает.
	out.state_variant_ref_2548 = { base = "Player", offset = 0x580 + 0x10 * index }
	out.state_variant_index_2528 = index

	local requested
	if variant.surface_override_enabled_60 ~= 0 then
		local value = surface_default_mode
		if value >= 1 and value <= 3 then
			requested = 1
		elseif value == 5 then
			requested = 3
		elseif value == 13 then
			requested = 2
		else
			requested = value
		end
	else
		requested = surface_default_mode
	end
	select_surface_mode(requested, out)
	return nil
end

function publication.publish_external_physics(player: PlayerInputState, packet: AnimationInputPacket, out: ProcessedPhysicsInput)
	if packet.use_external_physics_10688 ~= 0 then
		out.flags_2472 = bit32.bor(out.flags_2472, bit(29))
		actor_packet.ExternalPhysicsInput.copy_from(out.external_physics_1616, packet.external_physics_10512)
		if bit32.band(out.external_physics_1616.flags, bit(26)) ~= 0 then
			actor_packet.ExternalPhysicsInput.copy_from(player.external_physics_cache_1008, packet.external_physics_10512)
		else
			local cache = player.external_physics_cache_1008
			-- ROBLOX: vectors[5..9] -> индексы 6..9, vectors[9] -> индекс 10.
			for i = 6, 9 do
				out.external_physics_1616.vectors[i] = table.clone(cache.vectors[i])
			end
			out.external_physics_1616.vectors[10] = table.clone(cache.vectors[10])
			out.external_physics_1616.flags = transfer_bit(out.external_physics_1616.flags, 27, cache.flags, 27)
			out.external_physics_1616.flags = bit32.bor(out.external_physics_1616.flags, bit(26))
		end
	end
	out.flags_2472 = replace_byte(out.flags_2472, 28, packet.external_physics_flag_10689)
end

function publication.publish_state_prefix(
	player: PlayerInputState,
	physical: PhysicalPlayerInput,
	packet: AnimationInputPacket,
	captured_state: number,
	out: ProcessedPhysicsInput
)
	out.flags_2468 = transfer_bit(out.flags_2468, 13, player.flags_1296, 31)
	local has_probe_or_animation_flag = bit32.band(out.flags_2468, bit(2)) ~= 0 or out.probe_1792.byte_104 ~= 0
	out.flags_2468 = replace_bool(out.flags_2468, 18, has_probe_or_animation_flag)
	player.frames_since_teleport_1328 = if bit32.band(player.flags_1296, bit(29)) ~= 0
		then 0
		else rt.wrapping_add_u32(player.frames_since_teleport_1328, 1)
	out.frames_since_teleport_2584 = player.frames_since_teleport_1328
	player.flags_1296 = bit32.band(player.flags_1296, bit32.bnot(bit(29)))
	out.state_count_2564 = player.state_count_1312
	out.state_timer_2664 = player.state_timer_1344
	out.update_count_2568 = player.update_count_1316
	out.flags_2472 = replace_byte(out.flags_2472, 12, packet.flag_10373)
	out.flags_2468 = replace_byte(out.flags_2468, 0, packet.flag_10786)
	out.flags_2472 = replace_byte(out.flags_2472, 31, packet.flag_10787)
	out.state_2508 = captured_state
	out.state_2504 = captured_state
	out.category_2512 = physical.state.category_12
	out.flags_2472 = replace_byte(out.flags_2472, 30, physical.state.flag_61)
	out.flags_2472 = replace_byte(out.flags_2472, 18, physical.state.flag_69)
	out.flags_2480 = replace_byte(out.flags_2480, 31, physical.state.flag_74)
	out.grind_words_2532_2536 = table.clone(physical.grinds.words_136_140)
	out.category_2516 = physical.state.category_12
	out.player_state_value_2520 = player.state_value_1336
end

local function publish_wheel_contacts(physical: PhysicalPlayerInput, out: ProcessedPhysicsInput)
	local wheel = physical.collision.wheel_contact_3296_3299
	local outer_tail = wheel[3] ~= 0 or wheel[4] ~= 0
	local outer_nose = wheel[1] ~= 0 or wheel[2] ~= 0
	local left_pair = wheel[3] ~= 0 or wheel[1] ~= 0
	local right_pair = wheel[4] ~= 0 or wheel[2] ~= 0
	local switched = bit32.band(out.flags_2468, bit(20)) ~= 0
	out.flags_2472 = replace_bool(out.flags_2472, 27, if switched then outer_nose else outer_tail)
	out.flags_2472 = replace_bool(out.flags_2472, 26, if switched then outer_tail else outer_nose)
	out.flags_2472 = replace_bool(out.flags_2472, 25, if switched then right_pair else left_pair)
	out.flags_2472 = replace_bool(out.flags_2472, 24, if switched then left_pair else right_pair)
end

function publication.publish_physical_outputs(physical: PhysicalPlayerInput, packet: AnimationInputPacket, out: ProcessedPhysicsInput)
	out.vectors_400_416[1] = physical.skateboard.vector_80
	out.vectors_400_416[2] = physical.skateboard.vector_96
	out.scalar_2736 = physical.skateboard.scalar_172
	out.scalar_2612 = physical.skateboard.scalar_168
	out.scalar_2656 = physical.skateboard.scalar_164
	out.scalar_2652 = physical.skateboard.scalar_160
	out.vectors_720_784_800_816_832_864[1] = physical.skateboard.vector_64
	out.vectors_720_784_800_816_832_864[2] = physical.skateboard.vector_128
	out.vectors_720_784_800_816_832_864[3] = physical.skateboard.vector_144

	out.vectors_624_640_656_672[1] = packet.vector_10816
	out.vectors_624_640_656_672[2] = packet.vector_10832
	out.flags_2476 = transfer_bit(out.flags_2476, 6, packet.flags_10932, 31)
	out.flags_2476 = transfer_bit(out.flags_2476, 5, packet.flags_10932, 30)
	out.flags_2476 = transfer_bit(out.flags_2476, 4, packet.flags_10932, 29)
	out.scalar_2696 = packet.scalar_10912
	out.vectors_624_640_656_672[3] = packet.vector_10848
	out.scalar_2700 = packet.scalar_10916
	out.vectors_624_640_656_672[4] = packet.vector_10864
	out.flags_2480 = replace_byte(out.flags_2480, 0, packet.flag_10369)
	out.vectors_880_896_912_928_944[1] = packet.vector_10880
	out.vectors_880_896_912_928_944[2] = packet.vector_10896
	out.flags_2488 = transfer_bit(out.flags_2488, 24, packet.flags_10932, 22)

	out.vectors_544_560_592_608[3] = physical.reckoning.vector_64
	out.vectors_880_896_912_928_944[5] = physical.reckoning.vector_144
	out.flags_2488 = replace_byte(out.flags_2488, 21, physical.reckoning.flag_164)
	out.vectors_544_560_592_608[4] = if physical.air.use_air_reckoning_452 ~= 0
		then physical.air.vector_160
		else physical.reckoning.vector_16
	out.vectors_544_560_592_608[1] = physical.reckoning.vector_96
	out.vectors_544_560_592_608[2] = physical.board_reckoning_side_176
	out.vectors_464_480_496_512_528[1] = physical.ground.vector_96
	out.vectors_464_480_496_512_528[5] = physical.ground.vector_64
	out.vectors_720_784_800_816_832_864[5] = physical.ground.vector_128
	out.flags_2476 = replace_byte(out.flags_2476, 27, physical.ground.flag_317)
	out.flags_2476 = replace_byte(out.flags_2476, 23, physical.ground.flag_318)

	out.air_scalar_2772 = physical.air.scalar_184
	out.flags_2476 = replace_byte(out.flags_2476, 26, physical.air.flag_441)
	out.flags_2476 = replace_byte(out.flags_2476, 0, physical.air.flag_446)
	out.flags_2480 = replace_byte(out.flags_2480, 25, physical.air.flag_447)
	out.flags_2480 = replace_byte(out.flags_2480, 24, physical.air.flag_448)
	out.flags_2480 = transfer_bit(out.flags_2480, 30, physical.component_1832_word_1876, 28)
	out.flags_2468 = replace_byte(out.flags_2468, 9, physical.grinds.flag_318)
	out.flags_2468 = replace_byte(out.flags_2468, 8, physical.grinds.flag_322)

	out.flags_2468 = replace_byte(out.flags_2468, 15, physical.collision.flag_3478)
	out.flags_2468 = replace_byte(out.flags_2468, 16, physical.collision.flag_3475)
	out.flags_2468 = replace_byte(out.flags_2468, 17, physical.collision.flag_3472)
	out.wheel_count_2556 = physical.collision.wheel_count_0
	out.flags_2468 = replace_byte(out.flags_2468, 14, physical.collision.flag_3477)
	out.collision_scalar_2924 = physical.collision.scalar_28
	out.flags_2488 = replace_byte(out.flags_2488, 30, physical.collision.flag_3481)
	out.flags_2472 = replace_byte(out.flags_2472, 11, physical.physics.flag_32)
	out.vectors_720_784_800_816_832_864[4] = physical.physics.vector_16
	out.flags_2472 = replace_byte(out.flags_2472, 9, physical.skeleton.flag_597)
	out.flags_2480 = replace_byte(out.flags_2480, 10, physical.skeleton.flag_600)
	out.flags_2480 = replace_byte(out.flags_2480, 9, physical.skeleton.flag_601)
	out.filtered_state_2524 = physical.filtered_state_0

	out.flags_2476 = replace_byte(out.flags_2476, 21, physical.off_board.flag_304)
	out.flags_2476 = replace_bool(out.flags_2476, 17, physical.off_board.scalar_32 <= 0.0)
	out.flags_2480 = replace_byte(out.flags_2480, 15, physical.off_board.flag_311)
	out.flags_2476 = replace_byte(out.flags_2476, 16, physical.off_board.flag_315)
	out.flags_2476 = replace_byte(out.flags_2476, 8, physical.off_board.flag_316)
	out.off_board_scalar_2832 = physical.off_board.scalar_32
	out.flags_2480 = replace_byte(out.flags_2480, 1, physical.off_board.flag_318)
	out.flags_2484 = replace_byte(out.flags_2484, 23, physical.off_board.flag_314)
	out.vectors_880_896_912_928_944[3] = physical.off_board.vector_64
	out.flags_2484 = replace_byte(out.flags_2484, 16, physical.off_board.flag_328)
	publish_wheel_contacts(physical, out)
end

function publication.effective_animation_transform(source: RawMatrix, flags_2476: number): RawMatrix
	-- ROBLOX: копия значения матрицы (строки 1 и 3 = Rust 0 и 2).
	local result = { table.clone(source[1]), table.clone(source[2]), table.clone(source[3]), table.clone(source[4]) }
	if bit32.band(flags_2476, bit(2)) ~= 0 then
		for _, row in { 1, 3 } do
			for lane = 1, 4 do
				-- ROBLOX: (-f32::from_bits(w)).to_bits() == w ^ 0x8000_0000 (смена знака
				-- сохраняет NaN-полезную нагрузку; в Luau делаем это битовой операцией).
				result[row][lane] = bit32.bxor(result[row][lane], 0x80000000)
			end
		end
	end
	return result
end

function publication.publish_line_tests(player: PlayerInputState, out: ProcessedPhysicsInput)
	out.line_tests_960_1008_1056 = {
		copy(player.left_line_test_1536),
		copy(player.right_line_test_1584),
		copy(player.hips_line_test_1488),
	}
	if out.line_tests_960_1008_1056[1].valid ~= 0 then
		out.left_surface_2596 = out.line_tests_960_1008_1056[1].surface
	end
	if out.line_tests_960_1008_1056[2].valid ~= 0 then
		out.right_surface_2600 = out.line_tests_960_1008_1056[2].surface
	end
end

return publication
