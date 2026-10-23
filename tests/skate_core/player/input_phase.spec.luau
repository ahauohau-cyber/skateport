--!strict
--!nolint SameLineStatement
-- Сверка player::input_phase с Rust: тесты из input_phase/tests.rs,
-- special_surface.rs, types.rs (snapshot) и deck_angles_tests.rs, плюс
-- эталон golden/src/inphase.rs -> tests/golden/inphase.luau.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local ip = require("../../../src/skate_core/player/input_phase")

local f32 = rt.f32
local F, B = rt.from_bits, rt.to_bits
local eq, check = harness.eq, harness.check

local function bit(n: number): number
	return bit32.lshift(1, n)
end
local function has(word: number, n: number): boolean
	return bit32.band(word, bit(n)) ~= 0
end
local function bits4(t: { number }): { number }
	return { B(t[1]), B(t[2]), B(t[3]), B(t[4]) }
end
local function floats4(t: { number }): { number }
	return { F(t[1]), F(t[2]), F(t[3]), F(t[4]) }
end
local function same(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

local function external(flags: number): any
	local e = ip.empty_external_physics()
	e.flags = flags
	return e
end

local function animation_publication(): any
	return {
		stance_byte = 0,
		timestep = 0.25,
		scalar_10388 = 0.0,
		flags_10375_10496_10784 = { 0, 0, 0 },
		vector_10480 = { 0, 0, 0, 0 },
		matrix_10704 = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } },
		byte_10768 = 0,
		truck_tightness = 0.0,
		scalar_10792 = 0.0,
		flag_10371 = 0,
	}
end

local function packet(publication: any, external_physics: any): any
	return {
		publication = publication,
		external_physics_10512 = external_physics,
		flag_10369 = 0,
		flag_10370 = 0,
		flag_10373 = 0,
		suppress_transition_10376 = 0,
		use_external_physics_10688 = 0,
		external_physics_flag_10689 = 0,
		flag_10786 = 0,
		flag_10787 = 0,
		force_braking_10796 = 0,
		vector_10816 = { 0, 0, 0, 0 },
		vector_10832 = { 0, 0, 0, 0 },
		vector_10848 = { 0, 0, 0, 0 },
		vector_10864 = { 0, 0, 0, 0 },
		vector_10880 = { 0, 0, 0, 0 },
		vector_10896 = { 0, 0, 0, 0 },
		scalar_10912 = 0.0,
		scalar_10916 = 0.0,
		state_variant_10928 = 0,
		flags_10932 = 0,
	}
end

-- Порт тестового Services из tests.rs (таблица с методами).
local function services(opts: any): any
	local s: any = {
		calls = {},
		manager_state_change = opts.manager_state_change,
		actor_input_available = opts.actor_input_available or false,
	}
	function s.update_pre_input_manager_82d81610(self: any, _player: any, physical: any)
		table.insert(self.calls, "manager")
		if self.manager_state_change then
			physical.state.state_16 = self.manager_state_change[1]
			physical.state.category_12 = self.manager_state_change[2]
		end
	end
	function s.reset_processed_input_82bf9ef0(self: any, output: any)
		table.insert(self.calls, "reset")
		-- ROBLOX: *output = Default -> перезапись полей той же таблицы.
		table.clear(output)
		for k, v in ip.ProcessedPhysicsInput.default() :: any do
			output[k] = v
		end
	end
	function s.actor_query_slot_56(self: any): number
		table.insert(self.calls, "actor56")
		return 56
	end
	function s.actor_query_slot_44(self: any): number
		table.insert(self.calls, "actor44")
		return 44
	end
	function s.reset_player_probe_82d7a330(self: any, player: any, _physical: any)
		table.insert(self.calls, "probe_reset")
		player.probe.byte_104 = 0
	end
	function s.check_teleport_82db88c8(self: any)
		table.insert(self.calls, "teleport")
	end
	function s.actor_input_available_slot_4(self: any): boolean
		table.insert(self.calls, "actor_input")
		return self.actor_input_available
	end
	function s.transition_action_825903c8(self: any): number
		table.insert(self.calls, "transition")
		return 2.0
	end
	function s.calculate_ground_position_82c02840(self: any, _physical: any): { number }
		table.insert(self.calls, "ground_position")
		return bits4({ 2.0, 4.0, 6.0, 0.0 })
	end
	function s.prepare_board_toolkit_82c013f0(self: any)
		table.insert(self.calls, "board_toolkit")
	end
	function s.process_skeleton_82bd8918(self: any, _packet: any, _physical: any, output: any)
		table.insert(self.calls, "skeleton")
		output.flags_2472 = bit32.bor(output.flags_2472, bit(21), bit(23))
		output.flags_2476 = bit32.bor(output.flags_2476, bit(22))
		output.spin_input_2672 = 2.0
		output.crouch_2776 = 3.0
	end
	function s.update_grind_manager_82d8a828(self: any)
		table.insert(self.calls, "grind")
	end
	return s
end

-- Golden: сервисы отвечают записанными значениями.
local function golden_services(g: any): any
	local s: any = { calls = {} }
	function s.update_pre_input_manager_82d81610(self: any, _player: any, physical: any)
		table.insert(self.calls, "manager")
		if g.manager then
			physical.state.state_16 = g.manager[1]
			physical.state.category_12 = g.manager[2]
		end
	end
	function s.reset_processed_input_82bf9ef0(self: any, output: any)
		table.insert(self.calls, "reset")
		table.clear(output)
		for k, v in ip.ProcessedPhysicsInput.default() :: any do
			output[k] = v
		end
	end
	function s.actor_query_slot_56(self: any): number
		table.insert(self.calls, "actor56")
		return g.a56
	end
	function s.actor_query_slot_44(self: any): number
		table.insert(self.calls, "actor44")
		return g.a44
	end
	function s.reset_player_probe_82d7a330(self: any, player: any)
		table.insert(self.calls, "probe_reset")
		player.probe.byte_104 = 0
	end
	function s.check_teleport_82db88c8(self: any)
		table.insert(self.calls, "teleport")
	end
	function s.actor_input_available_slot_4(self: any): boolean
		table.insert(self.calls, "actor_input")
		return g.available
	end
	function s.transition_action_825903c8(self: any): number
		table.insert(self.calls, "transition")
		return g.transition
	end
	function s.calculate_ground_position_82c02840(self: any): { number }
		table.insert(self.calls, "ground_position")
		return g.ground
	end
	function s.prepare_board_toolkit_82c013f0(self: any)
		table.insert(self.calls, "board_toolkit")
	end
	function s.process_skeleton_82bd8918(self: any, _packet: any, _physical: any, o: any)
		table.insert(self.calls, "skeleton")
		o.flags_2468 = bit32.bor(o.flags_2468, g.skel_2468)
		o.flags_2472 = bit32.bor(o.flags_2472, g.skel_2472)
		o.flags_2476 = bit32.bor(o.flags_2476, g.skel_2476)
		o.spin_input_2672 = g.spin
		o.crouch_2776 = g.crouch
	end
	function s.update_grind_manager_82d8a828(self: any)
		table.insert(self.calls, "grind")
	end
	return s
end

-- Знак и полезная нагрузка NaN в Rust не определены (зависят от того, какой
-- NaN-операнд FMA x86 вернёт при нескольких NaN). Для слов, полученных
-- арифметикой f32, сравниваем «это NaN», а не точные биты NaN.
local function canonical_nan(words: { number }): { number }
	local result = table.clone(words)
	for i, w in result do
		if bit32.band(w, 0x7f800000) == 0x7f800000 and bit32.band(w, 0x007fffff) ~= 0 then
			result[i] = 0x7fc00000
		end
	end
	return result
end
local function canonicalize(view: any, keys: { string })
	for _, k in keys do
		if type(view[k]) == "table" then
			view[k] = canonical_nan(view[k])
		end
	end
end
local PLAYER_FLOAT_WORDS = { "damped_ground_delta_1248", "ground_delta_1232", "prepared_jump_velocity_1184" }

-- Записать поля из эталона поверх записи (вложенные записи — рекурсивно,
-- массивы/векторы — целиком).
local function apply(dst: any, src: any)
	for k, v in src do
		if type(v) == "table" and v[1] == nil and type(dst[k]) == "table" and dst[k][1] == nil then
			apply(dst[k], v)
		else
			dst[k] = v
		end
	end
end

local function player_view(p: any): any
	local overrides = {}
	for i, v in p.state_variants_1408 do
		overrides[i] = v.surface_override_enabled_60
	end
	return {
		manager_1856_counter_320 = p.manager_1856_counter_320,
		manager_1852_flag_256 = p.manager_1852_flag_256,
		manager_1852_vector_176 = p.manager_1852_vector_176,
		flags_1296 = p.flags_1296,
		grounded_frames_1300 = p.grounded_frames_1300,
		state_count_1312 = p.state_count_1312,
		update_count_1316 = p.update_count_1316,
		spin_same_direction_frames_1324 = p.spin_same_direction_frames_1324,
		frames_since_teleport_1328 = p.frames_since_teleport_1328,
		state_value_1336 = p.state_value_1336,
		state_timer_1344 = p.state_timer_1344,
		time_since_last_input_1348 = p.time_since_last_input_1348,
		time_on_ground_1352 = p.time_on_ground_1352,
		signed_ground_time_1356 = p.signed_ground_time_1356,
		previous_spin_input_1360 = p.previous_spin_input_1360,
		previous_crouch_1364 = p.previous_crouch_1364,
		time_off_board_1368 = p.time_off_board_1368,
		skitch_value_1372 = p.skitch_value_1372,
		skitch_timer_1376 = p.skitch_timer_1376,
		ground_timer_1380 = p.ground_timer_1380,
		secondary_ground_timer_1384 = p.secondary_ground_timer_1384,
		probe_byte_104 = p.probe.byte_104,
		queued_vector_1280 = p.queued_vector_1280,
		prepared_jump_velocity_1184 = p.prepared_jump_velocity_1184,
		previous_ground_position_1200 = p.previous_ground_position_1200,
		current_ground_position_1216 = p.current_ground_position_1216,
		ground_delta_1232 = p.ground_delta_1232,
		damped_ground_delta_1248 = p.damped_ground_delta_1248,
		overrides = overrides,
		left_valid = p.left_line_test_1536.valid,
		left_surface = p.left_line_test_1536.surface,
		right_valid = p.right_line_test_1584.valid,
		right_surface = p.right_line_test_1584.surface,
		hips_surface = p.hips_line_test_1488.surface,
		ground_history_frames_1304 = p.ground_history_frames_1304,
		cache_flags = p.external_physics_cache_1008.flags,
		cache_vectors = p.external_physics_cache_1008.vectors,
	}
end

local function player_from(g: any): any
	local p = ip.PlayerInputState.default()
	for k, v in g do
		if k == "probe_byte_104" then
			p.probe.byte_104 = v
		elseif k == "overrides" then
			for i, o in v do
				p.state_variants_1408[i].surface_override_enabled_60 = o
			end
		elseif k == "left_valid" then
			p.left_line_test_1536.valid = v
		elseif k == "left_surface" then
			p.left_line_test_1536.surface = v
		elseif k == "right_valid" then
			p.right_line_test_1584.valid = v
		elseif k == "right_surface" then
			p.right_line_test_1584.surface = v
		elseif k == "hips_surface" then
			p.hips_line_test_1488.surface = v
		elseif k == "cache_flags" then
			p.external_physics_cache_1008.flags = v
		elseif k == "cache_vectors" then
			p.external_physics_cache_1008.vectors = v
		else
			(p :: any)[k] = v
		end
	end
	return p
end

return function(report: harness.Report)
	-- tests.rs ----------------------------------------------------------------
	harness.test(report, "input_phase: complete_phase_keeps_native_service_order_and_persistent_counters", function()
		local pkt = packet(animation_publication(), external(0))
		local player = ip.PlayerInputState.default()
		player.manager_1856_counter_320 = 2
		player.manager_1852_flag_256 = 9
		player.grounded_frames_1300 = 6
		player.update_count_1316 = 42
		player.frames_since_teleport_1328 = 2
		player.ground_history_frames_1304 = 1
		player.time_since_last_input_1348 = 1.0
		player.time_on_ground_1352 = 1.0
		player.previous_spin_input_1360 = 1.0
		player.previous_crouch_1364 = 1.0
		player.previous_ground_position_1200 = bits4({ 1.0, 2.0, 3.0, 0.0 })
		player.damped_ground_delta_1248 = { 0, 0, 0, 0 }
		player.probe.byte_104 = 7
		player.left_line_test_1536.surface = 123
		player.left_line_test_1536.valid = 2
		local physical = ip.PhysicalPlayerInput.default()
		physical.state.category_12 = 100
		physical.state.state_16 = 104
		physical.state.skitch_value_40 = 77
		physical.state.signed_ground_step_84 = 1
		physical.surface_default_mode = 1
		physical.ground.scalar_276 = 0.0
		physical.ground.scalar_292 = 0.5
		physical.ground.scalar_296 = 0.75
		local output = ip.ProcessedPhysicsInput.default()
		local svc = services({ actor_input_available = true })

		local _, err = rt.catch(ip.process_input, player, physical, pkt, output, svc)
		check(err == nil, "process_input unwrap")

		same(u.diff(svc.calls, {
			"manager", "reset", "actor56", "actor44", "probe_reset", "teleport",
			"actor_input", "transition", "ground_position", "board_toolkit", "skeleton", "grind",
		}), "calls")
		eq(player.manager_1856_counter_320, 1)
		eq(player.manager_1852_flag_256, 0)
		eq(output.actor_query_2948, 56)
		eq(output.actor_query_2952, 44)
		eq(output.probe_1792.byte_104, 7)
		eq(player.probe.byte_104, 0)
		eq(player.grounded_frames_1300, 7)
		eq(player.update_count_1316, 42)
		eq(output.update_count_2568, 42)
		eq(output.time_on_ground_2752, 1.25)
		check(has(output.flags_2468, 13), "flags_2468 bit13")
		eq(output.transition_2636, 1.0)
		eq(player.skitch_timer_1376, 1.75)
		eq(output.skitch_value_2592, 77)
		eq(output.ground_timer_2848, 0.25)
		eq(output.secondary_ground_timer_2852, 0.5)
		same(u.diff(floats4(output.vectors_464_480_496_512_528[2]), { 2.0, 4.0, 6.0, 0.0 }), "v480")
		same(u.diff(floats4(output.vectors_464_480_496_512_528[3]), { 2.0, 4.0, 6.0, 0.0 }), "v496")
		local expected = { 0.2, 0.4, 0.6, 0.0 }
		for i, actual in floats4(output.vectors_464_480_496_512_528[4]) do
			check(math.abs(actual - expected[i]) < 1e-6, "v512")
		end
		same(u.diff(floats4(player.ground_delta_1232), { 1.0, 2.0, 3.0, 0.0 }), "ground_delta")
		eq(output.time_since_last_input_2748, 1.25)
		same(u.diff(floats4(output.prepared_jump_704), { 0.0, 0.0, 0.0, 0.0 }), "prepared_jump")
		eq(output.spin_same_direction_frames_2580, 1)
		eq(output.crouch_delta_2780, 2.0)
		eq(output.left_surface_2596, 123)
	end)

	harness.test(report, "input_phase: manager_call_precedes_category_capture_but_state_number_is_already_captured", function()
		local pkt = packet(animation_publication(), external(0))
		local player = ip.PlayerInputState.default()
		local physical = ip.PhysicalPlayerInput.default()
		physical.state.state_16 = 11
		physical.state.category_12 = 100
		physical.surface_default_mode = 1
		physical.skeleton.anim_to_world_11920[4] = { 7, 8, 9, 10 }
		local output = ip.ProcessedPhysicsInput.default()
		local svc = services({ manager_state_change = { 22, 500 } })
		local _, err = rt.catch(ip.process_input, player, physical, pkt, output, svc)
		check(err == nil, "unwrap")
		eq(output.state_2504, 11)
		eq(output.state_2508, 11)
		eq(output.category_2512, 500)
		eq(output.category_2516, 500)
		same(u.diff(player.current_ground_position_1216, { 7, 8, 9, 10 }), "ground")
		check(table.find(svc.calls, "ground_position") == nil, "no ground_position")
		eq(B(player.time_off_board_1368), 0x3c888889)
	end)

	harness.test(report, "input_phase: physical_publication_uses_low_flag_bits_and_stance_wheel_permutation", function()
		local pkt = packet(animation_publication(), external(0))
		pkt.flags_10932 = bit32.bor(bit(31), bit(29), bit(22))
		pkt.flag_10369 = 2
		local physical = ip.PhysicalPlayerInput.default()
		physical.ground.flag_317 = 3
		physical.air.flag_446 = 2
		physical.off_board.scalar_32 = 0 / 0
		physical.collision.wheel_contact_3296_3299 = { 1, 0, 0, 0 }
		local output = ip.ProcessedPhysicsInput.default()
		output.flags_2468 = bit32.band(output.flags_2468, bit32.bnot(bit(20)))

		ip.publication.publish_physical_outputs(physical, pkt, output)
		check(has(output.flags_2476, 6))
		check(not has(output.flags_2476, 5))
		check(has(output.flags_2476, 4))
		check(has(output.flags_2488, 24))
		check(bit32.band(output.flags_2480, 1) == 0)
		check(has(output.flags_2476, 27))
		check(bit32.band(output.flags_2476, 1) == 0)
		check(not has(output.flags_2476, 17))
		check(not has(output.flags_2472, 27))
		check(has(output.flags_2472, 26))
		check(has(output.flags_2472, 25))
		check(not has(output.flags_2472, 24))

		output.flags_2468 = bit32.bor(output.flags_2468, bit(20))
		ip.publication.publish_physical_outputs(physical, pkt, output)
		check(has(output.flags_2472, 27))
		check(not has(output.flags_2472, 26))
		check(not has(output.flags_2472, 25))
		check(has(output.flags_2472, 24))
	end)

	harness.test(report, "input_phase: external_physics_fallback_uses_cached_trajectory_and_preserves_packet_high_bits", function()
		local incoming = external(bit32.bor(bit(31), bit(25)))
		for i = 1, 10 do
			incoming.vectors[i] = { 0x100, 0x100, 0x100, 0x100 }
		end
		local pkt = packet(animation_publication(), incoming)
		pkt.use_external_physics_10688 = 1
		pkt.external_physics_flag_10689 = 3
		local player = ip.PlayerInputState.default()
		for index = 5, 9 do
			player.external_physics_cache_1008.vectors[index + 1] = { index, index, index, index }
		end
		player.external_physics_cache_1008.flags = bit(27)
		local output = ip.ProcessedPhysicsInput.default()
		output.external_physics_1616.flags = 0x1234

		ip.publication.publish_external_physics(player, pkt, output)

		check(has(output.flags_2472, 29))
		check(has(output.flags_2472, 28))
		same(u.diff(output.external_physics_1616.vectors[5], { 0x100, 0x100, 0x100, 0x100 }), "v4")
		same(u.diff(output.external_physics_1616.vectors[6], { 5, 5, 5, 5 }), "v5")
		same(u.diff(output.external_physics_1616.vectors[10], { 9, 9, 9, 9 }), "v9")
		check(has(output.external_physics_1616.flags, 31))
		check(has(output.external_physics_1616.flags, 27))
		check(has(output.external_physics_1616.flags, 26))
		eq(bit32.band(output.external_physics_1616.flags, 0x01ffffff), 0x1234)
	end)

	harness.test(report, "input_phase: surface_selector_and_effective_transform_match_recovered_switches", function()
		local pkt = packet(animation_publication(), external(0))
		local player = ip.PlayerInputState.default()
		player.state_variants_1408[3].surface_override_enabled_60 = 1
		pkt.state_variant_10928 = 2
		local output = ip.ProcessedPhysicsInput.default()

		check(ip.publication.select_surface(player, pkt, 13, output) == nil)
		eq(output.surface_mode_2540, 2)
		eq((output.state_variant_ref_2548 :: any).offset, 0x5a0)
		eq((output.surface_primary_ref_2544 :: any).offset, 40)
		eq((output.surface_secondary_ref_2552 :: any).offset, 116)

		player.state_variants_1408[3].surface_override_enabled_60 = 0
		check(ip.publication.select_surface(player, pkt, 6, output) == nil)
		eq(output.surface_mode_2540, 3)
		pkt.state_variant_10928 = 5
		eq(ip.publication.select_surface(player, pkt, 1, output) :: number, 5)

		local matrix = {
			{ B(1.0), B(-2.0), B(0.0), B(4.0) },
			{ B(5.0), B(5.0), B(5.0), B(5.0) },
			{ B(6.0), B(7.0), B(8.0), B(9.0) },
			{ B(10.0), B(10.0), B(10.0), B(10.0) },
		}
		local flipped = ip.publication.effective_animation_transform(matrix, bit(2))
		eq(flipped[1][1], B(-1.0))
		eq(flipped[1][2], B(2.0))
		same(u.diff(flipped[2], matrix[2]), "row1")
		eq(flipped[3][1], B(-6.0))
		same(u.diff(flipped[4], matrix[4]), "row3")
	end)

	harness.test(report, "input_phase: physical_vector_publication_uses_the_restored_native_offsets", function()
		local pkt = packet(animation_publication(), external(0))
		local physical = ip.PhysicalPlayerInput.default()
		local function w(n: number): { number }
			return { n, n, n, n }
		end
		physical.board_reckoning_side_176 = w(176)
		physical.reckoning.vector_16 = w(16)
		physical.reckoning.vector_64 = w(64)
		physical.reckoning.vector_96 = w(96)
		physical.physics.vector_16 = w(116)
		physical.off_board.vector_64 = w(164)
		physical.air.vector_160 = w(160)
		local output = ip.ProcessedPhysicsInput.default()
		ip.publication.publish_physical_outputs(physical, pkt, output)
		same(u.diff(output.vectors_544_560_592_608, { w(96), w(176), w(64), w(16) }), "544")
		same(u.diff(output.vectors_720_784_800_816_832_864[4], w(116)), "816")
		same(u.diff(output.vectors_880_896_912_928_944[3], w(164)), "912")
		physical.air.use_air_reckoning_452 = 1
		ip.publication.publish_physical_outputs(physical, pkt, output)
		same(u.diff(output.vectors_544_560_592_608[4], w(160)), "608")
	end)

	harness.test(report, "input_phase: deck_angles_preserve_native_quadrants_stance_and_pitch_projection", function()
		local output = ip.SkeletonOutputFields.default()
		local pi = f32(math.pi)
		for _, c in {
			{ 1.0, 1.0, pi / 4.0 }, { -1.0, 1.0, -pi / 4.0 },
			{ 1.0, -1.0, 3.0 * pi / 4.0 }, { -1.0, -1.0, -3.0 * pi / 4.0 },
			{ 0.0, 0.0, pi / 2.0 }, { -0.0, -0.0, -pi / 2.0 },
		} do
			ip.SkeletonOutputFields.publish_deck_angles(output, { c[1], 0.5, c[2], 0.0 }, false)
			check(math.abs(output.deck_yaw_536 - c[3]) < 0.00001, "yaw")
			eq(output.deck_pitch_540, 0.5)
		end
		ip.SkeletonOutputFields.publish_deck_angles(output, { 1.0, 0.5, 1.0, 0.0 }, true)
		check(math.abs(output.deck_yaw_536 + 3.0 * pi / 4.0) < 0.00001, "flipped yaw")
		eq(output.deck_pitch_540, -0.5)
	end)

	-- types.rs snapshot_tests -------------------------------------------------
	harness.test(report, "input_phase: processed_snapshot_is_immutable_and_tick_owned", function()
		local input = ip.ProcessedPhysicsInput.default()
		input.flags_2468 = 0x10
		local snapshot = ip.ProcessedPhysicsSnapshot.new(23, input)
		input.flags_2468 = 0x20
		eq(snapshot.tick, 23)
		eq(snapshot.input.flags_2468, 0x10)
		eq(input.flags_2468, 0x20)
	end)

	-- special_surface.rs tests ------------------------------------------------
	local function run(state: number, out: any, p: any, board: number): { boolean }
		p.state_2508 = state
		local flags = table.create(36, false)
		ip.publish_special_surface(out, p, flags, board, 8.0)
		return flags
	end

	harness.test(report, "special_surface: board_feedback_is_owned_by_riding_states", function()
		for _, state in { 200, 202, 400, 401, 500, 501, 502, 600, 601, 602, 701, 702 } do
			local out = ip.PhysicalPlayerInput.default()
			out.collision.surface_type_16 = 12
			check(not run(state, out, ip.ProcessedPhysicsInput.default(), bit(25))[14])
			eq(out.collision.flag_3481, 0)
		end
		for _, state in { 100, 101, 102, 103, 104, 503 } do
			for _, c: any in { { 0, false, false }, { 6, false, true }, { 9, true, false }, { 12, true, false } } :: any do
				local out = ip.PhysicalPlayerInput.default()
				out.collision.surface_type_16 = c[1]
				local f = run(state, out, ip.ProcessedPhysicsInput.default(), bit(25))
				check(f[14] == c[2] and f[18] == c[3], "flags")
				check((out.state.flag_69 ~= 0) == c[3], "flag_69")
				eq(out.collision.flag_3481, 1)
				run(state, out, ip.ProcessedPhysicsInput.default(), 0)
				eq(out.collision.flag_3481, 0)
				eq(out.collision.scalar_28, 8.0)
			end
		end
	end)

	harness.test(report, "special_surface: air_probes_use_the_exact_strict_threshold", function()
		for _, state in { 201, 501 } do
			for _, c: any in { { F(0x3d851eb7), true }, { ip.special_surface.PROBE_TIME, false }, { F(0x3d851eb9), false }, { 0 / 0, false } } :: any do
				local t, expected = c[1], c[2]
				local out = ip.PhysicalPlayerInput.default()
				out.air.surface_category_232 = 12
				out.air.scalar_184 = t
				local cp = table.clone(out.air.collision_position_16)
				cp[2] = B(3.0)
				out.air.collision_position_16 = cp
				out.off_board.word_144 = 12
				out.off_board.scalar_32 = t
				out.off_board.scalar_148 = 3.0
				local f = run(state, out, ip.ProcessedPhysicsInput.default(), 0)
				check(f[14] == expected, string.format("state %d, time %s", state, tostring(t)))
				check((out.collision.flag_3481 ~= 0) == expected)
				if expected then
					eq(out.collision.scalar_28, 3.0)
				end
			end
		end
	end)

	harness.test(report, "special_surface: foot_priority_and_existing_height_match_the_native_branches", function()
		for _, state in { 500, 502 } do
			local p = ip.ProcessedPhysicsInput.default()
			for i, h in { 8.0, 4.0 } do
				local line = p.line_tests_960_1008_1056[i]
				line.surface = bit32.lshift(12, 7)
				local pos = table.clone(line.position)
				pos[2] = B(h)
				line.position = pos
			end
			local out = ip.PhysicalPlayerInput.default()
			check(run(state, out, p, 0)[14])
			eq(out.collision.scalar_28, 4.0)
			out.collision.scalar_28 = 20.0
			run(state, out, p, 0)
			eq(out.collision.scalar_28, 20.0)
			out.off_board.flags_306_307 = { 1, 1 }
			run(state, out, p, 0)
			eq(out.collision.scalar_28, 8.0)
			out.off_board.flags_306_307 = { 0, 1 }
			run(state, out, p, 0)
			eq(out.collision.scalar_28, 8.0)
			out.collision.flag_3481 = 0
			run(state, out, p, 0)
			eq(out.collision.scalar_28, 4.0)
			out = ip.PhysicalPlayerInput.default()
			p.line_tests_960_1008_1056[2].surface = 0
			check(not run(state, out, p, 0)[14])
			eq(out.collision.flag_3481, 0)
		end
	end)

	harness.test(report, "special_surface: ragdoll_contacts_outrank_prediction_without_a_new_bail", function()
		local out = ip.PhysicalPlayerInput.default()
		local p = ip.ProcessedPhysicsInput.default()
		out.collision.flag_214 = 1
		out.collision.flag_217 = 1
		out.collision.flag_3483 = 1
		out.collision.surface_height_208 = 6.0
		out.collision.predicted_position_64 = { 0, B(10.0), 0, 0 }
		local f = run(300, out, p, 0)
		check(not f[14])
		check(f[18])
		eq(out.collision.scalar_28, 6.0)
		out.collision.flag_217 = 0
		run(300, out, p, 0)
		eq(out.collision.scalar_28, 10.0)
	end)

	harness.test(report, "special_surface: plant_contacts_use_the_native_validity_and_packed_surface", function()
		for _, state in { 601, 602 } do
			for _, valid in { false, true } do
				for _, surface in { 0, 6, 9, 12 } do
					local out = ip.PhysicalPlayerInput.default()
					local p = ip.ProcessedPhysicsInput.default()
					out.air.flag_448 = if valid then 1 else 0
					out.air.footplant_surface_224 = bit32.bor(bit32.lshift(surface, 7), 37)
					out.air.footplant_surface_height_216 = 7.0
					local line = p.line_tests_960_1008_1056[3]
					line.valid = if valid then 1 else 0
					line.surface = bit32.bor(bit32.lshift(surface, 7), 37)
					line.position = { 0, B(7.0), 0, 0 }
					local flags = run(state, out, p, 0)
					check(flags[14] == (valid and (surface == 9 or surface == 12)), "bail")
					check(flags[18] == (valid and surface == 6), "teleport")
					check((out.collision.flag_3481 ~= 0) == (valid and surface == 12), "water")
					if valid and surface == 12 then
						eq(out.collision.scalar_28, 7.0)
					end
				end
			end
		end
	end)

	-- Эталон Rust --------------------------------------------------------------
	local ok, golden = pcall(require, "../../golden/inphase")
	if not ok or type(golden) ~= "table" then
		return
	end
	local g: any = golden

	harness.test(report, "input_phase: process_input, deck angles, twist vs Rust", function()
		local errors = 0
		for n, case in g.phase do
			local w = string.format("inphase#%d ", n)
			local player = player_from(case.player)
			local physical = ip.PhysicalPlayerInput.default()
			apply(physical, case.physical)
			local gp = case.packet
			local pub = animation_publication()
			apply(pub, gp.publication)
			local pkt = packet(pub, { vectors = gp.external.vectors, flags = gp.external.flags })
			for k, v in gp do
				if k ~= "publication" and k ~= "external" then
					pkt[k] = v
				end
			end
			local svc = golden_services(case.services)
			local output = ip.ProcessedPhysicsInput.default()
			local _, err = rt.catch(ip.process_input, player, physical, pkt, output, svc)
			if case.err ~= nil then
				errors += 1
				check(err ~= nil and err.kind == "InvalidStateVariant" and err.value == case.err, w .. "error")
			else
				check(err == nil, w .. "unexpected error " .. tostring(err and err.kind))
			end
			same(u.diff(svc.calls, case.calls), w .. "calls")
			local pv, pw = player_view(player), table.clone(case.player_out)
			canonicalize(pv, PLAYER_FLOAT_WORDS)
			canonicalize(pw, PLAYER_FLOAT_WORDS)
			same(u.diff(pv, pw), w .. "player")
			local view: any = table.clone(output)
			view.external_vectors = output.external_physics_1616.vectors
			view.external_flags = output.external_physics_1616.flags
			view.probe_byte_104 = output.probe_1792.byte_104
			local want = table.clone(case.out)
			for _, t in { view, want } do
				t.prepared_jump_704 = canonical_nan(t.prepared_jump_704)
				t.vectors_464_480_496_512_528 = table.clone(t.vectors_464_480_496_512_528)
				t.vectors_464_480_496_512_528[4] = canonical_nan(t.vectors_464_480_496_512_528[4])
			end
			same(u.diff(view, want), w .. "out")
			same(u.diff(physical.state, case.phys_state), w .. "state")
		end
		for n, c in g.deck do
			local o = ip.SkeletonOutputFields.default()
			ip.SkeletonOutputFields.publish_deck_angles(o, c.forward, c.flipped)
			same(u.diff({ o.deck_yaw_536, o.deck_pitch_540 }, { c.yaw, c.pitch }), string.format("deck#%d", n))
		end
		for n, c in g.twist do
			local pose = {}
			pose[7] = { {}, {}, {}, c.p6 }
			pose[11] = { {}, {}, {}, c.p10 }
			local o = ip.SkeletonOutputFields.default()
			ip.SkeletonOutputFields.publish_twist(o, { pose = pose }, c.forward, c.up)
			same(u.diff(o.twist_504, c.twist), string.format("twist#%d", n))
		end
		table.insert(report.lines, string.format("      input_phase: %d фаз (%d с ошибкой варианта), %d deck, %d twist", #g.phase, errors, #g.deck, #g.twist))
	end)
end
