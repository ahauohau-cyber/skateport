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

local v8 = require(sim.import)("skate_core/physics/native_arithmetic")
local t1 = {}

function t1.matrix(p4) -- line: 37
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4[1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[2])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[3])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[4])

    local t2 = {
        v10,
        v12,
        v14,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[5])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[6])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[7])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[8])

    local t3 = {
        v17,
        v19,
        v21,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[9])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[10])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[11])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[12])

    local t4 = {
        v24,
        v26,
        v28,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[13])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[14])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[15])

    local v35 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[16])

    return {
        t2,
        t3,
        t4,
        {
            v31,
            v33,
            v35,
            (buffer.readf32(v1, 0))
        }
    }
end

function t1.madd(p5, p6, p7) -- line: 46
    return {
        p5[1] * p6 + p7[1],
        p5[2] * p6 + p7[2],
        p5[3] * p6 + p7[3],
        p5[4] * p6 + p7[4]
    }
end

function t1.scale(p8, p9) -- line: 55
    -- upvalues: rt (copy)
    return rt.map(p8, function(p10) -- line: 56
        -- upvalues: p9 (copy)
        return p10 * p9
    end)
end

function t1.cross(p11, p12) -- line: 61
    return {
        -p11[3] * p12[2] + p11[2] * p12[3],
        -p11[1] * p12[3] + p11[3] * p12[1],
        -p11[2] * p12[1] + p11[1] * p12[2],
        -p11[4] * p12[4] + p11[4] * p12[4]
    }
end

function t1.dot(p13, p14) -- line: 70
    -- upvalues: v8 (copy)
    return v8.dot3(p13, p14)
end

function t1.part_mass_transform(p15) -- line: 77
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local body = p15.body

    if body ~= nil then
        local t5 = {
            16, 20, 24, 4
        }

        return {
            body[t5[rt.idiv(0, 4) + 1] + rt.irem(0, 4) + 1],
            body[t5[rt.idiv(1, 4) + 1] + rt.irem(1, 4) + 1],
            body[t5[rt.idiv(2, 4) + 1] + rt.irem(2, 4) + 1],
            body[t5[rt.idiv(3, 4) + 1] + rt.irem(3, 4) + 1],
            body[t5[rt.idiv(4, 4) + 1] + rt.irem(4, 4) + 1],
            body[t5[rt.idiv(5, 4) + 1] + rt.irem(5, 4) + 1],
            body[t5[rt.idiv(6, 4) + 1] + rt.irem(6, 4) + 1],
            body[t5[rt.idiv(7, 4) + 1] + rt.irem(7, 4) + 1],
            body[t5[rt.idiv(8, 4) + 1] + rt.irem(8, 4) + 1],
            body[t5[rt.idiv(9, 4) + 1] + rt.irem(9, 4) + 1],
            body[t5[rt.idiv(10, 4) + 1] + rt.irem(10, 4) + 1],
            body[t5[rt.idiv(11, 4) + 1] + rt.irem(11, 4) + 1],
            body[t5[rt.idiv(12, 4) + 1] + rt.irem(12, 4) + 1],
            body[t5[rt.idiv(13, 4) + 1] + rt.irem(13, 4) + 1],
            body[t5[rt.idiv(14, 4) + 1] + rt.irem(14, 4) + 1],
            body[t5[rt.idiv(15, 4) + 1] + rt.irem(15, 4) + 1]
        }
    end

    if p15.local_mass_frame == nil then
        return rt.copy(p15.transform)
    end

    local v37 = t1.matrix(p15.local_mass_frame)
    local t6 = {
        {
            v37[1][1],
            v37[2][1],
            v37[3][1],
            0
        },
        {
            v37[1][2],
            v37[2][2],
            v37[3][2],
            0
        },
        {
            v37[1][3],
            v37[2][3],
            v37[3][3],
            0
        }
    }
    local v38 = rt.map(v37[4], function(p16) -- line: 109
        return 0 - p16
    end)
    local v39 = t1.madd(t6[1], v38[1], t1.madd(t6[2], v38[2], t1.scale(t6[3], v38[3])))
    local v40 = t1.matrix(p15.transform)
    local v41 = rt.from_fn(4, function(p17) -- line: 114
        -- upvalues: t6 (copy), v39 (copy), v40 (copy), t1 (copy)
        local v42 = if p17 == 3 then v39 else t6[p17 + 1]
        local v43 = if p17 == 3 then t1.madd(v40[1], v42[1], v40[4]) else t1.scale(v40[1], v42[1])

        return t1.madd(v40[3], v42[3], t1.madd(v40[2], v42[2], v43))
    end)
    local v44 = v41[rt.idiv(0, 4) + 1][rt.irem(0, 4) + 1]
    local v45

    if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
        local v46 = math.abs(v44) * 7.1362384635298E+44
        local v47 = math.floor(v46)
        local v48 = v46 - v47

        v45 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

        if v44 < 0 then
            v45 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v44)
        v45 = buffer.readu32(v1, 0)
    end

    local v49 = v41[rt.idiv(1, 4) + 1][rt.irem(1, 4) + 1]
    local v50

    if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
        local v51 = math.abs(v49) * 7.1362384635298E+44
        local v52 = math.floor(v51)
        local v53 = v51 - v52

        v50 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

        if v49 < 0 then
            v50 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v49)
        v50 = buffer.readu32(v1, 0)
    end

    local v54 = v41[rt.idiv(2, 4) + 1][rt.irem(2, 4) + 1]
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

    local v59 = v41[rt.idiv(3, 4) + 1][rt.irem(3, 4) + 1]
    local v60

    if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
        local v61 = math.abs(v59) * 7.1362384635298E+44
        local v62 = math.floor(v61)
        local v63 = v61 - v62

        v60 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

        if v59 < 0 then
            v60 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v59)
        v60 = buffer.readu32(v1, 0)
    end

    local v64 = v41[rt.idiv(4, 4) + 1][rt.irem(4, 4) + 1]
    local v65

    if v64 ~= 0 and v64 > -1.1754943508222875E-38 and v64 < 1.1754943508222875E-38 then
        local v66 = math.abs(v64) * 7.1362384635298E+44
        local v67 = math.floor(v66)
        local v68 = v66 - v67

        v65 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v64 < 0 then
            v65 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v64)
        v65 = buffer.readu32(v1, 0)
    end

    local v69 = v41[rt.idiv(5, 4) + 1][rt.irem(5, 4) + 1]
    local v70

    if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
        local v71 = math.abs(v69) * 7.1362384635298E+44
        local v72 = math.floor(v71)
        local v73 = v71 - v72

        v70 = if v73 > 0.5 or v73 == 0.5 and v72 % 2 == 1 then v72 + 1 else v72

        if v69 < 0 then
            v70 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v69)
        v70 = buffer.readu32(v1, 0)
    end

    local v74 = v41[rt.idiv(6, 4) + 1][rt.irem(6, 4) + 1]
    local v75

    if v74 ~= 0 and v74 > -1.1754943508222875E-38 and v74 < 1.1754943508222875E-38 then
        local v76 = math.abs(v74) * 7.1362384635298E+44
        local v77 = math.floor(v76)
        local v78 = v76 - v77

        v75 = if v78 > 0.5 or v78 == 0.5 and v77 % 2 == 1 then v77 + 1 else v77

        if v74 < 0 then
            v75 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v74)
        v75 = buffer.readu32(v1, 0)
    end

    local v79 = v41[rt.idiv(7, 4) + 1][rt.irem(7, 4) + 1]
    local v80

    if v79 ~= 0 and v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        local v81 = math.abs(v79) * 7.1362384635298E+44
        local v82 = math.floor(v81)
        local v83 = v81 - v82

        v80 = if v83 > 0.5 or v83 == 0.5 and v82 % 2 == 1 then v82 + 1 else v82

        if v79 < 0 then
            v80 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v79)
        v80 = buffer.readu32(v1, 0)
    end

    local v84 = v41[rt.idiv(8, 4) + 1][rt.irem(8, 4) + 1]
    local v85

    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
        local v86 = math.abs(v84) * 7.1362384635298E+44
        local v87 = math.floor(v86)
        local v88 = v86 - v87

        v85 = if v88 > 0.5 or v88 == 0.5 and v87 % 2 == 1 then v87 + 1 else v87

        if v84 < 0 then
            v85 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v84)
        v85 = buffer.readu32(v1, 0)
    end

    local v89 = v41[rt.idiv(9, 4) + 1][rt.irem(9, 4) + 1]
    local v90

    if v89 ~= 0 and v89 > -1.1754943508222875E-38 and v89 < 1.1754943508222875E-38 then
        local v91 = math.abs(v89) * 7.1362384635298E+44
        local v92 = math.floor(v91)
        local v93 = v91 - v92

        v90 = if v93 > 0.5 or v93 == 0.5 and v92 % 2 == 1 then v92 + 1 else v92

        if v89 < 0 then
            v90 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v89)
        v90 = buffer.readu32(v1, 0)
    end

    local v94 = v41[rt.idiv(10, 4) + 1][rt.irem(10, 4) + 1]
    local v95

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        local v96 = math.abs(v94) * 7.1362384635298E+44
        local v97 = math.floor(v96)
        local v98 = v96 - v97

        v95 = if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97

        if v94 < 0 then
            v95 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v94)
        v95 = buffer.readu32(v1, 0)
    end

    local v99 = v41[rt.idiv(11, 4) + 1][rt.irem(11, 4) + 1]
    local v100

    if v99 ~= 0 and v99 > -1.1754943508222875E-38 and v99 < 1.1754943508222875E-38 then
        local v101 = math.abs(v99) * 7.1362384635298E+44
        local v102 = math.floor(v101)
        local v103 = v101 - v102

        v100 = if v103 > 0.5 or v103 == 0.5 and v102 % 2 == 1 then v102 + 1 else v102

        if v99 < 0 then
            v100 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v99)
        v100 = buffer.readu32(v1, 0)
    end

    local v104 = v41[rt.idiv(12, 4) + 1][rt.irem(12, 4) + 1]
    local v105

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        local v106 = math.abs(v104) * 7.1362384635298E+44
        local v107 = math.floor(v106)
        local v108 = v106 - v107

        v105 = if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107

        if v104 < 0 then
            v105 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v104)
        v105 = buffer.readu32(v1, 0)
    end

    local v109 = v41[rt.idiv(13, 4) + 1][rt.irem(13, 4) + 1]
    local v110

    if v109 ~= 0 and v109 > -1.1754943508222875E-38 and v109 < 1.1754943508222875E-38 then
        local v111 = math.abs(v109) * 7.1362384635298E+44
        local v112 = math.floor(v111)
        local v113 = v111 - v112

        v110 = if v113 > 0.5 or v113 == 0.5 and v112 % 2 == 1 then v112 + 1 else v112

        if v109 < 0 then
            v110 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v109)
        v110 = buffer.readu32(v1, 0)
    end

    local v114 = v41[rt.idiv(14, 4) + 1][rt.irem(14, 4) + 1]
    local v115

    if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
        local v116 = math.abs(v114) * 7.1362384635298E+44
        local v117 = math.floor(v116)
        local v118 = v116 - v117

        v115 = if v118 > 0.5 or v118 == 0.5 and v117 % 2 == 1 then v117 + 1 else v117

        if v114 < 0 then
            v115 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v114)
        v115 = buffer.readu32(v1, 0)
    end

    local v119 = v41[rt.idiv(15, 4) + 1][rt.irem(15, 4) + 1]
    local v120

    if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
        local v121 = math.abs(v119) * 7.1362384635298E+44
        local v122 = math.floor(v121)
        local v123 = v121 - v122

        v120 = if v123 > 0.5 or v123 == 0.5 and v122 % 2 == 1 then v122 + 1 else v122

        if v119 < 0 then
            v120 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v119)
        v120 = buffer.readu32(v1, 0)
    end

    return {
        v45,
        v50,
        v55,
        v60,
        v65,
        v70,
        v75,
        v80,
        v85,
        v90,
        v95,
        v100,
        v105,
        v110,
        v115,
        v120
    }
end

function t1.calculate_wheel_compressions(p18, p19) -- line: 147
    -- upvalues: v1 (copy), t1 (copy)
    local v124 = t1.matrix(t1.part_mass_transform(p19[7]))
    local t8 = {
        t1.matrix(t1.part_mass_transform(p19[1]))[4],
        t1.matrix(t1.part_mass_transform(p19[2]))[4],
        t1.matrix(t1.part_mass_transform(p19[3]))[4],
        t1.matrix(t1.part_mass_transform(p19[4]))[4]
    }

    buffer.writeu32(v1, 0, p18[8381] * 16777216 + p18[8382] * 65536 + p18[8383] * 256 + p18[8384])

    local v126 = buffer.readf32(v1, 0)
    local v127 = t1.average_wheel_compressions(v124, t8, v126)

    for _, v128 in {
            {
                8372,
                v127[1]
            },
            {
                8376,
                v127[2]
            }
        } do
        local v129 = v128[1]
        local v130 = v128[2]
        local v131

        if v130 == v130 then
            if v130 == 0 then
                buffer.writef32(v1, 0, v130)
                v131 = buffer.readu32(v1, 0)
            elseif v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
                local v132 = math.abs(v130) * 7.1362384635298E+44

                v131 = math.floor(v132)

                local v133 = v132 - v131

                if v133 > 0.5 or v133 == 0.5 and v131 % 2 == 1 then
                    v131 += 1
                end

                if v130 < 0 then
                    v131 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v130)
                v131 = buffer.readu32(v1, 0)
            end
        else
            local v134

            if v130 == 0 then
                buffer.writef32(v1, 0, v130)
                v134 = buffer.readu32(v1, 0)
            elseif v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
                local v135 = math.abs(v130) * 7.1362384635298E+44

                v134 = math.floor(v135)

                local v136 = v135 - v134

                if v136 > 0.5 or v136 == 0.5 and v134 % 2 == 1 then
                    v134 += 1
                end

                if v130 < 0 then
                    v134 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v130)
                v134 = buffer.readu32(v1, 0)
            end

            v131 = bit32.bor(v134, 4194304)
        end

        p18[v129 + 1] = bit32.band(bit32.rshift(v131, 24), 255)
        p18[v129 + 2] = bit32.band(bit32.rshift(v131, 16), 255)
        p18[v129 + 3] = bit32.band(bit32.rshift(v131, 8), 255)
        p18[v129 + 4] = bit32.band(v131, 255)
    end
end

function t1.average_wheel_compressions(p20, p21, p22) -- line: 176
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v143 = t1.cross(p20[2], p20[3])
    local v144 = t1.cross(p20[3], p20[1])
    local v145 = t1.cross(p20[1], p20[2])
    local v146 = t1.dot(p20[1], v143)
    local v147 = t1.reciprocal_estimate(v146)
    local v148 = v147 * (-v147 * v146 + 1) + v147
    local v149 = v148 * (-v148 * v146 + 1) + v148
    local t9 = {
        t1.scale({
            v143[1],
            v144[1],
            v145[1],
            v144[1]
        }, v149),
        t1.scale({
            v143[2],
            v144[2],
            v145[2],
            v144[2]
        }, v149),
        t1.scale({
            v143[3],
            v144[3],
            v145[3],
            v144[3]
        }, v149)
    }
    local v150 = rt.map(p20[4], function(p23) -- line: 191
        -- upvalues: v1 (copy)
        local v151

        if p23 ~= 0 and p23 > -1.1754943508222875E-38 and p23 < 1.1754943508222875E-38 then
            local v152 = math.abs(p23) * 7.1362384635298E+44
            local v153 = math.floor(v152)
            local v154 = v152 - v153

            v151 = if v154 > 0.5 or v154 == 0.5 and v153 % 2 == 1 then v153 + 1 else v153

            if p23 < 0 then
                v151 += 2147483648
            end
        else
            buffer.writef32(v1, 0, p23)
            v151 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v151, 2147483648)))

        return (buffer.readf32(v1, 0))
    end)
    local v156 = t1.madd(t9[3], v150[3], t1.madd(t9[2], v150[2], t1.scale(t9[1], v150[1])))
    local v157 = rt.from_fn(4, function(p24) -- line: 195
        -- upvalues: p21 (copy), t9 (copy), v156 (copy), t1 (copy)
        local v158 = p21[p24 + 1]

        return t1.madd(t9[3], v158[3], t1.madd(t9[2], v158[2], t1.madd(t9[1], v158[1], v156)))[2]
    end)

    return {
        (v157[1] + v157[2]) * 0.5 - p22,
        (v157[3] + v157[4]) * 0.5 - p22
    }
end

function t1.reciprocal_estimate(p25) -- line: 206
    -- upvalues: v8 (copy)
    return v8.reciprocal_estimate(p25)
end

return t1
