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
local v8 = import("skate_core/physics/native_arithmetic")
local v9 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {}

function t1.matrix(p4) -- line: 39
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4[1])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[2])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[3])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[4])

    local t2 = {
        v11,
        v13,
        v15,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[5])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[6])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[7])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[8])

    local t3 = {
        v18,
        v20,
        v22,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[9])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[10])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[11])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[12])

    local t4 = {
        v25,
        v27,
        v29,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p4[13])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[14])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[15])

    local v36 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[16])

    return {
        t2,
        t3,
        t4,
        {
            v32,
            v34,
            v36,
            (buffer.readf32(v1, 0))
        }
    }
end

function t1.words(p5) -- line: 48
    -- upvalues: rt (copy), v1 (copy)
    local v38 = p5[rt.idiv(0, 4) + 1][rt.irem(0, 4) + 1]
    local v39

    if v38 ~= 0 and v38 > -1.1754943508222875E-38 and v38 < 1.1754943508222875E-38 then
        local v40 = math.abs(v38) * 7.1362384635298E+44
        local v41 = math.floor(v40)
        local v42 = v40 - v41

        v39 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

        if v38 < 0 then
            v39 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v38)
        v39 = buffer.readu32(v1, 0)
    end

    local v43 = p5[rt.idiv(1, 4) + 1][rt.irem(1, 4) + 1]
    local v44

    if v43 ~= 0 and v43 > -1.1754943508222875E-38 and v43 < 1.1754943508222875E-38 then
        local v45 = math.abs(v43) * 7.1362384635298E+44
        local v46 = math.floor(v45)
        local v47 = v45 - v46

        v44 = if v47 > 0.5 or v47 == 0.5 and v46 % 2 == 1 then v46 + 1 else v46

        if v43 < 0 then
            v44 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v43)
        v44 = buffer.readu32(v1, 0)
    end

    local v48 = p5[rt.idiv(2, 4) + 1][rt.irem(2, 4) + 1]
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

    local v53 = p5[rt.idiv(3, 4) + 1][rt.irem(3, 4) + 1]
    local v54

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        local v55 = math.abs(v53) * 7.1362384635298E+44
        local v56 = math.floor(v55)
        local v57 = v55 - v56

        v54 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

        if v53 < 0 then
            v54 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v54 = buffer.readu32(v1, 0)
    end

    local v58 = p5[rt.idiv(4, 4) + 1][rt.irem(4, 4) + 1]
    local v59

    if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
        local v60 = math.abs(v58) * 7.1362384635298E+44
        local v61 = math.floor(v60)
        local v62 = v60 - v61

        v59 = if v62 > 0.5 or v62 == 0.5 and v61 % 2 == 1 then v61 + 1 else v61

        if v58 < 0 then
            v59 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v58)
        v59 = buffer.readu32(v1, 0)
    end

    local v63 = p5[rt.idiv(5, 4) + 1][rt.irem(5, 4) + 1]
    local v64

    if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
        local v65 = math.abs(v63) * 7.1362384635298E+44
        local v66 = math.floor(v65)
        local v67 = v65 - v66

        v64 = if v67 > 0.5 or v67 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66

        if v63 < 0 then
            v64 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v63)
        v64 = buffer.readu32(v1, 0)
    end

    local v68 = p5[rt.idiv(6, 4) + 1][rt.irem(6, 4) + 1]
    local v69

    if v68 ~= 0 and v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
        local v70 = math.abs(v68) * 7.1362384635298E+44
        local v71 = math.floor(v70)
        local v72 = v70 - v71

        v69 = if v72 > 0.5 or v72 == 0.5 and v71 % 2 == 1 then v71 + 1 else v71

        if v68 < 0 then
            v69 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v68)
        v69 = buffer.readu32(v1, 0)
    end

    local v73 = p5[rt.idiv(7, 4) + 1][rt.irem(7, 4) + 1]
    local v74

    if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
        local v75 = math.abs(v73) * 7.1362384635298E+44
        local v76 = math.floor(v75)
        local v77 = v75 - v76

        v74 = if v77 > 0.5 or v77 == 0.5 and v76 % 2 == 1 then v76 + 1 else v76

        if v73 < 0 then
            v74 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v73)
        v74 = buffer.readu32(v1, 0)
    end

    local v78 = p5[rt.idiv(8, 4) + 1][rt.irem(8, 4) + 1]
    local v79

    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
        local v80 = math.abs(v78) * 7.1362384635298E+44
        local v81 = math.floor(v80)
        local v82 = v80 - v81

        v79 = if v82 > 0.5 or v82 == 0.5 and v81 % 2 == 1 then v81 + 1 else v81

        if v78 < 0 then
            v79 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v78)
        v79 = buffer.readu32(v1, 0)
    end

    local v83 = p5[rt.idiv(9, 4) + 1][rt.irem(9, 4) + 1]
    local v84

    if v83 ~= 0 and v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
        local v85 = math.abs(v83) * 7.1362384635298E+44
        local v86 = math.floor(v85)
        local v87 = v85 - v86

        v84 = if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86

        if v83 < 0 then
            v84 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v83)
        v84 = buffer.readu32(v1, 0)
    end

    local v88 = p5[rt.idiv(10, 4) + 1][rt.irem(10, 4) + 1]
    local v89

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        local v90 = math.abs(v88) * 7.1362384635298E+44
        local v91 = math.floor(v90)
        local v92 = v90 - v91

        v89 = if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91

        if v88 < 0 then
            v89 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v88)
        v89 = buffer.readu32(v1, 0)
    end

    local v93 = p5[rt.idiv(11, 4) + 1][rt.irem(11, 4) + 1]
    local v94

    if v93 ~= 0 and v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
        local v95 = math.abs(v93) * 7.1362384635298E+44
        local v96 = math.floor(v95)
        local v97 = v95 - v96

        v94 = if v97 > 0.5 or v97 == 0.5 and v96 % 2 == 1 then v96 + 1 else v96

        if v93 < 0 then
            v94 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v93)
        v94 = buffer.readu32(v1, 0)
    end

    local v98 = p5[rt.idiv(12, 4) + 1][rt.irem(12, 4) + 1]
    local v99

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        local v100 = math.abs(v98) * 7.1362384635298E+44
        local v101 = math.floor(v100)
        local v102 = v100 - v101

        v99 = if v102 > 0.5 or v102 == 0.5 and v101 % 2 == 1 then v101 + 1 else v101

        if v98 < 0 then
            v99 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v98)
        v99 = buffer.readu32(v1, 0)
    end

    local v103 = p5[rt.idiv(13, 4) + 1][rt.irem(13, 4) + 1]
    local v104

    if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
        local v105 = math.abs(v103) * 7.1362384635298E+44
        local v106 = math.floor(v105)
        local v107 = v105 - v106

        v104 = if v107 > 0.5 or v107 == 0.5 and v106 % 2 == 1 then v106 + 1 else v106

        if v103 < 0 then
            v104 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v103)
        v104 = buffer.readu32(v1, 0)
    end

    local v108 = p5[rt.idiv(14, 4) + 1][rt.irem(14, 4) + 1]
    local v109

    if v108 ~= 0 and v108 > -1.1754943508222875E-38 and v108 < 1.1754943508222875E-38 then
        local v110 = math.abs(v108) * 7.1362384635298E+44
        local v111 = math.floor(v110)
        local v112 = v110 - v111

        v109 = if v112 > 0.5 or v112 == 0.5 and v111 % 2 == 1 then v111 + 1 else v111

        if v108 < 0 then
            v109 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v108)
        v109 = buffer.readu32(v1, 0)
    end

    local v113 = p5[rt.idiv(15, 4) + 1][rt.irem(15, 4) + 1]
    local v114

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        local v115 = math.abs(v113) * 7.1362384635298E+44
        local v116 = math.floor(v115)
        local v117 = v115 - v116

        v114 = if v117 > 0.5 or v117 == 0.5 and v116 % 2 == 1 then v116 + 1 else v116

        if v113 < 0 then
            v114 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v113)
        v114 = buffer.readu32(v1, 0)
    end

    return {
        v39,
        v44,
        v49,
        v54,
        v59,
        v64,
        v69,
        v74,
        v79,
        v84,
        v89,
        v94,
        v99,
        v104,
        v109,
        v114
    }
end

function t1.add(p6, p7) -- line: 69
    return {
        p6[1] + p7[1],
        p6[2] + p7[2],
        p6[3] + p7[3],
        p6[4] + p7[4]
    }
end

function t1.sub(p8, p9) -- line: 73
    return {
        p8[1] - p9[1],
        p8[2] - p9[2],
        p8[3] - p9[3],
        p8[4] - p9[4]
    }
end

function t1.mul(p10, p11) -- line: 77
    return {
        p10[1] * p11[1],
        p10[2] * p11[2],
        p10[3] * p11[3],
        p10[4] * p11[4]
    }
end

function t1.madd(p12, p13, p14) -- line: 81
    return {
        p12[1] * p13[1] + p14[1],
        p12[2] * p13[2] + p14[2],
        p12[3] * p13[3] + p14[3],
        p12[4] * p13[4] + p14[4]
    }
end

function t1.nmsub(p15, p16, p17) -- line: 90
    return {
        -p15[1] * p16[1] + p17[1],
        -p15[2] * p16[2] + p17[2],
        -p15[3] * p16[3] + p17[3],
        -p15[4] * p16[4] + p17[4]
    }
end

function t1.perm(p18, p19) -- line: 100
    -- upvalues: rt (copy)
    return rt.map(p19, function(p20) -- line: 101
        -- upvalues: p18 (copy)
        return p18[p20 + 1]
    end)
end

function t1.dot(p21, p22, p23) -- line: 106
    -- upvalues: v8 (copy)
    if p23 then
        return v8.dot4(p21, p22)
    end

    return v8.dot3(p21, p22)
end

function t1.rsqrt(p24) -- line: 114
    -- upvalues: v9 (copy)
    local v118 = v9.estimate(p24)
    local v119 = v118 * v118
    local v120 = v118 * 0.5 * (-p24 * v119 + 1) + v118
    local v121 = v120 * v120

    return v120 * 0.5 * (-p24 * v121 + 1) + v120
end

function t1.normalize(p25, p26) -- line: 124
    -- upvalues: rt (copy), t1 (copy)
    return t1.mul(p25, rt.filled(4, t1.rsqrt(t1.dot(p25, p25, p26))))
end

function t1.cross(p27, p28) -- line: 128
    -- upvalues: t1 (copy)
    return t1.perm(t1.nmsub(t1.perm(p27, { 1, 2, 0, 3 }), p28, t1.mul(p27, t1.perm(p28, { 1, 2, 0, 3 }))), { 1, 2, 0, 3 })
end

function t1.compose(p29, p30) -- line: 135
    -- upvalues: rt (copy), t1 (copy)
    return rt.from_fn(4, function(p31) -- line: 136
        -- upvalues: p29 (copy), p30 (copy), rt (copy), t1 (copy)
        local v122 = if p31 == 3 then t1.madd(rt.filled(4, p30[p31 + 1][1]), p29[1], p29[4]) else t1.mul(rt.filled(4, p30[p31 + 1][1]), p29[1])

        return t1.madd(rt.filled(4, p30[p31 + 1][3]), p29[3], t1.madd(rt.filled(4, p30[p31 + 1][2]), p29[2], v122))
    end)
end

function t1.inverse_rigid(p32) -- line: 147
    -- upvalues: rt (copy), t1 (copy)
    local v123 = rt.from_fn(4, function(p33) -- line: 148
        -- upvalues: p32 (copy)
        if p33 < 3 then
            return {
                p32[1][p33 + 1],
                p32[2][p33 + 1],
                p32[3][p33 + 1],
                0
            }
        end

        return table.create(4, 0)
    end)
    local v124 = t1.sub(table.create(4, 0), p32[4])

    v123[4] = t1.madd(rt.filled(4, v124[1]), v123[1], t1.madd(rt.filled(4, v124[2]), v123[2], t1.mul(rt.filled(4, v124[3]), v123[3])))

    return v123
end

return t1
