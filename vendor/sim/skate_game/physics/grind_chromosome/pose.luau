-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/board_motion_output")
local t1 = {
    dot = import("skate_core/riding/ground_correction_math").dot_product
}
local dot = t1.dot

t1.ApproachPose = {}
t1.Input = {}

function t1.straight(p1) -- line: 34
    -- upvalues: rt (copy), Vector3 (copy), v1 (copy), t1 (copy), dot (copy)
    local v2 = dot(p1.basic_twist_axis_128, p1.normal)
    local v3 = t1.sub(p1.basic_twist_axis_128, rt.map(p1.normal, function(p2) -- line: 38
        -- upvalues: v2 (copy)
        return p2 * v2
    end))
    local v4 = v1.length(Vector3.new(v3[1], v3[2], v3[3]))

    if v4 <= 0.01 then
        return true
    end

    local v5 = 1 / v4
    local v6 = v5 * (-v5 * v4 + 1) + v5
    local v7 = v6 * (-v6 * v4 + 1) + v6

    return math.abs((dot(rt.map(v3, function(p3) -- line: 52
        -- upvalues: v7 (copy)
        return p3 * v7
    end), p1.direction))) > 0.9397
end

function t1.low(p4) -- line: 61
    -- upvalues: t1 (copy), dot (copy)
    local v9 = t1.signed(p4.basic_forward_32, dot(t1.sub(p4.basic_position_48, p4.point), p4.basic_forward_32) > 0)

    return dot(p4.normal, v9) <= -0.1
end

function t1.add(p5, p6) -- line: 69
    return {
        p5[1] + p6[1],
        p5[2] + p6[2],
        p5[3] + p6[3],
        p5[4] + p6[4]
    }
end

function t1.sub(p7, p8) -- line: 73
    return {
        p7[1] - p8[1],
        p7[2] - p8[2],
        p7[3] - p8[3],
        p7[4] - p8[4]
    }
end

function t1.signed(p9, p10) -- line: 77
    -- upvalues: rt (copy)
    return rt.map(p9, function(p11) -- line: 78
        -- upvalues: p10 (copy)
        if p10 then
            return p11
        end

        return -p11
    end)
end

return t1
