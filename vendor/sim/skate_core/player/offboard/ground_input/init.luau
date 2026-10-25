-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_input/math")
local PointGraph = import("skate_core/point_graph").PointGraph
local cross, dot, inverse_frame, length = v1.cross, v1.dot, v1.inverse_frame, v1.length
local normalize, signed_angle = v1.normalize, v1.signed_angle
local t1 = {}

t1.GroundInput = {}
t1.GroundInputOutput = {}

function t1.GroundInputOutput.eq(p1, p2) -- line: 46
    if p1.state_708 == p2.state_708 and p1.state_712 == p2.state_712 and p1.state_656[1] == p2.state_656[1] and p1.state_656[2] == p2.state_656[2] and p1.state_656[3] == p2.state_656[3] then
        return p1.state_656[4] == p2.state_656[4]
    end

    return false
end

function t1.calculate(p3, p4, p5) -- line: 58
    -- upvalues: PointGraph (copy), cross (copy), dot (copy), inverse_frame (copy), length (copy), normalize (copy), signed_angle (copy)
    if bit32.band(p3.processed_flags_2472, 268435456) ~= 0 then
        return {
            state_708 = p3.processed_direct_2684,
            state_712 = p3.processed_direct_2680,
            state_656 = { 0, 0, 0, 0 }
        }
    end

    local t2 = {
        p3.processed_stick_2692,
        0,
        p3.processed_stick_2688
    }
    local t3 = {
        0, 1, 0
    }
    local v2 = {
        1, 0, 0
    }
    local v3 = {
        0, 0, 1
    }

    if dot(p3.frame_forward_112, t3) < 0.9990000128746033 then
        v2 = normalize(cross(t3, p3.frame_forward_112))
        v3 = normalize(cross(v2, t3))
    end

    local v4 = inverse_frame(v2, t3, v3, t2)
    local v5 = signed_angle(v4[1], -v4[3]) * 0.31830987334251404
    local v6 = if v5 >= 0 then 1 else -1
    local v7 = v5 * v6
    local v8 = length(v4)

    return {
        state_708 = PointGraph.evaluate(p4, v7) * v8 * p3.processed_scale_2912,
        state_712 = PointGraph.evaluate(p5, v7) * v8 * v6 * p3.processed_scale_2908,
        state_656 = {
            t2[1],
            t2[2],
            t2[3],
            0
        }
    }
end

return t1
