-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    SteeringSettings = {},
    SteeringInput = {}
}

function t1.SteeringInput.default() -- line: 43
    return {
        turn = 0,
        hard_turn = 0,
        absolute_body_speed = 0,
        flipped_controls_scalar = 0,
        balance = 0,
        truck_tightness = 0,
        pushing = false
    }
end

function t1.calculate_tilt(p1, p2, p3, p4) -- line: 59
    -- upvalues: rt (copy), PointGraph (copy)
    local v1 = math.abs(p2.hard_turn) * p1.hard_turn_increase + 1
    local turn = p2.turn

    if p2.hard_turn ~= 0 then
        turn = if turn >= 0 then 1 else -1
    end

    local v2

    if p4 ~= nil then
        v2 = (1 - p1.damping) * p4 + p1.damping * turn
        turn = v2
    else
        v2 = p4
    end

    local v3 = PointGraph.evaluate(p1.speed_graph, rt.clamp(p2.absolute_body_speed / p1.speed_graph_max_speed, 0, 1))
    local v4 = PointGraph.evaluate(p1.input_graph, (math.abs(turn)))
    local v5, v6

    if p3 ~= nil then
        local v7 = if p2.pushing then p3 - p1.push_scalar_decrement else p1.push_scalar_increment + p3

        v5 = rt.clamp(v7, p1.push_scalar_min, 1)
        v6 = v5
    else
        v5 = p3
        v6 = 1
    end

    local v8 = if p2.balance == 0 then 1 else p1.manual_scalar
    local v9 = p1.tight_trucks_scalar * p2.truck_tightness + 1 - p2.truck_tightness

    return p2.flipped_controls_scalar * p1.general_scalar * v8 * v9 * v6 * v4 * v3 * v1 * turn, v5, v2
end

t1.TruckSteeringState = {}

function t1.TruckSteeringState.default() -- line: 118
    return {
        deck_tilt = 0,
        targets = { 0, 0 },
        activation_time = { 0, 0 }
    }
end

function t1.TruckSteeringState.update(p5, p6, p7, p8, p9) -- line: 128
    -- upvalues: rt (copy)
    p5.deck_tilt = (1 - p7) * p5.deck_tilt + p7 * p6

    local t2 = {
        bit32.band(p9, 134217728) ~= 0,
        bit32.band(p9, 67108864) ~= 0
    }

    if bit32.band(p8, 1048576) ~= 0 then
        local v12 = t2[1]

        t2[1] = t2[2]
        t2[2] = v12
    end

    for i = 0, #t2 - 1 do
        if t2[i + 1] then
            if p5.activation_time[i + 1] <= 0.16500001 then
                p5.activation_time[i + 1] += 0.01666666753590107

                local v13 = rt.clamp(p5.activation_time[i + 1] * 6.060606, 0, 1)

                p5.targets[i + 1] = (1 - v13) * p5.targets[i + 1] + v13 * p5.deck_tilt
            else
                p5.targets[i + 1] = p5.deck_tilt
            end
        else
            if p5.activation_time[i + 1] == 0 then
                p5.targets[i + 1] *= 0.983
            end

            p5.activation_time[i + 1] = 0
        end
    end
end

return t1
