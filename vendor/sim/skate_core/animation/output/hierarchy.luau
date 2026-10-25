-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

function t1.compose_hierarchy(p1, p2, p3, p4, p5) -- line: 20
    -- upvalues: rt (copy), t1 (copy)
    local v1 = math.max(p1, 0)

    t1.validate(v1, p2, p3, #p4, #p5)
    p5[1] = rt.copy(p4[1])

    for i = 0, v1 - 1 do
        local v2 = p2[i + 1]

        if v2 == -1 or v2 == p3 then
            p5[i + 1] = rt.copy(p4[i + 1])
        else
            p5[i + 1] = t1.concatenate(p4[i + 1], p5[v2 + 1])
        end
    end
end

function t1.compose_hierarchy_in_place(p6, p7, p8, p9) -- line: 35
    -- upvalues: t1 (copy)
    local v3 = math.max(p6, 0)

    t1.validate(v3, p7, p8, #p9, #p9)

    for i = 0, v3 - 1 do
        local v4 = p7[i + 1]

        if v4 ~= -1 and v4 ~= p8 then
            p9[i + 1] = t1.concatenate(p9[i + 1], p9[v4 + 1])
        end
    end
end

function t1.validate(p10, p11, p12, p13, p14) -- line: 46
    if p13 < math.max(p10, 1) then
        error({
            tag = "ShortInput"
        }, 0)
    end

    if p14 < math.max(p10, 1) then
        error({
            tag = "ShortOutput"
        }, 0)
    end

    if #p11 < p10 then
        error({
            tag = "ShortParents"
        }, 0)
    end

    for i = 0, p10 - 1 do
        local v5 = p11[i + 1]

        if v5 ~= -1 and v5 ~= p12 and (v5 < 0 or p14 <= v5) then
            error({
                tag = "InvalidParent",
                bone = i,
                parent = v5
            }, 0)
        end
    end
end

function t1.concatenate_reference(p15, p16) -- line: 65
    -- upvalues: rt (copy)
    local v6 = rt.copy(p15)

    for i = 0, 3 do
        for j = 0, 3 do
            local v7 = if i == 3 then p16[1][j + 1] * p15[i + 1][1] + p16[4][j + 1] else p16[1][j + 1] * p15[i + 1][1]
            local v8 = p16[2][j + 1] * p15[i + 1][2] + v7

            v6[i + 1][j + 1] = p16[3][j + 1] * p15[i + 1][3] + v8
        end
    end

    return v6
end

local function concatenate_lanes(p17, p18, p19, p20, p21) -- line: 85
    local v9 = p21[1]
    local v10 = p21[2]
    local v11 = p21[3]
    local v12 = p21[4]
    local v13 = v9[1]
    local v14 = v9[2]
    local v15 = v9[3]
    local v16 = v9[4]
    local v17 = v10[1]
    local v18 = v10[2]
    local v19 = v10[3]
    local v20 = v10[4]
    local v21 = v11[1]
    local v22 = v11[2]
    local v23 = v11[3]
    local v24 = v11[4]
    local v25 = v12[1]
    local v26 = v12[2]
    local v27 = v12[3]
    local v28 = v12[4]
    local v29 = p17[1]
    local v30 = p17[2]
    local v31 = p17[3]
    local v32 = v21 * v31 + (v17 * v30 + v13 * v29)
    local v33 = v22 * v31 + (v18 * v30 + v14 * v29)
    local v34 = v23 * v31 + (v19 * v30 + v15 * v29)
    local v35 = v24 * v31 + (v20 * v30 + v16 * v29)
    local v36 = p18[1]
    local v37 = p18[2]
    local v38 = p18[3]
    local v39 = v21 * v38 + (v17 * v37 + v13 * v36)
    local v40 = v22 * v38 + (v18 * v37 + v14 * v36)
    local v41 = v23 * v38 + (v19 * v37 + v15 * v36)
    local v42 = v24 * v38 + (v20 * v37 + v16 * v36)
    local v43 = p19[1]
    local v44 = p19[2]
    local v45 = p19[3]
    local v46 = v21 * v45 + (v17 * v44 + v13 * v43)
    local v47 = v22 * v45 + (v18 * v44 + v14 * v43)
    local v48 = v23 * v45 + (v19 * v44 + v15 * v43)
    local v49 = v24 * v45 + (v20 * v44 + v16 * v43)
    local v50 = p20[1]
    local v51 = p20[2]
    local v52 = p20[3]

    return v32, v33, v34, v35, v39, v40, v41, v42, v46, v47, v48, v49, v21 * v52 + (v17 * v51 + (v13 * v50 + v25)), v22 * v52 + (v18 * v51 + (v14 * v50 + v26)), v23 * v52 + (v19 * v51 + (v15 * v50 + v27)), v24 * v52 + (v20 * v51 + (v16 * v50 + v28))
end

function t1.concatenate(p22, p23) -- line: 118
    -- upvalues: t1 (copy), concatenate_lanes (copy)
    local v53 = p22[1]
    local v54 = p22[2]
    local v55 = p22[3]
    local v56 = p22[4]

    if #p22 ~= 4 or #v53 ~= 4 or #v54 ~= 4 or #v55 ~= 4 or #v56 ~= 4 then
        return t1.concatenate_reference(p22, p23)
    end

    local v57, v58, v59, v60, v61, v62, v63, v64, v65, v66, v67, v68, v69, v70, v71, v72 = concatenate_lanes(v53, v54, v55, v56, p23)

    return {
        { v57, v58, v59, v60 },
        { v61, v62, v63, v64 },
        { v65, v66, v67, v68 },
        { v69, v70, v71, v72 }
    }
end

function t1.concatenate_in_place(p24, p25) -- line: 139
    -- upvalues: concatenate_lanes (copy)
    local v73 = p24[1]
    local v74 = p24[2]
    local v75 = p24[3]
    local v76 = p24[4]
    local v77, v78, v79, v80, v81, v82, v83, v84, v85, v86, v87, v88, v89, v90, v91, v92 = concatenate_lanes(v73, v74, v75, v76, p25)

    v73[1] = v77
    v73[2] = v78
    v73[3] = v79
    v73[4] = v80
    v74[1] = v81
    v74[2] = v82
    v74[3] = v83
    v74[4] = v84
    v75[1] = v85
    v75[2] = v86
    v75[3] = v87
    v75[4] = v88
    v76[1] = v89
    v76[2] = v90
    v76[3] = v91
    v76[4] = v92
end

function t1.compose_hierarchy_in_place_owned(p26, p27, p28, p29) -- line: 153
    -- upvalues: t1 (copy)
    local v93 = math.max(p26, 0)

    t1.validate(v93, p27, p28, #p29, #p29)

    for i = 0, v93 - 1 do
        local v94 = p27[i + 1]

        if v94 ~= -1 and v94 ~= p28 then
            t1.concatenate_in_place(p29[i + 1], p29[v94 + 1])
        end
    end
end

return t1
