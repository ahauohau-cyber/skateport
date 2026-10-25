-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local orthonormalize = import("skate_core/physics/skeleton_root").orthonormalize
local t1 = {
    DT = 0.01666666753590107,
    FrameOutput = {}
}

function t1.FrameOutput.eq(p1, p2) -- line: 27
    for i = 1, 4 do
        for j = 1, 4 do
            if p1.frame[i][j] ~= p2.frame[i][j] then
                return false
            end
        end
    end

    if p1.velocity[1] == p2.velocity[1] and p1.velocity[2] == p2.velocity[2] and p1.velocity[3] == p2.velocity[3] then
        return p1.velocity[4] == p2.velocity[4]
    end

    return false
end

function t1.FrameOutput.update(p3, p4, p5, p6, p7) -- line: 44
    -- upvalues: rt (copy), orthonormalize (copy), t1 (copy)
    local v1 = t1.normalize(t1.cross(p5, p4))
    local v2 = t1.normalize(t1.cross(v1, p6))

    p3.frame = orthonormalize({
        v1,
        rt.copy(p5),
        v2,
        rt.copy(p3.frame[4])
    })

    local t2 = {
        (p7[1] - p3.frame[4][1]) * 60 - p3.velocity[1],
        (p7[2] - p3.frame[4][2]) * 60 - p3.velocity[2],
        (p7[3] - p3.frame[4][3]) * 60 - p3.velocity[3],
        (p7[4] - p3.frame[4][4]) * 60 - p3.velocity[4]
    }

    t2[2] = t1.select(t2[2] - -1, t2[2], -1)
    p3.velocity = {
        p3.velocity[1] + t2[1],
        p3.velocity[2] + t2[2],
        p3.velocity[3] + t2[3],
        p3.velocity[4] + t2[4]
    }
    p3.frame[4] = {
        p3.velocity[1] * t1.DT + p3.frame[4][1],
        p3.velocity[2] * t1.DT + p3.frame[4][2],
        p3.velocity[3] * t1.DT + p3.frame[4][3],
        p3.velocity[4] * t1.DT + p3.frame[4][4]
    }
end

t1.PositionInput = {}

function t1.update_position(p8, p9) -- line: 78
    -- upvalues: rt (copy), dot3 (copy), t1 (copy)
    local v3 = rt.copy(p9.projection_axis_416)
    local v4 = rt.copy(p9.previous_origin_112)

    if p9.use_override_711 then
        v4 = rt.copy(p9.override_origin_592)
    elseif bit32.band(p9.contact_flags_176, 1) ~= 0 and dot3(t1.subtract(p9.contact_origin_0, v4), v3) > 0 then
        v4 = rt.copy(p9.contact_origin_0)
    end

    if bit32.band(p9.contact_flags_176, 2) ~= 0 then
        local v5 = dot3(t1.subtract(p9.contact_origin_96, v4), v3)
        local v6 = dot3(t1.subtract(p9.frame_position_176, v4), v3)
        local v7 = t1.select(v5 - v6, v5, v6)
        local v8 = t1.select(v7 - 0.3, 0.3, v7)

        if not (v8 <= 0) then
            v4 = {
                v3[1] * v8 + v4[1],
                v3[2] * v8 + v4[2],
                v3[3] * v8 + v4[3],
                v3[4] * v8 + v4[4]
            }
        end
    end

    local v9 = t1.subtract(p9.animation_position_272, v4)
    local v10 = dot3(v3, v9)
    local t3 = {
        v9[1] - v3[1] * v10,
        v9[2] - v3[2] * v10,
        v9[3] - v3[3] * v10,
        v9[4] - v3[4] * v10
    }
    local t4 = {
        v3[1] * 0.95 + (v4[1] + t3[1]),
        v3[2] * 0.95 + (v4[2] + t3[2]),
        v3[3] * 0.95 + (v4[3] + t3[3]),
        v3[4] * 0.95 + (v4[4] + t3[4])
    }
    local v11 = t1.subtract(t4, p8)
    local v12 = dot3(v11, v3)
    local v13 = t1.select(-0.1 - v12, -0.1, v12)
    local v14 = t1.select(0.1 - v13, v13, 0.1) - v12

    rt.assign(p8, {
        p8[1] + (v3[1] * v14 + v11[1]),
        p8[2] + (v3[2] * v14 + v11[2]),
        p8[3] + (v3[3] * v14 + v11[3]),
        p8[4] + (v3[4] * v14 + v11[4])
    })
end

function t1.subtract(p10, p11) -- line: 134
    return {
        p10[1] - p11[1],
        p10[2] - p11[2],
        p10[3] - p11[3],
        p10[4] - p11[4]
    }
end

function t1.select(p12, p13, p14) -- line: 138
    if p12 >= 0 then
        return p13
    end

    return p14
end

function t1.cross(p15, p16) -- line: 146
    return {
        -p15[3] * p16[2] + p15[2] * p16[3],
        -p15[1] * p16[3] + p15[3] * p16[1],
        -p15[2] * p16[1] + p15[1] * p16[2],
        -p15[4] * p16[4] + p15[4] * p16[4]
    }
end

function t1.normalize(p17) -- line: 155
    -- upvalues: dot3 (copy), estimate (copy)
    local v15 = dot3(p17, p17)
    local v16 = estimate(v15)
    local v17 = v16 * 0.5 * (-v15 * (v16 * v16) + 1) + v16
    local v18 = v17 * 0.5 * (-v15 * (v17 * v17) + 1) + v17

    return {
        p17[1] * v18,
        p17[2] * v18,
        p17[3] * v18,
        p17[4] * v18
    }
end

return t1
