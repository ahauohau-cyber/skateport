-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/player/post_input")
local run_post_input, copy_grab_record_82762ab0 = v2.run_post_input, v2.copy_grab_record_82762ab0
local Requests = import("skate_core/player/wipeout").Requests
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector

local function player_input_grind() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind")
end

local function grind_host() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_host")
end

local function air_trajectory() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function air_phase() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function grab_runtime() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground/grab_runtime")
end

local function riding_outputs() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function solve() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function grind() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {}

local function map_from_bits(p2) -- line: 53
    -- upvalues: v1 (copy)
    local v3 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v3[i] = buffer.readf32(v1, 0)
    end

    return v3
end

t1.PostInputState = {}

function t1.PostInputState.new() -- line: 66
    return {
        jump_fix_frames = 1000,
        latch_frames = 0,
        state_frames = 100,
        heading_adjust = 0,
        complete = false,
        trajectory_pending = false,
        trajectory_valid = false,
        trajectory_available = false,
        trajectory_new_candidate = false,
        jump_reference = { 0, 0, 0, 0 }
    }
end

t1.Services = {}

function t1.Services.update_grind_manager_82d8ab08(p3) -- line: 96
    -- upvalues: rt (copy), import (copy)
    local pending = p3.pending

    p3.pending = nil

    if pending ~= nil then
        local LiveHost = import("skate_game/physics/grind_host").LiveHost
        local host = p3.host
        local t2 = {
            apply_material_mode = function(_, p5) -- apply_material_mode | line: 107
                -- upvalues: LiveHost (copy), host (copy)
                return LiveHost.apply_material_mode(host, p5)
            end,
            surface_probe = function(_, p7, p8, p9, p10) -- surface_probe | line: 110
                -- upvalues: LiveHost (copy), host (copy)
                return LiveHost.surface_probe(host, p7, p8, p9, p10)
            end,
            force_exit_line = function(_, p12, p13, p14) -- force_exit_line | line: 113
                -- upvalues: LiveHost (copy), host (copy)
                return LiveHost.force_exit_line(host, p12, p13, p14)
            end
        }
        local post_update = import("skate_game/physics/player_input/grind").GrindInputState.post_update
        local grind, processed, world = p3.grind, p3.processed, p3.world
        local v5 = rt.copy(p3.grind_context)
        local ok, result = pcall(post_update, grind, processed, world, pending, v5, t2)

        if ok then
            p3.result = result
        else
            p3.error = result
        end
    else
        p3.error = "Grind post-input requires this tick's pre-input queries"
    end
end

function t1.Services.update_trajectory_selector_82d68800(p15) -- line: 133
    -- upvalues: rt (copy), import (copy)
    local v6 = rt.copy(p15.trajectory_input)

    v6.flags_2476 = p15.processed.flags_2476

    local v7 = import("skate_game/physics/air_trajectory").GrindContext.from_processed(p15.processed, rt.copy(p15.trajectory_board_position))
    local update = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.update
    local trajectory, world = p15.trajectory, p15.world
    local ok, result = pcall(update, trajectory, v6, world, v7)

    if ok then
        if result then
            return 1
        end
    else
        p15.error = result
    end

    return 0
end

function t1.Services.calculate_scalar_2740_82db5e10(p16) -- line: 150
    return p16.heading
end

function t1.Services.register_candidate_82762ab0(p17, p18) -- line: 154
    -- upvalues: copy_grab_record_82762ab0 (copy)
    local v8 = if p18 == "First1888" then 0 else 1
    local v9 = p17.grab_records[v8 + 1]

    if v9 ~= nil then
        copy_grab_record_82762ab0(p17.processed.grab_records_1888_2176[v8 + 1], v9[1])
    else
        p17.error = "Grab publication requested without a completed record"
    end
end

function t1.advance_reference(p19, p20) -- line: 172
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), run_post_input (copy), Requests (copy), TrajectorySelector (copy), t1 (copy)
    local v10 = import("skate_game/physics/air_phase").selector_input(p19, p20)
    local toolkit = p20.player_input.toolkit

    if toolkit == nil then
        error("Post-input trajectory requires this tick's board toolkit", 0)
    end

    local v11 = rt.copy(toolkit.deck[4])
    local post = p20.player_state.post
    local processed = p20.player_input.processed
    local v12 = import("skate_game/physics/biped_ground/grab_runtime").Owner.publish(p20.offboard_grab)
    local v13 = if v12.object == nil then nil else v12.object[1]
    local t3 = {
        first_object_present_196 = v12.records[1] ~= nil,
        first_pending_288 = v12.records[1] ~= nil,
        second_object_present_500 = v12.records[2] ~= nil,
        second_pending_592 = v12.records[2] ~= nil,
        staged_word_12768 = if v13 == nil then processed.object_2464 else v13,
        staged_valid_12772 = v13 == nil and 0 or 1,
        staged_latched_12776 = p20.offboard_grab.interactable_latched and 1 or 0,
        staged_pending_12780 = v12.object ~= nil
    }
    local t4 = {
        jump_reference_1264 = rt.copy(post.jump_reference),
        flags_1296 = p20.player_input.player.flags_1296,
        state_frames_1304 = rt.to_u32(p20.player_input.player.ground_history_frames_1304),
        jump_fix_frames_1308 = post.jump_fix_frames,
        latch_frames_1320 = post.latch_frames
    }
    local t5 = {
        jump_reference_848 = rt.copy(post.jump_reference),
        word_2464 = processed.object_2464,
        flags_2468 = processed.flags_2468,
        flags_2472 = processed.flags_2472,
        flags_2480 = processed.flags_2480,
        flags_2484 = processed.flags_2484,
        current_state_2508 = processed.state_2508,
        state_frames_2572 = post.state_frames,
        jump_fix_frames_2576 = post.jump_fix_frames,
        scalar_2740 = post.heading_adjust
    }
    local ground_output = p20.player_state.ground_output
    local t6 = {
        reset_state_frames_316 = ground_output ~= nil and ground_output.ground_32.wall_ride_exit,
        capture_jump_reference_442 = p20.player_input.physical.air.launched_442 ~= 0,
        jump_reference_128 = rt.copy(p20.player_input.physical.air.launch_velocity_128),
        complete_76 = post.complete
    }
    local update_input_heading = import("skate_game/physics/riding_outputs").RidingOutputs.update_input_heading
    local riding = p19.riding

    buffer.writeu32(v1, 0, processed.vectors_464_480_496_512_528[1][2])

    local v15 = update_input_heading(riding, buffer.readf32(v1, 0), processed.scalar_2612)
    local pending_grind = p20.player_input.pending_grind

    p20.player_input.pending_grind = nil

    local t7 = {
        result = nil,
        error = nil,
        heading = v15,
        grind = p20.player_input.grind,
        pending = pending_grind,
        grind_context = {
            board = import("skate_game/physics/solve").deck_frame(p19.board),
            balance_2720 = p20.animation_input.fields.balance,
            translation_2796 = p20.animation_input.extra.grind_translation,
            stability_nudge_2800 = p20.animation_input.extra.grind_stability_nudge,
            up_down_2804 = p20.animation_input.extra.grind_up_down,
            grab_min_height_2808 = p20.animation_input.extra.grind_grab_min_height
        },
        host = {
            board = p19.board,
            settings = p19.settings,
            materials = p19.grind_materials
        },
        processed = processed,
        trajectory = p20.trajectory,
        trajectory_input = v10,
        trajectory_board_position = v11,
        world = p19.world,
        grab_records = v12.records
    }

    run_post_input({
        player = t4,
        processed = t5,
        phys_out = t6,
        candidates = t3
    }, {
        update_grind_manager_82d8ab08 = function(_) -- update_grind_manager_82d8ab08 | line: 261
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Services.update_grind_manager_82d8ab08(t7)
        end,
        update_trajectory_selector_82d68800 = function(_) -- update_trajectory_selector_82d68800 | line: 264
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Services.update_trajectory_selector_82d68800(t7)
        end,
        calculate_scalar_2740_82db5e10 = function(_) -- calculate_scalar_2740_82db5e10 | line: 267
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Services.calculate_scalar_2740_82db5e10(t7)
        end,
        register_candidate_82762ab0 = function(_, p25) -- register_candidate_82762ab0 | line: 270
            -- upvalues: t7 (copy), t1 (copy)
            return t1.Services.register_candidate_82762ab0(t7, p25)
        end
    })

    local _error = t7.error

    t7.error = nil

    if _error ~= nil then
        error(_error, 0)
    end

    local result = t7.result

    t7.result = nil

    if result == nil then
        error("Grind post-input did not publish its result", 0)
    end

    t5.flags_2468 = bit32.bor(t5.flags_2468, (bit32.band(t7.processed.flags_2468, 262144)))

    for _, v17 in result.wipeout_reasons do
        Requests.request(p20.wipeout.state, v17, 0)
    end

    import("skate_game/physics/grind").Runtime.observe(p20.grind, rt.copy(result.observation))
    p20.player_input.grind_observation = rt.copy(result.observation)

    local v18 = rt.copy(processed.grind)

    if bit32.band(v18.flags_1516, 134217728) == 0 then
        p20.ground_lifecycle.edge = nil
    else
        local function xyz(p26) -- line: 299
            -- upvalues: v1 (copy), Vector3 (copy)
            local new = Vector3.new

            buffer.writeu32(v1, 0, p26[1])

            local v20 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, p26[2])

            local v22 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, p26[3])

            return new(v20, v22, (buffer.readf32(v1, 0)))
        end

        local ground_lifecycle = p20.ground_lifecycle
        local t9 = {
            flags = v18.flags_1516
        }
        local vector_1232 = v18.vector_1232
        local v24 = table.create(#vector_1232)

        for i = 1, #vector_1232 do
            buffer.writeu32(v1, 0, vector_1232[i])
            v24[i] = buffer.readf32(v1, 0)
        end

        t9.point = v24

        local second_start_1312 = v18.second_start_1312
        local new = Vector3.new

        buffer.writeu32(v1, 0, second_start_1312[1])

        local v27 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_start_1312[2])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_start_1312[3])
        t9.start = new(v27, v29, (buffer.readf32(v1, 0)))

        local second_end_1328 = v18.second_end_1328
        local new2 = Vector3.new

        buffer.writeu32(v1, 0, second_end_1328[1])

        local v32 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_end_1328[2])

        local v34 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_end_1328[3])
        t9["end"] = new2(v32, v34, (buffer.readf32(v1, 0)))
        ground_lifecycle.edge = t9
    end

    post.trajectory_pending = TrajectorySelector.pending(p20.trajectory.selector)
    post.trajectory_valid = TrajectorySelector.valid(p20.trajectory.selector)
    post.trajectory_available = TrajectorySelector.valid(p20.trajectory.selector)
    post.trajectory_new_candidate = TrajectorySelector.just_changed(p20.trajectory.selector)
    p20.player_input.player.flags_1296 = t4.flags_1296
    p20.player_input.player.ground_history_frames_1304 = rt.to_i32(t4.state_frames_1304)
    processed.flags_2468 = t5.flags_2468
    processed.flags_2472 = t5.flags_2472
    processed.flags_2480 = t5.flags_2480
    processed.flags_2484 = t5.flags_2484
    processed.object_2464 = t5.word_2464
    post.jump_reference = rt.copy(t4.jump_reference_1264)
    post.jump_fix_frames = t4.jump_fix_frames_1308
    post.latch_frames = t4.latch_frames_1320
    post.state_frames = t5.state_frames_2572
    post.heading_adjust = t5.scalar_2740
    post.complete = t6.complete_76
end

local v36 = false

function t1.set_reference(p27) -- line: 373
    -- upvalues: v36 (ref)
    v36 = p27
end

local function fast_update_grind_manager(p28) -- line: 377
    -- upvalues: import (copy)
    local pending = p28.pending

    p28.pending = nil

    if pending ~= nil then
        local post_update = import("skate_game/physics/player_input/grind").GrindInputState.post_update
        local grind, processed, world, grind_context = p28.grind, p28.processed, p28.world, p28.grind_context
        local host = p28.host
        local ok, result = pcall(post_update, grind, processed, world, pending, grind_context, host)

        if ok then
            p28.result = result
        else
            p28.error = result
        end
    else
        p28.error = "Grind post-input requires this tick's pre-input queries"
    end
end

local function fast_update_trajectory_selector(p29) -- line: 400
    -- upvalues: rt (copy), import (copy)
    local trajectory_input = p29.trajectory_input

    trajectory_input.flags_2476 = p29.processed.flags_2476
    trajectory_input.grind_lock_distance = rt.copy(trajectory_input.grind_lock_distance)

    local v37 = import("skate_game/physics/air_trajectory").GrindContext.from_processed(p29.processed, p29.trajectory_board_position)
    local update = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.update
    local trajectory, world = p29.trajectory, p29.world
    local ok, result = pcall(update, trajectory, trajectory_input, world, v37)

    if ok then
        if result then
            return 1
        end
    else
        p29.error = result
    end

    return 0
end

local v38

local function new_pool() -- line: 420
    -- upvalues: import (copy), t1 (copy), fast_update_grind_manager (copy), fast_update_trajectory_selector (copy)
    local LiveHost = import("skate_game/physics/grind_host").LiveHost
    local t10 = {}
    local t11 = {}
    local t12 = {}
    local t13 = {}

    return {
        player = t10,
        processed = t11,
        output = t12,
        candidates = t13,
        context = {
            player = t10,
            processed = t11,
            phys_out = t12,
            candidates = t13
        },
        services = {
            update_grind_manager_82d8ab08 = fast_update_grind_manager,
            update_trajectory_selector_82d68800 = fast_update_trajectory_selector,
            calculate_scalar_2740_82db5e10 = t1.Services.calculate_scalar_2740_82db5e10,
            register_candidate_82762ab0 = t1.Services.register_candidate_82762ab0,
            grind_context = {},
            host = {
                apply_material_mode = LiveHost.apply_material_mode,
                surface_probe = LiveHost.surface_probe,
                force_exit_line = LiveHost.force_exit_line
            }
        }
    }
end

local function edge_xyz(p30) -- line: 449
    -- upvalues: v1 (copy), Vector3 (copy)
    local new = Vector3.new

    buffer.writeu32(v1, 0, p30[1])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p30[2])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p30[3])

    return new(v40, v42, (buffer.readf32(v1, 0)))
end

function t1.advance(p31, p32) -- line: 454
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), run_post_input (copy), Requests (copy), TrajectorySelector (copy), t1 (copy), v36 (ref), v38 (ref), new_pool (copy)
    if v36 then
        return t1.advance_reference(p31, p32)
    end

    local v44 = import("skate_game/physics/air_phase").selector_input(p31, p32)
    local toolkit = p32.player_input.toolkit

    if toolkit == nil then
        error("Post-input trajectory requires this tick's board toolkit", 0)
    end

    local v45 = rt.copy(toolkit.deck[4])
    local post = p32.player_state.post
    local processed = p32.player_input.processed
    local v46 = import("skate_game/physics/biped_ground/grab_runtime").Owner.publish(p32.offboard_grab)
    local v47 = if v46.object == nil then nil else v46.object[1]
    local v48 = v38

    v38 = nil

    if v48 == nil then
        v48 = new_pool()
    end

    local candidates = v48.candidates

    candidates.first_object_present_196 = v46.records[1] ~= nil
    candidates.first_pending_288 = v46.records[1] ~= nil
    candidates.second_object_present_500 = v46.records[2] ~= nil
    candidates.second_pending_592 = v46.records[2] ~= nil

    if v47 ~= nil then
        candidates.staged_word_12768 = v47
    else
        candidates.staged_word_12768 = processed.object_2464
    end

    candidates.staged_valid_12772 = v47 == nil and 0 or 1
    candidates.staged_latched_12776 = p32.offboard_grab.interactable_latched and 1 or 0
    candidates.staged_pending_12780 = v46.object ~= nil

    local jump_reference = post.jump_reference
    local player = v48.player

    player.jump_reference_1264 = jump_reference
    player.flags_1296 = p32.player_input.player.flags_1296
    player.state_frames_1304 = rt.to_u32(p32.player_input.player.ground_history_frames_1304)
    player.jump_fix_frames_1308 = post.jump_fix_frames
    player.latch_frames_1320 = post.latch_frames

    local processed2 = v48.processed

    processed2.jump_reference_848 = jump_reference
    processed2.word_2464 = processed.object_2464
    processed2.flags_2468 = processed.flags_2468
    processed2.flags_2472 = processed.flags_2472
    processed2.flags_2480 = processed.flags_2480
    processed2.flags_2484 = processed.flags_2484
    processed2.current_state_2508 = processed.state_2508
    processed2.state_frames_2572 = post.state_frames
    processed2.jump_fix_frames_2576 = post.jump_fix_frames
    processed2.scalar_2740 = post.heading_adjust

    local ground_output = p32.player_state.ground_output
    local output = v48.output

    if ground_output ~= nil then
        output.reset_state_frames_316 = ground_output.ground_32.wall_ride_exit
    else
        output.reset_state_frames_316 = false
    end

    output.capture_jump_reference_442 = p32.player_input.physical.air.launched_442 ~= 0
    output.jump_reference_128 = p32.player_input.physical.air.launch_velocity_128
    output.complete_76 = post.complete

    local update_input_heading = import("skate_game/physics/riding_outputs").RidingOutputs.update_input_heading
    local riding = p31.riding

    buffer.writeu32(v1, 0, processed.vectors_464_480_496_512_528[1][2])

    local v50 = update_input_heading(riding, buffer.readf32(v1, 0), processed.scalar_2612)
    local pending_grind = p32.player_input.pending_grind

    p32.player_input.pending_grind = nil

    local services = v48.services

    services.heading = v50
    services.grind = p32.player_input.grind
    services.pending = pending_grind

    local grind_context = services.grind_context

    grind_context.board = import("skate_game/physics/solve").deck_frame_into(p31.board, grind_context.board)
    grind_context.balance_2720 = p32.animation_input.fields.balance
    grind_context.translation_2796 = p32.animation_input.extra.grind_translation
    grind_context.stability_nudge_2800 = p32.animation_input.extra.grind_stability_nudge
    grind_context.up_down_2804 = p32.animation_input.extra.grind_up_down
    grind_context.grab_min_height_2808 = p32.animation_input.extra.grind_grab_min_height

    local host = services.host

    host.board = p31.board
    host.settings = p31.settings
    host.materials = p31.grind_materials
    services.result = nil
    services.processed = processed
    services.trajectory = p32.trajectory
    services.trajectory_input = v44
    services.trajectory_board_position = v45
    services.world = p31.world
    services.grab_records = v46.records
    services.error = nil
    run_post_input(v48.context, services)

    local _error = services.error

    services.error = nil

    if _error ~= nil then
        error(_error, 0)
    end

    local result = services.result

    services.result = nil

    if result == nil then
        error("Grind post-input did not publish its result", 0)
    end

    processed2.flags_2468 = bit32.bor(processed2.flags_2468, (bit32.band(services.processed.flags_2468, 262144)))

    for _, v52 in result.wipeout_reasons do
        Requests.request(p32.wipeout.state, v52, 0)
    end

    local observation = result.observation

    import("skate_game/physics/grind").Runtime.observe(p32.grind, rt.copy(observation))
    p32.player_input.grind_observation = observation

    local grind = processed.grind

    if bit32.band(grind.flags_1516, 134217728) == 0 then
        p32.ground_lifecycle.edge = nil
    else
        local ground_lifecycle = p32.ground_lifecycle
        local t14 = {
            flags = grind.flags_1516
        }
        local vector_1232 = grind.vector_1232
        local v53 = table.create(#vector_1232)

        for i = 1, #vector_1232 do
            buffer.writeu32(v1, 0, vector_1232[i])
            v53[i] = buffer.readf32(v1, 0)
        end

        t14.point = v53

        local second_start_1312 = grind.second_start_1312
        local new = Vector3.new

        buffer.writeu32(v1, 0, second_start_1312[1])

        local v56 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_start_1312[2])

        local v58 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_start_1312[3])
        t14.start = new(v56, v58, (buffer.readf32(v1, 0)))

        local second_end_1328 = grind.second_end_1328
        local new2 = Vector3.new

        buffer.writeu32(v1, 0, second_end_1328[1])

        local v61 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_end_1328[2])

        local v63 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, second_end_1328[3])
        t14["end"] = new2(v61, v63, (buffer.readf32(v1, 0)))
        ground_lifecycle.edge = t14
    end

    post.trajectory_pending = TrajectorySelector.pending(p32.trajectory.selector)
    post.trajectory_valid = TrajectorySelector.valid(p32.trajectory.selector)
    post.trajectory_available = TrajectorySelector.valid(p32.trajectory.selector)
    post.trajectory_new_candidate = TrajectorySelector.just_changed(p32.trajectory.selector)
    p32.player_input.player.flags_1296 = player.flags_1296
    p32.player_input.player.ground_history_frames_1304 = rt.to_i32(player.state_frames_1304)
    processed.flags_2468 = processed2.flags_2468
    processed.flags_2472 = processed2.flags_2472
    processed.flags_2480 = processed2.flags_2480
    processed.flags_2484 = processed2.flags_2484
    processed.object_2464 = processed2.word_2464

    local jump_reference_1264 = player.jump_reference_1264

    if jump_reference_1264 ~= jump_reference then
        post.jump_reference = jump_reference_1264
    end

    post.jump_fix_frames = player.jump_fix_frames_1308
    post.latch_frames = player.latch_frames_1320
    post.state_frames = processed2.state_frames_2572
    post.heading_adjust = processed2.scalar_2740
    post.complete = output.complete_76
    player.jump_reference_1264 = nil
    processed2.jump_reference_848 = nil
    output.jump_reference_128 = nil
    services.grind = nil
    services.pending = nil
    host.board = nil
    host.settings = nil
    host.materials = nil
    services.processed = nil
    services.trajectory = nil
    services.trajectory_input = nil
    services.trajectory_board_position = nil
    services.world = nil
    services.grab_records = nil
    v38 = v48
end

return t1
