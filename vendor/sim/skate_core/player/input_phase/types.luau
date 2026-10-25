-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/input_phase/air_output")
local v2 = import("skate_core/player/input_phase/pose_output")
local v3 = import("skate_core/player/input_phase/grind_output")
local v4 = import("skate_core/player/input_phase/grind_input")
local AirOutputFields = v1.AirOutputFields
local AnimationOutputFields, ScoringOutputFields, SkeletonOutputFields = v2.AnimationOutputFields, v2.ScoringOutputFields, v2.SkeletonOutputFields
local GrindOutputFields = v3.GrindOutputFields
local GrindInvestigationFields = v4.GrindInvestigationFields
local t1 = {}
local copy = rt.copy

local function assign_into(p1, p2) -- line: 34
    -- upvalues: copy (copy), assign_into (copy)
    for v5 in p1 do
        if p2[v5] == nil then
            p1[v5] = nil
        end
    end

    for v6, v7 in p2 do
        if type(v7) == "table" then
            local v8 = p1[v6]

            if type(v8) == "table" then
                assign_into(v8, v7)
            else
                p1[v6] = copy(v7)
            end
        else
            p1[v6] = v7
        end
    end
end

t1.assign_into = assign_into

function t1.copy_into(p3, p4, p5) -- line: 67
    -- upvalues: copy (copy), assign_into (copy)
    local v9 = p3[p4]

    if type(p5) ~= "table" or type(v9) ~= "table" or v9 == p5 then
        p3[p4] = copy(p5)

        return
    end

    if #v9 == 4 and #p5 == 4 then
        local v10 = p5[1]

        if type(v10) == "number" then
            local v11 = p5[2]
            local v12 = p5[3]
            local v13 = p5[4]

            v9[1] = v10
            v9[2] = v11
            v9[3] = v12
            v9[4] = v13

            return
        end
    end

    assign_into(v9, p5)
end

local v14 = false

function t1.set_general(p6) -- line: 87
    -- upvalues: v14 (ref)
    v14 = p6
end

function t1.general() -- line: 90
    -- upvalues: v14 (ref)
    return v14
end

t1.freeze_deep = (function()
    local freeze_deep

    function freeze_deep(p7) -- line: 96
        -- upvalues: freeze_deep (ref)
        if type(p7) ~= "table" or table.isfrozen(p7) then
            return p7
        end

        for _, v15 in p7 do
            freeze_deep(v15)
        end

        table.freeze(p7)

        return p7
    end

    return freeze_deep
end)()
t1.RawVector = {}
t1.RawMatrix = {}
t1.ProbeFields = {}

function t1.ProbeFields.default() -- line: 113
    -- upvalues: rt (copy)
    return {
        byte_104 = 0,
        vectors_16_32_48 = rt.filled(3, table.create(4, 0)),
        words_64_68 = table.create(2, 0),
        bytes_72_73 = table.create(2, 0),
        vector_80 = table.create(4, 0),
        words_96_100 = table.create(2, 0)
    }
end

t1.LineTestFields = {}

function t1.LineTestFields.default() -- line: 125
    return {
        surface = 0,
        valid = 0,
        position = table.create(4, 0),
        normal = table.create(4, 0)
    }
end

t1.StateVariantFields = {}

function t1.StateVariantFields.default() -- line: 136
    return {
        surface_override_enabled_60 = 0
    }
end

t1.CurrentStateFields = {}

function t1.CurrentStateFields.default() -- line: 146
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
        signed_ground_step_84 = 0
    }
end

t1.SkateboardMotionFields = {}

function t1.SkateboardMotionFields.default() -- line: 164
    return {
        scalar_160 = 0,
        scalar_164 = 0,
        scalar_168 = 0,
        scalar_172 = 0,
        vector_64 = table.create(4, 0),
        vector_80 = table.create(4, 0),
        vector_96 = table.create(4, 0),
        vector_128 = table.create(4, 0),
        vector_144 = table.create(4, 0)
    }
end

t1.SystemReckoningFields = {}

function t1.SystemReckoningFields.default() -- line: 179
    return {
        flag_164 = 0,
        vector_16 = table.create(4, 0),
        vector_64 = table.create(4, 0),
        vector_96 = table.create(4, 0),
        vector_144 = table.create(4, 0)
    }
end

t1.GroundOutputFields = {}

function t1.GroundOutputFields.default() -- line: 192
    return {
        landing_half_turns_312 = 0,
        hippy_jumping_322 = 0,
        hippy_takeoff_323 = 0,
        flag_273 = 0,
        scalar_276 = 0,
        scalar_292 = 0,
        scalar_296 = 0,
        flag_317 = 0,
        flag_318 = 0,
        vector_64 = table.create(4, 0),
        vector_80 = table.create(4, 0),
        vector_96 = table.create(4, 0),
        vector_128 = table.create(4, 0)
    }
end

t1.CollisionOutputFields = {}

function t1.CollisionOutputFields.default() -- line: 215
    return {
        wheel_count_0 = 0,
        scalar_28 = 0,
        flag_215 = 0,
        flag_216 = 0,
        flag_3472 = 0,
        flag_3475 = 0,
        flag_3477 = 0,
        flag_3478 = 0,
        flag_3479 = 0,
        flag_3480 = 0,
        flag_3481 = 0,
        flag_3482 = 0,
        flag_3483 = 0,
        vector_48 = table.create(4, 0),
        predicted_position_64 = table.create(4, 0),
        wheel_contact_3296_3299 = table.create(4, 0)
    }
end

t1.PhysicsOutputFields = {}

function t1.PhysicsOutputFields.default() -- line: 239
    return {
        flag_32 = 0,
        vector_16 = table.create(4, 0)
    }
end

t1.OffBoardOutputFields = {}

function t1.OffBoardOutputFields.default() -- line: 248
    return {
        kind_88 = 0,
        scalar_112 = 0,
        distance_116 = 0,
        flags_306_307 = table.create(2, 0),
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
        vector_64 = table.create(4, 0),
        scalar_92 = 0,
        vector_96 = table.create(4, 0),
        word_144 = 0,
        scalar_148 = 0,
        scalar_152 = 0,
        scalar_156 = 0,
        vector_160 = table.create(4, 0),
        vector_176 = table.create(4, 0),
        vector_192 = table.create(4, 0),
        vector_208 = table.create(4, 0),
        vector_224 = table.create(4, 0),
        vector_240 = table.create(4, 0),
        flag_320 = 0
    }
end

t1.PhysicalPlayerInput = {}

function t1.PhysicalPlayerInput.default() -- line: 311
    -- upvalues: AirOutputFields (copy), AnimationOutputFields (copy), ScoringOutputFields (copy), SkeletonOutputFields (copy), GrindOutputFields (copy), t1 (copy)
    return {
        teleport_output = nil,
        filtered_state_0 = 0,
        surface_default_mode = 0,
        component_1832_word_1876 = 0,
        board_reckoning_side_176 = table.create(4, 0),
        skateboard = t1.SkateboardMotionFields.default(),
        air = AirOutputFields.default(),
        physics = t1.PhysicsOutputFields.default(),
        grinds = GrindOutputFields.default(),
        skeleton = SkeletonOutputFields.default(),
        animation = AnimationOutputFields.default(),
        scoring = ScoringOutputFields.default(),
        collision = t1.CollisionOutputFields.default(),
        state = t1.CurrentStateFields.default(),
        ground = t1.GroundOutputFields.default(),
        reckoning = t1.SystemReckoningFields.default(),
        off_board = t1.OffBoardOutputFields.default()
    }
end

t1.AnimationInputPacket = {}
t1.NativeReferenceBase = {}
t1.NativeRelativeReference = {}
t1.PlayerInputState = {}

function t1.PlayerInputState.default() -- line: 353
    -- upvalues: rt (copy), t1 (copy)
    return {
        manager_1856_counter_320 = 0,
        manager_1852_flag_256 = 0,
        manager_1852_vector_176 = table.create(4, 0),
        flags_1296 = 0,
        grounded_frames_1300 = 0,
        state_count_1312 = 0,
        update_count_1316 = 0,
        spin_same_direction_frames_1324 = 0,
        frames_since_teleport_1328 = 0,
        dismount_request_frames_1332 = 0,
        state_value_1336 = 0,
        state_timer_1344 = 0,
        time_since_last_input_1348 = 0,
        time_on_ground_1352 = 0,
        signed_ground_time_1356 = 0,
        previous_spin_input_1360 = 0,
        previous_crouch_1364 = 0,
        time_off_board_1368 = 0,
        skitch_value_1372 = 0,
        skitch_timer_1376 = 0,
        ground_timer_1380 = 0,
        secondary_ground_timer_1384 = 0,
        probe = t1.ProbeFields.default(),
        queued_vector_1280 = table.create(4, 0),
        external_physics_cache_1008 = t1.empty_external_physics(),
        prepared_jump_velocity_1184 = table.create(4, 0),
        previous_ground_position_1200 = table.create(4, 0),
        current_ground_position_1216 = table.create(4, 0),
        ground_delta_1232 = table.create(4, 0),
        damped_ground_delta_1248 = table.create(4, 0),
        state_variants_1408 = rt.filled(5, t1.StateVariantFields.default()),
        hips_line_test_1488 = t1.LineTestFields.default(),
        left_line_test_1536 = t1.LineTestFields.default(),
        right_line_test_1584 = t1.LineTestFields.default(),
        ground_history_frames_1304 = 0
    }
end

t1.ProcessedPhysicsInput = {}
t1.ProcessedPhysicsSnapshot = {}

function t1.ProcessedPhysicsSnapshot.new(p8, p9) -- line: 400
    -- upvalues: rt (copy)
    return {
        tick = p8,
        input = rt.copy(p9)
    }
end

function t1.ProcessedPhysicsInput.default_reference() -- line: 405
    -- upvalues: rt (copy), GrindInvestigationFields (copy), t1 (copy)
    return {
        effective_anim_transform_192 = rt.filled(4, table.create(4, 0)),
        vectors_400_416 = rt.filled(2, table.create(4, 0)),
        vectors_464_480_496_512_528 = rt.filled(5, table.create(4, 0)),
        vectors_544_560_592_608 = rt.filled(4, table.create(4, 0)),
        vectors_624_640_656_672 = rt.filled(4, table.create(4, 0)),
        prepared_jump_704 = table.create(4, 0),
        collision_pose_error_736 = table.create(4, 0),
        animation_com_to_deck_752 = table.create(4, 0),
        animation_com_to_deck_delta_768 = table.create(4, 0),
        vectors_720_784_800_816_832_864 = rt.filled(6, table.create(4, 0)),
        vectors_880_896_912_928_944 = rt.filled(5, table.create(4, 0)),
        line_tests_960_1008_1056 = rt.filled(3, t1.LineTestFields.default()),
        grind = GrindInvestigationFields.default(),
        vector_1520 = table.create(4, 0),
        matrix_1536 = rt.filled(4, table.create(4, 0)),
        byte_1600 = 0,
        external_physics_1616 = t1.empty_external_physics(),
        probe_1792 = t1.ProbeFields.default(),
        grab_records_1888_2176 = rt.filled(2, table.create(72, 0)),
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
        grind_words_2532_2536 = table.create(2, 0),
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
        timestep_2604 = 0,
        scalar_2612 = 0,
        scalar_2616 = 0,
        transition_2636 = 0,
        grind_adjusted_body_spin_2644 = 0,
        gravity_2648 = 0,
        scalar_2652 = 0,
        scalar_2656 = 0,
        state_timer_2664 = 0,
        scalar_2668 = 0,
        spin_input_2672 = 0,
        scalar_2696 = 0,
        scalar_2700 = 0,
        scalar_2736 = 0,
        time_since_last_input_2748 = 0,
        time_on_ground_2752 = 0,
        signed_ground_time_2756 = 0,
        truck_tightness_2760 = 0,
        scalar_2764 = 0,
        board_at_y_delta_2768 = 0,
        air_scalar_2772 = 0,
        crouch_2776 = 0,
        crouch_delta_2780 = 0,
        off_board_scalar_2832 = 0,
        time_off_board_2836 = 0,
        ground_timer_2848 = 0,
        secondary_ground_timer_2852 = 0,
        collision_scalar_2924 = 0,
        actor_query_2948 = 0,
        actor_query_2952 = 0
    }
end

function t1.ProcessedPhysicsInput.default() -- line: 503
    -- upvalues: GrindInvestigationFields (copy), t1 (copy)
    return {
        effective_anim_transform_192 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        vectors_400_416 = {
            table.create(4, 0),
            table.create(4, 0)
        },
        vectors_464_480_496_512_528 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        vectors_544_560_592_608 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        vectors_624_640_656_672 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        prepared_jump_704 = table.create(4, 0),
        collision_pose_error_736 = table.create(4, 0),
        animation_com_to_deck_752 = table.create(4, 0),
        animation_com_to_deck_delta_768 = table.create(4, 0),
        vectors_720_784_800_816_832_864 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        vectors_880_896_912_928_944 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        line_tests_960_1008_1056 = {
            t1.LineTestFields.default(),
            t1.LineTestFields.default(),
            t1.LineTestFields.default()
        },
        grind = GrindInvestigationFields.default(),
        vector_1520 = table.create(4, 0),
        matrix_1536 = {
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0),
            table.create(4, 0)
        },
        byte_1600 = 0,
        external_physics_1616 = t1.empty_external_physics(),
        probe_1792 = t1.ProbeFields.default(),
        grab_records_1888_2176 = {
            table.create(72, 0),
            table.create(72, 0)
        },
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
        grind_words_2532_2536 = table.create(2, 0),
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
        timestep_2604 = 0,
        scalar_2612 = 0,
        scalar_2616 = 0,
        transition_2636 = 0,
        grind_adjusted_body_spin_2644 = 0,
        gravity_2648 = 0,
        scalar_2652 = 0,
        scalar_2656 = 0,
        state_timer_2664 = 0,
        scalar_2668 = 0,
        spin_input_2672 = 0,
        scalar_2696 = 0,
        scalar_2700 = 0,
        scalar_2736 = 0,
        time_since_last_input_2748 = 0,
        time_on_ground_2752 = 0,
        signed_ground_time_2756 = 0,
        truck_tightness_2760 = 0,
        scalar_2764 = 0,
        board_at_y_delta_2768 = 0,
        air_scalar_2772 = 0,
        crouch_2776 = 0,
        crouch_delta_2780 = 0,
        off_board_scalar_2832 = 0,
        time_off_board_2836 = 0,
        ground_timer_2848 = 0,
        secondary_ground_timer_2852 = 0,
        collision_scalar_2924 = 0,
        actor_query_2948 = 0,
        actor_query_2952 = 0
    }
end

function t1.empty_external_physics() -- line: 599
    -- upvalues: rt (copy)
    return {
        flags = 0,
        vectors = rt.filled(10, table.create(4, 0))
    }
end

return t1
