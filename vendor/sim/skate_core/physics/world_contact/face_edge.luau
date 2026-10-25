-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local v8 = require(sim.import)("skate_core/physics/world_contact/prism_math")
local load, dot, sub, madd = v8.load, v8.dot, v8.sub, v8.madd
local t1 = {}

function t1.store(p3, p4, p5) -- line: 34
    -- upvalues: v1 (copy)
    local v9 = p4 + 1
    local v10 = p5[1]
    local v11

    if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
        local v12 = math.abs(v10) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13

        if v10 < 0 then
            v11 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readu32(v1, 0)
    end

    p3[v9] = v11

    local v15 = p4 + 2
    local v16 = p5[2]
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    p3[v15] = v17

    local v21 = p4 + 3
    local v22 = p5[3]
    local v23

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        local v24 = math.abs(v22) * 7.1362384635298E+44
        local v25 = math.floor(v24)
        local v26 = v24 - v25

        v23 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

        if v22 < 0 then
            v23 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v22)
        v23 = buffer.readu32(v1, 0)
    end

    p3[v21] = v23

    local v27 = p4 + 4
    local v28 = p5[4]
    local v29

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v30 = math.abs(v28) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if v28 < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v28)
        v29 = buffer.readu32(v1, 0)
    end

    p3[v27] = v29
end

local function end_(p6, p7) -- line: 43
    -- upvalues: load (copy)
    local v33 = load(p6, 4 + p7 * 16)
    local v34 = load(p6, 8 + p7 * 16)
    local v35 = load(p6, 16 + p7 * 16)

    return {
        v34[1] * v35[1] + v33[1],
        v34[2] * v35[2] + v33[2],
        v34[3] * v35[3] + v33[3],
        v34[4] * v35[4] + v33[4]
    }
end

t1["end"] = end_

function t1.intersect_feature_corner_edge(p8, p9, p10, p11, p12, p13) -- line: 59
    -- upvalues: rt (copy), v1 (copy), load (copy), dot (copy), sub (copy), madd (copy), end_ (copy)
    local v36 = if p13 then 0 else 64
    local v37 = if p13 then 64 else 0
    local v38 = if p11 == 0 then p9[141] - 1 else p11 - 1

    if not (p11 < 8 and p12 < 8 and v38 >= 0 and v38 < 8) then
        error("assertion failed: corner < 8 && edge < 8 && previous < 8", 0)
    end

    local v39 = load(p10, 8 + p12 * 16)

    local function nearly_parallel(p14) -- line: 73
        -- upvalues: p9 (copy), v39 (copy), load (copy), dot (copy)
        return math.abs((dot(load(p9, 12 + p14 * 16), v39))) < 0.05000000074505806
    end

    local v41 = dot(load(p9, 12 + v38 * 16), v39)
    local v42, v43

    if math.abs(v41) < 0.05000000074505806 then
        v42 = true
    else
        v43 = dot(load(p9, 12 + p11 * 16), v39)
        v42 = math.abs(v43) < 0.05000000074505806
        v38 = p11
    end

    local v44 = load(p10, 4 + p12 * 16)
    local v45, v46, v47, v48, v49, v50, v51, v52, v53, v54, v55, v56, v57

    if not v42 then
        p9[1] = p11 * 2 + 1
        p10[1] = (p12 + 1) * 2

        local v58 = load(p9, 4 + p11 * 16)

        v45 = dot(v39, sub(v58, v44))

        if v45 < rt.F32_MIN_POSITIVE then
            v45 = 0
            p10[1] = rt.wrapping_sub_u32(p10[1], 1)
        else
            v46 = load(p10, 16 + p12 * 16)

            if v46[1] < v45 and v46[2] < v45 and v46[3] < v45 and v46[4] < v45 then
                p10[1] = rt.wrapping_add_u32(p10[1], 1)
                v45 = v46[1]
            end
        end

        v43 = v36 + 1
        v48 = v58[1]

        local v59

        if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
            v55 = math.abs(v48) * 7.1362384635298E+44
            v57 = math.floor(v55)
            v56 = v55 - v57
            v59 = if v56 > 0.5 or v56 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v48 < 0 then
                v59 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v48)
            v59 = buffer.readu32(v1, 0)
        end

        p8[v43] = v59
        v43 = v36 + 2
        v48 = v58[2]

        local v60

        if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
            v55 = math.abs(v48) * 7.1362384635298E+44
            v57 = math.floor(v55)
            v56 = v55 - v57
            v60 = if v56 > 0.5 or v56 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v48 < 0 then
                v60 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v48)
            v60 = buffer.readu32(v1, 0)
        end

        p8[v43] = v60
        v43 = v36 + 3
        v48 = v58[3]

        local v61

        if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
            v55 = math.abs(v48) * 7.1362384635298E+44
            v57 = math.floor(v55)
            v56 = v55 - v57
            v61 = if v56 > 0.5 or v56 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v48 < 0 then
                v61 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v48)
            v61 = buffer.readu32(v1, 0)
        end

        p8[v43] = v61
        v43 = v36 + 4
        v48 = v58[4]

        local v62

        if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
            v55 = math.abs(v48) * 7.1362384635298E+44
            v57 = math.floor(v55)
            v56 = v55 - v57
            v62 = if v56 > 0.5 or v56 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v48 < 0 then
                v62 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v48)
            v62 = buffer.readu32(v1, 0)
        end

        p8[v43] = v62
        v43 = madd(v39, v45, v44)
        v41 = v37 + 1
        v54 = v43[1]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v55 = math.abs(v54) * 7.1362384635298E+44
            v57 = math.floor(v55)
            v56 = v55 - v57
            v49 = if v56 > 0.5 or v56 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v54 < 0 then
                v49 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v49 = buffer.readu32(v1, 0)
        end

        p8[v41] = v49
        v41 = v37 + 2
        v54 = v43[2]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v50 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v50 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v50 = buffer.readu32(v1, 0)
        end

        p8[v41] = v50
        v41 = v37 + 3
        v54 = v43[3]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v51 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v51 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v51 = buffer.readu32(v1, 0)
        end

        p8[v41] = v51
        v41 = v37 + 4
        v54 = v43[4]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v52 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v52 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v52 = buffer.readu32(v1, 0)
        end

        p8[v41] = v52

        return 1
    end

    p9[1] = (v38 + 1) * 2
    p10[1] = (p12 + 1) * 2
    v42 = load(p9, 4 + v38 * 16)
    v45 = load(p9, 8 + v38 * 16)
    v46 = dot(v45, sub(v44, v42))

    if v46 < rt.F32_MIN_POSITIVE then
        v41 = v36 + 1
        v54 = v42[1]

        local v63

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v63 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v63 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v63 = buffer.readu32(v1, 0)
        end

        p8[v41] = v63
        v41 = v36 + 2
        v54 = v42[2]

        local v64

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v64 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v64 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v64 = buffer.readu32(v1, 0)
        end

        p8[v41] = v64
        v41 = v36 + 3
        v54 = v42[3]

        local v65

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v65 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v65 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v65 = buffer.readu32(v1, 0)
        end

        p8[v41] = v65
        v41 = v36 + 4
        v54 = v42[4]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v48 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v48 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v48 = buffer.readu32(v1, 0)
        end

        p8[v41] = v48
        v41 = v37 + 1
        v54 = v44[1]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v49 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v49 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v49 = buffer.readu32(v1, 0)
        end

        p8[v41] = v49
        v41 = v37 + 2
        v54 = v44[2]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v50 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v50 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v50 = buffer.readu32(v1, 0)
        end

        p8[v41] = v50
        v41 = v37 + 3
        v54 = v44[3]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v51 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v51 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v51 = buffer.readu32(v1, 0)
        end

        p8[v41] = v51
        v41 = v37 + 4
        v54 = v44[4]

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            v57 = math.abs(v54) * 7.1362384635298E+44
            v53 = math.floor(v57)
            v47 = v57 - v53
            v52 = if v47 > 0.5 or v47 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v54 < 0 then
                v52 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v52 = buffer.readu32(v1, 0)
        end

        p8[v41] = v52
        p9[1] = rt.wrapping_sub_u32(p9[1], 1)
        p10[1] = rt.wrapping_sub_u32(p10[1], 1)

        return 1
    end

    v43 = load(p9, 16 + v38 * 16)
    v41 = load(p10, 16 + p12 * 16)
    v52 = true

    for i = 0, 3 do
        if not (rt.F32_MIN_POSITIVE > v43[i + 1] + v41[i + 1] - v46) then
            v52 = false
            break
        end
    end

    local v66, v67, v68, v69, v70, v71, v72, v73, v74, v75

    if v52 then
        v70 = end_(p9, v38)
        v55 = v36 + 1
        v53 = v70[1]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v69 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v69 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v69 = buffer.readu32(v1, 0)
        end

        p8[v55] = v69
        v55 = v36 + 2
        v53 = v70[2]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v71 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v71 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v71 = buffer.readu32(v1, 0)
        end

        p8[v55] = v71
        v55 = v36 + 3
        v53 = v70[3]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v72 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v72 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v72 = buffer.readu32(v1, 0)
        end

        p8[v55] = v72
        v55 = v36 + 4
        v53 = v70[4]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v73 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v73 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v73 = buffer.readu32(v1, 0)
        end

        p8[v55] = v73
        v70 = end_(p10, p12)
        v55 = v37 + 1
        v53 = v70[1]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v74 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v74 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v74 = buffer.readu32(v1, 0)
        end

        p8[v55] = v74
        v55 = v37 + 2
        v53 = v70[2]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v75 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v75 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v75 = buffer.readu32(v1, 0)
        end

        p8[v55] = v75
        v55 = v37 + 3
        v53 = v70[3]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v56 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v56 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v56 = buffer.readu32(v1, 0)
        end

        p8[v55] = v56
        v55 = v37 + 4
        v53 = v70[4]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v57 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v57 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v57 = buffer.readu32(v1, 0)
        end

        p8[v55] = v57
        p9[1] = rt.wrapping_add_u32(p9[1], 1)
        p10[1] = rt.wrapping_add_u32(p10[1], 1)

        return 1
    end

    v52 = true

    for i = 1, 4 do
        if not (rt.F32_MIN_POSITIVE > v43[i] - v46) then
            v52 = false
            break
        end
    end

    local v76, v77

    if v52 then
        local v78 = end_(p9, v38)
        local v79 = v36 + 1

        v53 = v78[1]

        if v53 == 0 then
            buffer.writef32(v1, 0, v53)
            v67 = buffer.readu32(v1, 0)
        elseif v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67

            if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then
                v67 += 1
            end

            if v53 < 0 then
                v67 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v67 = buffer.readu32(v1, 0)
        end

        p8[v79] = v67

        local v80 = v36 + 2

        v53 = v78[2]

        local v81

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v81 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v81 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v81 = buffer.readu32(v1, 0)
        end

        p8[v80] = v81
        v80 = v36 + 3
        v53 = v78[3]

        local v82

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v82 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v82 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v82 = buffer.readu32(v1, 0)
        end

        p8[v80] = v82
        v80 = v36 + 4
        v53 = v78[4]

        local v83

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v83 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v83 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v83 = buffer.readu32(v1, 0)
        end

        p8[v80] = v83
        v78 = sub(v44, {
            v39[1] * (v43[1] - v46),
            v39[2] * (v43[2] - v46),
            v39[3] * (v43[3] - v46),
            v39[4] * (v43[4] - v46)
        })
        v80 = v37 + 1
        v53 = v78[1]

        local v84

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v84 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v84 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v84 = buffer.readu32(v1, 0)
        end

        p8[v80] = v84
        v80 = v37 + 2
        v53 = v78[2]

        local v85

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v85 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v85 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v85 = buffer.readu32(v1, 0)
        end

        p8[v80] = v85
        v80 = v37 + 3
        v53 = v78[3]

        local v86

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v86 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v86 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v86 = buffer.readu32(v1, 0)
        end

        p8[v80] = v86
        v80 = v37 + 4
        v53 = v78[4]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v69 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v69 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v69 = buffer.readu32(v1, 0)
        end

        p8[v80] = v69
    else
        local v87 = madd(v45, v46, v42)
        local v88 = v36 + 1

        v53 = v87[1]

        local v89

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v89 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v89 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v89 = buffer.readu32(v1, 0)
        end

        p8[v88] = v89
        v88 = v36 + 2
        v53 = v87[2]

        local v90

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v90 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v90 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v90 = buffer.readu32(v1, 0)
        end

        p8[v88] = v90
        v88 = v36 + 3
        v53 = v87[3]

        local v91

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v91 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v91 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v91 = buffer.readu32(v1, 0)
        end

        p8[v88] = v91
        v88 = v36 + 4
        v53 = v87[4]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v69 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v69 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v69 = buffer.readu32(v1, 0)
        end

        p8[v88] = v69
        v87 = v37 + 1
        v69 = v44[1]

        local v92

        if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
            v76 = math.abs(v69) * 7.1362384635298E+44
            v66 = math.floor(v76)
            v77 = v76 - v66
            v92 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v69 < 0 then
                v92 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v69)
            v92 = buffer.readu32(v1, 0)
        end

        p8[v87] = v92
        v87 = v37 + 2
        v69 = v44[2]

        local v93

        if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
            v76 = math.abs(v69) * 7.1362384635298E+44
            v66 = math.floor(v76)
            v77 = v76 - v66
            v93 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v69 < 0 then
                v93 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v69)
            v93 = buffer.readu32(v1, 0)
        end

        p8[v87] = v93
        v87 = v37 + 3
        v69 = v44[3]

        local v94

        if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
            v76 = math.abs(v69) * 7.1362384635298E+44
            v66 = math.floor(v76)
            v77 = v76 - v66
            v94 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v69 < 0 then
                v94 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v69)
            v94 = buffer.readu32(v1, 0)
        end

        p8[v87] = v94
        v87 = v37 + 4
        v69 = v44[4]

        local v95

        if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
            v76 = math.abs(v69) * 7.1362384635298E+44
            v66 = math.floor(v76)
            v77 = v76 - v66
            v95 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v69 < 0 then
                v95 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v69)
            v95 = buffer.readu32(v1, 0)
        end

        p8[v87] = v95
    end

    v52 = true

    for i = 1, 4 do
        if not (rt.F32_MIN_POSITIVE > v41[i] - v46) then
            v52 = false
            break
        end
    end

    v54 = v36 + 4

    if v52 then
        v70 = sub(v42, {
            v45[1] * (v41[1] - v46),
            v45[2] * (v41[2] - v46),
            v45[3] * (v41[3] - v46),
            v45[4] * (v41[4] - v46)
        })

        local v96 = v54 + 1

        v53 = v70[1]

        local v97

        if v53 == 0 then
            buffer.writef32(v1, 0, v53)
            v97 = buffer.readu32(v1, 0)
        elseif v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            local v98 = math.abs(v53) * 7.1362384635298E+44

            v97 = math.floor(v98)
            v76 = v98 - v97

            if v76 > 0.5 or v76 == 0.5 and v97 % 2 == 1 then
                v97 += 1
            end

            if v53 < 0 then
                v97 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v97 = buffer.readu32(v1, 0)
        end

        p8[v96] = v97
        v55 = v54 + 2
        v53 = v70[2]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v71 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v71 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v71 = buffer.readu32(v1, 0)
        end

        p8[v55] = v71
        v55 = v54 + 3
        v53 = v70[3]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v72 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v72 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v72 = buffer.readu32(v1, 0)
        end

        p8[v55] = v72
        v55 = v54 + 4
        v53 = v70[4]

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            v66 = math.abs(v53) * 7.1362384635298E+44
            v67 = math.floor(v66)
            v68 = v66 - v67
            v73 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v53 < 0 then
                v73 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v73 = buffer.readu32(v1, 0)
        end

        p8[v55] = v73
        v54 = v37 + 4
        v70 = end_(p10, p12)
    else
        v70 = v54 + 1
        v73 = v42[1]

        local v99, v100

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            v99 = math.abs(v73) * 7.1362384635298E+44
            v66 = math.floor(v99)
            v77 = v99 - v66
            v100 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v73 < 0 then
                v100 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v73)
            v100 = buffer.readu32(v1, 0)
        end

        p8[v70] = v100
        v70 = v54 + 2
        v73 = v42[2]

        local v101

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            v99 = math.abs(v73) * 7.1362384635298E+44
            v66 = math.floor(v99)
            v77 = v99 - v66
            v101 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v73 < 0 then
                v101 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v73)
            v101 = buffer.readu32(v1, 0)
        end

        p8[v70] = v101
        v70 = v54 + 3
        v73 = v42[3]

        local v102

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            v99 = math.abs(v73) * 7.1362384635298E+44
            v66 = math.floor(v99)
            v77 = v99 - v66
            v102 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v73 < 0 then
                v102 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v73)
            v102 = buffer.readu32(v1, 0)
        end

        p8[v70] = v102
        v70 = v54 + 4
        v73 = v42[4]

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            v99 = math.abs(v73) * 7.1362384635298E+44
            v66 = math.floor(v99)
            v77 = v99 - v66
            v55 = if v77 > 0.5 or v77 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

            if v73 < 0 then
                v55 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v73)
            v55 = buffer.readu32(v1, 0)
        end

        p8[v70] = v55
        v54 = v37 + 4
        v70 = madd(v39, v46, v44)
    end

    v55 = v54 + 1
    v53 = v70[1]

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        v66 = math.abs(v53) * 7.1362384635298E+44
        v67 = math.floor(v66)
        v68 = v66 - v67
        v74 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v53 < 0 then
            v74 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v74 = buffer.readu32(v1, 0)
    end

    p8[v55] = v74
    v55 = v54 + 2
    v53 = v70[2]

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        v66 = math.abs(v53) * 7.1362384635298E+44
        v67 = math.floor(v66)
        v68 = v66 - v67
        v75 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v53 < 0 then
            v75 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v75 = buffer.readu32(v1, 0)
    end

    p8[v55] = v75
    v55 = v54 + 3
    v53 = v70[3]

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        v66 = math.abs(v53) * 7.1362384635298E+44
        v67 = math.floor(v66)
        v68 = v66 - v67
        v56 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v53 < 0 then
            v56 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v56 = buffer.readu32(v1, 0)
    end

    p8[v55] = v56
    v55 = v54 + 4
    v53 = v70[4]

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        v66 = math.abs(v53) * 7.1362384635298E+44
        v67 = math.floor(v66)
        v68 = v66 - v67
        v57 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v53 < 0 then
            v57 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v57 = buffer.readu32(v1, 0)
    end

    p8[v55] = v57

    return 2
end

return t1
