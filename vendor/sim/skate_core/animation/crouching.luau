-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {},
    AutoPumpSettings = {},
    Physical = {},
    Intents = {},
    State = {},
    Output = {}
}
local minimum, maximum, bound, nonnegative, unit

function t1.State.begin(p3, p4) -- line: 81
    -- upvalues: PointGraph (copy), unit (ref)
    local v9 = PointGraph.evaluate(p4.maximum_height, p3.body_164)

    return {
        absorbed_velocity = 0,
        filtered_input = 0,
        delta_fraction = 0,
        player_pumping = false,
        auto_fraction = 0,
        auto_state = 0,
        auto_time = 0,
        previous_angle = 0,
        previous_magnitude = 0,
        filtered_potential = 0,
        pump_idle_time = 0.5,
        fraction = 1 - unit((p3.animation_height_72 - p4.minimum_height) / (v9 - p4.minimum_height))
    }
end

function t1.State.update(p5, p6, p7, p8, p9) -- line: 102
    -- upvalues: v1 (copy), PointGraph (copy), minimum (ref), maximum (ref), bound (ref), nonnegative (ref), unit (ref)
    local v10 = -PointGraph.evaluate(p9.absorption_upforce, 1 - p5.fraction)
    local v11 = bound(-p6.force_516 / p9.maximum_force, -1, 1)

    p5.absorbed_velocity += p6.body_84
    p5.absorbed_velocity = p9.skateboard_damping * p5.absorbed_velocity

    if p5.absorbed_velocity < 0 then
        v11 = -v11
    end

    local v12 = bound(-p6.ground_force_520 / p9.maximum_ground_force, -1, 1)

    if v11 < 0 then
        if v12 > 0 then
            v11 = v12 + v11
        end
    else
        v11 = maximum(v11, v12)
    end

    if v11 < 0 then
        if not (v11 < v10) then
            v11 = v10
        end
    else
        v11 += v10
    end

    local v13 = if p7.auto_pump_angle == nil then 0 else p7.auto_pump_angle
    local v14 = if p7.auto_pump_magnitude == nil then 0 else p7.auto_pump_magnitude
    local auto_pump = p9.auto_pump
    local v15 = math.abs(p5.previous_angle) < auto_pump.intent_angle_region and p5.previous_magnitude < auto_pump.intent_magnitude_start and math.abs(v13) < auto_pump.intent_angle_region and auto_pump.intent_magnitude_start < v14

    p5.previous_angle = v13
    p5.previous_magnitude = v14
    p5.filtered_potential = p6.body_188 * auto_pump.potential_blend + (1 - auto_pump.potential_blend) * p5.filtered_potential

    local v16 = not (p5.filtered_potential < auto_pump.potential_threshold)

    if v15 then
        p5.auto_time = 0
        p5.auto_state = 1
    end

    if p5.auto_state == 1 and p5.auto_time > auto_pump.crouch_time then
        p5.auto_state = 2
    end

    if not ((p5.auto_state == 1 or p5.auto_state == 2) and p5.fraction > auto_pump.sufficient_crouch) then
        v16 = false
    end

    if v16 then
        p5.auto_state = 3
    end

    if (p5.auto_state == 2 or p5.auto_state == 3) and not (p5.fraction > auto_pump.standing_threshold + p6.minimum_crouch_528) then
        p5.auto_state = 0
    end

    local auto_state = p5.auto_state

    if auto_state == 0 then
        p5.auto_fraction = 0
    elseif auto_state == 1 then
        p5.auto_fraction = minimum(PointGraph.evaluate(auto_pump.maximum_crouch, p6.body_164), auto_pump.crouch_speed + p5.auto_fraction)
        p5.auto_time = minimum(auto_pump.crouch_time + 1, p8 + p5.auto_time)
    elseif auto_state == 2 then
        p5.auto_fraction = nonnegative(p5.auto_fraction - auto_pump.rise_speed)
    elseif auto_state == 3 then
        p5.auto_fraction = nonnegative(p5.auto_fraction - auto_pump.pump_speed)
    end

    local v17 = if p7.crouch == nil then 0 else p7.crouch

    if not p7.motion_flag_108 then
        v17 = maximum(v17, if p7.hard_turn_crouch == nil then 0 else p7.hard_turn_crouch)
    end

    if p7.motion_flag_108 and p7.manual ~= nil and p7.manual < 0 then
        v17 = maximum(v17, 0.4000000059604645)
    end

    local v18 = unit(p9.input_blend)

    p5.filtered_input = maximum(v17, p5.auto_fraction) * v18 + (1 - v18) * p5.filtered_input

    if math.abs(p5.filtered_input) < 0.004999999888241291 then
        p5.filtered_input = 0
    end

    local v19 = p9.absorption_factor * v11

    if not (v17 > 0) and not (p5.auto_fraction > 0) and (not p5.player_pumping or not (p5.fraction > p6.minimum_crouch_528)) then
        p5.player_pumping = false

        local v20 = p5.pump_idle_time + 0.01666666753590107
        local v21

        if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
            local v22 = math.abs(v20) * 7.1362384635298E+44
            local v23 = math.floor(v22)
            local v24 = v22 - v23

            v21 = (if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23) * 1.401298464324817E-45

            if v20 < 0 then
                v21 = -v21
            end
        else
            buffer.writef32(v1, 0, v20)
            v21 = buffer.readf32(v1, 0)
        end

        p5.pump_idle_time = v21
    else
        p5.player_pumping = true
        v19 = maximum(minimum(1, maximum(p6.minimum_crouch_528, p5.filtered_input)) - p5.fraction, -p9.maximum_delta)
        p5.pump_idle_time = 0
    end

    local v25 = p5.pump_idle_time < 0.5
    local v26 = -(PointGraph.evaluate(p9.pump_maxspeed, 1 - p5.fraction) * p9.pump_vertical_speed)
    local v27 = PointGraph.evaluate(p9.pump_maxspeed, p5.fraction) * p9.pump_vertical_speed
    local v28 = bound(v19, v26, v27)

    p5.delta_fraction = bound(v28, p5.delta_fraction - p9.maximum_delta_delta, p9.maximum_delta_delta + p5.delta_fraction)
    p5.fraction = bound(p5.fraction + p5.delta_fraction, p6.minimum_crouch_528, 1)

    local v29 = p9.maximum_crouch_from_deck * p6.deck_angle_532

    if p5.fraction < v29 then
        p5.fraction = v29
    end

    local v30 = unit(-p9.maximum_ratio * p5.fraction + 1)

    return {
        height = (PointGraph.evaluate(p9.maximum_height, p6.body_164) - p9.minimum_height) * v30 + p9.minimum_height,
        new_auto_pump = v16,
        player_controlled_pump = v25
    }
end

function t1.minimum(p10, p11) -- line: 220
    if p10 - p11 >= 0 then
        return p11
    end

    return p10
end

minimum = t1.minimum

function t1.maximum(p12, p13) -- line: 229
    if p12 - p13 >= 0 then
        return p12
    end

    return p13
end

maximum = t1.maximum

function t1.bound(p14, p15, p16) -- line: 238
    -- upvalues: minimum (ref), maximum (ref)
    return minimum(p16, maximum(p15, p14))
end

bound = t1.bound

function t1.nonnegative(p17) -- line: 243
    if -p17 >= 0 then
        return 0
    end

    return p17
end

nonnegative = t1.nonnegative

function t1.unit(p18) -- line: 252
    -- upvalues: minimum (ref), nonnegative (ref)
    return minimum(1, nonnegative(p18))
end

unit = t1.unit

return t1
