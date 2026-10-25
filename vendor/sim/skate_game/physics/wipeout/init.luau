-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout/observations")
local v2 = import("skate_game/physics/wipeout/settings")
local v3 = import("skate_game/physics/solve")
local v4 = import("skate_core/air/trajectory")
local v5 = import("skate_core/player/state")
local v6 = import("skate_core/player/wipeout")
local TrajectorySelector = v4.TrajectorySelector
local PhysicalStateId = v5.PhysicalStateId
local Requests = v6.Requests

local function footplant_ground() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant/ground")
end

local function grind_trick() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_trick")
end

local function handplant() -- line: 27
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function player_state() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local v7 = false
local v8
local t1 = {}

local function release_observation() -- line: 40
    -- upvalues: t1 (copy)
    t1.processed = nil
    t1.board = nil
    t1.collision = nil
    t1.input_board = nil
    t1.world_to_animation = nil
    t1.pose_error = nil
    t1.air = nil
    t1.grind_normal = nil
end

local t2 = {
    Observations = v1.Observations
}
local Observations = t2.Observations

t2.Wipeout = {}

local Wipeout = t2.Wipeout

function t2.Wipeout.adopt_mode_settings(p1, p2) -- line: 66
    p1.modes = p2.modes
end

function t2.Wipeout.check_air_collision(p3, p4, p5) -- line: 71
    -- upvalues: v6 (copy), Wipeout (copy)
    local v9 = Wipeout.mode(p3, p4)

    v6.check_air_collision(p3.state, p3.settings, v9, p5)
end

function t2.Wipeout.load(p6) -- line: 77
    -- upvalues: v2 (copy), Requests (copy)
    local v10, v11 = v2.load(p6)
    local v12 = Requests.new()

    Requests.initialize_player(v12)

    return {
        state = v12,
        settings = v10,
        modes = v11
    }
end

local function mode_view(p7, p8) -- line: 94
    local v13 = p7.modes[p8.state_variant_index_2528 + 1]

    if v13 == nil then
        error(string.format("Undefined wipeout physics mode %d", p8.state_variant_index_2528), 0)
    end

    return v13
end

function t2.Wipeout.check_ground(p9, p10) -- line: 103
    -- upvalues: v6 (copy), v7 (ref), Observations (copy), Wipeout (copy)
    if v7 then
        local v14 = Wipeout.mode(p9, p10.processed)
        local v15 = Observations.frame(p10)

        v6.check_ground(p9.state, p9.settings, v14, v15)
    else
        local processed = p10.processed
        local v16 = p9.modes[processed.state_variant_index_2528 + 1]

        if v16 == nil then
            error(string.format("Undefined wipeout physics mode %d", processed.state_variant_index_2528), 0)
        end

        v6.check_ground(p9.state, p9.settings, v16, Observations.frame_view(p10))
    end
end

function t2.Wipeout.check_ground_animation(p11, p12, p13) -- line: 115
    -- upvalues: v6 (copy), v7 (ref), Observations (copy), Wipeout (copy)
    if v7 then
        local v17 = Wipeout.mode(p11, p12.processed)
        local v18 = Observations.frame(p12)

        v6.check_ground_animation(p11.state, p11.settings, v17, v18, p13)
    else
        local processed = p12.processed
        local v19 = p11.modes[processed.state_variant_index_2528 + 1]

        if v19 == nil then
            error(string.format("Undefined wipeout physics mode %d", processed.state_variant_index_2528), 0)
        end

        v6.check_ground_animation(p11.state, p11.settings, v19, Observations.frame_view(p12), p13)
    end
end

function t2.Wipeout.check_air(p14, p15, p16) -- line: 127
    -- upvalues: v6 (copy), v7 (ref), Observations (copy), Wipeout (copy)
    if v7 then
        local v20 = Wipeout.mode(p14, p15.processed)
        local v21 = Observations.frame(p15)

        v6.check_air(p14.state, p14.settings, v20, v21, p16)
    else
        local processed = p15.processed
        local v22 = p14.modes[processed.state_variant_index_2528 + 1]

        if v22 == nil then
            error(string.format("Undefined wipeout physics mode %d", processed.state_variant_index_2528), 0)
        end

        v6.check_air(p14.state, p14.settings, v22, Observations.frame_view(p15), p16)
    end
end

function t2.Wipeout.mode(p17, p18) -- line: 139
    -- upvalues: rt (copy)
    local v23 = p17.modes[p18.state_variant_index_2528 + 1]

    if v23 == nil then
        error(string.format("Undefined wipeout physics mode %d", p18.state_variant_index_2528), 0)
    end

    return rt.copy(v23)
end

function t2.Wipeout.requests_runout(p19, p20) -- line: 149
    -- upvalues: v1 (copy), Requests (copy), v7 (ref)
    if v7 then
        return Requests.requests_runout(p19.state, v1.request_input(p20))
    end

    return Requests.requests_runout(p19.state, v1.request_input_view(p20))
end

function t2.Wipeout.requests_wipeout(p21, p22) -- line: 156
    -- upvalues: v1 (copy), Requests (copy), v7 (ref)
    if v7 then
        return Requests.requests_wipeout(p21.state, v1.request_input(p22))
    end

    return Requests.requests_wipeout(p21.state, v1.request_input_view(p22))
end

function t2.check_after_physics(p23, p24) -- line: 182
    -- upvalues: rt (copy), import (copy), v3 (copy), v6 (copy), TrajectorySelector (copy), PhysicalStateId (copy), v7 (ref), v8 (ref), t1 (copy), Observations (copy), Wipeout (copy)
    local PlayerState = import("skate_game/physics/player_state").PlayerState
    local v24 = PlayerState.current(p24.player_state)
    local v25 = v24 == PhysicalStateId.FootPlant or v24 == PhysicalStateId.HandPlant

    if not v7 and not v25 and v24 ~= PhysicalStateId.PhysicsGround and v24 ~= PhysicalStateId.SlideGround and v24 ~= PhysicalStateId.RevertGround and v24 ~= PhysicalStateId.GroundAnimation and v24 ~= PhysicalStateId.PhysicsAirSecondary and v24 ~= PhysicalStateId.PhysicsAir then
        return
    end

    local v26 = v7 or v25
    local animation_target = p24.animated_skeleton.board_frames.animation_target
    local world_to_animation = p24.animated_skeleton.roots.world_to_animation
    local collision_pose_error = p24.collision_pose_error
    local v27

    if v7 then
        v27 = v3.deck_frame(p23.board)
    else
        v27 = v3.deck_frame_into(p23.board, v8)
        v8 = v27
    end

    local t3

    if v7 then
        t3 = {
            processed = p24.player_input.processed,
            board = p23.riding.ground,
            collision = p24.collision_feedback,
            deck = v27
        }

        if v26 then
            t3.input_board = rt.copy(animation_target)
        else
            t3.input_board = animation_target
        end
    else
        t3 = t1
        t1.processed = p24.player_input.processed
        t1.board = p23.riding.ground
        t1.collision = p24.collision_feedback
        t1.deck = v27

        if v26 then
            animation_target = rt.copy(animation_target)
        end

        t1.input_board = animation_target
    end

    if v26 then
        world_to_animation = rt.copy(world_to_animation)
    end

    t3.world_to_animation = world_to_animation

    if v26 then
        collision_pose_error = rt.copy(collision_pose_error)
    end

    t3.pose_error = collision_pose_error
    t3.maximum_pose_error = p24.collision_maximum_error
    t3.jump_fix_frames = p24.player_state.post.jump_fix_frames
    t3.air = p24.air_reckoning.state
    t3.system_up_y = p23.riding.reckoning_frames.system[2][2]
    t3.grind_locked_to_middle = TrajectorySelector.grind_locked_to_middle(p24.trajectory.selector)
    t3.grind_normal = TrajectorySelector.grind_normal(p24.trajectory.selector)

    if v24 == PhysicalStateId.FootPlant or v24 == PhysicalStateId.HandPlant then
        local v28 = Observations.frame(t3)

        if PlayerState.current(p24.player_state) == PhysicalStateId.HandPlant then
            import("skate_game/physics/handplant").trace_solved(p23, p24)
            Wipeout.check_air(p24.wipeout, t3, false)
        else
            v6.check_plant(p24.wipeout.state, p24.wipeout.settings, v28)
        end

        if p24.wipeout.state.count == 0 then
        end

        if PlayerState.current(p24.player_state) == PhysicalStateId.FootPlant then
            import("skate_game/physics/footplant/ground").post_physics(p24)
        end
    elseif v24 ~= PhysicalStateId.PhysicsGround and v24 ~= PhysicalStateId.SlideGround and v24 ~= PhysicalStateId.RevertGround then
        if v24 == PhysicalStateId.GroundAnimation then
            Wipeout.check_ground_animation(p24.wipeout, t3, 1)
        elseif v24 == PhysicalStateId.PhysicsAirSecondary then
            Wipeout.check_ground_animation(p24.wipeout, t3, import("skate_game/physics/grind_trick").GrindTrick.wipeout_scale(p24.grind_trick))
        elseif v24 == PhysicalStateId.PhysicsAir then
            Wipeout.check_air(p24.wipeout, t3, false)
        end
    else
        Wipeout.check_ground(p24.wipeout, t3)
    end

    if t3 ~= t1 then
        return
    end

    t1.processed = nil
    t1.board = nil
    t1.collision = nil
    t1.input_board = nil
    t1.world_to_animation = nil
    t1.pose_error = nil
    t1.air = nil
    t1.grind_normal = nil
end

function t2.check_after_physics_reference(p25, p26) -- line: 296
    -- upvalues: v7 (ref), t2 (copy)
    local v29 = v7

    v7 = true

    local check_after_physics = t2.check_after_physics
    local ok, result = pcall(check_after_physics, p25, p26)

    v7 = v29

    if not ok then
        error(result, 0)
    end
end

return t2
