-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    GROUND_PUMPING_TIMESTEP = 0.01666666753590107,
    PumpingSample = {},
    PumpingGeometry = {}
}

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 47
    -- upvalues: rt (copy), PointGraph (copy), t1 (copy)
    p1.pump_acceleration = 0

    local v1 = p6.height(p6, p4.normal, p4.com_to_deck_world)

    if p1.record_valid then
        p1.intentional_pumping = p4.intentional_pumping

        local v2 = v1 - p1.previous_height

        if not (v2 >= 0) then
            v2 = 0
        end

        local v3 = (1 - p2.height_change_damping) * p1.smoothed_height_change
        local v4 = v2 * p2.height_change_damping + v3

        p1.smoothed_height_change = v4

        if v4 < p2.minimum_height_change then
            v4 = 0
        end

        if v4 > 0 then
            p1.pumping_time += p5
        else
            p1.pumping_time = 0
        end

        if math.abs(v4) > p2.maximum_height_change then
            v4 = (if not (v4 >= 0) then -1 elseif v4 > 0 then 1 else 0) * p2.maximum_height_change
        end

        local v5 = PointGraph.evaluate(p2.pump_vs_time, p1.pumping_time) * v4
        local v6 = t1.calculate(p1, p2, p4, p5, p6)

        p1.pumping = v6

        local v7 = v6 * (if v6 * v5 > 0 then p3.acceleration_factor else p3.absorption_factor) * v5
        local v8 = -(p3.maximum_absorption_per_second * p5)
        local v9 = p3.maximum_acceleration_per_second * p5

        if not (v8 - v7 >= 0) then
            v8 = v7
        end

        if v9 - v8 >= 0 then
            p1.pump_acceleration = v8
        else
            p1.pump_acceleration = v9
        end
    end

    p1.previous_position = rt.copy(p4.position)
    p1.previous_normal = rt.copy(p4.normal)
    p1.record_valid = true
    p1.previous_height = v1
end

function t1.update_ground(p7, p8, p9, p10, p11) -- line: 119
    -- upvalues: t1 (copy)
    return t1.update(p7, p8, p9, p10, t1.GROUND_PUMPING_TIMESTEP, p11)
end

function t1.calculate(p12, p13, p14, p15, p16) -- line: 125
    -- upvalues: PointGraph (copy), t1 (copy)
    local v10 = p16.speed(p16, p12.previous_position, p14.position, p15)
    local v11 = PointGraph.evaluate(p13.pump_vs_speed, v10)
    local v12 = p16.angular_speed(p16, p12.previous_position, p12.previous_normal, p14, p15) * p13.angular_speed_damping

    p12.angular_speed = (1 - p13.angular_speed_damping) * p12.angular_speed + v12
    p12.absorption = -(v10 * p12.angular_speed)

    local v13 = p16.inclination_radians(p16, t1.unit(p12.previous_normal[2]))
    local v14 = t1.unit(0.6366197466850281 * v13)

    p12.ground_normal_absorption = PointGraph.evaluate(p13.compression_vs_ground_angle, v14) * p13.ground_compression_scale
    p12.minimum_crouch = PointGraph.evaluate(p13.min_crouch_vs_ground_angle, v14)
    p12.deck_angle_absorption = PointGraph.evaluate(p13.compression_vs_deck_angle, p14.deck_angle * 0.6366197466850281)

    local v15 = p13.deck_compression_scale * p12.deck_angle_absorption
    local v16 = p12.angular_speed * v11

    if v15 * v15 > p12.ground_normal_absorption * p12.ground_normal_absorption then
        p12.ground_normal_absorption = v15
    end

    return v16
end

function t1.unit(p17) -- line: 150
    local v17 = if -p17 >= 0 then 0 else p17

    if 1 - v17 >= 0 then
        return v17
    end

    return 1
end

return t1
