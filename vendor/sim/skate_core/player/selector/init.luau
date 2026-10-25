-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/selector/air")
local v2 = import("skate_core/player/selector/conditions")
local v3 = import("skate_core/player/selector/ground")
local v4 = import("skate_core/player/selector/input")
local v5 = import("skate_core/player/selector/offboard")
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local condition_is_off_ground, condition_is_off_ground_skitching, is_skateboard_animated = v2.condition_is_off_ground, v2.condition_is_off_ground_skitching, v2.is_skateboard_animated
local t1 = {
    ProcessedStateInput = v4.ProcessedStateInput,
    StateSelectionInput = v4.StateSelectionInput
}
local ProcessedStateInput = t1.ProcessedStateInput

t1.StateSelector = {}

local StateSelector = t1.StateSelector

function t1.StateSelector.default() -- line: 49
    return {
        current_state = nil,
        nonspecific_collision_free_frames = 0,
        nonspecific_collision_frames = 0,
        something_colliding_frames = 0,
        two_wheel_counter = 0,
        three_wheel_counter = 0,
        post_grind_jump_counter = 0,
        air_frames = 0,
        teleport_countdown = 0,
        skitch_exit_countdown = 0,
        revert_exited_normally = false,
        request_teleport = false
    }
end

t1.FrameFacts = {}

function t1.StateSelector.calculate(p1, p2, p3) -- line: 73
    -- upvalues: rt (copy), PhysicalStateId (copy), condition_is_off_ground (copy), condition_is_off_ground_skitching (copy), is_skateboard_animated (copy), t1 (copy), ProcessedStateInput (copy), StateSelector (copy)
    local v6 = ProcessedStateInput.read(p3.processed)

    if p1.teleport_countdown > 0 then
        p1.teleport_countdown = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p1.teleport_countdown), 1))
    end

    p1.current_state = p2
    p1.revert_exited_normally = false
    p1.request_teleport = false

    local v7 = v6.wheel_contact_count_2556 > 0 or ProcessedStateInput.has_2468(v6, 65536) or ProcessedStateInput.has_2468(v6, 131072)

    if p2 ~= PhysicalStateId.Nonspecific or v7 then
        p1.nonspecific_collision_free_frames = 0
    else
        p1.nonspecific_collision_free_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.nonspecific_collision_free_frames), 1))
    end

    if p2 ~= PhysicalStateId.Nonspecific or not v7 then
        p1.nonspecific_collision_frames = 0
    else
        p1.nonspecific_collision_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.nonspecific_collision_frames), 1))
    end

    if p3.skateboard_contact_count_869 > 1 then
        p1.two_wheel_counter = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.two_wheel_counter), 1))
    else
        p1.two_wheel_counter = 0
    end

    if p3.skateboard_contact_count_869 > 2 then
        p1.three_wheel_counter = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.three_wheel_counter), 1))
    else
        p1.three_wheel_counter = 0
    end

    if v7 then
        p1.something_colliding_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.something_colliding_frames), 1))
    else
        p1.something_colliding_frames = 0
    end

    if v6.category_2512 == 400 and ProcessedStateInput.has_2468(v6, 4194304) then
        p1.post_grind_jump_counter = 0
    else
        p1.post_grind_jump_counter = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.post_grind_jump_counter), 1))
    end

    if v6.category_2512 == 200 then
        if ProcessedStateInput.has_2468(v6, 8) then
            p1.air_frames = p1.air_frames
        else
            p1.air_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.air_frames), 1))
        end
    else
        p1.air_frames = 0
    end

    if p2 == PhysicalStateId.Skitching then
        p1.skitch_exit_countdown = 10
    elseif p1.skitch_exit_countdown > 0 then
        p1.skitch_exit_countdown = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p1.skitch_exit_countdown), 1))
    else
        p1.skitch_exit_countdown = 0
    end

    if ProcessedStateInput.has_2468(v6, 2) or ProcessedStateInput.has_2472(v6, 262144) then
        return PhysicalStateId.Teleporting
    end

    if p1.air_frames > 300 then
        p1.request_teleport = true

        return p2
    end

    if v6.field_1776 < 0 and bit32.band(rt.to_u32(v6.field_1776), 33554432) == 0 and p1.teleport_countdown == 0 then
        return PhysicalStateId.FollowPath
    end

    local t2 = {
        colliding = v7,
        wipeout = ProcessedStateInput.has_2468(v6, 262144),
        force_known_air = ProcessedStateInput.has_2472(v6, 64),
        skateboard_animated = is_skateboard_animated(p3.skeleton),
        off_ground = condition_is_off_ground(p3.board_body, p3.normal_off_ground),
        off_ground_skitching = condition_is_off_ground_skitching(p3.board_body, p3.skitching_off_ground),
        grind = t1.check_for_grind(v6)
    }

    if p2 == PhysicalStateId.PhysicsGround
        or p2 == PhysicalStateId.SlideGround
        or p2 == PhysicalStateId.RevertGround
        or p2 == PhysicalStateId.GroundAnimation
        or p2 == PhysicalStateId.Skitching
        or p2 == PhysicalStateId.FollowPath then
        return StateSelector.select_ground_family(p1, p2, p3, t2)
    end

    if p2 == PhysicalStateId.PhysicsAir then
        return StateSelector.select_physics_air(p1, p2, p3, t2)
    end

    if p2 == PhysicalStateId.KnownAir then
        return StateSelector.select_known_air(p1, p2, p3, t2)
    end

    if p2 == PhysicalStateId.PhysicsAirSecondary then
        if t2.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2484(v6, 1048576) then
            return p2
        end

        return PhysicalStateId.PhysicsAir
    end

    if p2 == PhysicalStateId.WipeoutGround or p2 == PhysicalStateId.Sleeping or p2 == PhysicalStateId.Teleporting then
        return p2
    end

    if p2 == PhysicalStateId.GrindBoardslide
        or p2 == PhysicalStateId.GrindFiftyFifty
        or p2 == PhysicalStateId.GrindTipslide
        or p2 == PhysicalStateId.GrindFiveO
        or p2 == PhysicalStateId.GrindBackslash
        or p2 == PhysicalStateId.GrindDarkslide then
        return StateSelector.select_grind(p1, p2, p3, t2)
    end

    if p2 == PhysicalStateId.BipedGround
        or p2 == PhysicalStateId.BipedAir
        or p2 == PhysicalStateId.OffBoardPushing
        or p2 == PhysicalStateId.LandingOnDeck
        or p2 == PhysicalStateId.HandPlant
        or p2 == PhysicalStateId.FootPlant
        or p2 == PhysicalStateId.Boneless then
        return StateSelector.select_biped_or_plant(p1, p2, p3, t2)
    end

    if p2 == PhysicalStateId.Nonspecific then
        return StateSelector.select_nonspecific(p1, p2, p3, t2)
    end

    error("StateSelector::calculate: not a PhysicalStateId", 0)
end

function t1.StateSelector.select_nonspecific(p4, p5, p6, p7) -- line: 218
    -- upvalues: PhysicalStateId (copy), ProcessedStateInput (copy)
    local v9 = ProcessedStateInput.read(p6.processed)

    if ProcessedStateInput.has_2484(v9, 1048576) then
        return PhysicalStateId.PhysicsAirSecondary
    end

    if p7.wipeout then
        return PhysicalStateId.WipeoutGround
    end

    if ProcessedStateInput.has_2468(v9, 256) then
        return ProcessedStateInput.air_variant_from_2468(v9)
    end

    if ProcessedStateInput.has_2468(v9, 4194304) then
        return p5
    end

    if ProcessedStateInput.has_2472(v9, 8) then
        if ProcessedStateInput.has_2484(v9, 2097152) then
            return PhysicalStateId.WipeoutGround
        end

        return PhysicalStateId.PhysicsAir
    end

    if ProcessedStateInput.has_2472(v9, 4) then
        return p5
    end

    if p7.grind ~= nil then
        return p7.grind
    end

    local v10 = bit32.band(v9.grind_investigation_flags_1516, 134217728) == 0
    local v11, v12

    if v10 then
        v12 = p4.two_wheel_counter > 2
    else
        v11 = p4.three_wheel_counter > 10
    end

    if v10 and not v12 or not v10 and not v11 then
        if p4.nonspecific_collision_free_frames > 2 then
            return PhysicalStateId.PhysicsAir
        end

        if (if ProcessedStateInput.has_2484(v9, 2097152) then 30 else 60) < p4.nonspecific_collision_frames then
            return PhysicalStateId.PhysicsGround
        end

        return p5
    end

    if v10 and p7.skateboard_animated then
        return PhysicalStateId.GroundAnimation
    end

    return PhysicalStateId.PhysicsGround
end

for v13, v14 in v1.StateSelector do
    t1.StateSelector[v13] = v14
end

for v15, v16 in v3.StateSelector do
    t1.StateSelector[v15] = v16
end

for v17, v18 in v5.StateSelector do
    t1.StateSelector[v17] = v18
end

function t1.check_for_grind(p8) -- line: 283
    -- upvalues: PhysicalStateId (copy), ProcessedStateInput (copy)
    if not p8.grind_candidate_1488 or ProcessedStateInput.has_2480(p8, 131072) or ProcessedStateInput.has_2480(p8, 67108864) then
        return nil
    end

    local grind_type_1248 = p8.grind_type_1248

    if grind_type_1248 == 0 then
        return PhysicalStateId.GrindFiftyFifty
    end

    if grind_type_1248 == 1 then
        return PhysicalStateId.GrindBoardslide
    end

    if grind_type_1248 == 2 then
        return PhysicalStateId.GrindTipslide
    end

    if grind_type_1248 == 3 then
        return PhysicalStateId.GrindFiveO
    end

    if grind_type_1248 == 4 then
        return PhysicalStateId.GrindBackslash
    end

    return if grind_type_1248 == 5 then PhysicalStateId.GrindDarkslide else nil
end

return t1
