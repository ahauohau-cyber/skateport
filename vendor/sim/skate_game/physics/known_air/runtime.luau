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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_game/physics/known_air/math")
local v9 = import("skate_game/physics/known_air/flip")
local sub, dot, scale, xyz = v8.sub, v8.dot, v8.scale, v8.xyz
local v10 = import("skate_core/air/trajectory")
local Trajectory, TrajectorySelector = v10.Trajectory, v10.TrajectorySelector
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState

local function input_phase() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_controller() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function foot_ik() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function footplant() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function skeleton_input_runtime() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function air_reckoning() -- line: 58
    -- upvalues: import (copy)
    return import("skate_game/physics/air_reckoning")
end

local function wipeout() -- line: 61
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local function solve() -- line: 64
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function grind_world() -- line: 67
    -- upvalues: import (copy)
    return import("skate_game/grind_world")
end

local function grind_target() -- line: 70
    -- upvalues: import (copy)
    return import("skate_core/air/trajectory/grind")
end

local function grind_air() -- line: 73
    -- upvalues: import (copy)
    return import("skate_core/physics/grind_air")
end

local function steering() -- line: 76
    -- upvalues: import (copy)
    return import("skate_core/riding/steering")
end

local v11 = BoardRuntime.transform_scratch()
local t1 = {}

t1.Runtime = {}

for v12, v13 in v8.Runtime do
    t1.Runtime[v12] = v13
end

for v14, v15 in v9.Runtime do
    t1.Runtime[v14] = v15
end

local Runtime = t1.Runtime

function t1.Runtime.new(p4, p5) -- line: 111
    -- upvalues: rt (copy), TrajectorySelector (copy)
    local selector = p5.trajectory.selector
    local v16 = TrajectorySelector.selection(selector)

    if v16 == nil then
        error("KnownAir requires its actual winning query result", 0)
    end

    local v17 = rt.copy(v16)
    local v18 = TrajectorySelector.local_com_position(selector)

    if v18 == nil then
        error("KnownAir requires selector local COM", 0)
    end

    local v19 = TrajectorySelector.board_position(selector)

    if v19 == nil then
        error("KnownAir requires selector board position", 0)
    end

    local toolkit = p5.player_input.toolkit

    if toolkit == nil then
        error("KnownAir requires prepared board toolkit", 0)
    end

    return {
        error = nil,
        physics = p4,
        skater = p5,
        toolkit = rt.copy(toolkit),
        selection = v17,
        local_com = rt.copy(v18),
        board_position = rt.copy(v19)
    }
end

function t1.Runtime.finish(p6) -- line: 142
    if p6.error ~= nil then
        error(p6.error, 0)
    end
end

function t1.Runtime.record(p7, p8) -- line: 150
    if p7.error == nil then
        p7.error = p8
    end
end

local function attempt(p9, p10, ...) -- line: 157
    -- upvalues: Runtime (copy)
    local ok, result = pcall(p10, ...)
    local record = Runtime.record

    if ok then
        result = nil
    end

    record(p9, result)
end

function t1.trajectory(p11) -- line: 163
    -- upvalues: rt (copy), v1 (copy)
    local t2 = {
        position = rt.copy(p11.position),
        velocity = rt.copy(p11.velocity),
        acceleration = rt.copy(p11.acceleration),
        scalar_48 = p11.duration
    }
    local duration = p11.duration
    local v20

    if duration ~= 0 and duration > -1.1754943508222875E-38 and duration < 1.1754943508222875E-38 then
        local v21 = math.abs(duration) * 7.1362384635298E+44
        local v22 = math.floor(v21)
        local v23 = v21 - v22

        v20 = if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22

        if duration < 0 then
            v20 += 2147483648
        end
    else
        buffer.writef32(v1, 0, duration)
        v20 = buffer.readu32(v1, 0)
    end

    t2.word_52 = v20

    local duration2 = p11.duration
    local v24

    if duration2 ~= 0 and duration2 > -1.1754943508222875E-38 and duration2 < 1.1754943508222875E-38 then
        local v25 = math.abs(duration2) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

        if duration2 < 0 then
            v24 += 2147483648
        end
    else
        buffer.writef32(v1, 0, duration2)
        v24 = buffer.readu32(v1, 0)
    end

    t2.word_56 = v24

    local duration3 = p11.duration
    local v28

    if duration3 ~= 0 and duration3 > -1.1754943508222875E-38 and duration3 < 1.1754943508222875E-38 then
        local v29 = math.abs(duration3) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

        if duration3 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, duration3)
        v28 = buffer.readu32(v1, 0)
    end

    t2.word_60 = v28

    return t2
end

local trajectory = t1.trajectory

function t1.actual(p12) -- line: 179
    -- upvalues: rt (copy)
    return {
        position = rt.copy(p12.position),
        velocity = rt.copy(p12.velocity),
        acceleration = rt.copy(p12.acceleration),
        duration = p12.scalar_48
    }
end

local actual = t1.actual

function t1.Runtime.enable_board_angular_drive_only(p13) -- line: 191
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    local ground_lifecycle = p13.skater.ground_lifecycle

    ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p13.physics.board).drive, ground_lifecycle.board_animated_290)
end

function t1.Runtime.set_air_collision_update_enabled(p14, p15) -- line: 197
    p14.skater.ground_lifecycle.skeleton_controller.flag_18 = p15
end

function t1.Runtime.set_skeleton_collision_state(p16, p17) -- line: 201
    -- upvalues: import (copy), attempt (copy)
    attempt(p16, import("skate_game/physics/skeleton_controller").SkeletonControllerState.request, p16.skater.ground_lifecycle.skeleton_controller, p17, p16.skater.skeleton_collision)
end

function t1.Runtime.set_skeleton_physics_truck_tilt_enabled(p18, p19) -- line: 211
    p18.skater.ground_lifecycle.skeleton_elapsed_16505 = p19
end

function t1.Runtime.set_skeleton_inverse_kinematics_enabled(p20, p21) -- line: 215
    -- upvalues: import (copy)
    import("skate_game/physics/foot_ik").FootIk.enable_feet(p20.skater.foot_ik, p21)
end

function t1.Runtime.reset_reckoning_flipping(p22) -- line: 219
    -- upvalues: Runtime (copy)
    Runtime.reset_flip(p22)
end

function t1.Runtime.set_footplant_flag_240(p23, p24) -- line: 223
    p23.skater.footplant.enabled = p24
end

function t1.Runtime.reset_footplants(p25) -- line: 227
    -- upvalues: import (copy)
    import("skate_game/physics/footplant").Footplant.reset(p25.skater.footplant)
end

function t1.Runtime.board_transform_height(p26) -- line: 234
    -- upvalues: BoardRuntime (copy)
    local _, v32 = BoardRuntime.part_translation(p26.physics.board, 6)

    return v32
end

function t1.Runtime.skeleton_com_position(p27) -- line: 242
    -- upvalues: rt (copy)
    return rt.copy(p27.skater.animated_skeleton.board_frames.centre_of_mass)
end

function t1.Runtime.selector_targeting_grind(p28) -- line: 246
    -- upvalues: TrajectorySelector (copy)
    return TrajectorySelector.grind_locked_to_middle(p28.skater.trajectory.selector)
end

function t1.Runtime.start_grind_air_adjust_from_selector(p29) -- line: 250
    -- upvalues: rt (copy), import (copy), Runtime (copy)
    local grind = p29.selection.grind

    if grind ~= nil then
        import("skate_core/physics/grind_air").GrindAir.start(p29.skater.skeleton_input.grind_air, import("skate_core/air/trajectory/grind").GrindTarget.air_target(rt.copy(grind)))
        p29.skater.skeleton_input.grind_air_started = true
    else
        Runtime.record(p29, "KnownAir grind lock has no accepted trajectory target")
    end
end

function t1.Runtime.selector_closest_trajectory_point(p30, p31, p32) -- line: 264
    -- upvalues: sub (copy), dot (copy), Trajectory (copy)
    local com_trajectory = p30.selection.com_trajectory
    local n1 = 1E+08
    local v33 = p32

    for i = 0, 99 do
        local v34 = sub(p31, Trajectory.position_at(com_trajectory, i * 0.01666666753590107))
        local v35 = dot(v34, v34)

        if n1 < v35 then
            return i - 1, v33
        end

        v33 = v34
        n1 = v35
    end

    return 0, p32
end

function t1.Runtime.selected_prediction(p33) -- line: 281
    -- upvalues: rt (copy), trajectory (copy)
    return {
        trajectory = trajectory(p33.selection.prediction.request.trajectory),
        collision_time_48 = p33.selection.prediction.result.contact_time,
        collision_frame_128 = rt.copy(p33.selection.prediction.result.contact_frame)
    }
end

function t1.Runtime.selector_trajectory_2704(p34) -- line: 290
    -- upvalues: trajectory (copy)
    return trajectory(p34.selection.com_trajectory)
end

function t1.Runtime.selector_contact_position(p35) -- line: 294
    -- upvalues: rt (copy)
    return rt.copy(p35.selection.prediction.result.contact_position)
end

function t1.Runtime.selector_vector_2848(p36) -- line: 298
    -- upvalues: rt (copy)
    return rt.copy(p36.board_position)
end

function t1.Runtime.selector_com_position_2784(p37) -- line: 302
    -- upvalues: rt (copy)
    return rt.copy(p37.local_com)
end

function t1.Runtime.highest_trajectory_position(_, p39) -- line: 307
    -- upvalues: Trajectory (copy), actual (copy)
    return Trajectory.highest_position(actual(p39))
end

function t1.Runtime.selector_has_just_changed(p40) -- line: 311
    -- upvalues: TrajectorySelector (copy)
    return TrajectorySelector.just_changed(p40.skater.trajectory.selector)
end

function t1.Runtime.reset_trajectory_selector(p41) -- line: 315
    -- upvalues: TrajectorySelector (copy)
    TrajectorySelector.reset(p41.skater.trajectory.selector)
end

function t1.Runtime.begin_reckoning_body_flip(p42, p43) -- line: 319
    -- upvalues: Runtime (copy)
    Runtime.begin_flip(p42, p43)
end

function t1.Runtime.update_air_collision(p44) -- line: 323
    -- upvalues: v1 (copy), import (copy), attempt (copy)
    local processed = p44.skater.player_input.processed
    local update_air = import("skate_game/physics/skeleton_controller").SkeletonControllerState.update_air
    local skeleton_controller = p44.skater.ground_lifecycle.skeleton_controller
    local flags_2472 = processed.flags_2472

    buffer.writeu32(v1, 0, processed.vectors_400_416[1][2])
    attempt(p44, update_air, skeleton_controller, flags_2472, buffer.readf32(v1, 0), p44.skater.skeleton_collision)
end

function t1.Runtime.grind_air_adjust_started(p45) -- line: 335
    return p45.skater.skeleton_input.grind_air_started
end

function t1.Runtime.set_grind_air_adjust_started(p46, p47) -- line: 339
    p46.skater.skeleton_input.grind_air_started = p47
end

function t1.Runtime.set_grind_air_adjust_activated(p48, p49) -- line: 343
    p48.skater.skeleton_input.grind_air_active = p49
end

function t1.Runtime.grind_air_adjust_adjusting(p50) -- line: 347
    return p50.skater.skeleton_input.grind_air_adjusting
end

function t1.Runtime.disable_grind_foot_collision(p51, p52) -- line: 352
    local v37

    if p52 == "Body3152" then
        v37 = 15
    elseif p52 == "Body3156" then
        v37 = 16
    elseif p52 == "Body3160" then
        v37 = 17
    elseif p52 == "Body3168" then
        v37 = 19
    elseif p52 == "Body3172" then
        v37 = 20
    elseif p52 == "Body3176" then
        v37 = 21
    else
        error("unreachable GrindFootBody " .. tostring(p52), 0)
    end

    local skeleton_collision = p51.skater.skeleton_collision

    skeleton_collision.pending_reenable = true
    skeleton_collision.disable_count[v37 + 1] = 2
    skeleton_collision.parts[v37 + 1].enabled = false
end

function t1.Runtime.update_reckoning_air_states(p53, p54, p55, p56, p57) -- line: 375
    -- upvalues: import (copy), attempt (copy)
    attempt(p53, import("skate_game/physics/air_reckoning").AirReckoning.update, p53.skater.air_reckoning, p53.physics.riding, p53.skater.player_input.processed, p53.skater.animation_input.extra.physical_body_spin, p54, p55, p56, p57)
end

function t1.Runtime.update_known_air_skeleton(p58, p59) -- line: 391
    -- upvalues: import (copy), attempt (copy)
    local v38 = import("skate_game/physics/input_phase").collision(p58.skater)
    local skater = p58.skater
    local t3 = {
        animated = skater.animated_skeleton,
        body = skater.skeleton,
        drives = skater.skeleton_drives,
        ik = skater.foot_ik,
        animation_input = skater.animation_input,
        correction = skater.skeleton_output.correction,
        pose_errors = skater.pose_errors
    }
    local packet = skater.animation.packet

    attempt(p58, import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_known_air, skater.skeleton_input, skater.skeleton_air, p58.physics.board, p58.physics.riding.reckoning_frames.system, p59, packet, skater.player_input.processed, t3, packet.hierarchy, v38, p58.physics.settings.step.simulation)
end

function t1.Runtime.set_skeleton_add_skateboard_error(p60, p61) -- line: 422
    p60.skater.skeleton_output.correction.pending = p61
end

function t1.Runtime.set_head_tracking_target(p62, p63, p64) -- line: 426
    -- upvalues: rt (copy)
    p62.skater.skeleton_input.head_tracking_history[6] = rt.copy(p63)
    p62.skater.skeleton_input.head_tracking_active = p64
end

function t1.Runtime.update_board_steering_tilt(p65, p66) -- line: 431
    -- upvalues: import (copy)
    local processed = p65.skater.player_input.processed

    import("skate_core/riding/steering").TruckSteeringState.update(p65.skater.ground.steering, p66, p65.skater.air_settings.steering_blend, processed.flags_2468, processed.flags_2472)
end

function t1.Runtime.shift_footplant_trajectory_to_index(_, p68, p69) -- line: 443
    -- upvalues: Trajectory (copy), actual (copy)
    local v39 = actual(p68)
    local v40 = p69 * 0.01666666753590107

    p68.position = Trajectory.position_at(v39, v40)
    p68.velocity = Trajectory.velocity_at(v39, v40)
end

local function footplant_frame(p70) -- line: 451
    -- upvalues: import (copy)
    local gravity_acceleration = p70.physics.settings.step.simulation.gravity_acceleration

    return {
        processed = p70.skater.player_input.processed,
        toolkit = p70.toolkit,
        animated = p70.skater.animated_skeleton,
        body = p70.skater.skeleton,
        gravity = {
            gravity_acceleration.x,
            gravity_acceleration.y,
            gravity_acceleration.z,
            0
        },
        world = p70.physics.world,
        edges = import("skate_game/grind_world").StaticProvider.primitives(p70.physics.grind_world)
    }
end

function t1.Runtime.update_footplant_prediction(p71, p72) -- line: 464
    -- upvalues: import (copy), footplant_frame (copy)
    local v41 = footplant_frame(p71)

    import("skate_game/physics/footplant").Footplant.update_candidate(p71.skater.footplant, p72, v41)
end

function t1.Runtime.update_footplant_lock(p73, p74) -- line: 469
    -- upvalues: import (copy)
    import("skate_game/physics/footplant").Footplant.update_launch(p73.skater.footplant, p74)
end

function t1.Runtime.update_footplant_pose(p75, p76) -- line: 473
    -- upvalues: import (copy), attempt (copy), footplant_frame (copy)
    local v42 = footplant_frame(p75)

    attempt(p75, import("skate_game/physics/footplant").Footplant.consume_and_submit, p75.skater.footplant, p76, v42, p75.skater.foot_ik, p75.skater.skeleton_collision)
end

function t1.Runtime.board_body_velocity(p77) -- line: 486
    -- upvalues: BoardRuntime (copy)
    local linear_velocity = BoardRuntime.bodies(p77.physics.board)[7].rates.linear_velocity

    return {
        linear_velocity.x,
        linear_velocity.y,
        linear_velocity.z,
        0
    }
end

function t1.Runtime.set_board_velocity(p78, p79) -- line: 491
    -- upvalues: xyz (copy), BoardRuntime (copy)
    for _, v43 in BoardRuntime.bodies_mut(p78.physics.board) do
        v43.rates.linear_velocity = xyz(p79)
    end
end

function t1.Runtime.board_forward_axis(p80) -- line: 497
    -- upvalues: scale (copy), BoardRuntime (copy), v11 (copy)
    local v44 = BoardRuntime.part_transform_into(p80.physics.board, 6, v11).basis.columns[3]

    return scale({
        v44[1],
        v44[2],
        v44[3],
        0
    }, if bit32.band(p80.skater.player_input.processed.flags_2468, 1048576) == 0 then 1 else -1)
end

function t1.Runtime.check_for_air_wipeout(p81, p82) -- line: 515
    -- upvalues: rt (copy), import (copy), TrajectorySelector (copy), attempt (copy)
    local skater = p81.skater
    local t5 = {
        processed = skater.player_input.processed,
        board = p81.physics.riding.ground,
        collision = skater.collision_feedback,
        deck = import("skate_game/physics/solve").deck_frame(p81.physics.board),
        input_board = rt.copy(skater.animated_skeleton.board_frames.animation_target),
        world_to_animation = rt.copy(skater.animated_skeleton.roots.world_to_animation),
        pose_error = rt.copy(skater.collision_pose_error),
        maximum_pose_error = skater.collision_maximum_error,
        jump_fix_frames = skater.player_state.post.jump_fix_frames,
        air = skater.air_reckoning.state,
        system_up_y = p81.physics.riding.reckoning_frames.system[2][2],
        grind_locked_to_middle = TrajectorySelector.grind_locked_to_middle(skater.trajectory.selector),
        grind_normal = TrajectorySelector.grind_normal(skater.trajectory.selector)
    }

    attempt(p81, import("skate_game/physics/wipeout").Wipeout.check_air, skater.wipeout, t5, p82)
end

function t1.Runtime.reckoning_com_transform_816(p83) -- line: 536
    -- upvalues: rt (copy)
    return {
        vectors = rt.copy(p83.physics.riding.reckoning_frames.system)
    }
end

return t1
