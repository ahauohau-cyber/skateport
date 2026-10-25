-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local BodyInertias = import("skate_core/riding/grounded/drag").BodyInertias
local v1 = import("skate_core/riding/grounded/manual_entry")
local PumpingState = import("skate_core/riding/pumping/state").PumpingState
local SpeedWobbleState = import("skate_core/riding/speed_wobble").SpeedWobbleState
local enter_call
local t1 = {}

t1.GroundEnterInput = {}
t1.GroundEnterStage = {}
t1.GroundEnterError = {}
t1.GroundEnterResult = {}
t1.GroundEntryComponents = {}

local function finish_manual_projection(p1, ...) -- line: 65
    if p1 then
        return ...
    end

    error({
        tag = "ManualProjection",
        stage = "EnterManual",
        source = ...
    }, 0)

    return ...
end

function t1.enter(p2, p3, p4, p5, p6, p7) -- line: 75
    -- upvalues: BoardForceQueue (copy), v1 (copy), PumpingState (copy), SpeedWobbleState (copy), enter_call (ref), finish_manual_projection (copy)
    enter_call("SetBoardStandard", p7.set_board_standard_82c03af8, p7)
    enter_call("InitializeSkeleton", p7.initialize_ground_skeleton, p7)
    enter_call("SetCollisionState", p7.set_collision_state_82d911a8, p7, 6)
    p2.word_2560 = 0
    p2.word_2564 = 0
    p2.flag_2708 = false
    p2.controls_latched_2725 = false
    p2.captured_position_valid_2726 = false
    p2.was_pinning_2728 = false
    p2.flag_2731 = false
    p2.manual_correction_2732 = false
    p2.manual_opposition_2733 = false
    enter_call("ResetExternalObjects", p7.reset_ground_external_objects, p7)
    enter_call("InitializeBoardSpeed", p7.initialize_board_speed_82d375d0, p7)
    SpeedWobbleState.reset(p3.speed_wobble)

    local enter_ground = v1.enter_ground
    local manual = p3.manual
    local previous_category_2516, powerslide_exit_scale, manual_ground = p4.previous_category_2516, p4.powerslide_exit_scale, p4.manual_ground

    finish_manual_projection(pcall(enter_ground, manual, previous_category_2516, powerslide_exit_scale, manual_ground, p5, p6))

    if p4.previous_category_2516 == 200 then
        enter_call("EnterFromAir", p7.enter_from_air_82bf2f18, p7)
    end

    local t3 = {
        landing_force_attempted = false,
        landing_force_queued = false
    }

    if p4.previous_state_2504 == 503 then
        local v2 = enter_call("BuildLandingOnDeckForce", p7.landing_on_deck_force, p7)

        v2.tag = 19
        t3.landing_force_attempted = true
        t3.landing_force_queued = BoardForceQueue.append(p3.force_queue, v2)
    end

    if p4.previous_state_2504 == 101 then
        p2.straighten_scale_2672 = 0.1599999964237213
    else
        p2.straighten_scale_2672 = 1
    end

    PumpingState.reset(p3.pumping)
    enter_call("SetControllerMode", p7.set_controller_mode_one, p7)
    p2.steering_push_scalar_2640 = 1
    p2.steering_damped_turn_2644 = 0
    p2.elapsed_2648 = 0
    p2.collision_countdown_2652 = 0
    p2.vector_2592 = table.create(4, 0)
    p2.vector_2608 = table.create(4, 0)
    p2.anti_flip_torque_2624 = table.create(4, 0)
    p2.hang_detection_frames_2740 = 0
    p2.hang_force_frames_2744 = 0
    p2.hung_wipeout_frames_2748 = 0
    p2.anti_flip_nudge_frames_2752 = 0
    p2.flag_2721 = false
    p2.anti_flip_nudge_applied_2723 = false
    p2.push_suppressed_2730 = false

    return t3
end

t1.GroundExitStage = {}
t1.GroundExitError = {}

local function finish_exit_drag(p8, ...) -- line: 157
    if p8 then
        return ...
    end

    error({
        tag = "Drag",
        (...)
    }, 0)

    return ...
end

local function finish_exit_service(p9, p10, ...) -- line: 164
    if p10 then
        return ...
    end

    error({
        tag = "Service",
        stage = p9,
        source = ...
    }, 0)

    return ...
end

function t1.exit(p11, p12, p13, p14) -- line: 172
    -- upvalues: rt (copy), BodyInertias (copy), PumpingState (copy), finish_exit_drag (copy), finish_exit_service (copy)
    p11.steering_damped_turn_2644 = 0
    p11.steering_push_scalar_2640 = 1
    PumpingState.reset(p12)

    local set_linear_drag = BodyInertias.set_linear_drag
    local t6 = {
        tag = "AllParts"
    }

    finish_exit_drag(pcall(set_linear_drag, p13, 0, t6))

    local set_default_wheel_materials = p14.set_default_wheel_materials

    finish_exit_service("SetWheelMaterials", pcall(set_default_wheel_materials, p14))

    if p11.flag_2708 then
        local restore_animated_board_velocity = p14.restore_animated_board_velocity
        local copy = rt.copy
        local vector_2688 = p11.vector_2688

        finish_exit_service("RestoreAnimatedBoardVelocity", pcall(restore_animated_board_velocity, p14, copy(vector_2688)))
    end
end

local function finish_enter_call(p15, p16, ...) -- line: 186
    if p16 then
        return ...
    end

    error({
        tag = "Service",
        stage = p15,
        source = ...
    }, 0)

    return ...
end

function enter_call(p17, p18, ...) -- line: 196
    -- upvalues: finish_enter_call (copy)
    return finish_enter_call(p17, pcall(p18, ...))
end

t1.enter_call = enter_call

return t1
