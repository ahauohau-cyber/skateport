-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/hippy_jump")
local v2 = import("skate_core/player/offboard/landing_deck")
local Manager, GRAVITY, STEP = v2.Manager, v2.GRAVITY, v2.STEP
local wrap_angle = import("skate_core/player/wipeout_state/math").wrap_angle
local projected_angle = import("skate_core/player/wipeout_state/orientation").projected_angle
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local t1 = {
    UP = { 0, 1, 0, 0 },
    EPSILON = 1.52587890625E-05,
    Settings = {},
    State = {}
}

function t1.State.default() -- line: 37
    return {
        output = nil,
        time_to_land = 0,
        dangerous = false,
        near_deck = false,
        turning = false,
        hippy = false,
        takeoff_frames = 0,
        spin_rate = 0,
        applied_spin = 0,
        transition_angle = 0,
        accumulated_spin = 0,
        half_turns = 0,
        next_half_turns = 0
    }
end

t1.Entry = {}

function t1.State.enter(p1, p2, p3) -- line: 63
    -- upvalues: rt (copy), v1 (copy), Manager (copy), GRAVITY (copy), STEP (copy), wrap_angle (copy), projected_angle (copy), t1 (copy)
    local v3 = p3.previous_category == 500

    if not v3 then
        Manager.reset(p2)
    end

    rt.assign(p1, t1.State.default())

    local v4 = rt.from_fn(4, function(p4) -- line: 69
        -- upvalues: p3 (copy)
        local v5 = p3.animation_right[p4 + 1]

        if p3.reversed then
            return -v5
        end

        return v5
    end)

    p1.transition_angle = wrap_angle(projected_angle(p3.hips_up, v4, t1.UP))

    local v6, v7

    if p3.hippy then
        v6 = if p3.hippy then v1.calculate({
            desired_height = (1 - p3.strength) * 1.35 + p3.strength * 1.65,
            board_position = rt.copy(p3.board_position),
            centre_of_mass_position = rt.copy(p3.com_position),
            reference_up = rt.copy(p3.up),
            current_velocity = rt.copy(p3.board_velocity)
        }) else rt.copy(p3.com_velocity)
        v7 = false
    elseif v3 then
        v7 = true
    else
        v6 = if p3.hippy then v1.calculate({
            desired_height = (1 - p3.strength) * 1.35 + p3.strength * 1.65,
            board_position = rt.copy(p3.board_position),
            centre_of_mass_position = rt.copy(p3.com_position),
            reference_up = rt.copy(p3.up),
            current_velocity = rt.copy(p3.board_velocity)
        }) else rt.copy(p3.com_velocity)
        v7 = false
    end

    if v7 then
        p2.elapsed_160 += STEP
        Manager.correct_trajectory(p2, p3.com_position)
    else
        p2.trajectory_32 = {
            duration = -1,
            position = rt.copy(p3.com_position),
            velocity = v6,
            acceleration = rt.copy(GRAVITY)
        }
        p2.elapsed_160 = 0
        p2.trajectory_valid_164 = true
        p2.force_257 = p3.hippy

        if p3.hippy then
            p1.takeoff_frames = 2
        end
    end

    p1.hippy = p3.hippy
end

function t1.State.align(p5, p6, p7, p8, p9, p10, p11) -- line: 107
    -- upvalues: rt (copy), wrap_angle (copy), projected_angle (copy), t1 (copy)
    local v8 = p5.time_to_land * 59.999996
    local v9 = projected_angle(p7, p8, t1.UP)

    if p9 < 0.28 then
        v9 -= (1 - p9 * 3.5714285) * p5.transition_angle
    end

    local v10 = wrap_angle(p5.spin_rate * v8 + v9)

    p5.turning = math.abs(v10) > 1.5707963267948966

    if not (p5.time_to_land > t1.EPSILON) then
        return
    end

    local v11 = p10 > 0
    local v12 = if not (v11 and p5.hippy) then 0 else p11
    local v13, v14

    if math.abs(v12) > t1.EPSILON then
        v13 = -p6.input_speed * v12
        v14 = p6.input_delta
    else
        local v15 = v10

        if v11 then
            v15 = wrap_angle(v10)

            if math.abs(v15) > 1.5707963267948966 then
                v15 = (math.abs(v15) - 3.141592653589793) * rt.signum(v15)
            end
        end

        local v16 = p6.minimum_auto_angle * 0.017453292

        if v16 < math.abs(v15) then
            local v17 = if v15 > 0 then rt.fmax(v15 - v16, 0) else rt.fmin(v15 + v16, 0)

            v13 = rt.clamp(p5.spin_rate - v17 / v8, -p6.automatic_speed, p6.automatic_speed)
        else
            v13 = p5.spin_rate
        end

        v14 = p6.automatic_delta
    end

    p5.spin_rate = rt.clamp(v13, p5.spin_rate - v14, p5.spin_rate + v14)
    p5.applied_spin = p5.spin_rate

    if p9 < 0.28 then
        p5.applied_spin = -p5.transition_angle * 0.059523813 + p5.spin_rate
    end
end

function t1.State.advance_spin(p12, p13) -- line: 161
    -- upvalues: rt (copy)
    p12.accumulated_spin += p12.applied_spin
    p12.half_turns = rt.f_to_i32(p12.accumulated_spin * 0.31830987)
    p12.next_half_turns = p12.half_turns

    if not (p12.accumulated_spin < 0 and p12.applied_spin < 0) then
        if p12.accumulated_spin > 0 and p12.applied_spin > 0 then
            p12.next_half_turns += 1
        end
    else
        p12.next_half_turns -= 1
    end

    p12.time_to_land = p13.time_to_land
    p12.output = rt.copy(p13)
end

function t1.State.accurate_time(p14, p15, p16, p17, p18) -- line: 176
    -- upvalues: inverse_length_squared (copy)
    local v18 = (p17[1] + p17[2]) * 0.5 - 0.15000001
    local v19 = p16 - p15
    local v20 = p14 - v18
    local v21 = if p18 == 0 then -4.9 else -9.8
    local v22 = v19 * v19 + v20 * v21 * 2

    if v22 > 0 then
        local v23 = v22 * inverse_length_squared(v22, 2)

        return (-v19 - v23) / v21
    end

    return 0
end

function t1.State.finish(p19, p20, p21) -- line: 197
    if p19.takeoff_frames > 0 then
        p19.takeoff_frames -= 1
    end

    if p19.time_to_land < 0.07 then
        p19.dangerous = p21 < -p20.maximum_landing_speed
    else
        p19.dangerous = false
    end
end

function t1.State.landing_half_turns(p22) -- line: 204
    if p22.time_to_land >= 0.05 then
        return p22.half_turns
    end

    return p22.next_half_turns
end

function t1.State.requests_board_flip(p23) -- line: 212
    return p23.turning and p23.time_to_land < 0.02
end

return t1
