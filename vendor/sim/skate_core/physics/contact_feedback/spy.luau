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

require(sim.import)

local to_bits, from_bits = rt.to_bits, rt.from_bits
local t1 = {}

function t1.spy_contact_jacobians(p4, p5, p6, p7, p8) -- line: 43
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    if not (#p4 >= p5 * 64) then
        error("assertion failed: storage.len() >= contact_count as usize * 64", 0)
    end

    local v8 = p7 * p7
    local v9 = p5 - 1
    local v10 = p6
    local n1 = 0

    for i = 0, v9 do
        local v11 = i * 64

        if bit32.band(p4[v11 + 11 + 1], 8) ~= 0 then
            local v13 = t1.vector(p4, v11 + 20)

            if v13[1] > 0 then
                local v14 = p4[v11 + 31 + 1]
                local v15 = p4[v11 + 43 + 1]
                local v16 = rt.map(p8(v15), rt.from_bits)
                local v17 = rt.map(p8(v14), rt.from_bits)
                local v18 = t1.vector(p4, v11)
                local v19 = t1.vector(p4, v11 + 4)

                buffer.writeu32(v1, 0, p4[v11 + 35 + 1])

                local v21 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, p4[v11 + 39 + 1])

                local v23 = buffer.readf32(v1, 0)
                local v24 = t1.vector(p4, v11 + 28)
                local v25 = t1.vector(p4, v11 + 40)
                local v26 = t1.vector(p4, v11 + 52)
                local t2 = {
                    v25[1] * v13[2] + v26[1] * v13[3],
                    v25[2] * v13[2] + v26[2] * v13[3],
                    v25[3] * v13[2] + v26[3] * v13[3],
                    v25[4] * v13[2] + v26[4] * v13[3]
                }
                local v27 = 1 / (v23 + v21)
                local t3 = {
                    ((v17[1] + v18[1]) * v21 + (v16[1] + v19[1]) * v23) * v27,
                    ((v17[2] + v18[2]) * v21 + (v16[2] + v19[2]) * v23) * v27,
                    ((v17[3] + v18[3]) * v21 + (v16[3] + v19[3]) * v23) * v27,
                    ((v17[4] + v18[4]) * v21 + (v16[4] + v19[4]) * v23) * v27
                }
                local v28 = p4[v11 + 55 + 1]

                p4[n1 + 24 + 1] = v14
                p4[n1 + 25 + 1] = v15
                p4[n1 + 26 + 1] = v28

                for j = 0, 3 do
                    local v29 = n1 + 16 + j + 1
                    local v30 = v24[j + 1] * v13[1] * v8

                    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
                        local v31 = math.abs(v30) * 7.1362384635298E+44
                        local v32 = math.floor(v31)
                        local v33 = v31 - v32
                        local v34 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

                        if v30 < 0 then
                            p4[v29] = v34 + 2147483648
                        else
                            p4[v29] = v34
                        end
                    else
                        buffer.writef32(v1, 0, v30)
                        p4[v29] = buffer.readu32(v1, 0)
                    end

                    local v35 = n1 + 20 + j + 1
                    local v36 = t2[j + 1] * v8

                    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
                        local v37 = math.abs(v36) * 7.1362384635298E+44
                        local v38 = math.floor(v37)
                        local v39 = v37 - v38
                        local v40 = if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38

                        if v36 < 0 then
                            p4[v35] = v40 + 2147483648
                        else
                            p4[v35] = v40
                        end
                    else
                        buffer.writef32(v1, 0, v36)
                        p4[v35] = buffer.readu32(v1, 0)
                    end

                    local v41 = n1 + j + 1
                    local v42 = v24[j + 1]

                    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
                        local v43 = math.abs(v42) * 7.1362384635298E+44
                        local v44 = math.floor(v43)
                        local v45 = v43 - v44
                        local v46 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

                        if v42 < 0 then
                            p4[v41] = v46 + 2147483648
                        else
                            p4[v41] = v46
                        end
                    else
                        buffer.writef32(v1, 0, v42)
                        p4[v41] = buffer.readu32(v1, 0)
                    end

                    local v47 = n1 + 4 + j + 1
                    local v48 = v25[j + 1]

                    if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
                        local v49 = math.abs(v48) * 7.1362384635298E+44
                        local v50 = math.floor(v49)
                        local v51 = v49 - v50
                        local v52 = if v51 > 0.5 or v51 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50

                        if v48 < 0 then
                            p4[v47] = v52 + 2147483648
                        else
                            p4[v47] = v52
                        end
                    else
                        buffer.writef32(v1, 0, v48)
                        p4[v47] = buffer.readu32(v1, 0)
                    end

                    local v53 = n1 + 8 + j + 1
                    local v54 = v26[j + 1]

                    if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
                        local v55 = math.abs(v54) * 7.1362384635298E+44
                        local v56 = math.floor(v55)
                        local v57 = v55 - v56
                        local v58 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

                        if v54 < 0 then
                            p4[v53] = v58 + 2147483648
                        else
                            p4[v53] = v58
                        end
                    else
                        buffer.writef32(v1, 0, v54)
                        p4[v53] = buffer.readu32(v1, 0)
                    end

                    local v59 = n1 + 12 + j + 1
                    local v60 = t3[j + 1]

                    if v60 ~= 0 and v60 > -1.1754943508222875E-38 and v60 < 1.1754943508222875E-38 then
                        local v61 = math.abs(v60) * 7.1362384635298E+44
                        local v62 = math.floor(v61)
                        local v63 = v61 - v62
                        local v64 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

                        if v60 < 0 then
                            p4[v59] = v64 + 2147483648
                        else
                            p4[v59] = v64
                        end
                    else
                        buffer.writef32(v1, 0, v60)
                        p4[v59] = buffer.readu32(v1, 0)
                    end
                end

                v10 = rt.wrapping_add_u32(v10, 1)
                n1 += 28
            end
        end
    end

    return v10
end

function t1.spy_contact_jacobians_scalar(p9, p10, p11, p12, p13, p14, p15) -- line: 121
    -- upvalues: rt (copy), to_bits (copy), from_bits (copy)
    if not (#p9 >= p10 * 64) then
        error("assertion failed: storage.len() >= contact_count as usize * 64", 0)
    end

    local v65 = p12 * p12
    local v66 = p10 - 1
    local v67 = p11
    local n2 = 0

    for i = 0, v66 do
        local v68 = i * 64

        if bit32.band(p9[v68 + 12], 8) ~= 0 then
            local v70 = from_bits(p9[v68 + 21])

            if v70 > 0 then
                local v71 = from_bits(p9[v68 + 22])
                local v72 = from_bits(p9[v68 + 23])
                local v73 = p9[v68 + 32]
                local v74 = p9[v68 + 44]
                local v75, v76, v77, v78 = p13(p14, p15, v74)
                local v79 = from_bits(v75)
                local v80 = from_bits(v76)
                local v81 = from_bits(v77)
                local v82 = from_bits(v78)
                local v83, v84, v85, v86 = p13(p14, p15, v73)
                local v87 = from_bits(v83)
                local v88 = from_bits(v84)
                local v89 = from_bits(v85)
                local v90 = from_bits(v86)
                local v91 = from_bits(p9[v68 + 1])
                local v92 = from_bits(p9[v68 + 2])
                local v93 = from_bits(p9[v68 + 3])
                local v94 = from_bits(p9[v68 + 4])
                local v95 = from_bits(p9[v68 + 5])
                local v96 = from_bits(p9[v68 + 6])
                local v97 = from_bits(p9[v68 + 7])
                local v98 = from_bits(p9[v68 + 8])
                local v99 = from_bits(p9[v68 + 36])
                local v100 = from_bits(p9[v68 + 40])
                local v101 = from_bits(p9[v68 + 29])
                local v102 = from_bits(p9[v68 + 30])
                local v103 = from_bits(p9[v68 + 31])
                local v104 = from_bits(p9[v68 + 32])
                local v105 = from_bits(p9[v68 + 41])
                local v106 = from_bits(p9[v68 + 42])
                local v107 = from_bits(p9[v68 + 43])
                local v108 = from_bits(p9[v68 + 44])
                local v109 = from_bits(p9[v68 + 53])
                local v110 = from_bits(p9[v68 + 54])
                local v111 = from_bits(p9[v68 + 55])
                local v112 = from_bits(p9[v68 + 56])
                local v113 = v105 * v71 + v109 * v72
                local v114 = v106 * v71 + v110 * v72
                local v115 = v107 * v71 + v111 * v72
                local v116 = v108 * v71 + v112 * v72
                local v117 = 1 / (v100 + v99)
                local v118 = ((v87 + v91) * v99 + (v79 + v95) * v100) * v117
                local v119 = ((v88 + v92) * v99 + (v80 + v96) * v100) * v117
                local v120 = ((v89 + v93) * v99 + (v81 + v97) * v100) * v117
                local v121 = ((v90 + v94) * v99 + (v82 + v98) * v100) * v117
                local v122 = p9[v68 + 56]

                p9[n2 + 25] = v73
                p9[n2 + 26] = v74
                p9[n2 + 27] = v122
                p9[n2 + 17] = to_bits(v101 * v70 * v65)
                p9[n2 + 18] = to_bits(v102 * v70 * v65)
                p9[n2 + 19] = to_bits(v103 * v70 * v65)
                p9[n2 + 20] = to_bits(v104 * v70 * v65)
                p9[n2 + 21] = to_bits(v113 * v65)
                p9[n2 + 22] = to_bits(v114 * v65)
                p9[n2 + 23] = to_bits(v115 * v65)
                p9[n2 + 24] = to_bits(v116 * v65)
                p9[n2 + 1] = to_bits(v101)
                p9[n2 + 2] = to_bits(v102)
                p9[n2 + 3] = to_bits(v103)
                p9[n2 + 4] = to_bits(v104)
                p9[n2 + 5] = to_bits(v105)
                p9[n2 + 6] = to_bits(v106)
                p9[n2 + 7] = to_bits(v107)
                p9[n2 + 8] = to_bits(v108)
                p9[n2 + 9] = to_bits(v109)
                p9[n2 + 10] = to_bits(v110)
                p9[n2 + 11] = to_bits(v111)
                p9[n2 + 12] = to_bits(v112)
                p9[n2 + 13] = to_bits(v118)
                p9[n2 + 14] = to_bits(v119)
                p9[n2 + 15] = to_bits(v120)
                p9[n2 + 16] = to_bits(v121)
                v67 = rt.wrapping_add_u32(v67, 1)
                n2 += 28
            end
        end
    end

    return v67
end

function t1.vector(p16, p17) -- line: 214
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p16[p17 + 0 + 1])

    local v124 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p16[p17 + 1 + 1])

    local v126 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p16[p17 + 2 + 1])

    local v128 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p16[p17 + 3 + 1])

    return {
        v124,
        v126,
        v128,
        (buffer.readf32(v1, 0))
    }
end

return t1
