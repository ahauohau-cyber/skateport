-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local v1 = import("skate_core/physics/manual/controller")
local v2 = import("skate_core/riding/anti_flip")
local v3 = import("skate_core/riding/ground_force")
local v4 = import("skate_core/riding/grounded/propulsion")
local GroundPropulsion = v4.GroundPropulsion
local v5 = import("skate_core/riding/grounded/drag")
local GroundDragInput, BodyInertias = v5.GroundDragInput, v5.BodyInertias
local v6 = import("skate_core/riding/heading")
local v7 = import("skate_core/riding/pumping")
local v8 = import("skate_core/riding/slide_friction")
local v9 = import("skate_core/riding/speed_model")
local v10 = import("skate_core/riding/straighten")
local v11 = import("skate_core/riding/grounded/state/corrections")

local function board() -- line: 28
    -- upvalues: import (copy)
    return import("skate_core/riding/grounded/state/board")
end

local ground_forces, apply_body_vectors, update_speed_model_reset, first_balance_selector, second_balance_selector, force_record, vector4
local t1 = {}

t1.OrdinaryGroundResult = {}

local function finish_tagged(p1, p2, ...) -- line: 52
    if p2 then
        return ...
    end

    error({
        tag = p1,
        (...)
    }, 0)

    return ...
end

function t1.update(p3, p4, p5, p6, p7, p8) -- line: 61
    -- upvalues: rt (copy), import (copy), BoardForceQueue (copy), v1 (copy), v2 (copy), v4 (copy), GroundPropulsion (copy), GroundDragInput (copy), BodyInertias (copy), v6 (copy), v7 (copy), v8 (copy), v9 (copy), v10 (copy), v11 (copy), ground_forces (ref), apply_body_vectors (ref), update_speed_model_reset (ref), force_record (ref), vector4 (ref), finish_tagged (copy)
    local service = import("skate_core/riding/grounded/state/board").service
    local v12, v13 = v4.calculate(p6.propulsion, p5.propulsion, 0)

    p3.push_suppressed_2730 = v13 ~= 0

    local v14, v15 = ground_forces(p5.ground_force, p6.ground_force)

    p6.speed_model.manual_state_276 = p4.manual.angular_correction

    local v16 = v9.update(p4.speed_model, p5.speed_model, p6.speed_model)

    p6.slide_friction.heading_time = p3.elapsed_2648

    local v17 = v8.calculate(p5.slide_friction, p6.slide_friction)
    local v18 = v7.calculate(p6.pump_force)

    p6.straighten.heading_time = p3.elapsed_2648

    local v19 = v10.calculate(p5.straighten, p6.straighten)
    local v20 = table.create(4)

    v20[1] = v19[1] * p3.straighten_scale_2672
    v20[2] = v19[2] * p3.straighten_scale_2672
    v20[3] = v19[3] * p3.straighten_scale_2672
    v20[4] = v19[4] * p3.straighten_scale_2672

    local v21, v22 = v6.calculate(p5.heading, p6.heading, p4.heading_previous)

    p4.heading_previous = v22

    local v23 = v2.calculate(p5.anti_flip, p6.anti_flip)

    p3.anti_flip_torque_2624 = rt.copy(v23)
    p6.manual.powersliding = false

    local calculate = v1.calculate
    local manual = p4.manual
    local manual2, manual_mode = p5.manual, p5.manual_mode
    local manual3 = p6.manual
    local Manual = finish_tagged("Manual", pcall(calculate, manual, manual2, manual_mode, manual3, p8))

    p3.manual_correction_2732 = Manual.correction_active
    p3.manual_opposition_2733 = Manual.opposing_motion_without_correction

    local v24 = GroundDragInput.calculate(p6.ground_drag, p5.linear_drag)
    local v25

    if Manual.correction_active then
        local v26 = GroundPropulsion.submit(v12, Manual, p4.force_queue)

        if v26.tag == "ManualCorrection" then
            v25 = v26[1]
        else
            error("internal error: entered unreachable code", 0)
        end
    else
        local v27 = vector4(v12.push.vector)

        if service("PushForceSquared", p8.dot3, p8, v27, rt.copy(v27)) > 1 then
            p3.flag_2721 = true
        end

        service("AntiFlipNudge", v11.update_anti_flip_nudge, p3, p6.anti_flip_nudge, p4.force_queue, p8)

        if p6.contact_time_2756 < p5.ground_force_contact_time_limit then
            BoardForceQueue.append(p4.force_queue, force_record(4, v14))
            BoardForceQueue.append(p4.force_queue, force_record(5, v15))
        end

        if GroundPropulsion.submit(v12, Manual, p4.force_queue).tag ~= "BrakingAndPush" then
            error("internal error: entered unreachable code", 0)
        end

        apply_body_vectors(p3, p5.collision_response_scale, p6.propulsion.timestep, v20, v21, v23, rt.copy(Manual.angular_displacement), p8)

        if bit32.band(p6.trajectory_state_1776_bits, 2147483648) == 0 then
            BoardForceQueue.append(p4.force_queue, force_record(6, v16))
        end

        BoardForceQueue.append(p4.force_queue, force_record(1, v17))
        BoardForceQueue.append(p4.force_queue, force_record(8, v18))
        p7.tag = 16
        v25 = BoardForceQueue.append(p4.force_queue, p7)
    end

    local apply_ground_drag = BodyInertias.apply_ground_drag
    local inertias = p4.inertias

    finish_tagged("Drag", pcall(apply_ground_drag, inertias, v24))

    local v28 = update_speed_model_reset(p4.speed_model, p5.speed_model_reset_force_squared, rt.copy(v12.braking.force_world), rt.copy(v12.push.vector), v18, p8)

    service("HangUps", v11.manage_hang_ups, p3, p6.hang_up, p8)
    service("HalfpipeWheelCatch", v11.manage_halfpipe_wheel_catches, p6.halfpipe_wheel_catch, p8)
    service("Pinning", v11.consider_pinning, p3, p6.pinning, p8)

    return {
        manual_correction = Manual.correction_active,
        terminal_force_tag = Manual.correction_active and 7 or 16,
        terminal_force_queued = v25,
        speed_model_reset = v28
    }
end

local t4 = {
    argument_1 = 0,
    application_z = 0,
    argument_3 = 0,
    argument_4 = 0,
    balance = 0,
    surface_speed = 0,
    axis_384 = false,
    velocity_400 = false,
    axis_544 = false
}

function ground_forces(p9, p10) -- line: 195
    -- upvalues: v3 (copy), first_balance_selector (ref), second_balance_selector (ref), t4 (copy)
    local v29

    if p10.processed_2776 == 0 or p10.processed_2780 < 0 then
        v29 = p10.ground_scalar_1232 * p10.previous_state_scalar_56

        if -v29 >= 0 then
            v29 = 0
        end
    else
        v29 = 0
    end

    t4.argument_1 = p10.argument_1_2752
    t4.application_z = p10.ground_scalar_1216
    t4.argument_3 = v29
    t4.argument_4 = first_balance_selector(p10.balance_2720)
    t4.balance = p10.balance_2720
    t4.surface_speed = p10.surface_speed_2656
    t4.axis_384 = p10.axis_384
    t4.velocity_400 = p10.velocity_400
    t4.axis_544 = p10.axis_544

    local v30 = v3.calculate(p9, t4)

    t4.argument_1 = p10.argument_1_2752
    t4.application_z = -p10.ground_scalar_1240
    t4.argument_3 = p10.ground_scalar_1236 * v29
    t4.argument_4 = second_balance_selector(p10.balance_2720)
    t4.balance = p10.balance_2720
    t4.surface_speed = p10.surface_speed_2656
    t4.axis_384 = p10.axis_384
    t4.velocity_400 = p10.velocity_400
    t4.axis_544 = p10.axis_544

    local v31 = v3.calculate(p9, t4)

    t4.axis_384 = false
    t4.velocity_400 = false
    t4.axis_544 = false

    return v30, v31
end

t1.ground_forces = ground_forces

function t1.ground_forces_reference(p11, p12) -- line: 234
    -- upvalues: rt (copy), v3 (copy), first_balance_selector (ref), second_balance_selector (ref)
    local v32

    if p12.processed_2776 == 0 or p12.processed_2780 < 0 then
        v32 = p12.ground_scalar_1232 * p12.previous_state_scalar_56

        if -v32 >= 0 then
            v32 = 0
        end
    else
        v32 = 0
    end

    local function common(p13, p14, p15) -- line: 240
        -- upvalues: p12 (copy), rt (copy)
        return {
            argument_1 = p12.argument_1_2752,
            application_z = p13,
            argument_3 = p14,
            argument_4 = p15,
            balance = p12.balance_2720,
            surface_speed = p12.surface_speed_2656,
            axis_384 = rt.copy(p12.axis_384),
            velocity_400 = rt.copy(p12.velocity_400),
            axis_544 = rt.copy(p12.axis_544)
        }
    end

    return v3.calculate(p11, (common(p12.ground_scalar_1216, v32, first_balance_selector(p12.balance_2720)))), (v3.calculate(p11, (common(-p12.ground_scalar_1240, p12.ground_scalar_1236 * v32, second_balance_selector(p12.balance_2720)))))
end

function apply_body_vectors(p16, p17, p18, p19, p20, p21, p22, p23) -- line: 269
    -- upvalues: rt (copy), import (copy)
    local service = import("skate_core/riding/grounded/state/board").service

    if p16.collision_countdown_2652 > 0 then
        p16.collision_countdown_2652 -= p18

        local v33 = table.create(4)

        v33[1] = p16.vector_2592[1] * p17
        v33[2] = p16.vector_2592[2] * p17
        v33[3] = p16.vector_2592[3] * p17
        v33[4] = p16.vector_2592[4] * p17
        p16.vector_2592 = v33
        service("ApplyCollisionDecay", p23.apply_vector_82c07000, p23, rt.copy(p16.vector_2592))
    end

    service("ApplyStraighten", p23.apply_vector_82c07000, p23, p19)
    service("ApplyHeading", p23.apply_vector_82c07000, p23, p20)
    service("ApplyAntiFlip", p23.apply_angular_displacement_82c075b8, p23, p21)
    service("ApplyManual", p23.apply_angular_displacement_82c075b8, p23, p22)
end

t1.apply_body_vectors = apply_body_vectors

function update_speed_model_reset(p24, p25, p26, p27, p28, p29) -- line: 287
    -- upvalues: rt (copy), import (copy)
    local service = import("skate_core/riding/grounded/state/board").service
    local t5 = {
        p27.x + p26.x + p28[1],
        p27.y + p26.y + p28[2],
        p27.z + p26.z + p28[3],
        p28[4]
    }

    if p25 < service("StrongForceSquared", p29.dot3, p29, t5, rt.copy(t5)) then
        p24.flags_1360 = bit32.bor(p24.flags_1360, 2147483648)

        return true
    end

    return false
end

t1.update_speed_model_reset = update_speed_model_reset

function first_balance_selector(p30) -- line: 305
    if p30 <= 0 then
        if p30 >= -0 then
            return 1
        end

        return 2
    end

    return 0
end

t1.first_balance_selector = first_balance_selector

function second_balance_selector(p31) -- line: 318
    local v34 = if p31 <= 0 then 1 else 2

    if p31 >= -0 then
        return v34
    end

    return 0
end

t1.second_balance_selector = second_balance_selector

function force_record(p32, p33) -- line: 328
    -- upvalues: Vector3 (copy)
    return {
        tag = p32,
        force_world = Vector3.new(p33[1], p33[2], p33[3]),
        point_body = Vector3.new(p33[5], p33[6], p33[7])
    }
end

t1.force_record = force_record

function vector4(p34) -- line: 337
    return {
        p34.x,
        p34.y,
        p34.z,
        0
    }
end

t1.vector4 = vector4

return t1
