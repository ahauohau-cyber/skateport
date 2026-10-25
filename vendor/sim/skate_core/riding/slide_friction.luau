-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/riding/vector")
local v2 = import("skate_core/point_graph")
local v3 = import("skate_core/trigonometry")
local clamp, dot3 = v1.clamp, v1.dot3
local PointGraph = v2.PointGraph
local acos = v3.acos

return {
    SlideFrictionSettings = {},
    SlideFrictionInput = {},
    calculate = function(p1, p2) -- calculate | line: 40
        -- upvalues: clamp (copy), dot3 (copy), PointGraph (copy), acos (copy)
        local v4 = if p2.normal[2] < -1 then -1 else p2.normal[2]

        if v4 > 1 then
            v4 = 1
        end

        local v5 = clamp(acos(v4) * 0.6366197466850281, 0, 1)
        local v6 = 1 - PointGraph.evaluate(p1.angle_response, v5)
        local v7 = 1 - PointGraph.evaluate(p1.speed_response, p2.surface_speed * 0.1)
        local v8 = PointGraph.evaluate(p1.time_response, clamp(p2.heading_time, 0, p1.heading_time_limit) / p1.heading_time_limit)
        local v9 = (1 - p1.scalar_516) * p2.scalar_2764 + p1.scalar_516

        if not (v6 - v7 >= 0) then
            v6 = v7
        end

        local v10 = -(v8 * v9 * v6 * p1.friction)
        local v11 = dot3(p2.velocity, p2.normal)
        local v12 = dot3({
            p2.velocity[1] - p2.normal[1] * v11,
            p2.velocity[2] - p2.normal[2] * v11,
            p2.velocity[3] - p2.normal[3] * v11,
            p2.velocity[4] - p2.normal[4] * v11
        }, p2.side_axis)
        local v13 = table.create(8, 0)

        v13[1] = p2.side_axis[1] * v12 * v10
        v13[2] = p2.side_axis[2] * v12 * v10
        v13[3] = p2.side_axis[3] * v12 * v10
        v13[4] = p2.side_axis[4] * v12 * v10

        return v13
    end
}
