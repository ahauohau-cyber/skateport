-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local State = import("skate_core/player/offboard/biped_air/recovered").State

local function biped_ground() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function air_selector() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local t1 = {}

local function map_from_bits(p1) -- line: 26
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

function t1.context(p2) -- line: 31
    -- upvalues: rt (copy)
    local processed = p2.player_input.processed
    local t2 = {
        selection_flags_2948 = processed.actor_query_2948,
        matching_group_2952 = rt.to_i32(processed.actor_query_2952)
    }
    local v1 = processed.vectors_544_560_592_608[1]

    t2.up_544 = rt.map(v1, rt.from_bits)

    local v2 = processed.effective_anim_transform_192[3]

    t2.forward_224 = rt.map(v2, rt.from_bits)

    return t2
end

function t1.effective_frame(p3) -- line: 42
    -- upvalues: rt (copy)
    local v3 = rt.copy(p3.animated_skeleton.roots.animation_to_world)

    if bit32.band(p3.player_input.processed.flags_2476, 4) ~= 0 then
        for _, v4 in ipairs({ 0, 2 }) do
            v3[v4 + 1] = rt.map(v3[v4 + 1], function(p4) -- line: 47
                return -p4
            end)
        end
    end

    return v3
end

function t1.enter(p5) -- line: 56
    -- upvalues: rt (copy), t1 (copy)
    local processed = p5.player_input.processed
    local t3 = {
        animation_frame = t1.effective_frame(p5),
        body_position_15872 = rt.copy(p5.animated_skeleton.board_frames.com_frame[4]),
        body_position_15936 = rt.copy(p5.animated_skeleton.board_frames.lifted_com_frame[4])
    }
    local v5 = processed.vectors_544_560_592_608[3]

    t3.position_592 = rt.map(v5, rt.from_bits)

    local v6 = processed.vectors_544_560_592_608[1]

    t3.up_544 = rt.map(v6, rt.from_bits)
    t3.flags_2484 = processed.flags_2484

    return t3
end

function t1.height(p6) -- line: 69
    -- upvalues: rt (copy), compose_affine (copy)
    local processed = p6.player_input.processed
    local v7 = rt.copy(p6.animated_skeleton.roots.animation_to_world)
    local t4 = {
        bone15 = rt.copy(compose_affine(v7, p6.animated_skeleton.record.pose[16])[4]),
        bone19 = rt.copy(compose_affine(v7, p6.animated_skeleton.record.pose[20])[4]),
        bone1 = rt.copy(compose_affine(v7, p6.skeleton_input.drive_frames[2])[4])
    }
    local v8 = processed.vectors_544_560_592_608[1]

    t4.up_544 = rt.map(v8, rt.from_bits)

    local v9 = processed.vectors_544_560_592_608[4]

    t4.velocity_608 = rt.map(v9, rt.from_bits)

    return t4
end

function t1.launch_packet(p7) -- line: 83
    -- upvalues: rt (copy), import (copy), State (copy)
    local processed, toolkit = p7.player_input.processed, p7.player_input.toolkit

    if toolkit == nil then
        error("BipedAir launch requires the completed BoardToolkit", 0)
    end

    local t5 = {
        board_position_112 = rt.copy(toolkit.deck[4])
    }
    local v10 = processed.effective_anim_transform_192[3]

    t5.forward_224 = rt.map(v10, rt.from_bits)

    local v11 = processed.vectors_544_560_592_608[1]

    t5.up_544 = rt.map(v11, rt.from_bits)

    local v12 = processed.vectors_544_560_592_608[3]

    t5.position_592 = rt.map(v12, rt.from_bits)

    local v13 = processed.vectors_544_560_592_608[4]

    t5.velocity_608 = rt.map(v13, rt.from_bits)

    local v14 = processed.vectors_880_896_912_928_944[3]

    t5.velocity_912 = rt.map(v14, rt.from_bits)

    local point_1120 = processed.grind.point_1120
    local t6 = {}

    t6.point_1120 = rt.map(point_1120, rt.from_bits)

    local direction_1136 = processed.grind.direction_1136

    t6.axis_1136 = rt.map(direction_1136, rt.from_bits)
    t5.departure_geometry = t6
    t5.flags_2472 = processed.flags_2472
    t5.flags_2476 = processed.flags_2476
    t5.flags_2480 = processed.flags_2480
    t5.previous_state_2504 = processed.state_2504
    t5.current_state_2508 = processed.state_2508
    t5.current_category_2512 = processed.category_2512
    t5.previous_category_2516 = processed.category_2516
    t5.raw_x_2692 = p7.animation_input.extra.biped_world_x
    t5.raw_z_2688 = p7.animation_input.extra.biped_world_z

    local v15, v16 = import("skate_game/physics/biped_ground").Owner.air_settings(p7.biped_ground)

    return State.launch_packet(p7.biped_air.state, t5, p7.biped_ground.controller.state, v15, v16)
end

function t1.submit(p8, p9, p10) -- line: 115
    -- upvalues: import (copy), t1 (copy)
    local v17 = t1.context(p9)
    local gravity_acceleration = p8.settings.step.simulation.gravity_acceleration

    import("skate_game/physics/offboard/air_selector").AirSelector.launch(p9.offboard_air_selector, p8.world, p10, {
        gravity_acceleration.x,
        gravity_acceleration.y,
        gravity_acceleration.z,
        0
    }, v17)
end

return t1
