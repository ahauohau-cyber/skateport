-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/riding/vector")
local v2 = import("skate_core/point_graph")
local v3 = import("skate_core/trigonometry")
local cross, dot3, normalize = v1.cross, v1.dot3, v1.normalize
local PointGraph = v2.PointGraph
local acos = v3.acos

return {
    AntiFlipSettings = {},
    AntiFlipInput = {},
    calculate = function(p1, p2) -- calculate | line: 36
        -- upvalues: cross (copy), dot3 (copy), normalize (copy), PointGraph (copy), acos (copy)
        if bit32.band(p2.flags_2468, 536870912) ~= 0 then
            return { 0, 0, 0, 0 }
        end

        local function project(p3) -- line: 40
            -- upvalues: p1 (copy), p2 (copy), dot3 (copy), normalize (copy)
            local v4 = dot3(p2.projection_axis_544, p3)

            return normalize({
                p3[1] - p2.projection_axis_544[1] * v4,
                p3[2] - p2.projection_axis_544[2] * v4,
                p3[3] - p2.projection_axis_544[3] * v4,
                p3[4] - p2.projection_axis_544[4] * v4
            }, p1.normal_threshold)
        end

        local v5 = project(p2.axis_96)
        local v6 = project(p2.axis_64)

        local function angle(p4, p5) -- line: 54
            -- upvalues: dot3 (copy), acos (copy)
            local v7 = dot3(p4, p5)

            if v7 < 0 then
                v7 = 0
            end

            if v7 > 1 then
                v7 = 1
            end

            return acos(v7) * 0.6366197466850281
        end

        local v8 = if dot3(p2.axis_64, cross(p2.axis_96, v5)) >= 0 then 1 else -1
        local v9 = if dot3(p2.axis_96, cross(p2.axis_64, v6)) >= 0 then 1 else -1
        local evaluate = PointGraph.evaluate
        local axis_64_response = p1.axis_64_response
        local v10 = dot3(p2.axis_64, v6)

        if v10 < 0 then
            v10 = 0
        end

        if v10 > 1 then
            v10 = 1
        end

        local v11 = evaluate(axis_64_response, acos(v10) * 0.6366197466850281) * v9
        local v12 = if p2.balance == 0 then 1 else 0
        local evaluate2 = PointGraph.evaluate
        local axis_96_response = p1.axis_96_response
        local v13 = dot3(p2.axis_96, v5)

        if v13 < 0 then
            v13 = 0
        end

        if v13 > 1 then
            v13 = 1
        end

        local v14 = evaluate2(axis_96_response, acos(v13) * 0.6366197466850281) * v8 * v12

        return {
            p2.axis_64[1] * v14 + p2.axis_96[1] * v11,
            p2.axis_64[2] * v14 + p2.axis_96[2] * v11,
            p2.axis_64[3] * v14 + p2.axis_96[3] * v11,
            p2.axis_64[4] * v14 + p2.axis_96[4] * v11
        }
    end
}
