-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/air_phase/board")
local v2 = import("skate_game/physics/air_phase/input")
local v3 = import("skate_game/physics/air_phase/skeleton")
local v4 = import("skate_game/physics/air_trajectory")
local v5 = import("skate_game/physics/air_reckoning")
local v6 = import("skate_core/air/state")
local v7 = import("skate_core/air/trajectory")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local PointGraph = import("skate_core/point_graph").PointGraph
local AirState = import("skate_core/air/reckoning").AirState
local AirMath, angle_between_vectors, calculate_velocity_from_jump, integrate_trajectory_fixed_step = v6.AirMath, v6.angle_between_vectors, v6.calculate_velocity_from_jump, v6.integrate_trajectory_fixed_step
local wrap_signed_angle = v6.wrap_signed_angle
local TrajectorySelector = v7.TrajectorySelector
local AirTrajectoryRuntime = v4.AirTrajectoryRuntime
local AirReckoning = v5.AirReckoning

local function skeleton_controller() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function foot_ik() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function footplant() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local t1 = {}

local function deck_height(p1) -- line: 50
    -- upvalues: BoardRuntime (copy)
    local _, v8 = BoardRuntime.part_translation(p1, 6)

    return v8
end

t1.AirSettings = v2.AirSettings
t1.launch_info = v2.launch_info
t1.selector_input = v2.selector_input

local function air_math_trait() -- line: 64
    -- upvalues: AirMath (copy)
    local t2 = {}

    return {
        minimum_vminfp = function(_, p3, p4) -- minimum_vminfp | line: 67
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.minimum_vminfp(t2, p3, p4)
        end,
        length_squared_vmsum3fp = function(_, p6) -- length_squared_vmsum3fp | line: 70
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.length_squared_vmsum3fp(t2, p6)
        end,
        length_vmsum3fp_vrsqrte = function(_, p8) -- length_vmsum3fp_vrsqrte | line: 73
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.length_vmsum3fp_vrsqrte(t2, p8)
        end,
        clamp_vector_within_max_length = function(_, p10, p11) -- clamp_vector_within_max_length | line: 76
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.clamp_vector_within_max_length(t2, p10, p11)
        end
    }
end

t1.COM_ACCELERATION = { 0, -9.800000190734863, 0, 0 }

function t1.enter(p12, p13) -- line: 87
    -- upvalues: rt (copy), import (copy), v2 (copy), BoardRuntime (copy), HookDriveState (copy), AirMath (copy), calculate_velocity_from_jump (copy), t1 (copy), air_math_trait (copy)
    local v9 = v2.frame(p13)
    local ground_lifecycle = p13.ground_lifecycle

    ground_lifecycle.skeleton_controller.flag_18 = true

    local SkeletonControllerState = import("skate_game/physics/skeleton_controller").SkeletonControllerState

    SkeletonControllerState.request(ground_lifecycle.skeleton_controller, 7, p13.skeleton_collision)
    import("skate_game/physics/foot_ik").FootIk.enable_feet(p13.foot_ik, true)
    SkeletonControllerState.request(ground_lifecycle.skeleton_controller, 6, p13.skeleton_collision)
    ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p12.board).drive, ground_lifecycle.board_animated_290)
    p13.footplant.enabled = false
    import("skate_game/physics/footplant").Footplant.reset(p13.footplant)

    local air_state = p13.air_state

    air_state.selector_latch_174 = false
    air_state.reached_apex = false
    air_state.trajectory_query_countdown = 0
    air_state.landing_normal = { 0, 1, 0, 0 }
    air_state.time_in_state = 0

    local board = p12.board
    local _, v10 = BoardRuntime.part_translation(board, 6)

    air_state.max_y = v10
    air_state.start_y = v9.ground_position_y_500

    local v11, v12

    if v9.previous_physics_category_2516 == 400 or v9.previous_physics_state_2504 == 701 then
        v11 = bit32.band(v9.flags_2468, 16384) == 0
        v12 = false
    else
        local previous_physics_state_2504 = v9.previous_physics_state_2504

        v11 = not (previous_physics_state_2504 == 100 or previous_physics_state_2504 == 103 or previous_physics_state_2504 == 201)
        v12 = v11
    end

    air_state.use_centre_of_mass_velocity = v11

    if v11 then
        local v13 = rt.copy(v9.trajectory_velocity_608)

        if v9.previous_physics_state_2504 == 500 then
            v13[2] = AirMath.minimum_vminfp({}, v13[2] * 0.6499999761581421, 3)
        end

        if v9.frames_since_jump_correction_2576 < 12 then
            v13 = calculate_velocity_from_jump(v9, v9.frames_since_jump_correction_2576, (air_math_trait()))
        end

        air_state.centre_of_mass_trajectory = {
            scalar_48 = -1,
            position = rt.copy(v9.trajectory_position_592),
            velocity = v13,
            acceleration = rt.copy(t1.COM_ACCELERATION)
        }
    end

    if v12 then
        p13.animated_skeleton.roots.initialize_heading = true
    end
end

function t1.exit(p14) -- line: 137
    -- upvalues: AirState (copy)
    p14.air_state.use_centre_of_mass_velocity = false
    AirState.reset_spin(p14.air_reckoning.state)
end

function t1.advance(p15, p16) -- line: 143
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v3 (copy), v4 (copy), BoardRuntime (copy), PointGraph (copy), angle_between_vectors (copy), calculate_velocity_from_jump (copy), integrate_trajectory_fixed_step (copy), wrap_signed_angle (copy), TrajectorySelector (copy), AirTrajectoryRuntime (copy), AirReckoning (copy), t1 (copy), air_math_trait (copy)
    local v14 = v2.frame(p16)

    import("skate_game/physics/skeleton_controller").SkeletonControllerState.update_air(p16.ground_lifecycle.skeleton_controller, p16.player_input.processed.flags_2472, v14.current_velocity_400[2], p16.skeleton_collision)

    local air_state = p16.air_state

    air_state.trajectory_query_countdown = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(air_state.trajectory_query_countdown), rt.to_u32(1)))

    if air_state.trajectory_query_countdown <= 0 and bit32.band(v14.flags_2468, 32768) == 0 and v14.previous_physics_state_2504 ~= 0 and not TrajectorySelector.pending(p16.trajectory.selector) then
        local v15 = v2.launch_info(p15, p16)

        if v14.frames_since_jump_correction_2576 < 12 then
            v15.start_velocity = calculate_velocity_from_jump(v14, v14.frames_since_jump_correction_2576, (air_math_trait()))
        elseif p16.air_state.use_centre_of_mass_velocity then
            local v16 = rt.copy(p16.air_state.centre_of_mass_trajectory.velocity)

            v15.start_velocity = {
                t1.COM_ACCELERATION[1] * 0.01666666753590107 + v16[1],
                t1.COM_ACCELERATION[2] * 0.01666666753590107 + v16[2],
                t1.COM_ACCELERATION[3] * 0.01666666753590107 + v16[3],
                t1.COM_ACCELERATION[4] * 0.01666666753590107 + v16[4]
            }
            v15.start_position_override = rt.copy(v15.animation_com_position)
            v15.start_position_override[2] += -0.6499999761581421
            v15.board_position_override = rt.copy(v15.animation_com_position)
            v15.board_position_override[2] += -0.800000011920929
            v15.use_position_override = true
            v15.trajectory_count = 5
            v15.cone_angle_x *= 0.4000000059604645
            v15.cone_angle_z *= 0.4000000059604645
        end

        v15.player_jumped = false

        local v17 = v2.selector_input(p15, p16)

        AirTrajectoryRuntime.launch(p16.trajectory, v15, v17, p15.world)
        p16.air_state.trajectory_query_countdown = 7
    end

    local v18 = v2.selector_input(p15, p16)
    local toolkit = p16.player_input.toolkit

    if toolkit == nil then
        error("Air trajectory requires current board toolkit", 0)
    end

    local v19 = v4.GrindContext.from_processed(p16.player_input.processed, rt.copy(toolkit.deck[4]))

    AirTrajectoryRuntime.update(p16.trajectory, v18, p15.world, v19)

    local current_landing_normal_1152 = AirReckoning.fields(p16.air_reckoning, p15.riding).current_landing_normal_1152
    local v20 = TrajectorySelector.suggested_normal(p16.trajectory.selector)

    if v20 == nil then
        v20 = current_landing_normal_1152
    end

    local air_state2 = p16.air_state

    air_state2.landing_normal = rt.copy(v20)

    local state = p16.air_settings.state
    local v21 = if wrap_signed_angle(angle_between_vectors(v20, current_landing_normal_1152)) <= state.landing_normal_angle_limit_444 then state.landing_normal_blend_388 else 0

    if not air_state2.use_centre_of_mass_velocity then
        if not air_state2.selector_latch_174 then
            air_state2.selector_latch_174 = TrajectorySelector.all_predictions_missed(p16.trajectory.selector)
        end

        if air_state2.selector_latch_174 then
            air_state2.use_centre_of_mass_velocity = true
            air_state2.centre_of_mass_trajectory = {
                scalar_48 = -1,
                position = rt.copy(v14.trajectory_position_592),
                velocity = rt.copy(v14.trajectory_velocity_608),
                acceleration = rt.copy(t1.COM_ACCELERATION)
            }
        end
    end

    if v14.state_timer_2664 <= 0 then
        v21 = 0
    elseif bit32.band(v14.flags_2468, 16384) ~= 0 then
        air_state2.use_centre_of_mass_velocity = false
    end

    local v22 = v14.body_spin_input_2640 * state.body_spin_scale_428 * 0.01745329238474369
    local v23 = PointGraph.evaluate(state.body_spin_over_time_320, air_state2.time_in_state * 2) * v22

    AirReckoning.update(p16.air_reckoning, p15.riding, p16.player_input.processed, p16.animation_input.extra.physical_body_spin, v20, v21, v23, 0)

    if p16.air_state.use_centre_of_mass_velocity then
        integrate_trajectory_fixed_step(p16.air_state.centre_of_mass_trajectory)
        v3.advance(p15, p16, rt.copy(p16.air_state.centre_of_mass_trajectory.position))
    else
        v3.advance(p15, p16, nil)
    end

    v1.advance(p15, p16, v14)
    p16.skeleton_output.correction.pending = true

    local board = p15.board
    local _, v24 = BoardRuntime.part_translation(board, 6)
    local air_state3 = p16.air_state

    if not (v24 < air_state3.max_y) then
        air_state3.max_y = v24
    end

    air_state3.time_in_state += v14.delta_time_2604
end

function t1.update_apex(p17, p18) -- line: 260
    -- upvalues: BoardRuntime (copy)
    if not p18.reached_apex and BoardRuntime.bodies(p17.board)[7].rates.linear_velocity.y < 0 then
        p18.reached_apex = true
    end
end

return t1
