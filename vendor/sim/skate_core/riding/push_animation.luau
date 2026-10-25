-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    PushAnimationCurves = {},
    PushBlendParameters = {}
}

function t1.PushAnimationCurves.strength(p1, p2, p3) -- line: 31
    -- upvalues: PointGraph (copy), t1 (copy)
    local v1 = PointGraph.evaluate(p1.button_time_max, p3)

    return PointGraph.evaluate(p1.button_time_to_dv, t1.unit_interval(p2 / v1))
end

function t1.PushAnimationCurves.update_blend(p4, p5, p6, p7, p8) -- line: 38
    -- upvalues: PointGraph (copy), t1 (copy)
    local v2 = if p5.vel_e < 0 then p6 else p5
    local v3 = 1 / (PointGraph.evaluate(p4.blend_speed_over_frames, v2.vel_e) * 0.01666666753590107)
    local v4 = if p7 >= 0 then p7 else 0
    local v5 = 1 / (PointGraph.evaluate(p4.blend_acc_over_frames, v4) * 0.01666666753590107)

    return {
        hstr_vel_b = t1.approach(v2.hstr_vel_b, p6.hstr_vel_b, v3, p8),
        lstr_vel_b = t1.approach(v2.lstr_vel_b, p6.lstr_vel_b, v3, p8),
        vel_e = t1.approach(v2.vel_e, p6.vel_e, v5, p8)
    }
end

function t1.approach(p9, p10, p11, p12) -- line: 59
    -- upvalues: t1 (copy)
    local v6 = p10 - p9
    local v7 = p10

    if math.abs(v6) > 0.001 then
        if v6 > 0 then
            v7 = p12 * p11 + p9

            if v7 - p10 >= 0 then
                v7 = p10
            end
        else
            v7 = -(p12 * p11 + -p9)

            if not (v7 - p10 >= 0) then
                v7 = p10
            end
        end
    end

    return t1.unit_interval(v7)
end

function t1.unit_interval(p13) -- line: 85
    local v8 = if -p13 >= 0 then 0 else p13

    if 1 - v8 >= 0 then
        return v8
    end

    return 1
end

return t1
