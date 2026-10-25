-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/manager_state")
local v2 = import("skate_core/camera/shake_curve")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/camera/orientation_math")
local clamp = v1.clamp
local t1 = {
    ShakeEffect = {}
}

function t1.ShakeEffect.update_reference(p1, p2, p3, p4, p5, p6, p7, p8) -- line: 23
    -- upvalues: rt (copy), v2 (copy), v3 (copy), v4 (copy), clamp (copy)
    p1.weight = clamp(if p6 then p2 * 5 + p1.weight else -(p2 * 5 + -p1.weight), 0, 1)

    local v6 = if p8.amplitude_top_speed == 0 then p8.amplitude_minimum else v2.sample(p8.amplitude_curve, clamp(p3 / p8.amplitude_top_speed, 0, 1)) * (p8.amplitude_maximum - p8.amplitude_minimum) + p8.amplitude_minimum
    local v7 = (p1.impulse + v6) * p1.weight
    local v8 = if p8.frequency_top_speed == 0 then p8.frequency_minimum else v2.sample(p8.frequency_curve, clamp(p3 / p8.frequency_top_speed, 0, 1)) * (p8.frequency_maximum - p8.frequency_minimum) + p8.frequency_minimum

    if p1.impulse > 0 then
        v8 = p8.impulse_frequency
    end

    p1.time = p8.data_frames_per_second * v8 * p2 + p1.time

    local v9 = v3.refined_reciprocal(1)
    local v10 = -rt.trunc(v9 * p1.time) * 1 + p1.time
    local v11 = #p7.rotations
    local v12 = rt.irem(rt.f_to_u32(p1.time - v10), v11)
    local v13 = rt.irem(v12 + 1, v11)
    local v14 = clamp((3.4000000953674316 - p4) * 1.6666662693023682, 0, 1)
    local v15 = 1 - v10
    local t2 = {}

    for i = 0, 2 do
        local v16 = p7.rotations[v12 + 1][i + 1] * v15 + p7.rotations[v13 + 1][i + 1] * v10

        t2[i + 1] = v16 * v7 * v14 * p8.rotation_multiplier
    end

    t2[3] *= p8.dutch_multiplier

    local v17 = v4.basis_from_angles(t2[1], t2[2], t2[3])
    local t3 = {}

    for i = 0, 2 do
        local v18 = p7.translations[v12 + 1][i + 1] * v15 + p7.translations[v13 + 1][i + 1] * v10

        t3[i + 1] = v18 * p8.translation_multiplier * v7 * v14
    end

    local t4 = {}

    for i = 0, 3 do
        if i == 3 then
            t4[i + 1] = 0
        else
            t4[i + 1] = p5.columns[3][i + 1] * t3[3] + (p5.columns[2][i + 1] * t3[2] + (p5.columns[1][i + 1] * t3[1] + 0))
        end
    end

    p1.translation = t4

    local t5 = {}

    for i = 1, 3 do
        local v19 = v17.columns[i]
        local t6 = {}

        for j = 0, 2 do
            t6[j + 1] = v19[3] * p5.columns[3][j + 1] + (v19[2] * p5.columns[2][j + 1] + v19[1] * p5.columns[1][j + 1])
        end

        t5[i] = t6
    end

    local t7 = {
        columns = t5
    }

    p1.impulse = (1 - p8.impulse_decay) * p1.impulse

    if p1.impulse < 0.004999999888241291 then
        p1.impulse = 0
    end

    return t7
end

local PERF = import("skate_core/camera/tracker").PERF
local basis_from_angles_lanes = v4.basis_from_angles_lanes
local v20 = v3.refined_reciprocal(1)

function t1.ShakeEffect.update_into(p9, p10, p11, p12, p13, p14, p15, p16, p17) -- line: 121
    -- upvalues: rt (copy), v2 (copy), clamp (copy), basis_from_angles_lanes (copy), v20 (copy)
    local v22 = clamp(if p14 then p10 * 5 + p9.weight else -(p10 * 5 + -p9.weight), 0, 1)

    p9.weight = v22

    local impulse = p9.impulse
    local v23 = (impulse + (if p16.amplitude_top_speed == 0 then p16.amplitude_minimum else v2.sample(p16.amplitude_curve, clamp(p11 / p16.amplitude_top_speed, 0, 1)) * (p16.amplitude_maximum - p16.amplitude_minimum) + p16.amplitude_minimum)) * v22
    local v24 = if p16.frequency_top_speed == 0 then p16.frequency_minimum else v2.sample(p16.frequency_curve, clamp(p11 / p16.frequency_top_speed, 0, 1)) * (p16.frequency_maximum - p16.frequency_minimum) + p16.frequency_minimum

    if impulse > 0 then
        v24 = p16.impulse_frequency
    end

    local v25 = p16.data_frames_per_second * v24 * p10 + p9.time

    p9.time = v25

    local v26 = -rt.trunc(v20 * v25) * 1 + v25
    local rotations, translations = p15.rotations, p15.translations
    local v27 = #rotations
    local v28 = rt.irem(rt.f_to_u32(v25 - v26), v27)
    local v29 = rt.irem(v28 + 1, v27)
    local v30 = clamp((3.4000000953674316 - p12) * 1.6666662693023682, 0, 1)
    local v31 = 1 - v26
    local columns = p13.columns
    local v32 = columns[1]
    local v33 = columns[2]
    local v34 = columns[3]
    local v35 = v32[1]
    local v36 = v32[2]
    local v37 = v32[3]
    local v38 = v33[1]
    local v39 = v33[2]
    local v40 = v33[3]
    local v41 = v34[1]
    local v42 = v34[2]
    local v43 = v34[3]
    local v44 = translations[v28 + 1]
    local v45 = translations[v29 + 1]
    local translation_multiplier = p16.translation_multiplier
    local v46 = (v44[1] * v31 + v45[1] * v26) * translation_multiplier * v23 * v30
    local v47 = (v44[2] * v31 + v45[2] * v26) * translation_multiplier * v23 * v30
    local v48 = (v44[3] * v31 + v45[3] * v26) * translation_multiplier * v23 * v30
    local translation = p9.translation

    translation[1] = v41 * v48 + (v38 * v47 + (v35 * v46 + 0))
    translation[2] = v42 * v48 + (v39 * v47 + (v36 * v46 + 0))
    translation[3] = v43 * v48 + (v40 * v47 + (v37 * v46 + 0))
    translation[4] = 0

    if p17 ~= nil then
        local v49 = rotations[v28 + 1]
        local v50 = rotations[v29 + 1]
        local rotation_multiplier = p16.rotation_multiplier
        local v54, v55, v56, v57, v58, v59, v60, v61, v62 = basis_from_angles_lanes((v49[1] * v31 + v50[1] * v26) * v23 * v30 * rotation_multiplier, (v49[2] * v31 + v50[2] * v26) * v23 * v30 * rotation_multiplier, (v49[3] * v31 + v50[3] * v26) * v23 * v30 * rotation_multiplier * p16.dutch_multiplier)
        local v63 = v56 * v41 + (v55 * v38 + v54 * v35)
        local v64 = v56 * v42 + (v55 * v39 + v54 * v36)
        local v65 = v56 * v43 + (v55 * v40 + v54 * v37)
        local v66 = v59 * v41 + (v58 * v38 + v57 * v35)
        local v67 = v59 * v42 + (v58 * v39 + v57 * v36)
        local v68 = v59 * v43 + (v58 * v40 + v57 * v37)
        local v69 = v62 * v41 + (v61 * v38 + v60 * v35)
        local v70 = v62 * v42 + (v61 * v39 + v60 * v36)
        local v71 = v62 * v43 + (v61 * v40 + v60 * v37)
        local columns = p17.columns
        local v72 = columns[1]

        v72[1] = v63
        v72[2] = v64
        v72[3] = v65

        local v73 = columns[2]

        v73[1] = v66
        v73[2] = v67
        v73[3] = v68

        local v74 = columns[3]

        v74[1] = v69
        v74[2] = v70
        v74[3] = v71
    end

    local v75 = (1 - p16.impulse_decay) * impulse

    p9.impulse = if v75 < 0.004999999888241291 then 0 else v75
end

function t1.ShakeEffect.update(p18, p19, p20, p21, p22, p23, p24, p25) -- line: 219
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.ShakeEffect.update_reference(p18, p19, p20, p21, p22, p23, p24, p25)
    end

    local t8 = {
        columns = {
            { 0, 0, 0 },
            { 0, 0, 0 },
            { 0, 0, 0 }
        }
    }

    t1.ShakeEffect.update_into(p18, p19, p20, p21, p22, p23, p24, p25, t8)

    return t8
end

return t1
