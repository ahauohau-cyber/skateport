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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/physics/world_contact/point_feature")
local v9 = import("skate_core/physics/world_contact/prism_math")
local closest_feature_segment = v8.closest_feature_segment
local load, dot, sub, scale = v9.load, v9.dot, v9.sub, v9.scale
local madd, cross, normalized, reciprocal = v9.madd, v9.cross, v9.normalized, v9.reciprocal
local t1 = {}

function t1.store(p4, p5, p6) -- line: 49
    -- upvalues: v1 (copy)
    local v10 = p5 + 1
    local v11 = p6[1]
    local v12

    if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
        local v13 = math.abs(v11) * 7.1362384635298E+44
        local v14 = math.floor(v13)
        local v15 = v13 - v14

        v12 = if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14

        if v11 < 0 then
            v12 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v11)
        v12 = buffer.readu32(v1, 0)
    end

    p4[v10] = v12

    local v16 = p5 + 2
    local v17 = p6[2]
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20

        if v17 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readu32(v1, 0)
    end

    p4[v16] = v18

    local v22 = p5 + 3
    local v23 = p6[3]
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

        if v23 < 0 then
            v24 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readu32(v1, 0)
    end

    p4[v22] = v24

    local v28 = p5 + 4
    local v29 = p6[4]
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if v29 < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readu32(v1, 0)
    end

    p4[v28] = v30
end

local function endpoint(p7, p8) -- line: 58
    -- upvalues: rt (copy), load (copy)
    if p8 then
        p7[1] = rt.wrapping_sub_u32(p7[1], 1)
    else
        p7[1] = rt.wrapping_add_u32(p7[1], 1)
    end

    local v34 = load(p7, 4)

    if p8 then
        return v34
    end

    local v35 = load(p7, 8)
    local v36 = load(p7, 16)

    return {
        v35[1] * v36[1] + v34[1],
        v35[2] * v36[2] + v34[2],
        v35[3] * v36[3] + v34[3],
        v35[4] * v36[4] + v34[4]
    }
end

t1.endpoint = endpoint

function t1.intersect_feature_segments(p9, p10, p11, p12, p13) -- line: 80
    -- upvalues: rt (copy), v1 (copy), closest_feature_segment (copy), load (copy), dot (copy), sub (copy), scale (copy), madd (copy), cross (copy), normalized (copy), reciprocal (copy), endpoint (copy)
    local v37 = if p13 then 0 else 64
    local v38 = if p13 then 64 else 0
    local v39 = load(p10, 8)
    local v40 = load(p11, 8)
    local v41 = load(p10, 4)
    local v42 = load(p11, 4)
    local v43 = cross(v39, v40)
    local v44, v45, v46, v47, v48, v49, v50, v51, v52, v53, v54, v55, v56

    if dot(v43, v43) > 1.1920928955078125E-07 then
        v47 = cross(normalized(v43), v40)
        v45 = dot(sub(v42, v41), v47) / dot(v39, v47)

        if v45 < 0 then
            v45 = 0
        end

        v44 = load(p10, 16)

        if v44[1] < v45 and v44[2] < v45 and v44[3] < v45 and v44[4] < v45 then
            v45 = v44[1]
        end

        p9[133] = 1
        v44 = madd(v39, v45, v41)
        v45 = {}
        v48 = v44[1]

        local v57

        if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
            v57 = math.abs(v48) * 7.1362384635298E+44
            v50 = math.floor(v57)

            local v58 = v57 - v50

            v54 = if v58 > 0.5 or v58 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50

            if v48 < 0 then
                v54 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v48)
            v54 = buffer.readu32(v1, 0)
        end

        v49 = v44[2]

        if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
            v50 = math.abs(v49) * 7.1362384635298E+44
            v56 = math.floor(v50)

            local v59 = v50 - v56

            v55 = if v59 > 0.5 or v59 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

            if v49 < 0 then
                v55 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v49)
            v55 = buffer.readu32(v1, 0)
        end

        local v60 = v44[3]
        local v61

        if v60 ~= 0 and v60 > -1.1754943508222875E-38 and v60 < 1.1754943508222875E-38 then
            v56 = math.abs(v60) * 7.1362384635298E+44
            v51 = math.floor(v56)

            local v62 = v56 - v51

            v61 = if v62 > 0.5 or v62 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51

            if v60 < 0 then
                v61 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v60)
            v61 = buffer.readu32(v1, 0)
        end

        v57 = v44[4]

        if v57 ~= 0 and v57 > -1.1754943508222875E-38 and v57 < 1.1754943508222875E-38 then
            v51 = math.abs(v57) * 7.1362384635298E+44
            v53 = math.floor(v51)
            v52 = v51 - v53
            v46 = if v52 > 0.5 or v52 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

            if v57 < 0 then
                v46 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v57)
            v46 = buffer.readu32(v1, 0)
        end

        v45[1] = v54
        v45[2] = v55
        v45[3] = v61
        v45[4] = v46
        v44 = closest_feature_segment(rt.slice(p11, 4, 20), v45)
        p11[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p11[1], v44), 2)
        p9[v38 + 1] = v45[1]
        p9[v38 + 2] = v45[2]
        p9[v38 + 3] = v45[3]
        p9[v38 + 4] = v45[4]
        v44 = closest_feature_segment(rt.slice(p10, 4, 20), v45)
        p10[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p10[1], v44), 2)
        p9[v37 + 1] = v45[1]
        p9[v37 + 2] = v45[2]
        p9[v37 + 3] = v45[3]
        p9[v37 + 4] = v45[4]

        return 1
    end

    buffer.writeu32(v1, 0, p12[1])
    v48 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p12[2])
    v54 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p12[3])
    v55 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p12[4])
    v47 = {
        v48,
        v54,
        v55,
        (buffer.readf32(v1, 0))
    }
    v43 = if math.abs((dot(v47, v39))) < math.abs((dot(v47, v40))) then v39 else v40

    local v64 = load(p10, 16)

    v45 = load(p11, 16)
    v44 = {
        v39[1] * v64[1] + v41[1],
        v39[2] * v64[2] + v41[2],
        v39[3] * v64[3] + v41[3],
        v39[4] * v64[4] + v41[4]
    }
    v64 = {
        v40[1] * v45[1] + v42[1],
        v40[2] * v45[2] + v42[2],
        v40[3] * v45[3] + v42[3],
        v40[4] * v45[4] + v42[4]
    }
    v48 = dot(v43, v41)

    local v63 = dot(v43, v42)

    v54 = dot(v43, v44)
    v55 = dot(v43, v64)

    if v48 < v54 then
        v51 = v54
        v46 = v48
    else
        v51 = v48
        v46 = v54
    end

    if v63 < v55 then
        v56 = v55
        v50 = v63
    else
        v56 = v63
        v50 = v55
    end

    v64 = if v50 < v46 then v46 else v50

    if not (v51 < v56) then
        v51 = v56
    end

    if v64 < v51 then
        v52 = normalized(cross(cross(v47, v39), v39))

        local v65 = normalized(cross(cross(v47, v40), v40))

        v53 = {
            v64,
            v51
        }

        local t2 = {
            { v37, v41, v39, v52 },
            { v38, v42, v40, v65 }
        }

        for i = 0, 1 do
            v56 = v53[i + 1]

            local v66 = scale(v43, v56)

            for _, v67 in t2 do
                local v68 = v67[1]
                local v69 = v67[2]
                local v70 = v67[3]
                local v71 = v67[4]
                local v73 = madd(v47, reciprocal(dot(v47, v71)) * dot(sub(v69, v66), v71), v66)

                v73 = madd(v70, dot(sub(v73, v69), v70), v69)

                local v74 = v68 + i * 4
                local v75 = v74 + 1
                local v76 = v73[1]
                local v77

                if v76 == 0 then
                    buffer.writef32(v1, 0, v76)
                    v77 = buffer.readu32(v1, 0)
                elseif v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                    v70 = math.abs(v76) * 7.1362384635298E+44
                    v77 = math.floor(v70)
                    v69 = v70 - v77

                    if v69 > 0.5 or v69 == 0.5 and v77 % 2 == 1 then
                        v77 += 1
                    end

                    if v76 < 0 then
                        v77 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v76)
                    v77 = buffer.readu32(v1, 0)
                end

                p9[v75] = v77
                v75 = v74 + 2
                v76 = v73[2]

                local v78

                if v76 == 0 then
                    buffer.writef32(v1, 0, v76)
                    v78 = buffer.readu32(v1, 0)
                elseif v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                    v77 = math.abs(v76) * 7.1362384635298E+44
                    v78 = math.floor(v77)

                    local v79 = v77 - v78

                    if v79 > 0.5 or v79 == 0.5 and v78 % 2 == 1 then
                        v78 += 1
                    end

                    if v76 < 0 then
                        v78 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v76)
                    v78 = buffer.readu32(v1, 0)
                end

                p9[v75] = v78
                v75 = v74 + 3
                v76 = v73[3]

                local v80, v81

                if v76 == 0 then
                    buffer.writef32(v1, 0, v76)
                    v80 = buffer.readu32(v1, 0)
                elseif v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                    v78 = math.abs(v76) * 7.1362384635298E+44
                    v80 = math.floor(v78)
                    v81 = v78 - v80

                    if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then
                        v80 += 1
                    end

                    if v76 < 0 then
                        v80 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v76)
                    v80 = buffer.readu32(v1, 0)
                end

                p9[v75] = v80
                v75 = v74 + 4
                v76 = v73[4]

                if v76 == 0 then
                    buffer.writef32(v1, 0, v76)
                    v80 = buffer.readu32(v1, 0)
                elseif v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                    v78 = math.abs(v76) * 7.1362384635298E+44
                    v80 = math.floor(v78)
                    v81 = v78 - v80

                    if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then
                        v80 += 1
                    end

                    if v76 < 0 then
                        v80 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v76)
                    v80 = buffer.readu32(v1, 0)
                end

                p9[v75] = v80
            end
        end

        p9[133] = 2
    else
        p9[133] = 1

        local v82

        if v46 < v50 then
            v53 = v54 < v48
            v82 = v63 < v55
        else
            v53 = v48 < v54
            v82 = v55 < v63
        end

        local v83 = endpoint(p10, v53)
        local v84 = v37 + 1
        local v85 = v83[1]
        local v86, v87, v88, v89

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v89 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v89 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v89 = buffer.readu32(v1, 0)
        end

        p9[v84] = v89
        v84 = v37 + 2
        v85 = v83[2]

        local v90

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v90 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v90 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v90 = buffer.readu32(v1, 0)
        end

        p9[v84] = v90
        v84 = v37 + 3
        v85 = v83[3]

        local v91

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v91 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v91 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v91 = buffer.readu32(v1, 0)
        end

        p9[v84] = v91
        v84 = v37 + 4
        v85 = v83[4]

        local v92

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v92 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v92 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v92 = buffer.readu32(v1, 0)
        end

        p9[v84] = v92
        v83 = endpoint(p11, v82)
        v84 = v38 + 1
        v85 = v83[1]

        local v93

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            local v94 = math.abs(v85) * 7.1362384635298E+44

            v86 = math.floor(v94)

            local v95 = v94 - v86

            v93 = if v95 > 0.5 or v95 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86

            if v85 < 0 then
                v93 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v93 = buffer.readu32(v1, 0)
        end

        p9[v84] = v93
        v84 = v38 + 2
        v85 = v83[2]

        local v96

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v96 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v96 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v96 = buffer.readu32(v1, 0)
        end

        p9[v84] = v96
        v84 = v38 + 3
        v85 = v83[3]

        local v97

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v97 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v97 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v97 = buffer.readu32(v1, 0)
        end

        p9[v84] = v97
        v84 = v38 + 4
        v85 = v83[4]

        local v98

        if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
            v86 = math.abs(v85) * 7.1362384635298E+44
            v87 = math.floor(v86)
            v88 = v86 - v87
            v98 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

            if v85 < 0 then
                v98 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v85)
            v98 = buffer.readu32(v1, 0)
        end

        p9[v84] = v98
    end

    return 1
end

return t1
