-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/tracker")
local v2 = import("skate_core/physics/native_arithmetic")
local v3 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {
    VectorTracker = {}
}
local PERF = v1.PERF
local length3, refined_reciprocal

function t1.VectorTracker.update(p1, p2, p3, p4) -- line: 35
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.VectorTracker.update_reference(p1, p2, p3, p4)
    end

    return t1.VectorTracker.update_lanes(p1, p2, p3[1], p3[2], p3[3], p3[4], p4)
end

function t1.VectorTracker.update_lanes(p5, p6, p7, p8, p9, p10, p11) -- line: 43
    -- upvalues: v1 (copy), length3 (ref), refined_reciprocal (ref)
    local position, velocity = p5.position, p5.velocity
    local v4 = position[1]
    local v5 = position[2]
    local v6 = position[3]
    local v7 = position[4]
    local v8 = velocity[1]
    local v9 = velocity[2]
    local v10 = velocity[3]
    local v11 = velocity[4]
    local v12 = p7 - v4
    local v13 = p8 - v5
    local v14 = p9 - v6
    local v15 = p10 - v7

    if p11.overshoot_zeroes_velocity and v12 * v8 + v13 * v9 + v14 * v10 < 0 then
        v8 *= 0
        v9 *= 0
        v10 *= 0
        v11 *= 0
    end

    local v16 = refined_reciprocal(p6)
    local v17 = (v16 * v12 - v8) * v16
    local v18 = (v16 * v13 - v9) * v16
    local v19 = (v16 * v14 - v10) * v16
    local v20 = (v16 * v15 - v11) * v16
    local v21 = length3(v12, v13, v14)
    local v22 = if v21 < p11.delta_umbra then 1 elseif v21 < p11.delta_penumbra then 1 - (v21 - p11.delta_umbra) / (p11.delta_penumbra - p11.delta_umbra) else 0

    if v17 * v12 + v18 * v13 + v19 * v14 > 0 then
        local v23 = v1.interpolate(p11.acceleration_clamp_min, p11.acceleration_clamp_max, v22)

        p5.acceleration_clamp = v23

        local v24 = length3(v17, v18, v19)

        if v23 < v24 then
            local v25 = v23 / v24

            v17 *= v25
            v18 *= v25
            v19 *= v25
            v20 *= v25
        end
    end

    local v26 = v17 * p6 + v8
    local v27 = v18 * p6 + v9
    local v28 = v19 * p6 + v10
    local v29 = v20 * p6 + v11
    local speed_clamp = p11.speed_clamp
    local v30 = length3(v26, v27, v28)

    if speed_clamp < v30 then
        local v31 = speed_clamp / v30

        v26 *= v31
        v27 *= v31
        v28 *= v31
        v29 *= v31
    end

    local v32 = v26 * p6 + v4
    local v33 = v27 * p6 + v5
    local v34 = v28 * p6 + v6
    local v35 = v29 * p6 + v7
    local v36 = v1.interpolate(p11.smoothing_min, p11.smoothing_max, v22)

    p5.smoothing = v36

    local v37 = 1 - v36
    local target = p5.target

    target[1] = p7
    target[2] = p8
    target[3] = p9
    target[4] = p10

    local acceleration = p5.acceleration

    acceleration[1] = v17
    acceleration[2] = v18
    acceleration[3] = v19
    acceleration[4] = v20
    velocity[1] = v26
    velocity[2] = v27
    velocity[3] = v28
    velocity[4] = v29
    position[1] = (v32 - v4) * v37 + v4
    position[2] = (v33 - v5) * v37 + v5
    position[3] = (v34 - v6) * v37 + v6
    position[4] = (v35 - v7) * v37 + v7
end

function t1.VectorTracker.update_reference(p12, p13, p14, p15) -- line: 99
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    p12.target = rt.copy(p14)

    local v38 = rt.copy(p12.position)
    local t2 = {}

    t2[1] = p14[1] - v38[1]
    t2[2] = p14[2] - v38[2]
    t2[3] = p14[3] - v38[3]
    t2[4] = p14[4] - v38[4]

    if p15.overshoot_zeroes_velocity and t1.dot(t2, p12.velocity) < 0 then
        local t3 = {}

        t3[1] = p12.velocity[1] * 0
        t3[2] = p12.velocity[2] * 0
        t3[3] = p12.velocity[3] * 0
        t3[4] = p12.velocity[4] * 0
        p12.velocity = t3
    end

    local v39 = t1.refined_reciprocal(p13)
    local t4 = {}

    t4[1] = (v39 * t2[1] - p12.velocity[1]) * v39
    t4[2] = (v39 * t2[2] - p12.velocity[2]) * v39
    t4[3] = (v39 * t2[3] - p12.velocity[3]) * v39
    t4[4] = (v39 * t2[4] - p12.velocity[4]) * v39
    p12.acceleration = t4

    local v40 = t1.length(t2)
    local v41 = if v40 < p15.delta_umbra then 1 elseif v40 < p15.delta_penumbra then 1 - (v40 - p15.delta_umbra) / (p15.delta_penumbra - p15.delta_umbra) else 0

    if t1.dot(p12.acceleration, t2) > 0 then
        p12.acceleration_clamp = v1.interpolate(p15.acceleration_clamp_min, p15.acceleration_clamp_max, v41)
        p12.acceleration = t1.clamp_magnitude(p12.acceleration, p12.acceleration_clamp)
    end

    local t5 = {}

    t5[1] = p12.acceleration[1] * p13 + p12.velocity[1]
    t5[2] = p12.acceleration[2] * p13 + p12.velocity[2]
    t5[3] = p12.acceleration[3] * p13 + p12.velocity[3]
    t5[4] = p12.acceleration[4] * p13 + p12.velocity[4]
    p12.velocity = t5
    p12.velocity = t1.clamp_magnitude(p12.velocity, p15.speed_clamp)

    local t6 = {}

    t6[1] = p12.velocity[1] * p13 + v38[1]
    t6[2] = p12.velocity[2] * p13 + v38[2]
    t6[3] = p12.velocity[3] * p13 + v38[3]
    t6[4] = p12.velocity[4] * p13 + v38[4]
    p12.smoothing = v1.interpolate(p15.smoothing_min, p15.smoothing_max, v41)

    local t7 = {}

    t7[1] = (t6[1] - v38[1]) * (1 - p12.smoothing) + v38[1]
    t7[2] = (t6[2] - v38[2]) * (1 - p12.smoothing) + v38[2]
    t7[3] = (t6[3] - v38[3]) * (1 - p12.smoothing) + v38[3]
    t7[4] = (t6[4] - v38[4]) * (1 - p12.smoothing) + v38[4]
    p12.position = t7
end

function t1.clamp_magnitude(p16, p17) -- line: 153
    -- upvalues: rt (copy), t1 (copy)
    local v42 = t1.length(p16)

    if p17 < v42 then
        local v43 = p17 / v42
        local t8 = {}

        for i = 1, #p16 do
            t8[i] = p16[i] * v43
        end

        return t8
    end

    return rt.copy(p16)
end

function t1.refined_reciprocal_reference(p18) -- line: 167
    -- upvalues: t1 (copy)
    local v44 = t1.reciprocal_estimate(p18)
    local v45 = v44 * (-v44 * p18 + 1) + v44

    return v45 * (-v45 * p18 + 1) + v45
end

function t1.reciprocal_estimate(p19) -- line: 175
    -- upvalues: v2 (copy)
    return v2.reciprocal_estimate(p19)
end

function t1.length_reference(p20) -- line: 179
    -- upvalues: v3 (copy), t1 (copy)
    local v46 = t1.dot_reference(p20, p20)
    local v47 = v3.estimate(v46)
    local v48 = -v46 * (v47 * v47) + 1
    local v49 = v47 * 0.5 * v48 + v47
    local v50 = -v46 * (v49 * v49) + 1
    local v51 = v49 * 0.5 * v50 + v49

    if v46 == 0 then
        return 0
    end

    return v46 * v51
end

function t1.dot_reference(p21, p22) -- line: 193
    -- upvalues: v2 (copy)
    return v2.dot3(p21, p22)
end

function t1.refined_reciprocal(p23) -- line: 202
    local v52 = 1 / p23
    local v53 = v52 * (-v52 * p23 + 1) + v52

    return v53 * (-v53 * p23 + 1) + v53
end

function t1.dot(p24, p25) -- line: 209
    return p24[1] * p25[1] + p24[2] * p25[2] + p24[3] * p25[3]
end

function t1.length(p26) -- line: 213
    local v54 = p26[1]
    local v55 = p26[2]
    local v56 = p26[3]
    local v57 = v54 * v54 + v55 * v55 + v56 * v56
    local v58 = 1 / math.sqrt(v57)
    local v59 = -v57 * (v58 * v58) + 1
    local v60 = v58 * 0.5 * v59 + v58
    local v61 = -v57 * (v60 * v60) + 1
    local v62 = v60 * 0.5 * v61 + v60

    if v57 == 0 then
        return 0
    end

    return v57 * v62
end

function t1.length3(p27, p28, p29) -- line: 231
    local v63 = p27 * p27 + p28 * p28 + p29 * p29
    local v64 = 1 / math.sqrt(v63)
    local v65 = -v63 * (v64 * v64) + 1
    local v66 = v64 * 0.5 * v65 + v64
    local v67 = -v63 * (v66 * v66) + 1
    local v68 = v66 * 0.5 * v67 + v66

    if v63 == 0 then
        return 0
    end

    return v63 * v68
end

length3 = t1.length3
refined_reciprocal = t1.refined_reciprocal

return t1
