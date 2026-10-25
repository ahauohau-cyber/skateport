-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local StateSelector = import("skate_core/player/selector").StateSelector
local Requests = import("skate_core/player/wipeout").Requests
local v1 = import("skate_game/physics/player_state/transition")

local function parent() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local v2 = false
local t1 = {}

function t1.set_reference(p1) -- line: 24
    -- upvalues: v2 (ref)
    v2 = p1
end

local t2 = {
    processed = {},
    board_body = {},
    skeleton = {}
}

function t1.input_view(p2, p3, p4) -- line: 38
    -- upvalues: rt (copy), t2 (copy)
    local processed = t2.processed

    processed.grind_type_1248 = p4.grind.family_1248
    processed.grind_candidate_1488 = p4.grind.valid_1488
    processed.grind_investigation_flags_1516 = p4.grind.flags_1516
    processed.field_1776 = rt.to_i32(p4.external_physics_1616.flags)
    processed.flags_2468 = p4.flags_2468
    processed.flags_2472 = p4.flags_2472
    processed.flags_2476 = p4.flags_2476
    processed.flags_2480 = p4.flags_2480
    processed.flags_2484 = p4.flags_2484
    processed.flags_2488 = p4.flags_2488
    processed.category_2512 = p4.category_2512
    processed.wheel_contact_count_2556 = rt.to_i32(p4.wheel_count_2556)
    processed.field_2572 = p3.player_state.post.state_frames
    processed.state_timer_2664 = p4.state_timer_2664
    processed.field_2732 = p3.animation_input.fields.slide
    processed.field_2744 = p3.animation_input.extra.revert_direction
    processed.trajectory_collision_time_2772 = p4.air_scalar_2772
    t2.skateboard_contact_count_869 = p2.riding.ground.wheel_contact_count

    local board_body = t2.board_body

    board_body.field_856 = p2.riding.wheel_lines.minimum_distance
    board_body.field_7692 = p2.riding.ground.time_without_wheel_contact

    local skeleton = t2.skeleton

    skeleton.mode_16420 = p3.skeleton_input.force_mode
    skeleton.back_chain_lane_12656 = p3.skeleton_input.drive_frames[1][3][2]
    skeleton.threshold_800 = p3.player_state.animated_board_threshold
    t2.normal_off_ground = p3.player_state.normal_off_ground
    t2.skitching_off_ground = p3.player_state.skitching_off_ground

    return t2
end

function t1.advance(p5, p6, p7) -- line: 73
    -- upvalues: import (copy), StateSelector (copy), Requests (copy), v1 (copy), t1 (copy), v2 (ref), t2 (copy)
    local PlayerState = import("skate_game/physics/player_state").PlayerState

    if p7.tick ~= p5.ticks then
        error(string.format("assertion `left == right` failed\n  left: %s\n right: %s", tostring(p7.tick), (tostring(p5.ticks))), 0)
    end

    local input = p7.input
    local v4 = if v2 then t1.input_reference(p5, p6, input) else t1.input_view(p5, p6, input)
    local v5 = PlayerState.current(p6.player_state)
    local v6 = StateSelector.calculate(p6.player_state.selector, v5, v4)

    if v4 == t2 then
        v4.normal_off_ground = nil
        v4.skitching_off_ground = nil
    end

    p6.player_state.requested_state = v6

    if v6 ~= v5 then
        p6.player_input.player.ground_history_frames_1304 = 100
        v1.set(p5, p6, v6)
    end

    Requests.clear_after_selection(p6.wipeout.state)
end

function t1.input_reference(p8, p9, p10) -- line: 105
    -- upvalues: rt (copy)
    return {
        processed = {
            grind_type_1248 = p10.grind.family_1248,
            grind_candidate_1488 = p10.grind.valid_1488,
            grind_investigation_flags_1516 = p10.grind.flags_1516,
            field_1776 = rt.to_i32(p10.external_physics_1616.flags),
            flags_2468 = p10.flags_2468,
            flags_2472 = p10.flags_2472,
            flags_2476 = p10.flags_2476,
            flags_2480 = p10.flags_2480,
            flags_2484 = p10.flags_2484,
            flags_2488 = p10.flags_2488,
            category_2512 = p10.category_2512,
            wheel_contact_count_2556 = rt.to_i32(p10.wheel_count_2556),
            field_2572 = p9.player_state.post.state_frames,
            state_timer_2664 = p10.state_timer_2664,
            field_2732 = p9.animation_input.fields.slide,
            field_2744 = p9.animation_input.extra.revert_direction,
            trajectory_collision_time_2772 = p10.air_scalar_2772
        },
        skateboard_contact_count_869 = p8.riding.ground.wheel_contact_count,
        board_body = {
            field_856 = p8.riding.wheel_lines.minimum_distance,
            field_7692 = p8.riding.ground.time_without_wheel_contact
        },
        skeleton = {
            mode_16420 = p9.skeleton_input.force_mode,
            back_chain_lane_12656 = p9.skeleton_input.drive_frames[1][3][2],
            threshold_800 = p9.player_state.animated_board_threshold
        },
        normal_off_ground = rt.copy(p9.player_state.normal_off_ground),
        skitching_off_ground = rt.copy(p9.player_state.skitching_off_ground)
    }
end

return t1
