-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/player/input_phase/publication")
local v9 = import("skate_core/player/input_phase/motion_math")
local effective_animation_transform, publish_animation_packet, publish_collision_prefix, publish_external_physics = v8.effective_animation_transform, v8.publish_animation_packet, v8.publish_collision_prefix, v8.publish_external_physics
local publish_force_braking, publish_line_tests, publish_physical_outputs, publish_player_flags = v8.publish_force_braking, v8.publish_line_tests, v8.publish_physical_outputs, v8.publish_player_flags
local publish_state_prefix, replace_bool, replace_byte, select_surface = v8.publish_state_prefix, v8.replace_bool, v8.replace_byte, v8.select_surface
local transfer_bit, copy_into, effective_animation_transform_into = v8.transfer_bit, v8.copy_into, v8.effective_animation_transform_into
local v10 = false
local t1 = {}

function t1.set_reference(p3) -- line: 52
    -- upvalues: v10 (ref)
    v10 = p3
end

local t2 = {
    0, 0, 0, 0
}

t1.FIXED_FRAME_STEP = 0.01666666753590107
t1.InputPhaseServices = {}
t1.InputPhaseError = {}
t1.InputContinuation = {}

local function map_err_service_reference(p4, ...) -- line: 95
    local v11 = table.pack(pcall(p4, ...))

    if not v11[1] then
        error({
            tag = "Service",
            v11[2]
        }, 0)
    end

    return table.unpack(v11, 2, v11.n)
end

t1.map_err_service_reference = map_err_service_reference

local function service_results(p5, ...) -- line: 107
    if p5 then
        return ...
    end

    error({
        tag = "Service",
        (...)
    }, 0)

    return ...
end

local function map_err_service(p6, ...) -- line: 113
    -- upvalues: v10 (ref), map_err_service_reference (copy), service_results (copy)
    if v10 then
        return map_err_service_reference(p6, ...)
    end

    return service_results(pcall(p6, ...))
end

t1.map_err_service = map_err_service

function t1.process_input(p7, p8, p9, p10, p11) -- line: 123
    -- upvalues: t1 (copy)
    local v12 = t1.start_input(p7, p8, p9, p10, p11)

    return t1.finish_input(v12, p7, p8, p9, p10, p11)
end

function t1.start_input(p12, p13, p14, p15, p16) -- line: 130
    -- upvalues: publish_animation_packet (copy), publish_collision_prefix (copy), publish_force_braking (copy), publish_player_flags (copy), copy_into (copy), t1 (copy), v10 (ref), map_err_service (copy)
    if v10 then
        return t1.start_input_reference(p12, p13, p14, p15, p16)
    end

    local state_16 = p13.state.state_16

    p12.manager_1856_counter_320 = t1.native_nonnegative_decrement(p12.manager_1856_counter_320)
    map_err_service(p16.update_pre_input_manager_82d81610, p16, p12, p13)
    p12.manager_1852_flag_256 = 0

    local category_12 = p13.state.category_12

    map_err_service(p16.reset_processed_input_82bf9ef0, p16, p15)
    publish_player_flags(p12, p15)
    p15.actor_query_2948 = map_err_service(p16.actor_query_slot_56, p16)
    p15.actor_query_2952 = map_err_service(p16.actor_query_slot_44, p16)
    publish_force_braking(p12, p13, p14, p15)
    copy_into(p15, "probe_1792", p12.probe)
    map_err_service(p16.reset_player_probe_82d7a330, p16, p12, p13)
    publish_collision_prefix(p12, p13, p15)
    publish_animation_packet(p14, p15)
    p15.state_identifier_2496 = p13.state.identifier_8
    map_err_service(p16.check_teleport_82db88c8, p16, p12, p13, p15)

    return {
        captured_state = state_16,
        captured_category = category_12
    }
end

function t1.start_input_reference(p17, p18, p19, p20, p21) -- line: 156
    -- upvalues: rt (copy), publish_animation_packet (copy), publish_collision_prefix (copy), publish_force_braking (copy), publish_player_flags (copy), t1 (copy), map_err_service (copy)
    local state_16 = p18.state.state_16

    p17.manager_1856_counter_320 = t1.native_nonnegative_decrement(p17.manager_1856_counter_320)
    map_err_service(p21.update_pre_input_manager_82d81610, p21, p17, p18)
    p17.manager_1852_flag_256 = 0

    local category_12 = p18.state.category_12

    map_err_service(p21.reset_processed_input_82bf9ef0, p21, p20)
    publish_player_flags(p17, p20)
    p20.actor_query_2948 = map_err_service(p21.actor_query_slot_56, p21)
    p20.actor_query_2952 = map_err_service(p21.actor_query_slot_44, p21)
    publish_force_braking(p17, p18, p19, p20)
    p20.probe_1792 = rt.copy(p17.probe)
    map_err_service(p21.reset_player_probe_82d7a330, p21, p17, p18)
    publish_collision_prefix(p17, p18, p20)
    publish_animation_packet(p19, p20)
    p20.state_identifier_2496 = p18.state.identifier_8
    map_err_service(p21.check_teleport_82db88c8, p21, p17, p18, p20)

    return {
        captured_state = state_16,
        captured_category = category_12
    }
end

function t1.finish_input(p22, p23, p24, p25, p26, p27) -- line: 179
    -- upvalues: publish_external_physics (copy), publish_line_tests (copy), publish_physical_outputs (copy), publish_state_prefix (copy), replace_byte (copy), select_surface (copy), transfer_bit (copy), effective_animation_transform_into (copy), t1 (copy), v10 (ref), map_err_service (copy)
    if v10 then
        return t1.finish_input_reference(p22, p23, p24, p25, p26, p27)
    end

    local captured_state, captured_category = p22.captured_state, p22.captured_category

    p26.flags_2472 = transfer_bit(p26.flags_2472, 10, p23.flags_1296, 29)
    t1.publish_transition(p25, p26, p27)
    t1.update_signed_ground_time(p23, p24, p26)
    t1.update_time_on_ground(p23, captured_category, p26)

    local surface_default_mode = p24.surface_default_mode
    local ok, result = pcall(select_surface, p23, p25, surface_default_mode, p26)

    if not ok then
        error({
            tag = "InvalidStateVariant",
            result
        }, 0)
    end

    p26.flags_2476 = replace_byte(p26.flags_2476, 2, p25.flag_10370)
    publish_external_physics(p23, p25, p26)
    publish_state_prefix(p23, p24, p25, captured_state, p26)
    publish_physical_outputs(p24, p25, p26)
    t1.update_timers(p23, p24, p26)
    t1.update_ground_position(p23, p24, captured_category, p26, p27)
    effective_animation_transform_into(p26, "effective_anim_transform_192", p24.skeleton.anim_to_world_11920, p26.flags_2476)
    t1.update_ground_history(p23, captured_category, p26)
    t1.publish_ground_history(p23, p26)
    map_err_service(p27.prepare_board_toolkit_82c013f0, p27, p23, p24, p26)
    publish_line_tests(p23, p26)
    map_err_service(p27.process_skeleton_82bd8918, p27, p25, p24, p26)
    t1.publish_post_skeleton(p23, p24, p26)
    map_err_service(p27.update_grind_manager_82d8a828, p27, p23, p24, p26)
end

function t1.finish_input_reference(p28, p29, p30, p31, p32, p33) -- line: 219
    -- upvalues: effective_animation_transform (copy), publish_external_physics (copy), publish_line_tests (copy), publish_physical_outputs (copy), publish_state_prefix (copy), replace_byte (copy), select_surface (copy), transfer_bit (copy), t1 (copy), map_err_service (copy)
    local captured_state, captured_category = p28.captured_state, p28.captured_category

    p32.flags_2472 = transfer_bit(p32.flags_2472, 10, p29.flags_1296, 29)
    t1.publish_transition(p31, p32, p33)
    t1.update_signed_ground_time(p29, p30, p32)
    t1.update_time_on_ground(p29, captured_category, p32)

    local surface_default_mode = p30.surface_default_mode
    local ok, result = pcall(select_surface, p29, p31, surface_default_mode, p32)

    if not ok then
        error({
            tag = "InvalidStateVariant",
            result
        }, 0)
    end

    p32.flags_2476 = replace_byte(p32.flags_2476, 2, p31.flag_10370)
    publish_external_physics(p29, p31, p32)
    publish_state_prefix(p29, p30, p31, captured_state, p32)
    publish_physical_outputs(p30, p31, p32)
    t1.update_timers(p29, p30, p32)
    t1.update_ground_position(p29, p30, captured_category, p32, p33)
    p32.effective_anim_transform_192 = effective_animation_transform(p30.skeleton.anim_to_world_11920, p32.flags_2476)
    t1.update_ground_history(p29, captured_category, p32)
    t1.publish_ground_history(p29, p32)
    map_err_service(p33.prepare_board_toolkit_82c013f0, p33, p29, p30, p32)
    publish_line_tests(p29, p32)
    map_err_service(p33.process_skeleton_82bd8918, p33, p31, p30, p32)
    t1.publish_post_skeleton(p29, p30, p32)
    map_err_service(p33.update_grind_manager_82d8a828, p33, p29, p30, p32)
end

function t1.publish_transition(p34, p35, p36) -- line: 251
    -- upvalues: t1 (copy), map_err_service (copy)
    if not map_err_service(p36.actor_input_available_slot_4, p36) then
        return
    end

    if p34.suppress_transition_10376 ~= 0 then
        p35.transition_2636 = 0

        return
    end

    local v13 = map_err_service(p36.transition_action_825903c8, p36)
    local v14 = t1.xenon_fsel(-1 - v13, -1, v13)

    p35.transition_2636 = t1.xenon_fsel(1 - v14, v14, 1)
end

function t1.update_signed_ground_time(p37, p38, p39) -- line: 264
    -- upvalues: t1 (copy)
    local signed_ground_time_1356 = p37.signed_ground_time_1356

    if p38.state.signed_ground_step_84 == 0 then
        p37.signed_ground_time_1356 = t1.xenon_fsel(signed_ground_time_1356, 0, signed_ground_time_1356) - t1.FIXED_FRAME_STEP
    else
        p37.signed_ground_time_1356 = t1.xenon_fsel(signed_ground_time_1356, signed_ground_time_1356, 0) + t1.FIXED_FRAME_STEP
    end

    p39.signed_ground_time_2756 = p37.signed_ground_time_1356
end

function t1.update_time_on_ground(p40, p41, p42) -- line: 274
    -- upvalues: rt (copy), replace_bool (copy)
    if p41 == 100 then
        p42.flags_2472 = bit32.bor(p42.flags_2472, 8192)
        p40.grounded_frames_1300 = rt.wrapping_add_u32(p40.grounded_frames_1300, 1)
        p40.time_on_ground_1352 += p42.timestep_2604
        p40.flags_1296 = replace_bool(p40.flags_1296, 31, rt.to_i32(p40.grounded_frames_1300) > 6)
    else
        p40.time_on_ground_1352 = 0
        p40.grounded_frames_1300 = 0
    end

    p42.time_on_ground_2752 = p40.time_on_ground_1352
end

function t1.update_timers(p43, p44, p45) -- line: 287
    if p44.state.state_16 == 104 then
        p43.skitch_timer_1376 = 2
        p43.skitch_value_1372 = p44.state.skitch_value_40
    end

    if p43.skitch_timer_1376 > 0 then
        p43.skitch_timer_1376 -= p45.timestep_2604
        p45.skitch_value_2592 = p43.skitch_value_1372
    end

    if p44.ground.scalar_292 > 0 then
        p43.ground_timer_1380 = p44.ground.scalar_292
    end

    if p43.ground_timer_1380 > 0 then
        p43.ground_timer_1380 -= p45.timestep_2604
        p45.ground_timer_2848 = p43.ground_timer_1380
        p45.skitch_value_2592 = p43.skitch_value_1372
    end

    if p44.ground.scalar_296 > 0 then
        p43.secondary_ground_timer_1384 = p44.ground.scalar_296
    end

    if p43.secondary_ground_timer_1384 > 0 then
        p43.secondary_ground_timer_1384 -= p45.timestep_2604
        p45.secondary_ground_timer_2852 = p43.secondary_ground_timer_1384
    end
end

function t1.update_ground_position(p46, p47, p48, p49, p50) -- line: 313
    -- upvalues: copy_into (copy), t1 (copy), v10 (ref), map_err_service (copy)
    if v10 then
        return t1.update_ground_position_reference(p46, p47, p48, p49, p50)
    end

    if p48 == 500 then
        copy_into(p46, "current_ground_position_1216", p47.skeleton.anim_to_world_11920[4])
        p46.time_off_board_1368 += t1.FIXED_FRAME_STEP
    else
        copy_into(p46, "current_ground_position_1216", (map_err_service(p50.calculate_ground_position_82c02840, p50, p47)))
        p46.time_off_board_1368 = 0
    end

    p49.time_off_board_2836 = p46.time_off_board_1368
end

function t1.update_ground_position_reference(p51, p52, p53, p54, p55) -- line: 332
    -- upvalues: rt (copy), t1 (copy), map_err_service (copy)
    if p53 == 500 then
        p51.current_ground_position_1216 = rt.copy(p52.skeleton.anim_to_world_11920[4])
        p51.time_off_board_1368 += t1.FIXED_FRAME_STEP
    else
        p51.current_ground_position_1216 = rt.copy(map_err_service(p55.calculate_ground_position_82c02840, p55, p52))
        p51.time_off_board_1368 = 0
    end

    p54.time_off_board_2836 = p51.time_off_board_1368
end

function t1.update_ground_history(p56, p57, p58) -- line: 348
    -- upvalues: v1 (copy), v9 (copy), copy_into (copy), t1 (copy), v10 (ref), t2 (copy)
    if v10 then
        return t1.update_ground_history_reference(p56, p57, p58)
    end

    if p57 == 200 or p57 == 600 or not (p56.ground_history_frames_1304 > 0) then
        return
    end

    local previous_ground_position_1200, current_ground_position_1216, damped_ground_delta_1248 = p56.previous_ground_position_1200, p56.current_ground_position_1216, p56.damped_ground_delta_1248

    if type(previous_ground_position_1200) ~= "table" or type(current_ground_position_1216) ~= "table" or type(damped_ground_delta_1248) ~= "table" then
        return t1.update_ground_history_reference(p56, p57, p58)
    end

    local v16 = previous_ground_position_1200[1]
    local v17 = previous_ground_position_1200[2]
    local v18 = previous_ground_position_1200[3]
    local v19 = previous_ground_position_1200[4]

    copy_into(p56, "previous_ground_position_1200", current_ground_position_1216)

    if not (p58.frames_since_teleport_2584 > 1) then
        return
    end

    local ground_history_words = v9.ground_history_words
    local v20 = current_ground_position_1216[1]
    local v21 = current_ground_position_1216[2]
    local v22 = current_ground_position_1216[3]
    local v23 = current_ground_position_1216[4]
    local v24 = damped_ground_delta_1248[1]
    local v25 = damped_ground_delta_1248[2]
    local v26 = damped_ground_delta_1248[3]
    local v27 = damped_ground_delta_1248[4]
    local timestep_2604 = p58.timestep_2604
    local v28

    if timestep_2604 == 0 then
        buffer.writef32(v1, 0, timestep_2604)
        v28 = buffer.readu32(v1, 0)
    elseif timestep_2604 > -1.1754943508222875E-38 and timestep_2604 < 1.1754943508222875E-38 then
        local v29 = math.abs(timestep_2604) * 7.1362384635298E+44

        v28 = math.floor(v29)

        local v30 = v29 - v28

        if v30 > 0.5 or v30 == 0.5 and v28 % 2 == 1 then
            v28 += 1
        end

        if timestep_2604 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, timestep_2604)
        v28 = buffer.readu32(v1, 0)
    end

    local v31, v32, v33, v34, v35, v36, v37, v38 = ground_history_words(v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28)

    t2[1] = v31
    t2[2] = v32
    t2[3] = v33
    t2[4] = v34
    copy_into(p56, "ground_delta_1232", t2)
    t2[1] = v35
    t2[2] = v36
    t2[3] = v37
    t2[4] = v38
    copy_into(p56, "damped_ground_delta_1248", t2)
end

function t1.update_ground_history_reference(p59, p60, p61) -- line: 388
    -- upvalues: rt (copy), v1 (copy), v9 (copy)
    local ground_history, t4, v39, v40

    if p60 == 200 or p60 == 600 then
        v40 = true
    elseif p59.ground_history_frames_1304 > 0 then
        local v41 = rt.copy(p59.previous_ground_position_1200)

        p59.previous_ground_position_1200 = rt.copy(p59.current_ground_position_1216)

        if p61.frames_since_teleport_2584 > 1 then
            ground_history = v9.ground_history
            t4 = {
                previous_position = v41,
                current_position = rt.copy(p59.current_ground_position_1216),
                previous_filtered_delta = rt.copy(p59.damped_ground_delta_1248)
            }

            local timestep_2604 = p61.timestep_2604

            if timestep_2604 == 0 then
                buffer.writef32(v1, 0, timestep_2604)
                v39 = buffer.readu32(v1, 0)
            elseif timestep_2604 > -1.1754943508222875E-38 and timestep_2604 < 1.1754943508222875E-38 then
                local v42 = math.abs(timestep_2604) * 7.1362384635298E+44

                v39 = math.floor(v42)

                local v43 = v42 - v39

                if v43 > 0.5 or v43 == 0.5 and v39 % 2 == 1 then
                    v39 += 1
                end

                if timestep_2604 < 0 then
                    v39 += 2147483648
                end
            else
                buffer.writef32(v1, 0, timestep_2604)
                v39 = buffer.readu32(v1, 0)
            end

            v40 = false
        else
            v40 = true
        end
    else
        v40 = true
    end

    if v40 then
        return
    end

    t4.timestep_bits = v39

    local v44 = ground_history(t4)

    p59.ground_delta_1232 = v44.delta
    p59.damped_ground_delta_1248 = v44.filtered_delta
end

function t1.publish_ground_history(p62, p63) -- line: 405
    -- upvalues: copy_into (copy), t1 (copy), v10 (ref)
    if v10 then
        return t1.publish_ground_history_reference(p62, p63)
    end

    local vectors_464_480_496_512_528 = p63.vectors_464_480_496_512_528

    copy_into(vectors_464_480_496_512_528, 2, p62.previous_ground_position_1200)
    copy_into(vectors_464_480_496_512_528, 3, p62.current_ground_position_1216)
    copy_into(vectors_464_480_496_512_528, 4, p62.damped_ground_delta_1248)
end

function t1.publish_ground_history_reference(p64, p65) -- line: 416
    -- upvalues: rt (copy)
    p65.vectors_464_480_496_512_528[2] = rt.copy(p64.previous_ground_position_1200)
    p65.vectors_464_480_496_512_528[3] = rt.copy(p64.current_ground_position_1216)
    p65.vectors_464_480_496_512_528[4] = rt.copy(p64.damped_ground_delta_1248)
end

function t1.publish_post_skeleton(p66, p67, p68) -- line: 422
    -- upvalues: rt (copy), v9 (copy), replace_bool (copy), replace_byte (copy), copy_into (copy), t1 (copy), v10 (ref), t2 (copy)
    if v10 then
        return t1.publish_post_skeleton_reference(p66, p67, p68)
    end

    if bit32.band(p68.flags_2472, 2097152) ~= 0 then
        p68.flags_2472 = replace_byte(p68.flags_2472, 21, p67.state.flag_66)
    end

    local v45 = p66.skitch_timer_1376 > 0 or bit32.band(p68.flags_2476, 4194304) ~= 0 and p67.ground.scalar_276 >= 0

    p68.flags_2476 = replace_bool(p68.flags_2476, 3, v45)

    if bit32.band(p68.flags_2472, 8388608) == 0 then
        p66.time_since_last_input_1348 = 0
    else
        p66.time_since_last_input_1348 += p68.timestep_2604
    end

    p68.time_since_last_input_2748 = p66.time_since_last_input_1348

    if bit32.band(p68.flags_2468, 2097152) == 0 then
        local v46 = p68.vectors_400_416[2]
        local prepared_jump_velocity_1184 = p66.prepared_jump_velocity_1184
        local v47, v48, v49, v50 = v9.prepared_jump_velocity_words(v46[1], v46[2], v46[3], v46[4], prepared_jump_velocity_1184[1], prepared_jump_velocity_1184[2], prepared_jump_velocity_1184[3], prepared_jump_velocity_1184[4])

        t2[1] = v47
        t2[2] = v48
        t2[3] = v49
        t2[4] = v50
        copy_into(p66, "prepared_jump_velocity_1184", t2)
    else
        copy_into(p66, "prepared_jump_velocity_1184", p68.vectors_400_416[2])
    end

    if p68.spin_input_2672 * p66.previous_spin_input_1360 <= 0 then
        p66.spin_same_direction_frames_1324 = 0
    else
        p66.spin_same_direction_frames_1324 = rt.wrapping_add_u32(p66.spin_same_direction_frames_1324, 1)
    end

    p66.previous_spin_input_1360 = p68.spin_input_2672
    p68.spin_same_direction_frames_2580 = p66.spin_same_direction_frames_1324
    copy_into(p68, "prepared_jump_704", p66.prepared_jump_velocity_1184)
    p68.crouch_delta_2780 = p68.crouch_2776 - p66.previous_crouch_1364
    p66.previous_crouch_1364 = p68.crouch_2776
end

function t1.publish_post_skeleton_reference(p69, p70, p71) -- line: 473
    -- upvalues: rt (copy), v9 (copy), replace_bool (copy), replace_byte (copy)
    if bit32.band(p71.flags_2472, 2097152) ~= 0 then
        p71.flags_2472 = replace_byte(p71.flags_2472, 21, p70.state.flag_66)
    end

    local v51 = p69.skitch_timer_1376 > 0 or bit32.band(p71.flags_2476, 4194304) ~= 0 and p70.ground.scalar_276 >= 0

    p71.flags_2476 = replace_bool(p71.flags_2476, 3, v51)

    if bit32.band(p71.flags_2472, 8388608) == 0 then
        p69.time_since_last_input_1348 = 0
    else
        p69.time_since_last_input_1348 += p71.timestep_2604
    end

    p71.time_since_last_input_2748 = p69.time_since_last_input_1348

    if bit32.band(p71.flags_2468, 2097152) == 0 then
        p69.prepared_jump_velocity_1184 = v9.prepared_jump_velocity({
            skateboard_vector = rt.copy(p71.vectors_400_416[2]),
            previous_velocity = rt.copy(p69.prepared_jump_velocity_1184)
        })
    else
        p69.prepared_jump_velocity_1184 = rt.copy(p71.vectors_400_416[2])
    end

    if p71.spin_input_2672 * p69.previous_spin_input_1360 <= 0 then
        p69.spin_same_direction_frames_1324 = 0
    else
        p69.spin_same_direction_frames_1324 = rt.wrapping_add_u32(p69.spin_same_direction_frames_1324, 1)
    end

    p69.previous_spin_input_1360 = p71.spin_input_2672
    p71.spin_same_direction_frames_2580 = p69.spin_same_direction_frames_1324
    p71.prepared_jump_704 = rt.copy(p69.prepared_jump_velocity_1184)
    p71.crouch_delta_2780 = p71.crouch_2776 - p69.previous_crouch_1364
    p69.previous_crouch_1364 = p71.crouch_2776
end

function t1.native_nonnegative_decrement(p72) -- line: 508
    -- upvalues: rt (copy)
    local v52 = rt.wrapping_sub_u32(p72, 1)

    if v52 + 2147483648 > 4294967295 then
        return 0
    end

    return v52
end

function t1.xenon_fsel(p73, p74, p75) -- line: 518
    if p73 >= -0 then
        return p74
    end

    return p75
end

return t1
