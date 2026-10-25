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
local v8 = import("skate_core/physics/reciprocal_sqrt")
local v9 = import("skate_core/physics/world_contact/prism_math")
local estimate = v8.estimate
local load, dot, scale, cross = v9.load, v9.dot, v9.scale, v9.cross
local minimum, maximum
local t1 = {}

function t1.triangle_box_reference(p4, p5) -- line: 49
    -- upvalues: rt (copy), v1 (copy), estimate (copy), load (copy), dot (copy), scale (copy), cross (copy), minimum (ref), maximum (ref)
    local v10 = rt.filled(13, { 0, 0, 0, 0 })

    v10[1] = load(p4, 4)
    v10[2] = load(p5, 12)
    v10[3] = load(p5, 8)
    v10[4] = load(p5, 4)

    for i = 0, 2 do
        for j = 0, 2 do
            local v11 = cross(load(p4, i * 4 + 16), load(p5, j * 4 + 16))
            local v12 = dot(v11, v11)
            local v13 = estimate(v12)
            local v14 = v13 * 0.5 * (-v12 * (v13 * v13) + 1) + v13

            v10[i * 3 + 4 + j + 1] = scale(v11, v14)
        end
    end

    local v15 = load(p5, 4)

    buffer.writeu32(v1, 0, p5[29])

    local v17 = scale(v15, (buffer.readf32(v1, 0)))
    local v18 = load(p5, 8)

    buffer.writeu32(v1, 0, p5[30])

    local v20 = scale(v18, (buffer.readf32(v1, 0)))
    local v21 = load(p5, 12)

    buffer.writeu32(v1, 0, p5[31])

    local t2 = {
        v17,
        v20,
        scale(v21, (buffer.readf32(v1, 0)))
    }
    local v23 = 0
    local v24 = rt.copy(v10[1])
    local v25 = 1

    for i = 0, 12 do
        local v26 = v10[i + 1]
        local v27 = dot(load(p4, 0), v26)
        local v28 = dot(load(p4, 8), v26)
        local v29 = dot(load(p4, 12), v26)
        local v30 = minimum(v27, minimum(v28, v29))
        local v31 = maximum(v27, maximum(v28, v29))
        local v32 = dot(load(p5, 0), v26)
        local t3 = {
            math.abs((dot(t2[1], v26))),
            math.abs((dot(t2[2], v26))),
            (math.abs((dot(t2[3], v26))))
        }
        local v38 = t3[1] + t3[2] + t3[3]
        local v39 = v30 - (v32 + v38)
        local v40 = v32 - v38 - v31
        local n1 = 1

        if v40 < v39 then
            n1 = -1
        else
            v39 = v40
        end

        if i == 0 or v23 < v39 then
            v23 = v39
            v24 = rt.copy(v26)
            v25 = n1
        end
    end

    local v41 = scale(v24, v25)
    local filled = rt.filled
    local v42

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v43 = math.abs(v23) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if v23 < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v42 = buffer.readu32(v1, 0)
    end

    local v46 = filled(4, v42)
    local v47 = v41[1]
    local v48

    if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
        local v49 = math.abs(v47) * 7.1362384635298E+44
        local v50 = math.floor(v49)
        local v51 = v49 - v50

        v48 = if v51 > 0.5 or v51 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50

        if v47 < 0 then
            v48 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v47)
        v48 = buffer.readu32(v1, 0)
    end

    local v52 = v41[2]
    local v53

    if v52 ~= 0 and v52 > -1.1754943508222875E-38 and v52 < 1.1754943508222875E-38 then
        local v54 = math.abs(v52) * 7.1362384635298E+44
        local v55 = math.floor(v54)
        local v56 = v54 - v55

        v53 = if v56 > 0.5 or v56 == 0.5 and v55 % 2 == 1 then v55 + 1 else v55

        if v52 < 0 then
            v53 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v52)
        v53 = buffer.readu32(v1, 0)
    end

    local v57 = v41[3]
    local v58

    if v57 ~= 0 and v57 > -1.1754943508222875E-38 and v57 < 1.1754943508222875E-38 then
        local v59 = math.abs(v57) * 7.1362384635298E+44
        local v60 = math.floor(v59)
        local v61 = v59 - v60

        v58 = if v61 > 0.5 or v61 == 0.5 and v60 % 2 == 1 then v60 + 1 else v60

        if v57 < 0 then
            v58 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v57)
        v58 = buffer.readu32(v1, 0)
    end

    local v62 = v41[4]
    local v63

    if v62 ~= 0 and v62 > -1.1754943508222875E-38 and v62 < 1.1754943508222875E-38 then
        local v64 = math.abs(v62) * 7.1362384635298E+44
        local v65 = math.floor(v64)
        local v66 = v64 - v65

        v63 = if v66 > 0.5 or v66 == 0.5 and v65 % 2 == 1 then v65 + 1 else v65

        if v62 < 0 then
            v63 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v62)
        v63 = buffer.readu32(v1, 0)
    end

    return v46, {
        v48,
        v53,
        v58,
        v63
    }
end

local v67 = buffer.create(8)

local function fb(p6) -- line: 110
    -- upvalues: v67 (copy)
    buffer.writeu32(v67, 0, p6)

    return (buffer.readf32(v67, 0))
end

local to_bits = rt.to_bits

local function tb(p7) -- line: 115
    -- upvalues: v67 (copy), to_bits (copy)
    if p7 ~= 0 and p7 > -1.1754943508222875E-38 and p7 < 1.1754943508222875E-38 then
        return to_bits(p7)
    end

    buffer.writef32(v67, 0, p7)

    return (buffer.readu32(v67, 0))
end

local v68 = table.create(52, 0)

local function triangle_box_into(p8, p9, p10) -- line: 131
    -- upvalues: estimate (copy), v67 (copy), to_bits (copy), tb (copy), v68 (copy)
    buffer.writeu32(v67, 0, p8[5])

    local v70 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[6])

    local v72 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[7])

    local v74 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[8])

    local v76 = buffer.readf32(v67, 0)

    v68[1] = v70
    v68[2] = v72
    v68[3] = v74
    v68[4] = v76
    buffer.writeu32(v67, 0, p9[13])
    v70 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[14])
    v72 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[15])
    v74 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[16])
    v76 = buffer.readf32(v67, 0)
    v68[5] = v70
    v68[6] = v72
    v68[7] = v74
    v68[8] = v76
    buffer.writeu32(v67, 0, p9[9])
    v70 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[10])
    v72 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[11])
    v74 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[12])
    v76 = buffer.readf32(v67, 0)
    v68[9] = v70
    v68[10] = v72
    v68[11] = v74
    v68[12] = v76
    buffer.writeu32(v67, 0, p9[5])
    v70 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[6])
    v72 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[7])
    v74 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p9[8])
    v76 = buffer.readf32(v67, 0)
    v68[13] = v70
    v68[14] = v72
    v68[15] = v74
    v68[16] = v76

    local v77, v78, v79, v80, v81, v82, v83, v84, v85, v86, v87, v88

    for i = 0, 2 do
        v72 = i * 4 + 16
        v81 = p8[v72 + 1]
        buffer.writeu32(v67, 0, v81)
        v82 = buffer.readf32(v67, 0)
        v81 = p8[v72 + 2]
        buffer.writeu32(v67, 0, v81)

        local v89 = buffer.readf32(v67, 0)

        v81 = p8[v72 + 3]
        buffer.writeu32(v67, 0, v81)

        local v90 = buffer.readf32(v67, 0)

        v81 = p8[v72 + 4]
        buffer.writeu32(v67, 0, v81)

        local v91 = buffer.readf32(v67, 0)

        for j = 0, 2 do
            v72 = j * 4 + 16
            buffer.writeu32(v67, 0, p9[v72 + 1])
            v77 = buffer.readf32(v67, 0)
            buffer.writeu32(v67, 0, p9[v72 + 2])

            local v93 = buffer.readf32(v67, 0)

            buffer.writeu32(v67, 0, p9[v72 + 3])

            local v94 = buffer.readf32(v67, 0)

            buffer.writeu32(v67, 0, p9[v72 + 4])

            local v95 = buffer.readf32(v67, 0)

            v72 = -v90 * v93 + v89 * v94

            local v92 = -v82 * v94 + v90 * v77

            v78 = -v89 * v77 + v82 * v93

            local v96 = -v91 * v95 + v91 * v95

            v83 = v72 * v72 + v92 * v92 + v78 * v78
            v77 = estimate(v83)
            v77 = v77 * 0.5 * (-v83 * (v77 * v77) + 1) + v77
            v83 = (i * 3 + 4 + j) * 4
            v84 = v83 + 1

            local v97 = v83 + 2

            v79 = v83 + 3
            v85 = v83 + 4
            v80 = v72 * v77
            v87 = v92 * v77
            v88 = v78 * v77
            v86 = v96 * v77
            v68[v84] = v80
            v68[v97] = v87
            v68[v79] = v88
            v68[v85] = v86
        end
    end

    buffer.writeu32(v67, 0, p9[29])

    local v71 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[5])

    local v69 = buffer.readf32(v67, 0) * v71

    buffer.writeu32(v67, 0, p9[6])
    v70 = buffer.readf32(v67, 0) * v71
    buffer.writeu32(v67, 0, p9[7])
    v72 = buffer.readf32(v67, 0) * v71
    buffer.writeu32(v67, 0, p9[30])

    local v98 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[9])
    v74 = buffer.readf32(v67, 0) * v98
    buffer.writeu32(v67, 0, p9[10])
    v76 = buffer.readf32(v67, 0) * v98
    buffer.writeu32(v67, 0, p9[11])

    local v99 = buffer.readf32(v67, 0) * v98

    buffer.writeu32(v67, 0, p9[31])

    local v101 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[13])

    local v100 = buffer.readf32(v67, 0) * v101

    buffer.writeu32(v67, 0, p9[14])
    v81 = buffer.readf32(v67, 0) * v101
    buffer.writeu32(v67, 0, p9[15])
    v82 = buffer.readf32(v67, 0) * v101
    buffer.writeu32(v67, 0, p8[1])
    v83 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p8[2])

    local v103 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[3])

    local v104 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[9])
    v84 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p8[10])

    local v105 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[11])

    local v106 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[13])
    v85 = buffer.readf32(v67, 0)
    buffer.writeu32(v67, 0, p8[14])

    local v107 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p8[15])

    local v108 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[1])

    local v109 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[2])

    local v110 = buffer.readf32(v67, 0)

    buffer.writeu32(v67, 0, p9[3])

    local v111 = buffer.readf32(v67, 0)
    local n2 = 0

    v87 = 0
    v88 = 1

    local v112, v113

    for i = 0, 12 do
        v113 = i * 4
        v112 = v68[v113 + 1]

        local v114 = v68[v113 + 2]
        local v115 = v68[v113 + 3]

        v113 = v83 * v112 + v103 * v114 + v104 * v115

        local v116 = v84 * v112 + v105 * v114 + v106 * v115
        local v117 = v85 * v112 + v107 * v114 + v108 * v115
        local v118 = if v116 < v117 then v116 else v117

        if v113 < v118 then
            v118 = v113
        end

        if not (v117 < v116) then
            v116 = v117
        end

        if not (v116 < v113) then
            v113 = v116
        end

        local v119 = v109 * v112 + v110 * v114 + v111 * v115

        v116 = math.abs(v69 * v112 + v70 * v114 + v72 * v115) + math.abs(v74 * v112 + v76 * v114 + v99 * v115) + math.abs(v100 * v112 + v81 * v114 + v82 * v115)
        v115 = v118 - (v119 + v116)

        local v124 = v119 - v116 - v113
        local v121 = 1

        if v124 < v115 then
            v121 = -1
        else
            v115 = v124
        end

        if i == 0 or n2 < v115 then
            v88 = v121
            n2 = v115
            v87 = i
        end
    end

    v80 = v87 * 4

    local v125 = v68[v80 + 1] * v88

    if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
        v86 = to_bits(v125)
    else
        buffer.writef32(v67, 0, v125)
        v86 = buffer.readu32(v67, 0)
    end

    local v126 = v68[v80 + 2] * v88

    if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
        v125 = to_bits(v126)
    else
        buffer.writef32(v67, 0, v126)
        v125 = buffer.readu32(v67, 0)
    end

    v113 = v68[v80 + 3] * v88

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        v126 = to_bits(v113)
    else
        buffer.writef32(v67, 0, v113)
        v126 = buffer.readu32(v67, 0)
    end

    v112 = v68[v80 + 4] * v88

    if v112 ~= 0 and v112 > -1.1754943508222875E-38 and v112 < 1.1754943508222875E-38 then
        v113 = to_bits(v112)
    else
        buffer.writef32(v67, 0, v112)
        v113 = buffer.readu32(v67, 0)
    end

    p10[1] = v86
    p10[2] = v125
    p10[3] = v126
    p10[4] = v113

    return tb(n2)
end

t1.triangle_box_into = triangle_box_into

function t1.triangle_box(p11, p12) -- line: 209
    -- upvalues: triangle_box_into (copy)
    local t5 = {
        0, 0, 0, 0
    }
    local v127 = triangle_box_into(p11, p12, t5)

    return { v127, v127, v127, v127 }, t5
end

function minimum(p13, p14) -- line: 218
    if p13 < p14 then
        return p13
    end

    return p14
end

function maximum(p15, p16) -- line: 221
    if p16 < p15 then
        return p15
    end

    return p16
end

t1.minimum = minimum
t1.maximum = maximum

return t1
