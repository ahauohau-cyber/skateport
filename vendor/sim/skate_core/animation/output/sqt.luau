-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Sqt = {}
}

function t1.Sqt.eq(p1, p2) -- line: 17
    for i = 1, 4 do
        if p1.scale[i] ~= p2.scale[i] or p1.rotation[i] ~= p2.rotation[i] or p1.translation[i] ~= p2.translation[i] then
            return false
        end
    end

    return true
end

function t1.sqt_to_local(p3, p4, p5, p6) -- line: 37
    -- upvalues: rt (copy), t1 (copy)
    if p4 >= 128 or rt.irem(p4, 16) ~= 0 then
        error({
            tag = "InvalidCacheOffset"
        }, 0)
    end

    local v1 = p3 + 3

    if v1 > 18446744073709552000 then
        error({
            tag = "CountOverflow"
        }, 0)
    end

    local v2 = v1 - rt.irem(v1, 4)

    if #p5 < v2 then
        error({
            tag = "ShortInput"
        }, 0)
    end

    local v3 = if v2 == 0 then 0 else rt.idiv(128 - p4, 4)
    local v5 = v2 + math.ceil(v3 / 16)

    if v5 > 18446744073709552000 then
        error({
            tag = "CountOverflow"
        }, 0)
    end

    if #p6 < v5 then
        error({
            tag = "ShortOutput"
        }, 0)
    end

    local v6 = v5 - 1
    local n1 = 0

    for i = v2, v6 do
        local v7 = p6[i + 1]

        for j = 1, 4 do
            local v8 = v7[j]

            if n1 < v3 then
                v8[1] = 0
                n1 += 1
            end

            if n1 < v3 then
                v8[2] = 0
                n1 += 1
            end

            if n1 < v3 then
                v8[3] = 0
                n1 += 1
            end

            if n1 < v3 then
                v8[4] = 0
                n1 += 1
            end
        end
    end

    for i = 0, v2 - 1 do
        p6[i + 1] = t1.sqt_to_matrix(p5[i + 1])
    end

    return v2
end

function t1.sqt_to_matrix(p7) -- line: 89
    local v9 = p7.rotation[1]
    local v10 = p7.rotation[2]
    local v11 = p7.rotation[3]
    local v12 = p7.rotation[4]
    local v13 = p7.scale[1]
    local v14 = p7.scale[2]
    local v15 = p7.scale[3]
    local v16 = v9 * v9
    local v17 = v10 * v10
    local v18 = v11 * v11
    local v19 = v9 * v10
    local v20 = v12 * v11
    local v21 = v9 * v11
    local v22 = v12 * v10
    local v23 = v10 * v11
    local v24 = v12 * v9

    return {
        {
            (-(v17 + v18) * 2 + 1) * v13,
            (v19 + v20) * 2 * v13,
            (v21 - v22) * 2 * v13,
            0
        },
        {
            (v19 - v20) * 2 * v14,
            (-(v16 + v18) * 2 + 1) * v14,
            (v23 + v24) * 2 * v14,
            0
        },
        {
            (v21 + v22) * 2 * v15,
            (v23 - v24) * 2 * v15,
            (-(v16 + v17) * 2 + 1) * v15,
            0
        },
        {
            p7.translation[1],
            p7.translation[2],
            p7.translation[3],
            1
        }
    }
end

function t1.sqt_to_matrix_into(p8, p9) -- line: 135
    local rotation, scale, translation = p9.rotation, p9.scale, p9.translation
    local v25 = rotation[1]
    local v26 = rotation[2]
    local v27 = rotation[3]
    local v28 = rotation[4]
    local v29 = scale[1]
    local v30 = scale[2]
    local v31 = scale[3]
    local v32 = translation[1]
    local v33 = translation[2]
    local v34 = translation[3]
    local v35 = v25 * v25
    local v36 = v26 * v26
    local v37 = v27 * v27
    local v38 = v25 * v26
    local v39 = v28 * v27
    local v40 = v25 * v27
    local v41 = v28 * v26
    local v42 = v26 * v27
    local v43 = v28 * v25
    local v44 = p8[1]

    v44[1] = (-(v36 + v37) * 2 + 1) * v29
    v44[2] = (v38 + v39) * 2 * v29
    v44[3] = (v40 - v41) * 2 * v29
    v44[4] = 0

    local v45 = p8[2]

    v45[1] = (v38 - v39) * 2 * v30
    v45[2] = (-(v35 + v37) * 2 + 1) * v30
    v45[3] = (v42 + v43) * 2 * v30
    v45[4] = 0

    local v46 = p8[3]

    v46[1] = (v40 + v41) * 2 * v31
    v46[2] = (v42 - v43) * 2 * v31
    v46[3] = (-(v35 + v36) * 2 + 1) * v31
    v46[4] = 0

    local v47 = p8[4]

    v47[1] = v32
    v47[2] = v33
    v47[3] = v34
    v47[4] = 1

    return p8
end

function t1.sqt_to_matrices_into(p10, p11, p12) -- line: 177
    local rotation, scale, translation = p12.rotation, p12.scale, p12.translation
    local v48 = rotation[1]
    local v49 = rotation[2]
    local v50 = rotation[3]
    local v51 = rotation[4]
    local v52 = scale[1]
    local v53 = scale[2]
    local v54 = scale[3]
    local v55 = translation[1]
    local v56 = translation[2]
    local v57 = translation[3]
    local v58 = v48 * v48
    local v59 = v49 * v49
    local v60 = v50 * v50
    local v61 = v48 * v49
    local v62 = v51 * v50
    local v63 = v48 * v50
    local v64 = v51 * v49
    local v65 = v49 * v50
    local v66 = v51 * v48
    local v67 = (-(v59 + v60) * 2 + 1) * v52
    local v68 = (v61 + v62) * 2 * v52
    local v69 = (v63 - v64) * 2 * v52
    local v70 = p10[1]

    v70[1] = v67
    v70[2] = v68
    v70[3] = v69
    v70[4] = 0

    local v71 = p11[1]

    v71[1] = v67
    v71[2] = v68
    v71[3] = v69
    v71[4] = 0

    local v72 = (v61 - v62) * 2 * v53
    local v73 = (-(v58 + v60) * 2 + 1) * v53
    local v74 = (v65 + v66) * 2 * v53
    local v75 = p10[2]

    v75[1] = v72
    v75[2] = v73
    v75[3] = v74
    v75[4] = 0

    local v76 = p11[2]

    v76[1] = v72
    v76[2] = v73
    v76[3] = v74
    v76[4] = 0

    local v77 = (v63 + v64) * 2 * v54
    local v78 = (v65 - v66) * 2 * v54
    local v79 = (-(v58 + v59) * 2 + 1) * v54
    local v80 = p10[3]

    v80[1] = v77
    v80[2] = v78
    v80[3] = v79
    v80[4] = 0

    local v81 = p11[3]

    v81[1] = v77
    v81[2] = v78
    v81[3] = v79
    v81[4] = 0

    local v82 = p10[4]

    v82[1] = v55
    v82[2] = v56
    v82[3] = v57
    v82[4] = 1

    local v83 = p11[4]

    v83[1] = v55
    v83[2] = v56
    v83[3] = v57
    v83[4] = 1
end

return t1
