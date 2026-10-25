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

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/physics/world_contact/face_clip")
local v13 = import("skate_core/physics/world_contact/point_feature")
local v14 = import("skate_core/physics/world_contact/prism_math")
local clamp_point_to_feature, clip_segment_to_feature = v12.clamp_point_to_feature, v12.clip_segment_to_feature
local closest_feature_segment = v13.closest_feature_segment
local load, dot, sub, madd = v14.load, v14.dot, v14.sub, v14.madd
local cross, normalized, inverse_length = v14.cross, v14.normalized, v14.inverse_length
local t1 = {}

local function to_bits4(p5) -- line: 60
    -- upvalues: v1 (copy)
    local v15 = p5[1]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if v15 < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readu32(v1, 0)
    end

    local v20 = p5[2]
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if v20 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readu32(v1, 0)
    end

    local v25 = p5[3]
    local v26

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v27 = math.abs(v25) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if v25 < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v25)
        v26 = buffer.readu32(v1, 0)
    end

    local v30 = p5[4]
    local v31

    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
        local v32 = math.abs(v30) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if v30 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v30)
        v31 = buffer.readu32(v1, 0)
    end

    return {
        v16,
        v21,
        v26,
        v31
    }
end

function t1.store(p6, p7, p8) -- line: 64
    -- upvalues: v1 (copy)
    local v35 = p7 + 1
    local v36 = p8[1]
    local v37

    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v36 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readu32(v1, 0)
    end

    p6[v35] = v37

    local v41 = p7 + 2
    local v42 = p8[2]
    local v43

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        local v44 = math.abs(v42) * 7.1362384635298E+44
        local v45 = math.floor(v44)
        local v46 = v44 - v45

        v43 = if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45

        if v42 < 0 then
            v43 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v42)
        v43 = buffer.readu32(v1, 0)
    end

    p6[v41] = v43

    local v47 = p7 + 3
    local v48 = p8[3]
    local v49

    if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
        local v50 = math.abs(v48) * 7.1362384635298E+44
        local v51 = math.floor(v50)
        local v52 = v50 - v51

        v49 = if v52 > 0.5 or v52 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51

        if v48 < 0 then
            v49 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v48)
        v49 = buffer.readu32(v1, 0)
    end

    p6[v47] = v49

    local v53 = p7 + 4
    local v54 = p8[4]
    local v55

    if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
        local v56 = math.abs(v54) * 7.1362384635298E+44
        local v57 = math.floor(v56)
        local v58 = v56 - v57

        v55 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

        if v54 < 0 then
            v55 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v54)
        v55 = buffer.readu32(v1, 0)
    end

    p6[v53] = v55
end

function t1.intersect_segment_face_reference(p9, p10, p11, p12, p13) -- line: 77
    -- upvalues: rt (copy), v1 (copy), clamp_point_to_feature (copy), clip_segment_to_feature (copy), closest_feature_segment (copy), load (copy), dot (copy), sub (copy), madd (copy), cross (copy), normalized (copy), inverse_length (copy), to_bits4 (copy)
    local v60 = if p13 then 0 else 64
    local v59 = if p13 then 64 else 0
    local t3 = {
        0, 0
    }
    local v61 = table.create(8, 0)
    local v62 = clip_segment_to_feature(p10, p11, p12, t3, v61)

    buffer.writeu32(v1, 0, p12[1])

    local v64 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p12[2])

    local v66 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p12[3])

    local v68 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p12[4])

    local t4 = {
        v64,
        v66,
        v68,
        (buffer.readf32(v1, 0))
    }
    local v70 = load(p11, 4)
    local v63 = load(p11, 8)

    v64 = load(p10, 4)
    v68 = t3[1]
    buffer.writeu32(v1, 0, v68)

    local v71 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, t3[2])

    local v73 = buffer.readf32(v1, 0)

    if v62 == 0 then
        v62 = v73 - v71

        if v62 > 0.0010000000474974513 then
            p9[133] = 2
            v68 = load(v61, 0)

            local v74 = load(v61, 4)

            v73 = madd(t4, dot(t4, sub(v64, v70)), v70)

            local v75 = madd(v74, dot(v74, sub(v68, v73)), v73)

            v75 = madd(v63, v71, v75)
            v73 = madd(v63, v62, v75)
            v75 = to_bits4(v75)

            local v76 = to_bits4(v73)

            v73 = clamp_point_to_feature(p10, p12, v75)

            local v77 = clamp_point_to_feature(p10, p12, v76)
            local v78 = rt.wrapping_add_u32
            local v79 = p10[1]

            p10[1] = v78(v79, (bit32.band(math.max(v73, v77), 4294967294)))
            p9[v60 + 1] = v75[1]
            p9[v60 + 2] = v75[2]
            p9[v60 + 3] = v75[3]
            p9[v60 + 4] = v75[4]
            p9[v60 + 4 + 1] = v76[1]
            p9[v60 + 4 + 2] = v76[2]
            p9[v60 + 4 + 3] = v76[3]
            p9[v60 + 4 + 4] = v76[4]
            closest_feature_segment(rt.slice(p11, 4, 20), v75)
            closest_feature_segment(rt.slice(p11, 4, 20), v76)
            p9[v59 + 1] = v75[1]
            p9[v59 + 2] = v75[2]
            p9[v59 + 3] = v75[3]
            p9[v59 + 4] = v75[4]
            p9[v59 + 4 + 1] = v76[1]
            p9[v59 + 4 + 2] = v76[2]
            p9[v59 + 4 + 3] = v76[3]
            p9[v59 + 4 + 4] = v76[4]
            v78 = load(p9, v60)

            local v80 = v75[1]

            buffer.writeu32(v1, 0, v80)

            local v81 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v75[2])

            local v83 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v75[3])

            local v85 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v75[4])
            v75 = sub(v78, {
                v81,
                v83,
                v85,
                (buffer.readf32(v1, 0))
            })
            v78 = dot(v75, v75)

            if v78 == 0 then
                buffer.writef32(v1, 0, v78)
                v74 = buffer.readf32(v1, 0)
            elseif v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
                v68 = math.abs(v78) * 7.1362384635298E+44
                v80 = math.floor(v68)

                local v87 = v68 - v80

                if v87 > 0.5 or v87 == 0.5 and v80 % 2 == 1 then
                    v80 += 1
                end

                v74 = v80 * 1.401298464324817E-45

                if v78 < 0 then
                    v74 = -v74
                end
            else
                buffer.writef32(v1, 0, v78)
                v74 = buffer.readf32(v1, 0)
            end

            v78 = if v74 == 0 then 0 else v74 * inverse_length(v74)

            if rt.F32_MIN_POSITIVE < v78 then
                p9[134] = 1

                local v88 = normalized(cross(v63, cross(v75, v63)))

                v80 = v88[1]

                local v89

                if v80 == 0 then
                    buffer.writef32(v1, 0, v80)
                    v89 = buffer.readu32(v1, 0)
                elseif v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
                    v83 = math.abs(v80) * 7.1362384635298E+44
                    v89 = math.floor(v83)
                    v85 = v83 - v89

                    if v85 > 0.5 or v85 == 0.5 and v89 % 2 == 1 then
                        v89 += 1
                    end

                    if v80 < 0 then
                        v89 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v80)
                    v89 = buffer.readu32(v1, 0)
                end

                p9[129] = v89
                v80 = v88[2]

                local v90, v91, v92

                if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
                    v89 = math.abs(v80) * 7.1362384635298E+44
                    v91 = math.floor(v89)
                    v92 = v89 - v91
                    v90 = if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91

                    if v80 < 0 then
                        v90 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v80)
                    v90 = buffer.readu32(v1, 0)
                end

                p9[130] = v90
                v80 = v88[3]

                local v93

                if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
                    v89 = math.abs(v80) * 7.1362384635298E+44
                    v91 = math.floor(v89)
                    v92 = v89 - v91
                    v93 = if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91

                    if v80 < 0 then
                        v93 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v80)
                    v93 = buffer.readu32(v1, 0)
                end

                p9[131] = v93
                v80 = v88[4]

                local v94

                if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
                    v89 = math.abs(v80) * 7.1362384635298E+44
                    v91 = math.floor(v89)
                    v92 = v89 - v91
                    v94 = if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91

                    if v80 < 0 then
                        v94 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v80)
                    v94 = buffer.readu32(v1, 0)
                end

                p9[132] = v94
            end
        else
            p9[133] = 1

            local v95 = madd(v63, v71, v70)

            v73 = to_bits4(madd(t4, dot(t4, sub(v64, v95)), v95))

            local v96 = clamp_point_to_feature(p10, p12, v73)

            p10[1] = rt.wrapping_add_u32(p10[1], v96)
            p9[v60 + 1] = v73[1]
            p9[v60 + 2] = v73[2]
            p9[v60 + 3] = v73[3]
            p9[v60 + 4] = v73[4]
            v96 = closest_feature_segment(rt.slice(p11, 4, 20), v73)
            p11[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p11[1], v96), 2)
            p9[v59 + 1] = v73[1]
            p9[v59 + 2] = v73[2]
            p9[v59 + 3] = v73[3]
            p9[v59 + 4] = v73[4]
        end
    else
        p9[133] = 2

        local v97 = load(p10, 132)

        v71 = {
            v71,
            v73
        }

        for i = 0, 1 do
            local v99 = madd(v63, v71[i + 1], v70)
            local v100 = v59 + i * 4
            local v101 = v100 + 1
            local v102 = v99[1]
            local v103, v104

            if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                v104 = math.abs(v102) * 7.1362384635298E+44
                v103 = math.floor(v104)

                local v105 = v104 - v103
                local v106 = if v105 > 0.5 or v105 == 0.5 and v103 % 2 == 1 then v103 + 1 else v103

                if v102 < 0 then
                    p9[v101] = v106 + 2147483648
                else
                    p9[v101] = v106
                end
            else
                buffer.writef32(v1, 0, v102)
                p9[v101] = buffer.readu32(v1, 0)
            end

            v101 = v100 + 2
            v102 = v99[2]

            local v107, v108

            if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                v103 = math.abs(v102) * 7.1362384635298E+44
                v107 = math.floor(v103)
                v108 = v103 - v107

                local v109 = if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107

                if v102 < 0 then
                    p9[v101] = v109 + 2147483648
                else
                    p9[v101] = v109
                end
            else
                buffer.writef32(v1, 0, v102)
                p9[v101] = buffer.readu32(v1, 0)
            end

            v101 = v100 + 3
            v102 = v99[3]

            if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                v103 = math.abs(v102) * 7.1362384635298E+44
                v107 = math.floor(v103)
                v108 = v103 - v107

                local v110 = if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107

                if v102 < 0 then
                    p9[v101] = v110 + 2147483648
                else
                    p9[v101] = v110
                end
            else
                buffer.writef32(v1, 0, v102)
                p9[v101] = buffer.readu32(v1, 0)
            end

            v101 = v100 + 4
            v102 = v99[4]

            if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                v103 = math.abs(v102) * 7.1362384635298E+44
                v107 = math.floor(v103)
                v108 = v103 - v107

                local v111 = if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107

                if v102 < 0 then
                    p9[v101] = v111 + 2147483648
                else
                    p9[v101] = v111
                end
            else
                buffer.writef32(v1, 0, v102)
                p9[v101] = buffer.readu32(v1, 0)
            end

            v100 = dot(sub(v64, v99), v97) / dot(t4, v97)
            v101 = v60 + i * 4

            local v112 = madd(t4, v100, v99)

            v102 = v101 + 1
            v104 = v112[1]

            local v113, v114, v115

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v113 = math.abs(v104) * 7.1362384635298E+44
                v114 = math.floor(v113)
                v115 = v113 - v114

                local v116 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

                if v104 < 0 then
                    p9[v102] = v116 + 2147483648
                else
                    p9[v102] = v116
                end
            else
                buffer.writef32(v1, 0, v104)
                p9[v102] = buffer.readu32(v1, 0)
            end

            v102 = v101 + 2
            v104 = v112[2]

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v113 = math.abs(v104) * 7.1362384635298E+44
                v114 = math.floor(v113)
                v115 = v113 - v114

                local v117 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

                if v104 < 0 then
                    p9[v102] = v117 + 2147483648
                else
                    p9[v102] = v117
                end
            else
                buffer.writef32(v1, 0, v104)
                p9[v102] = buffer.readu32(v1, 0)
            end

            v102 = v101 + 3
            v104 = v112[3]

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v113 = math.abs(v104) * 7.1362384635298E+44
                v114 = math.floor(v113)
                v115 = v113 - v114

                local v118 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

                if v104 < 0 then
                    p9[v102] = v118 + 2147483648
                else
                    p9[v102] = v118
                end
            else
                buffer.writef32(v1, 0, v104)
                p9[v102] = buffer.readu32(v1, 0)
            end

            v102 = v101 + 4
            v104 = v112[4]

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v113 = math.abs(v104) * 7.1362384635298E+44
                v114 = math.floor(v113)
                v115 = v113 - v114

                local v119 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

                if v104 < 0 then
                    p9[v102] = v119 + 2147483648
                else
                    p9[v102] = v119
                end
            else
                buffer.writef32(v1, 0, v104)
                p9[v102] = buffer.readu32(v1, 0)
            end
        end
    end

    return 1
end

local v120 = buffer.create(8)

local function fb(p14) -- line: 190
    -- upvalues: v120 (copy)
    buffer.writeu32(v120, 0, p14)

    return (buffer.readf32(v120, 0))
end

local to_bits = rt.to_bits

local function tb(p15) -- line: 195
    -- upvalues: v120 (copy), to_bits (copy)
    if p15 ~= 0 and p15 > -1.1754943508222875E-38 and p15 < 1.1754943508222875E-38 then
        return to_bits(p15)
    end

    buffer.writef32(v120, 0, p15)

    return (buffer.readu32(v120, 0))
end

local closest_feature_segment_at = v13.closest_feature_segment_at
local t5 = {
    0, 0
}
local v121 = table.create(8, 0)
local t6 = {
    0, 0, 0, 0
}
local t7 = {
    0, 0, 0, 0
}

function t1.intersect_segment_face(p16, p17, p18, p19, p20) -- line: 209
    -- upvalues: rt (copy), v1 (copy), clamp_point_to_feature (copy), clip_segment_to_feature (copy), inverse_length (copy), v120 (copy), to_bits (copy), closest_feature_segment_at (copy), t5 (copy), v121 (copy), t6 (copy), t7 (copy)
    local v123 = if p20 then 0 else 64
    local v122 = if p20 then 64 else 0

    t5[1] = 0
    t5[2] = 0
    v121[1] = 0
    v121[2] = 0
    v121[3] = 0
    v121[4] = 0
    v121[5] = 0
    v121[6] = 0
    v121[7] = 0
    v121[8] = 0

    local v124 = clip_segment_to_feature(p17, p18, p19, t5, v121)

    buffer.writeu32(v120, 0, p19[1])

    local v126 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p19[2])

    local v127 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p19[3])

    local v128 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p19[4])

    local v129 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[5])

    local v131 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[6])

    local v132 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[7])

    local v133 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[8])

    local v134 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[9])

    local v136 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[10])

    local v137 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[11])

    local v138 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p18[12])

    local v139 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p17[5])

    local v141 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p17[6])

    local v142 = buffer.readf32(v120, 0)

    buffer.writeu32(v120, 0, p17[7])

    local v143 = buffer.readf32(v120, 0)
    local v144 = t5[1]

    buffer.writeu32(v120, 0, v144)

    local v145 = buffer.readf32(v120, 0)
    local v146 = t5[2]

    buffer.writeu32(v120, 0, v146)

    local v147 = buffer.readf32(v120, 0)

    if v124 == 0 then
        v124 = v147 - v145

        if v124 > 0.0010000000474974513 then
            p16[133] = 2
            buffer.writeu32(v120, 0, v121[1])

            local v149 = buffer.readf32(v120, 0)

            buffer.writeu32(v120, 0, v121[2])

            local v150 = buffer.readf32(v120, 0)
            local v148 = v121[3]

            buffer.writeu32(v120, 0, v148)

            local v151 = buffer.readf32(v120, 0)

            buffer.writeu32(v120, 0, v121[5])

            local v153 = buffer.readf32(v120, 0)

            buffer.writeu32(v120, 0, v121[6])

            local v154 = buffer.readf32(v120, 0)

            buffer.writeu32(v120, 0, v121[7])

            local v155 = buffer.readf32(v120, 0)

            buffer.writeu32(v120, 0, v121[8])

            local v156 = buffer.readf32(v120, 0)

            v144 = v126 * (v141 - v131) + v127 * (v142 - v132) + v128 * (v143 - v133)

            local v152 = v126 * v144 + v131
            local v157 = v127 * v144 + v132
            local v158 = v128 * v144 + v133
            local v159 = v129 * v144 + v134

            v144 = v153 * (v149 - v152) + v154 * (v150 - v157) + v155 * (v151 - v158)
            v152 = v153 * v144 + v152
            v153 = v154 * v144 + v157
            v158 = v155 * v144 + v158
            v159 = v156 * v144 + v159

            local v160 = v136 * v145 + v152
            local v161 = v137 * v145 + v153
            local v162 = v138 * v145 + v158
            local v163 = v139 * v145 + v159
            local v164

            if v160 == 0 then
                buffer.writef32(v120, 0, v160)
                v164 = buffer.readu32(v120, 0)
            elseif v160 > -1.1754943508222875E-38 and v160 < 1.1754943508222875E-38 then
                v164 = to_bits(v160)
            else
                buffer.writef32(v120, 0, v160)
                v164 = buffer.readu32(v120, 0)
            end

            local writef32

            if v161 ~= 0 and v161 > -1.1754943508222875E-38 and v161 < 1.1754943508222875E-38 then
                writef32 = to_bits(v161)
            else
                buffer.writef32(v120, 0, v161)
                writef32 = buffer.readu32(v120, 0)
            end

            local v165

            if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
                v165 = to_bits(v162)
            else
                buffer.writef32(v120, 0, v162)
                v165 = buffer.readu32(v120, 0)
            end

            local v166

            if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
                v166 = to_bits(v163)
            else
                buffer.writef32(v120, 0, v163)
                v166 = buffer.readu32(v120, 0)
            end

            t6[1] = v164
            t6[2] = writef32
            t6[3] = v165
            t6[4] = v166
            writef32 = v136 * v124 + v160

            if writef32 ~= 0 and writef32 > -1.1754943508222875E-38 and writef32 < 1.1754943508222875E-38 then
                v164 = to_bits(writef32)
            else
                buffer.writef32(v120, 0, writef32)
                v164 = buffer.readu32(v120, 0)
            end

            v165 = v137 * v124 + v161

            if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
                writef32 = to_bits(v165)
            else
                buffer.writef32(v120, 0, v165)
                writef32 = buffer.readu32(v120, 0)
            end

            v166 = v138 * v124 + v162

            if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
                v165 = to_bits(v166)
            else
                buffer.writef32(v120, 0, v166)
                v165 = buffer.readu32(v120, 0)
            end

            local v167 = v139 * v124 + v163

            if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
                v166 = to_bits(v167)
            else
                buffer.writef32(v120, 0, v167)
                v166 = buffer.readu32(v120, 0)
            end

            t7[1] = v164
            t7[2] = writef32
            t7[3] = v165
            t7[4] = v166
            v163 = clamp_point_to_feature(p17, p19, t6)

            local v168 = clamp_point_to_feature(p17, p19, t7)

            p17[1] = rt.wrapping_add_u32(p17[1], (bit32.band(math.max(v163, v168), 4294967294)))
            v164 = v123 + 1
            writef32 = v123 + 2
            v165 = v123 + 3
            v166 = v123 + 4
            v167 = t6[1]

            local v169 = t6[2]
            local v170 = t6[3]
            local v171 = t6[4]

            p16[v164] = v167
            p16[writef32] = v169
            p16[v165] = v170
            p16[v166] = v171
            v164 = v123 + 5
            writef32 = v123 + 6
            v165 = v123 + 7
            v166 = v123 + 8
            v167 = t7[1]
            v169 = t7[2]
            v170 = t7[3]
            v171 = t7[4]
            p16[v164] = v167
            p16[writef32] = v169
            p16[v165] = v170
            p16[v166] = v171
            closest_feature_segment_at(p18, 4, t6)
            closest_feature_segment_at(p18, 4, t7)
            v164 = v122 + 1
            writef32 = v122 + 2
            v165 = v122 + 3
            v166 = v122 + 4
            v167 = t6[1]
            v169 = t6[2]
            v170 = t6[3]
            v171 = t6[4]
            p16[v164] = v167
            p16[writef32] = v169
            p16[v165] = v170
            p16[v166] = v171
            v164 = v122 + 5
            writef32 = v122 + 6
            v165 = v122 + 7
            v166 = v122 + 8
            v167 = t7[1]
            v169 = t7[2]
            v170 = t7[3]
            v171 = t7[4]
            p16[v164] = v167
            p16[writef32] = v169
            p16[v165] = v170
            p16[v166] = v171
            buffer.writeu32(v120, 0, p16[v123 + 1])
            v165 = buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, t6[1])
            v163 = v165 - buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, p16[v123 + 2])
            v165 = buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, t6[2])
            v162 = v165 - buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, p16[v123 + 3])
            v165 = buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, t6[3])
            v161 = v165 - buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, p16[v123 + 4])
            v165 = buffer.readf32(v120, 0)
            buffer.writeu32(v120, 0, t6[4])
            v160 = v165 - buffer.readf32(v120, 0)
            v164 = v163 * v163 + v162 * v162 + v161 * v161

            if v164 ~= 0 and v164 > -1.1754943508222875E-38 and v164 < 1.1754943508222875E-38 then
                v153 = math.abs(v164) * 7.1362384635298E+44
                v166 = math.floor(v153)
                v152 = v153 - v166
                v158 = (if v152 > 0.5 or v152 == 0.5 and v166 % 2 == 1 then v166 + 1 else v166) * 1.401298464324817E-45

                if v164 < 0 then
                    v158 = -v158
                end
            else
                buffer.writef32(v1, 0, v164)
                v158 = buffer.readf32(v1, 0)
            end

            v164 = if v158 == 0 then 0 else v158 * inverse_length(v158)

            if rt.F32_MIN_POSITIVE < v164 then
                p16[134] = 1

                local v173 = -v161 * v137 + v162 * v138
                local v174 = -v163 * v138 + v161 * v136
                local v175 = -v162 * v136 + v163 * v137

                v149 = -v160 * v139 + v160 * v139
                v148 = -v138 * v174 + v137 * v175

                local v176 = -v136 * v175 + v138 * v173

                v175 = -v137 * v173 + v136 * v174
                v173 = -v139 * v149 + v139 * v149

                local v177 = inverse_length(v148 * v148 + v176 * v176 + v175 * v175)

                v165 = v148 * v177

                local v178

                if v165 == 0 then
                    buffer.writef32(v120, 0, v165)
                    v178 = buffer.readu32(v120, 0)
                elseif v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
                    v178 = to_bits(v165)
                else
                    buffer.writef32(v120, 0, v165)
                    v178 = buffer.readu32(v120, 0)
                end

                v166 = v176 * v177

                if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
                    v165 = to_bits(v166)
                else
                    buffer.writef32(v120, 0, v166)
                    v165 = buffer.readu32(v120, 0)
                end

                v167 = v175 * v177

                if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
                    v166 = to_bits(v167)
                else
                    buffer.writef32(v120, 0, v167)
                    v166 = buffer.readu32(v120, 0)
                end

                v169 = v173 * v177

                if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
                    v167 = to_bits(v169)
                else
                    buffer.writef32(v120, 0, v169)
                    v167 = buffer.readu32(v120, 0)
                end

                p16[129] = v178
                p16[130] = v165
                p16[131] = v166
                p16[132] = v167
            end
        else
            p16[133] = 1
            v146 = v136 * v145 + v131
            v147 = v137 * v145 + v132

            local v179 = v138 * v145 + v133
            local v180 = v139 * v145 + v134
            local v181 = v126 * (v141 - v146) + v127 * (v142 - v147) + v128 * (v143 - v179)
            local v182 = v126 * v181 + v146
            local v183

            if v182 ~= 0 and v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
                v183 = to_bits(v182)
            else
                buffer.writef32(v120, 0, v182)
                v183 = buffer.readu32(v120, 0)
            end

            local v184 = v127 * v181 + v147

            if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
                v182 = to_bits(v184)
            else
                buffer.writef32(v120, 0, v184)
                v182 = buffer.readu32(v120, 0)
            end

            local v185 = v128 * v181 + v179

            if v185 ~= 0 and v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
                v184 = to_bits(v185)
            else
                buffer.writef32(v120, 0, v185)
                v184 = buffer.readu32(v120, 0)
            end

            local v186 = v129 * v181 + v180

            if v186 ~= 0 and v186 > -1.1754943508222875E-38 and v186 < 1.1754943508222875E-38 then
                v185 = to_bits(v186)
            else
                buffer.writef32(v120, 0, v186)
                v185 = buffer.readu32(v120, 0)
            end

            t6[1] = v183
            t6[2] = v182
            t6[3] = v184
            t6[4] = v185
            v183 = clamp_point_to_feature(p17, p19, t6)
            p17[1] = rt.wrapping_add_u32(p17[1], v183)
            v183 = v123 + 1
            v182 = v123 + 2
            v184 = v123 + 3
            v185 = v123 + 4
            v186 = t6[1]

            local v187 = t6[2]
            local v188 = t6[3]
            local v189 = t6[4]

            p16[v183] = v186
            p16[v182] = v187
            p16[v184] = v188
            p16[v185] = v189
            v183 = closest_feature_segment_at(p18, 4, t6)
            p18[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p18[1], v183), 2)
            v183 = v122 + 1
            v182 = v122 + 2
            v184 = v122 + 3
            v185 = v122 + 4
            v186 = t6[1]
            v187 = t6[2]
            v188 = t6[3]
            v189 = t6[4]
            p16[v183] = v186
            p16[v182] = v187
            p16[v184] = v188
            p16[v185] = v189
        end
    else
        p16[133] = 2
        buffer.writeu32(v120, 0, p17[133])

        local v191 = buffer.readf32(v120, 0)

        buffer.writeu32(v120, 0, p17[134])

        local v192 = buffer.readf32(v120, 0)

        buffer.writeu32(v120, 0, p17[135])

        local v193 = buffer.readf32(v120, 0)

        for i = 0, 1 do
            local v194 = if i == 0 then v145 else v147
            local v195 = v136 * v194 + v131
            local v196 = v137 * v194 + v132
            local v197 = v138 * v194 + v133
            local v198 = v139 * v194 + v134

            v194 = v122 + i * 4

            local v199 = v194 + 1
            local v200 = v194 + 2
            local v201 = v194 + 3
            local v202 = v194 + 4
            local v203

            if v195 ~= 0 and v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
                v203 = to_bits(v195)
            else
                buffer.writef32(v120, 0, v195)
                v203 = buffer.readu32(v120, 0)
            end

            local v204

            if v196 ~= 0 and v196 > -1.1754943508222875E-38 and v196 < 1.1754943508222875E-38 then
                v204 = to_bits(v196)
            else
                buffer.writef32(v120, 0, v196)
                v204 = buffer.readu32(v120, 0)
            end

            local v205

            if v197 ~= 0 and v197 > -1.1754943508222875E-38 and v197 < 1.1754943508222875E-38 then
                v205 = to_bits(v197)
            else
                buffer.writef32(v120, 0, v197)
                v205 = buffer.readu32(v120, 0)
            end

            local v206

            if v198 ~= 0 and v198 > -1.1754943508222875E-38 and v198 < 1.1754943508222875E-38 then
                v206 = to_bits(v198)
            else
                buffer.writef32(v120, 0, v198)
                v206 = buffer.readu32(v120, 0)
            end

            p16[v199] = v203
            p16[v200] = v204
            p16[v201] = v205
            p16[v202] = v206
            v199 = ((v141 - v195) * v191 + (v142 - v196) * v192 + (v143 - v197) * v193) / (v126 * v191 + v127 * v192 + v128 * v193)
            v194 = v123 + i * 4
            v200 = v194 + 1
            v201 = v194 + 2
            v202 = v194 + 3
            v203 = v194 + 4
            v205 = v126 * v199 + v195

            if v205 ~= 0 and v205 > -1.1754943508222875E-38 and v205 < 1.1754943508222875E-38 then
                v204 = to_bits(v205)
            else
                buffer.writef32(v120, 0, v205)
                v204 = buffer.readu32(v120, 0)
            end

            v206 = v127 * v199 + v196

            if v206 ~= 0 and v206 > -1.1754943508222875E-38 and v206 < 1.1754943508222875E-38 then
                v205 = to_bits(v206)
            else
                buffer.writef32(v120, 0, v206)
                v205 = buffer.readu32(v120, 0)
            end

            local v207 = v128 * v199 + v197

            if v207 ~= 0 and v207 > -1.1754943508222875E-38 and v207 < 1.1754943508222875E-38 then
                v206 = to_bits(v207)
            else
                buffer.writef32(v120, 0, v207)
                v206 = buffer.readu32(v120, 0)
            end

            local v208 = v129 * v199 + v198

            if v208 ~= 0 and v208 > -1.1754943508222875E-38 and v208 < 1.1754943508222875E-38 then
                v207 = to_bits(v208)
            else
                buffer.writef32(v120, 0, v208)
                v207 = buffer.readu32(v120, 0)
            end

            p16[v200] = v204
            p16[v201] = v205
            p16[v202] = v206
            p16[v203] = v207
        end
    end

    return 1
end

return t1
