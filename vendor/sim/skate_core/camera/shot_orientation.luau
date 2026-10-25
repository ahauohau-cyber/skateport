-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/physics/native_arithmetic")
local v3 = import("skate_core/physics/reciprocal_sqrt")
local v4 = import("skate_core/trigonometry")
local refined_reciprocal = v1.refined_reciprocal

local function shot() -- line: 16
    -- upvalues: import (copy)
    return import("skate_core/camera/shot")
end

local t1 = {}

function t1.interpolate_orientation(p1, p2, p3) -- line: 26
    -- upvalues: import (copy), t1 (copy)
    return t1.slerp(p1, p2, import("skate_core/camera/shot").sine_blend(p3))
end

function t1.slerp_reference(p4, p5, p6) -- line: 32
    -- upvalues: rt (copy), v2 (copy), v3 (copy), v4 (copy), refined_reciprocal (copy)
    local v5 = v2.dot4(p4, p5)
    local v6 = if v5 < 0 then {
        -p4[1],
        -p4[2],
        -p4[3],
        -p4[4]
    } else rt.copy(p4)

    if v5 < 0 then
        v5 = -v5
    end

    if v5 > 0.9961947202682495 then
        local v7 = v2.dot4(v6, p5) > 0
        local t2 = {}

        for i = 0, 3 do
            if v7 then
                t2[i + 1] = (p5[i + 1] - v6[i + 1]) * p6 + v6[i + 1]
            else
                t2[i + 1] = -(p5[i + 1] + v6[i + 1]) * p6 + v6[i + 1]
            end
        end

        local v8 = v2.dot4(t2, t2)
        local v9 = v3.estimate(v8)
        local v10 = v9 * 0.5 * (-v8 * (v9 * v9) + 1) + v9
        local v11 = v10 * 0.5 * (-v8 * (v10 * v10) + 1) + v10

        return {
            t2[1] * v11,
            t2[2] * v11,
            t2[3] * v11,
            t2[4] * v11
        }
    end

    local v12 = v4.acos(v5)
    local v13 = refined_reciprocal(v4.sin(v12))
    local v14 = v4.sin((1 - p6) * v12) * v13
    local v15 = v4.sin(p6 * v12) * v13
    local t3 = {}

    t3[1] = p5[1] * v15 + v6[1] * v14
    t3[2] = p5[2] * v15 + v6[2] * v14
    t3[3] = p5[3] * v15 + v6[3] * v14
    t3[4] = p5[4] * v15 + v6[4] * v14

    return t3
end

local PERF = import("skate_core/camera/tracker").PERF
local acos, sin = v4.acos, v4.sin

function t1.slerp_lanes(p7, p8, p9, p10, p11, p12, p13, p14, p15) -- line: 85
    -- upvalues: refined_reciprocal (copy), acos (copy), sin (copy)
    local v16 = p7 * p11 + p8 * p12 + p9 * p13 + p10 * p14
    local v17, v18, v19, v20

    if v16 < 0 then
        v17 = -p7
        v18 = -p8
        v19 = -p9
        v20 = -p10
        v16 = -v16
    else
        v17 = p7
        v18 = p8
        v19 = p9
        v20 = p10
    end

    if v16 > 0.9961947202682495 then
        local v21, v22, v23, v24

        if v17 * p11 + v18 * p12 + v19 * p13 + v20 * p14 > 0 then
            v21 = (p11 - v17) * p15 + v17
            v22 = (p12 - v18) * p15 + v18
            v23 = (p13 - v19) * p15 + v19
            v24 = (p14 - v20) * p15 + v20
        else
            v21 = -(p11 + v17) * p15 + v17
            v22 = -(p12 + v18) * p15 + v18
            v23 = -(p13 + v19) * p15 + v19
            v24 = -(p14 + v20) * p15 + v20
        end

        local v25 = v21 * v21 + v22 * v22 + v23 * v23 + v24 * v24
        local v26 = 1 / math.sqrt(v25)
        local v27 = v26 * 0.5 * (-v25 * (v26 * v26) + 1) + v26
        local v28 = v27 * 0.5 * (-v25 * (v27 * v27) + 1) + v27

        return v21 * v28, v22 * v28, v23 * v28, v24 * v28
    end

    local v29 = acos(v16)
    local v30 = refined_reciprocal(sin(v29))
    local v31 = sin((1 - p15) * v29) * v30
    local v32 = sin(p15 * v29) * v30

    return p11 * v32 + v17 * v31, p12 * v32 + v18 * v31, p13 * v32 + v19 * v31, p14 * v32 + v20 * v31
end

local slerp_lanes = t1.slerp_lanes

function t1.slerp(p16, p17, p18) -- line: 133
    -- upvalues: t1 (copy), PERF (copy), slerp_lanes (copy)
    if PERF.reference then
        return t1.slerp_reference(p16, p17, p18)
    end

    local v33, v34, v35, v36 = slerp_lanes(p16[1], p16[2], p16[3], p16[4], p17[1], p17[2], p17[3], p17[4], p18)

    return { v33, v34, v35, v36 }
end

function t1.slerp_into(p19, p20, p21, p22) -- line: 142
    -- upvalues: slerp_lanes (copy)
    local v37, v38, v39, v40 = slerp_lanes(p20[1], p20[2], p20[3], p20[4], p21[1], p21[2], p21[3], p21[4], p22)

    p19[1] = v37
    p19[2] = v38
    p19[3] = v39
    p19[4] = v40
end

return t1
