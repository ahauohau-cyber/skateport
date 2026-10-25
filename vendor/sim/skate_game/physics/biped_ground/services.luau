-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/biped_ground/entry")
local v2 = import("skate_game/physics/biped_ground/feet")
local v3 = import("skate_game/physics/biped_ground/grab")
local Mode = import("skate_core/animation/foot_ik/status").Mode
local FootIkState = import("skate_core/animation/foot_ik/state").FootIkState
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local State = import("skate_core/player/offboard/board_possession/manager").State

local function air_selector() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local t1 = {}

local function map_from_bits(p1) -- line: 27
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

function t1.enter_feet(p2) -- line: 34
    -- upvalues: Mode (copy), FootIkState (copy), State (copy)
    local processed = p2.player_input.processed

    if processed.state_2504 ~= 500 and processed.state_2504 ~= 501 and processed.state_2504 ~= 502 then
        State.reset(p2.offboard_feet)
        FootIkState.enable_feet(p2.foot_ik.state, false)

        for _, v4 in ipairs(p2.foot_ik.state.limbs) do
            v4.board_blend = 0
            v4.external_blend = 0
            v4.mode = Mode.Disabled
        end
    end

    p2.offboard_feet.flags_304_to_307[1] = processed.state_2508 == 502
end

function t1.feet_input(p3) -- line: 52
    -- upvalues: rt (copy), v1 (copy), compose_affine (copy)
    local processed = p3.player_input.processed
    local animated_skeleton = p3.animated_skeleton
    local v5 = rt.copy(animated_skeleton.roots.animation_to_world)
    local v6 = v1.effective_root(rt.copy(v5), processed.flags_2476)
    local pose = animated_skeleton.record.pose
    local t2 = {}

    t2.lines = rt.from_fn(2, function(p4) -- line: 59
        -- upvalues: processed (copy), rt (copy)
        local v7 = processed.line_tests_960_1008_1056[p4 + 1]
        local position = v7.position
        local t3 = {}

        t3.position = rt.map(position, rt.from_bits)

        local normal = v7.normal

        t3.normal = rt.map(normal, rt.from_bits)
        t3.surface = v7.surface
        t3.valid = v7.valid ~= 0

        return t3
    end)
    t2.root = v5
    t2.inverse_root = rt.copy(animated_skeleton.roots.world_to_animation)
    t2.effective_root = v6
    t2.local_foot_pairs = rt.map({
        15, 19
    }, function(p5) -- line: 71
        -- upvalues: pose (copy), rt (copy)
        return {
            rt.copy(pose[p5 + 1][4]),
            rt.copy(pose[p5 + 1 + 1][4])
        }
    end)
    t2.world_foot_pairs = rt.map({
        15, 19
    }, function(p6) -- line: 74
        -- upvalues: v5 (copy), pose (copy), rt (copy), compose_affine (copy)
        return {
            rt.copy(compose_affine(v5, pose[p6 + 1])[4]),
            rt.copy(compose_affine(v5, pose[p6 + 1 + 1])[4])
        }
    end)

    local v8 = processed.vectors_544_560_592_608[3]

    t2.position = rt.map(v8, rt.from_bits)

    local v9 = processed.vectors_544_560_592_608[4]

    t2.velocity = rt.map(v9, rt.from_bits)
    t2.flags_2476 = processed.flags_2476
    t2.flags_2480 = processed.flags_2480
    t2.flags_2484 = processed.flags_2484
    t2.state = processed.state_2508

    return t2
end

function t1.update_feet(p7) -- line: 90
    -- upvalues: v2 (copy), t1 (copy)
    local v10 = t1.feet_input(p7)

    v2.update(p7.offboard_feet, v10, p7.foot_ik.state)
end

function t1.launch_input(p8, p9) -- line: 97
    -- upvalues: rt (copy)
    local processed, toolkit = p8.player_input.processed, p8.player_input.toolkit

    if toolkit == nil then
        error("Ground launch requires the completed BoardToolkit", 0)
    end

    local t4 = {}
    local t5 = {
        board_position_112 = rt.copy(toolkit.deck[4])
    }
    local v11 = processed.effective_anim_transform_192[3]

    t5.forward_224 = rt.map(v11, rt.from_bits)

    local v12 = processed.vectors_544_560_592_608[1]

    t5.up_544 = rt.map(v12, rt.from_bits)

    local v13 = processed.vectors_544_560_592_608[3]

    t5.position_592 = rt.map(v13, rt.from_bits)

    local v14 = processed.vectors_544_560_592_608[4]

    t5.velocity_608 = rt.map(v14, rt.from_bits)

    local v15 = processed.vectors_880_896_912_928_944[3]

    t5.velocity_912 = rt.map(v15, rt.from_bits)
    t5.departure_geometry = p9
    t5.flags_2472 = processed.flags_2472
    t5.flags_2476 = processed.flags_2476
    t5.flags_2480 = processed.flags_2480
    t5.previous_state_2504 = processed.state_2504
    t5.current_state_2508 = processed.state_2508
    t5.current_category_2512 = processed.category_2512
    t5.previous_category_2516 = processed.category_2516
    t5.raw_x_2692 = p8.animation_input.extra.biped_world_x
    t5.raw_z_2688 = p8.animation_input.extra.biped_world_z
    t4.processed = t5
    t4.elapsed_2664 = processed.state_timer_2664
    t4.skeleton_point_10960 = rt.copy(p8.animated_skeleton.record.centre_of_mass)

    return t4
end

function t1.sync_grab(p10) -- line: 129
    -- upvalues: rt (copy), v3 (copy), compose_affine (copy), map_from_bits (copy)
    local processed = p10.player_input.processed
    local v16 = rt.copy(compose_affine(p10.animated_skeleton.roots.animation_to_world, p10.animated_skeleton.record.pose[24])[4])
    local t6 = {
        frame = rt.map(processed.effective_anim_transform_192, map_from_bits)
    }
    local v17 = processed.vectors_544_560_592_608[3]

    t6.position = rt.map(v17, rt.from_bits)
    t6.bone = v16
    t6.flags_2476 = processed.flags_2476
    t6.flags_2480 = processed.flags_2480
    t6.flags_2484 = processed.flags_2484
    t6.elapsed = processed.state_timer_2664
    t6.timer_2852 = processed.secondary_ground_timer_2852
    t6.context = {
        selection_flags_2948 = processed.actor_query_2948,
        matching_id_2952 = rt.to_i32(processed.actor_query_2952)
    }
    v3.sync(p10.biped_ground.ground, p10.offboard_grab, rt.copy(p10.biped_ground.grab_settings), t6)
end

function t1.submit_air(p11, p12, p13) -- line: 155
    -- upvalues: rt (copy), import (copy)
    local processed = p12.player_input.processed
    local gravity_acceleration = p11.settings.step.simulation.gravity_acceleration
    local t7 = {
        selection_flags_2948 = processed.actor_query_2948,
        matching_group_2952 = rt.to_i32(processed.actor_query_2952)
    }
    local v18 = processed.vectors_544_560_592_608[1]

    t7.up_544 = rt.map(v18, rt.from_bits)

    local v19 = processed.effective_anim_transform_192[3]

    t7.forward_224 = rt.map(v19, rt.from_bits)
    import("skate_game/physics/offboard/air_selector").AirSelector.launch(p12.offboard_air_selector, p11.world, p13, {
        gravity_acceleration.x,
        gravity_acceleration.y,
        gravity_acceleration.z,
        0
    }, t7)
end

return t1
