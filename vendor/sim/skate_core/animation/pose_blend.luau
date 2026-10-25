-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local v1 = require(sim.import)("skate_core/physics/native_arithmetic")
local interpolate
local t1 = {}

function t1.blend(p2, p3, p4, p5) -- line: 26
    -- upvalues: t1 (copy)
    if #p2 ~= #p3 then
        error({
            tag = "ShortInput"
        }, 0)
    end

    if #p5 < #p2 then
        error({
            tag = "ShortOutput"
        }, 0)
    end

    for i = 1, #p2 do
        p5[i] = t1.blend_sample(p2[i], p3[i], p4)
    end
end

function t1.blend_sample_reference(p6, p7, p8) -- line: 39
    -- upvalues: v1 (copy), interpolate (ref)
    local v2 = v1.dot4(p6.rotation, p7.rotation) > 0
    local v3 = table.create(4)

    for i = 0, 3 do
        if v2 then
            v3[i + 1] = (p7.rotation[i + 1] - p6.rotation[i + 1]) * p8 + p6.rotation[i + 1]
        else
            v3[i + 1] = -(p7.rotation[i + 1] + p6.rotation[i + 1]) * p8 + p6.rotation[i + 1]
        end
    end

    local v4 = v1.dot4(v3, v3)
    local v5 = v1.reciprocal_square_root_estimate(v4)
    local v6 = v5 * 0.5 * (-v4 * (v5 * v5) + 1) + v5
    local v7 = v6 * 0.5 * (-v4 * (v6 * v6) + 1) + v6

    return {
        scale = interpolate(p6.scale, p7.scale, p8),
        rotation = {
            v3[1] * v7,
            v3[2] * v7,
            v3[3] * v7,
            v3[4] * v7
        },
        translation = interpolate(p6.translation, p7.translation, p8)
    }
end

function t1.blend_sample(p9, p10, p11) -- line: 72
    local rotation = p9.rotation
    local rotation2 = p10.rotation
    local v8 = rotation[1]
    local v9 = rotation[2]
    local v10 = rotation[3]
    local v11 = rotation[4]
    local v12 = rotation2[1]
    local v13 = rotation2[2]
    local v14 = rotation2[3]
    local v15 = rotation2[4]
    local v16, v17, v18, v19

    if v8 * v12 + v9 * v13 + v10 * v14 + v11 * v15 > 0 then
        v16 = (v12 - v8) * p11 + v8
        v17 = (v13 - v9) * p11 + v9
        v18 = (v14 - v10) * p11 + v10
        v19 = (v15 - v11) * p11 + v11
    else
        v16 = -(v12 + v8) * p11 + v8
        v17 = -(v13 + v9) * p11 + v9
        v18 = -(v14 + v10) * p11 + v10
        v19 = -(v15 + v11) * p11 + v11
    end

    local v20 = v16 * v16 + v17 * v17 + v18 * v18 + v19 * v19
    local v21 = 1 / math.sqrt(v20)
    local v22 = v21 * 0.5 * (-v20 * (v21 * v21) + 1) + v21
    local v23 = v22 * 0.5 * (-v20 * (v22 * v22) + 1) + v22
    local scale = p9.scale
    local scale2 = p10.scale
    local translation = p9.translation
    local translation2 = p10.translation
    local v24 = scale[1]
    local v25 = scale[2]
    local v26 = scale[3]
    local v27 = scale[4]
    local v28 = translation[1]
    local v29 = translation[2]
    local v30 = translation[3]
    local v31 = translation[4]

    return {
        scale = {
            (scale2[1] - v24) * p11 + v24,
            (scale2[2] - v25) * p11 + v25,
            (scale2[3] - v26) * p11 + v26,
            (scale2[4] - v27) * p11 + v27
        },
        rotation = {
            v16 * v23,
            v17 * v23,
            v18 * v23,
            v19 * v23
        },
        translation = {
            (translation2[1] - v28) * p11 + v28,
            (translation2[2] - v29) * p11 + v29,
            (translation2[3] - v30) * p11 + v30,
            (translation2[4] - v31) * p11 + v31
        }
    }
end

function t1.blend_sample_into(p12, p13, p14) -- line: 121
    local rotation = p12.rotation
    local rotation2 = p13.rotation
    local v32 = rotation[1]
    local v33 = rotation[2]
    local v34 = rotation[3]
    local v35 = rotation[4]
    local v36 = rotation2[1]
    local v37 = rotation2[2]
    local v38 = rotation2[3]
    local v39 = rotation2[4]
    local v40, v41, v42, v43

    if v32 * v36 + v33 * v37 + v34 * v38 + v35 * v39 > 0 then
        v40 = (v36 - v32) * p14 + v32
        v41 = (v37 - v33) * p14 + v33
        v42 = (v38 - v34) * p14 + v34
        v43 = (v39 - v35) * p14 + v35
    else
        v40 = -(v36 + v32) * p14 + v32
        v41 = -(v37 + v33) * p14 + v33
        v42 = -(v38 + v34) * p14 + v34
        v43 = -(v39 + v35) * p14 + v35
    end

    local v44 = v40 * v40 + v41 * v41 + v42 * v42 + v43 * v43
    local v45 = 1 / math.sqrt(v44)
    local v46 = v45 * 0.5 * (-v44 * (v45 * v45) + 1) + v45
    local v47 = v46 * 0.5 * (-v44 * (v46 * v46) + 1) + v46
    local scale = p12.scale
    local scale2 = p13.scale
    local translation = p12.translation
    local translation2 = p13.translation
    local v48 = scale[1]
    local v49 = scale[2]
    local v50 = scale[3]
    local v51 = scale[4]
    local v52 = translation[1]
    local v53 = translation[2]
    local v54 = translation[3]
    local v55 = translation[4]
    local v56 = (scale2[1] - v48) * p14 + v48
    local v57 = (scale2[2] - v49) * p14 + v49
    local v58 = (scale2[3] - v50) * p14 + v50
    local v59 = (scale2[4] - v51) * p14 + v51
    local v60 = (translation2[1] - v52) * p14 + v52
    local v61 = (translation2[2] - v53) * p14 + v53
    local v62 = (translation2[3] - v54) * p14 + v54
    local v63 = (translation2[4] - v55) * p14 + v55

    scale[1] = v56
    scale[2] = v57
    scale[3] = v58
    scale[4] = v59

    local v64 = v40 * v47
    local v65 = v41 * v47
    local v66 = v42 * v47
    local v67 = v43 * v47

    rotation[1] = v64
    rotation[2] = v65
    rotation[3] = v66
    rotation[4] = v67
    translation[1] = v60
    translation[2] = v61
    translation[3] = v62
    translation[4] = v63
end

function t1.channel_blend_sample_into(p15, p16, p17, p18) -- line: 160
    -- upvalues: t1 (copy)
    local v68 = p17 * (if p18 then p15.translation[4] else p16.translation[4])

    if v68 > 1 then
        v68 = 1
    end

    if v68 < 0 then
        v68 = 0
    end

    t1.blend_sample_into(p15, p16, v68)
end

function t1.channel_blend_sample(p19, p20, p21, p22) -- line: 170
    -- upvalues: t1 (copy)
    local v69 = p21 * (if p22 then p19.translation[4] else p20.translation[4])

    if v69 > 1 then
        v69 = 1
    end

    if v69 < 0 then
        v69 = 0
    end

    return t1.blend_sample(p19, p20, v69)
end

function t1.interpolate(p23, p24, p25) -- line: 179
    return {
        (p24[1] - p23[1]) * p25 + p23[1],
        (p24[2] - p23[2]) * p25 + p23[2],
        (p24[3] - p23[3]) * p25 + p23[3],
        (p24[4] - p23[4]) * p25 + p23[4]
    }
end

interpolate = t1.interpolate

function t1.weighted(p26, p27) -- line: 193
    -- upvalues: v1 (copy)
    local v70 = p26[1]

    if v70 == nil then
        error({
            tag = "ShortInput"
        }, 0)
    end

    if #p26 ~= #p27 then
        error({
            tag = "ShortInput"
        }, 0)
    end

    for _, v71 in p26 do
        if #v71 ~= #v70 then
            error({
                tag = "ShortInput"
            }, 0)
        end
    end

    for _, v72 in p27 do
        if v72 ~= v72 or v72 == 1e999 or v72 == (-1e999) then
            error({
                tag = "NonFiniteWeight"
            }, 0)
        end
    end

    local v73 = table.create(#v70)

    for v74, v75 in v70 do
        local v76 = p27[1]

        v73[v74] = {
            scale = {
                v75.scale[1] * v76,
                v75.scale[2] * v76,
                v75.scale[3] * v76,
                v75.scale[4] * v76
            },
            rotation = {
                v75.rotation[1] * v76,
                v75.rotation[2] * v76,
                v75.rotation[3] * v76,
                v75.rotation[4] * v76
            },
            translation = {
                v75.translation[1] * v76,
                v75.translation[2] * v76,
                v75.translation[3] * v76,
                v75.translation[4] * v76
            }
        }
    end

    for i = 2, #p26 do
        local v77 = p26[i]
        local v78 = p27[i]

        for j = 1, #v73 do
            local v79 = v73[j]
            local v80 = v77[j]

            for k = 0, 3 do
                v79.scale[k + 1] = v80.scale[k + 1] * v78 + v79.scale[k + 1]
                v79.rotation[k + 1] = v80.rotation[k + 1] * v78 + v79.rotation[k + 1]
                v79.translation[k + 1] = v80.translation[k + 1] * v78 + v79.translation[k + 1]
            end
        end
    end

    for _, v81 in v73 do
        local v82 = v1.dot4(v81.rotation, v81.rotation)

        if v82 ~= v82 or v82 == 1e999 or v82 == (-1e999) or v82 <= 0 then
            error({
                tag = "InvalidQuaternion"
            }, 0)
        end

        local v83 = v1.reciprocal_square_root_estimate(v82)
        local v84 = v83 * 0.5 * (-v82 * (v83 * v83) + 1) + v83
        local v85 = v84 * 0.5 * (-v82 * (v84 * v84) + 1) + v84

        v81.rotation = {
            v81.rotation[1] * v85,
            v81.rotation[2] * v85,
            v81.rotation[3] * v85,
            v81.rotation[4] * v85
        }

        for _, v86 in v81.rotation do
            if v86 ~= v86 or v86 == 1e999 or v86 == (-1e999) then
                error({
                    tag = "InvalidQuaternion"
                }, 0)
            end
        end
    end

    return v73
end

return t1
