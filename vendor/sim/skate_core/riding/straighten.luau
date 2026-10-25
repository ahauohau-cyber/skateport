-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/riding/vector")
local v2 = import("skate_core/point_graph")
local clamp, cross, dot3 = v1.clamp, v1.cross, v1.dot3
local PointGraph = v2.PointGraph

return {
    StraightenSettings = {},
    StraightenInput = {},
    calculate = function(p1, p2) -- calculate | line: 37
        -- upvalues: rt (copy), clamp (copy), cross (copy), dot3 (copy), PointGraph (copy)
        local v3 = ((1 - p1.time_scalar) * p2.scalar_2764 + p1.time_scalar) * p1.heading_time_limit
        local v4 = PointGraph.evaluate(p1.time_response, clamp(p2.heading_time, 0, v3) / v3) * p1.strength
        local v6 = dot3(cross(if dot3(p2.forward, p2.velocity) < 0 then {
            -p2.forward[1],
            -p2.forward[2],
            -p2.forward[3],
            -p2.forward[4]
        } else rt.copy(p2.forward), p2.velocity), p2.normal)
        local t2 = {
            p2.normal[1] * (v6 * v4),
            p2.normal[2] * (v6 * v4),
            p2.normal[3] * (v6 * v4),
            p2.normal[4] * (v6 * v4)
        }

        if p2.turn * v6 < 0 then
            local v7 = 1 - clamp(math.abs(p2.turn), 0, p1.opposite_turn_limit) / p1.opposite_turn_limit

            t2[1] *= v7
            t2[2] *= v7
            t2[3] *= v7
            t2[4] *= v7
        end

        return t2
    end
}
