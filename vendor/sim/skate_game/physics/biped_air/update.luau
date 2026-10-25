-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/biped_air/input")
local v2 = import("skate_core/player/offboard/biped_air/recovered")
local projected_height = import("skate_core/player/offboard/biped_air/height").projected_height
local State = import("skate_core/player/offboard/board_possession/manager").State
local Requests = import("skate_core/player/wipeout").Requests
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState
local State2, TrajectoryResult = v2.State, v2.TrajectoryResult

local function air_feet() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_feet")
end

local function air_selector() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local function offboard_contact_toolkit() -- line: 27
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_toolkit")
end

local function landing_deck() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local function skeleton_controller() -- line: 33
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function input_phase() -- line: 36
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function biped_ground() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local t1 = {}

local function map_from_bits(p1) -- line: 48
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

local skeleton
local v3 = false

function t1.set_reference(p2) -- line: 65
    -- upvalues: v3 (ref)
    v3 = p2
end

function t1.update(p3, p4, p5) -- line: 68
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), projected_height (copy), State (copy), Requests (copy), TruckSteeringState (copy), State2 (copy), TrajectoryResult (copy), t1 (copy), skeleton (ref), v3 (ref)
    if v3 then
        return t1.update_reference(p3, p4, p5)
    end

    local AirSelector = import("skate_game/physics/offboard/air_selector").AirSelector
    local processed = p4.player_input.processed
    local flags_2468, flags_2472, flags_2476, flags_2484 = processed.flags_2468, processed.flags_2472, processed.flags_2476, processed.flags_2484
    local flags_2488, state_timer_2664 = processed.flags_2488, processed.state_timer_2664
    local v4 = processed.vectors_544_560_592_608[1]
    local v5 = rt.map(v4, rt.from_bits)
    local v6 = processed.vectors_544_560_592_608[3]
    local v7 = rt.map(v6, rt.from_bits)

    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request(p4.ground_lifecycle.skeleton_controller, bit32.band(flags_2484, 2) == 0 and 4 or 7, p4.skeleton_collision)

    local v8 = State2.begin_update(p4.biped_air.state)
    local offboard_feet = p4.offboard_feet

    p4.offboard_feet = State.default()
    import("skate_game/physics/offboard/air_feet").update_air(p4, offboard_feet)
    p4.offboard_feet = offboard_feet
    TruckSteeringState.update(p4.ground.steering, 0, p4.air_settings.steering_blend, flags_2468, flags_2472)

    local v9 = State2.animation_adjustment(p4.biped_air.state, rt.copy(p4.animation_input.fields.animation_end_com))

    if v9 ~= nil then
        AirSelector.adjust_animation(p4.offboard_air_selector, rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(v8), rt.to_u32(1))), v9, rt.copy(p4.biped_air.state.frame_144))
    end

    TrajectoryResult.reset(p4.biped_air.state.result)
    AirSelector.sample(p4.offboard_air_selector, v8, v2.DT, p4.biped_air.state.result)
    State2.orient_sample(p4.biped_air.state, p4.animation_input.extra.biped_start_angle, flags_2476)

    local v10 = State2.collision_response(p4.biped_air.state, rt.copy(p4.collision_extra_errors), rt.copy(v5), p4.offboard_air_selector.core.sampling.restart_allowed_8493)

    if v10.request_52 then
        Requests.request(p4.wipeout.state, 32, 0)
    end

    local restart = v10.restart

    if restart ~= nil then
        local v11 = v1.launch_packet(p4)
        local v12 = v1.height(p4)
        local v13 = projected_height(v12.bone15, v12.bone19, rt.copy(v7), rt.copy(v5))
        local v14 = State2.restart_packet(p4.biped_air.state, v11, rt.copy(restart), rt.copy(v7), rt.copy(v5), v13)

        v1.submit(p3, p4, v14)

        local v15 = v1.effective_frame(p4)

        State2.finish_restart(p4.biped_air.state, v15, rt.copy(restart))
    end

    State2.correct_restarted_sample(p4.biped_air.state)

    local v16 = v1.height(p4)

    State2.correct_height(p4.biped_air.state, v16)

    local v17 = v1.context(p4)

    AirSelector.requery(p4.offboard_air_selector, p3.world, v17, flags_2472, flags_2488)
    skeleton(p3, p4)
    State2.update_cadence(p4.biped_air.state, p4.biped_ground.controller.state, p4.animation_input.fields.cadence_end_percent)

    local v18 = import("skate_game/physics/offboard/contact_toolkit").StaticScene.new(p3.world)

    import("skate_game/physics/offboard/landing_deck").Owner.assist(p4.landing_deck, v18, p4.player_input, State2.landing_assist_limit(state_timer_2664))
    State2.finish_landing_latch(p4.biped_air.state)
end

function t1.update_reference(p6, p7, _) -- line: 156
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), projected_height (copy), State (copy), Requests (copy), TruckSteeringState (copy), State2 (copy), TrajectoryResult (copy), skeleton (ref)
    local AirSelector = import("skate_game/physics/offboard/air_selector").AirSelector
    local v19 = rt.copy(p7.player_input.processed)

    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request(p7.ground_lifecycle.skeleton_controller, bit32.band(v19.flags_2484, 2) == 0 and 4 or 7, p7.skeleton_collision)

    local v20 = State2.begin_update(p7.biped_air.state)
    local offboard_feet = p7.offboard_feet

    p7.offboard_feet = State.default()
    import("skate_game/physics/offboard/air_feet").update_air(p7, offboard_feet)
    p7.offboard_feet = offboard_feet
    TruckSteeringState.update(p7.ground.steering, 0, p7.air_settings.steering_blend, v19.flags_2468, v19.flags_2472)

    local v21 = State2.animation_adjustment(p7.biped_air.state, rt.copy(p7.animation_input.fields.animation_end_com))

    if v21 ~= nil then
        AirSelector.adjust_animation(p7.offboard_air_selector, rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(v20), rt.to_u32(1))), v21, rt.copy(p7.biped_air.state.frame_144))
    end

    TrajectoryResult.reset(p7.biped_air.state.result)
    AirSelector.sample(p7.offboard_air_selector, v20, v2.DT, p7.biped_air.state.result)
    State2.orient_sample(p7.biped_air.state, p7.animation_input.extra.biped_start_angle, v19.flags_2476)

    local v22 = v19.vectors_544_560_592_608[1]
    local v23 = rt.map(v22, rt.from_bits)
    local v24 = v19.vectors_544_560_592_608[3]
    local v25 = rt.map(v24, rt.from_bits)
    local v26 = State2.collision_response(p7.biped_air.state, rt.copy(p7.collision_extra_errors), rt.copy(v23), p7.offboard_air_selector.core.sampling.restart_allowed_8493)

    if v26.request_52 then
        Requests.request(p7.wipeout.state, 32, 0)
    end

    local restart = v26.restart

    if restart ~= nil then
        local v27 = v1.launch_packet(p7)
        local v28 = v1.height(p7)
        local v29 = projected_height(v28.bone15, v28.bone19, rt.copy(v25), rt.copy(v23))
        local v30 = State2.restart_packet(p7.biped_air.state, v27, rt.copy(restart), rt.copy(v25), rt.copy(v23), v29)

        v1.submit(p6, p7, v30)

        local v31 = v1.effective_frame(p7)

        State2.finish_restart(p7.biped_air.state, v31, rt.copy(restart))
    end

    State2.correct_restarted_sample(p7.biped_air.state)

    local v32 = v1.height(p7)

    State2.correct_height(p7.biped_air.state, v32)

    local v33 = v1.context(p7)

    AirSelector.requery(p7.offboard_air_selector, p6.world, v33, v19.flags_2472, v19.flags_2488)
    skeleton(p6, p7)
    State2.update_cadence(p7.biped_air.state, p7.biped_ground.controller.state, p7.animation_input.fields.cadence_end_percent)

    local v34 = import("skate_game/physics/offboard/contact_toolkit").StaticScene.new(p6.world)

    import("skate_game/physics/offboard/landing_deck").Owner.assist(p7.landing_deck, v34, p7.player_input, State2.landing_assist_limit(v19.state_timer_2664))
    State2.finish_landing_latch(p7.biped_air.state)
end

function t1.skeleton(p9, p10) -- line: 237
    -- upvalues: rt (copy), import (copy)
    local toolkit = p10.player_input.toolkit

    if toolkit == nil then
        error("BipedAir Skeleton requires the completed BoardToolkit", 0)
    end

    local v35 = rt.copy(toolkit.deck[3])
    local v36 = import("skate_game/physics/input_phase").collision(p10)
    local state = p10.biped_air.state
    local t2 = {
        frame_208 = rt.copy(state.frame_208),
        trajectory_position_272 = rt.copy(state.result.position_272),
        body_target_416 = rt.copy(state.body_target_416),
        lift_436 = state.body_offset_436,
        board_forward_96 = v35
    }
    local t3 = {
        animated = p10.animated_skeleton,
        body = p10.skeleton,
        drives = p10.skeleton_drives,
        ik = p10.foot_ik,
        animation_input = p10.animation_input,
        correction = p10.skeleton_output.correction,
        pose_errors = p10.pose_errors
    }
    local biped_ground, air_reckoning = p10.biped_ground, p10.air_reckoning
    local riding = p9.riding

    import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_biped_air(p10.skeleton_input, p10.skeleton_air, p9.board, t2, p10.player_input.processed, t3, p10.animation.packet.hierarchy, v36, rt.copy(p9.settings.step.simulation), function(p11, p12, p13) -- line: 277
        -- upvalues: biped_ground (copy), air_reckoning (copy), riding (copy), import (copy)
        import("skate_game/physics/biped_ground").Owner.finish_reckoning(biped_ground, p11, riding, air_reckoning, p12, p13)
    end)
end

skeleton = t1.skeleton

return t1
