-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/trigonometry")

import("skate_core/physics/native_arithmetic")

local v2 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {}

function t1.quaternion_from_angles(p1, p2, p3) -- line: 17
    -- upvalues: v1 (copy)
    local v3, v4 = v1.sin_cos(p1 * 0.5)
    local v5, v6 = v1.sin_cos(p2 * 0.5)
    local v7, v8 = v1.sin_cos(p3 * 0.5)
    local v9 = v4 * v8
    local v10 = v3 * v8
    local v11 = v3 * v7
    local v12 = v4 * v7

    return {
        v6 * v10 - v5 * v12,
        v6 * v11 + v5 * v9,
        v6 * v12 - v5 * v10,
        v6 * v9 + v5 * v11
    }
end

function t1.basis_from_angles(p4, p5, p6) -- line: 35
    -- upvalues: v1 (copy)
    local v13, v14 = v1.sin_cos(p4)
    local v15, v16 = v1.sin_cos(p5)
    local v17, v18 = v1.sin_cos(p6)
    local v19 = v14 * v17
    local v20 = v14 * v18
    local v21 = v13 * v17
    local v22 = v13 * v18

    return {
        columns = {
            {
                v16 * v18,
                v16 * v17,
                -v15
            },
            {
                v15 * v22 - v19,
                v15 * v21 + v20,
                v16 * v13
            },
            {
                v15 * v20 + v21,
                v15 * v19 - v22,
                v16 * v14
            }
        }
    }
end

function t1.rotate_about_axis(p7, p8, p9) -- line: 54
    -- upvalues: v1 (copy)
    local v23 = v1.cos(p9)
    local v24 = v1.sin(p9)
    local v25 = p8[1]
    local v26 = p8[2]
    local v27 = p8[3]
    local v28 = v24 * v25
    local v29 = v24 * v26
    local v30 = v24 * v27
    local v31 = 1 - v23
    local v32 = v31 * v25
    local v33 = v31 * v26
    local v34 = v31 * v27
    local t2 = {
        {
            v25 * v32 + v23,
            v32 * v26 + v30,
            v32 * v27 - v29
        },
        {
            v33 * v25 - v30,
            v33 * v26 + v23,
            v33 * v27 + v28
        },
        {
            v34 * v25 + v29,
            v34 * v26 - v28,
            v27 * v34 + v23
        }
    }
    local t3 = {}

    for i = 0, 2 do
        local v35 = p7.columns[i + 1]
        local t4 = {}

        for j = 0, 2 do
            t4[j + 1] = t2[3][j + 1] * v35[3] + (t2[2][j + 1] * v35[2] + t2[1][j + 1] * v35[1])
        end

        t3[i + 1] = t4
    end

    return {
        columns = t3
    }
end

function t1.look_basis(p10) -- line: 85
    -- upvalues: rt (copy), t1 (copy)
    local v36 = t1.normalize(t1.cross({ 0, 1, 0 }, p10))

    return {
        columns = {
            v36,
            t1.normalize(t1.cross(p10, v36)),
            rt.copy(p10)
        }
    }
end

function t1.cross(p11, p12) -- line: 93
    return {
        -p11[3] * p12[2] + p11[2] * p12[3],
        -p11[1] * p12[3] + p11[3] * p12[1],
        -p11[2] * p12[1] + p11[1] * p12[2]
    }
end

function t1.normalize(p13) -- line: 102
    -- upvalues: v2 (copy)
    local v37 = p13[1] * p13[1] + p13[2] * p13[2] + p13[3] * p13[3]
    local v38 = v2.estimate(v37)
    local v39 = v38 * 0.5 * (-v37 * (v38 * v38) + 1) + v38
    local v40 = v39 * 0.5 * (-v37 * (v39 * v39) + 1) + v39
    local v41 = table.create(#p13)

    for i = 1, #p13 do
        v41[i] = p13[i] * v40
    end

    return v41
end

function t1.quaternion_from_angles_lanes(p14, p15, p16) -- line: 122
    -- upvalues: v1 (copy)
    local v42, v43 = v1.sin_cos(p14 * 0.5)
    local v44, v45 = v1.sin_cos(p15 * 0.5)
    local v46, v47 = v1.sin_cos(p16 * 0.5)
    local v48 = v43 * v47
    local v49 = v42 * v47
    local v50 = v42 * v46
    local v51 = v43 * v46

    return v45 * v49 - v44 * v51, v45 * v50 + v44 * v48, v45 * v51 - v44 * v49, v45 * v48 + v44 * v50
end

function t1.basis_from_angles_lanes(p17, p18, p19) -- line: 134
    -- upvalues: v1 (copy)
    local v52, v53 = v1.sin_cos(p17)
    local v54, v55 = v1.sin_cos(p18)
    local v56, v57 = v1.sin_cos(p19)
    local v58 = v53 * v56
    local v59 = v53 * v57
    local v60 = v52 * v56
    local v61 = v52 * v57

    return v55 * v57, v55 * v56, -v54, v54 * v61 - v58, v54 * v60 + v59, v55 * v52, v54 * v59 + v60, v54 * v58 - v61, v55 * v53
end

function t1.quaternion_at_lanes(p20, p21, p22, p23) -- line: 165
    local v62 = p20 * 1.4142135381698608
    local v63 = p21 * 1.4142135381698608
    local v64 = p22 * 1.4142135381698608
    local v65 = p23 * 1.4142135381698608

    return v64 * v62 + v65 * v63, v63 * v64 - v65 * v62, -v62 * v62 + 0.5 + (-v63 * v63 + 0.5)
end

function t1.normalize3(p24, p25, p26) -- line: 171
    local v66 = p24 * p24 + p25 * p25 + p26 * p26
    local v67 = 1 / math.sqrt(v66)
    local v68 = v67 * 0.5 * (-v66 * (v67 * v67) + 1) + v67
    local v69 = v68 * 0.5 * (-v66 * (v68 * v68) + 1) + v68

    return p24 * v69, p25 * v69, p26 * v69
end

return t1
