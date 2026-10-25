-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/point_graph")
local v3 = import("skate_core/trigonometry")
local PointGraph = v2.PointGraph
local t1 = {
    SpeedAndSlopeSettings = {}
}

function t1.SpeedAndSlopeSettings.calculate(p1, p2, p3) -- line: 32
    -- upvalues: v1 (copy), v3 (copy), PointGraph (copy)
    local v4 = v1.vector_min(1, v1.vector_max(-1, p2))
    local v5 = v1.reciprocal_estimate(1.5707963705062866)
    local v6 = v5 * (-v5 * 1.5707963705062866 + 1) + v5
    local v7 = (v6 * (-v6 * 1.5707963705062866 + 1) + v6) * v3.acos(v4)

    if v7 > 1.2000000476837158 then
        v7 = 0
    end

    local v8 = math.abs(p3)

    if -v8 >= -0 then
        v8 = 0
    end

    if not (p1.heading_adjust_max_speed - v8 >= -0) then
        v8 = p1.heading_adjust_max_speed
    end

    local v9 = v8 / p1.heading_adjust_max_speed

    return PointGraph.evaluate(p1.turn_torque_vs_speed, v9) * PointGraph.evaluate(p1.turn_torque_vs_slope, v7)
end

return t1
