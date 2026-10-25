-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/grind_forces")
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local PointGraph = import("skate_core/point_graph").PointGraph
local scale = v1.scale

return {
    pin = function(p1, p2) -- pin | line: 17
        -- upvalues: scale (copy)
        if p2 > 0 then
            local v2 = scale(p1, -40)

            v2[2] = 0

            return v2
        end

        return nil
    end,
    coping = function(p3, p4, p5) -- coping | line: 27
        -- upvalues: dot3 (copy)
        return if p5 > 0 and dot3(p3, p4) < 0 then { 0, 120, 0, 0 } else nil
    end,
    exit_lean = function(p6, p7, p8) -- exit_lean | line: 35
        -- upvalues: PointGraph (copy), scale (copy)
        if p7 > 0 then
            return scale(p6, PointGraph.evaluate(p8, p7) * -65)
        end

        return nil
    end,
    truck_compensation = function(p9, p10) -- truck_compensation | line: 43
        -- upvalues: scale (copy)
        return scale(p9, math.abs(p10) * -600)
    end
}
