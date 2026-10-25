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
local v8 = import("skate_core/physics/world_contact/arithmetic")
local v9 = import("skate_core/physics/world_contact/axes")
local dot, scale, vector = v8.dot, v8.scale, v8.vector
local separating_axis_candidates = v9.separating_axis_candidates
local t1 = {
    PrimitiveKind = {}
}
local project

function t1.project_direction(p4, p5, p6, p7) -- line: 55
    -- upvalues: project (ref)
    project(p4, p5, p6, p7, false)
end

function t1.project_directions(p8, p9, p10, p11) -- line: 63
    -- upvalues: project (ref)
    if not (#p11 >= #p10) then
        error("assertion failed: output.len() >= directions.len()", 0)
    end

    for i = 1, #p10 do
        project(p8, p9, p10[i], p11[i], true)
    end
end

function t1.project_reference(p12, p13, p14, p15, p16) -- line: 73
    -- upvalues: v1 (copy), dot (copy), scale (copy), vector (copy)
    local v10 = vector(p14, 0)
    local v11 = dot(vector(p12, 0), v10)
    local v12

    if p13 == "Sphere" then
        v12 = v11
    elseif p13 == "Capsule" then
        local v14 = math.abs((dot(vector(p12, 16), v10)))

        buffer.writeu32(v1, 0, p12[29])

        local v16 = v14 * buffer.readf32(v1, 0)

        v11, v12 = v11 - v16, v11 + v16
    elseif p13 == "Triangle" then
        v12 = dot(vector(p12, 8), v10)

        local v17 = dot(vector(p12, 12), v10)
        local v18 = if v11 < v12 then v11 else v12

        if v12 < v11 then
            v12 = v11
        end

        v11 = if v18 < v17 then v18 else v17

        if not (v17 < v12) then
            v12 = v17
        end
    elseif p13 == "Box" then
        local t2 = {
            0, 0, 0
        }

        for i = 0, 2 do
            local v19 = vector(p12, i * 4 + 4)

            buffer.writeu32(v1, 0, p12[i + 28 + 1])

            local v21 = buffer.readf32(v1, 0)

            if p16 then
                local v22 = dot(scale(v19, v21), v10)

                t2[i + 1] = math.abs(v22)
            else
                local v23 = dot(v19, v10) * v21

                t2[i + 1] = math.abs(v23)
            end
        end

        local v24 = t2[1] + t2[2] + t2[3]

        v11, v12 = v11 - v24, v11 + v24
    else
        v11 = nil
        error("unreachable: PrimitiveKind " .. tostring(p13), 0)
    end

    local v25

    if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
        local v26 = math.abs(v11) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if v11 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v11)
        v25 = buffer.readu32(v1, 0)
    end

    local v29

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        local v30 = math.abs(v12) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if v12 < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v29 = buffer.readu32(v1, 0)
    end

    p15[1] = v25
    p15[2] = v25
    p15[3] = v25
    p15[4] = v25
    p15[5] = v29
    p15[6] = v29
    p15[7] = v29
    p15[8] = v29
end

local v33 = buffer.create(8)

local function fb(p17) -- line: 121
    -- upvalues: v33 (copy)
    buffer.writeu32(v33, 0, p17)

    return (buffer.readf32(v33, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p18) -- line: 126
    -- upvalues: v33 (copy), to_bits (copy)
    if p18 ~= 0 and p18 > -1.1754943508222875E-38 and p18 < 1.1754943508222875E-38 then
        return to_bits(p18)
    end

    buffer.writef32(v33, 0, p18)

    return (buffer.readu32(v33, 0))
end

function project(p19, p20, p21, p22, p23) -- line: 134
    -- upvalues: v33 (copy), to_bits (copy)
    buffer.writeu32(v33, 0, p21[1])

    local v35 = buffer.readf32(v33, 0)

    buffer.writeu32(v33, 0, p21[2])

    local v36 = buffer.readf32(v33, 0)

    buffer.writeu32(v33, 0, p21[3])

    local v37 = buffer.readf32(v33, 0)

    buffer.writeu32(v33, 0, p19[1])

    local v39 = buffer.readf32(v33, 0) * v35

    buffer.writeu32(v33, 0, p19[2])

    local v41 = v39 + buffer.readf32(v33, 0) * v36

    buffer.writeu32(v33, 0, p19[3])

    local v34 = v41 + buffer.readf32(v33, 0) * v37
    local v42

    if p20 == "Sphere" then
        v42 = v34
    elseif p20 == "Capsule" then
        buffer.writeu32(v33, 0, p19[17])

        local v44 = buffer.readf32(v33, 0) * v35

        buffer.writeu32(v33, 0, p19[18])

        local v46 = v44 + buffer.readf32(v33, 0) * v36

        buffer.writeu32(v33, 0, p19[19])

        local v48 = math.abs(v46 + buffer.readf32(v33, 0) * v37)

        buffer.writeu32(v33, 0, p19[29])
        v42 = v48 * buffer.readf32(v33, 0)
        v34, v42 = v34 - v42, v34 + v42
    elseif p20 == "Triangle" then
        buffer.writeu32(v33, 0, p19[9])

        local v50 = buffer.readf32(v33, 0) * v35

        buffer.writeu32(v33, 0, p19[10])

        local v52 = v50 + buffer.readf32(v33, 0) * v36

        buffer.writeu32(v33, 0, p19[11])
        v42 = v52 + buffer.readf32(v33, 0) * v37
        buffer.writeu32(v33, 0, p19[13])

        local v53 = buffer.readf32(v33, 0) * v35

        buffer.writeu32(v33, 0, p19[14])
        v50 = v53 + buffer.readf32(v33, 0) * v36
        buffer.writeu32(v33, 0, p19[15])
        v52 = v50 + buffer.readf32(v33, 0) * v37
        v50 = if v34 < v42 then v34 else v42

        if v42 < v34 then
            v42 = v34
        end

        v34 = if v50 < v52 then v50 else v52

        if not (v52 < v42) then
            v42 = v52
        end
    elseif p20 == "Box" then
        local v55, v56, v57

        if p23 then
            v55 = p19[29]
            buffer.writeu32(v33, 0, v55)

            local v58 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, p19[5])

            local v60 = buffer.readf32(v33, 0) * v58 * v35

            buffer.writeu32(v33, 0, p19[6])

            local v62 = v60 + buffer.readf32(v33, 0) * v58 * v36

            buffer.writeu32(v33, 0, p19[7])
            v58 = v62 + buffer.readf32(v33, 0) * v58 * v37
            v55 = math.abs(v58)
            v56 = p19[30]
            buffer.writeu32(v33, 0, v56)
            v58 = buffer.readf32(v33, 0)
            buffer.writeu32(v33, 0, p19[9])
            v60 = buffer.readf32(v33, 0) * v58 * v35
            buffer.writeu32(v33, 0, p19[10])
            v62 = v60 + buffer.readf32(v33, 0) * v58 * v36
            buffer.writeu32(v33, 0, p19[11])
            v58 = v62 + buffer.readf32(v33, 0) * v58 * v37
            v56 = math.abs(v58)
            buffer.writeu32(v33, 0, p19[31])
            v58 = buffer.readf32(v33, 0)
            buffer.writeu32(v33, 0, p19[13])
            v60 = buffer.readf32(v33, 0) * v58 * v35
            buffer.writeu32(v33, 0, p19[14])
            v62 = v60 + buffer.readf32(v33, 0) * v58 * v36
            buffer.writeu32(v33, 0, p19[15])
            v58 = v62 + buffer.readf32(v33, 0) * v58 * v37
            v57 = math.abs(v58)
        else
            buffer.writeu32(v33, 0, p19[5])

            local v65 = buffer.readf32(v33, 0) * v35

            buffer.writeu32(v33, 0, p19[6])

            local v67 = v65 + buffer.readf32(v33, 0) * v36

            buffer.writeu32(v33, 0, p19[7])

            local v68 = v67 + buffer.readf32(v33, 0) * v37

            buffer.writeu32(v33, 0, p19[29])
            v55 = v68 * buffer.readf32(v33, 0)
            v55 = math.abs(v55)
            buffer.writeu32(v33, 0, p19[9])
            v65 = buffer.readf32(v33, 0) * v35
            buffer.writeu32(v33, 0, p19[10])
            v67 = v65 + buffer.readf32(v33, 0) * v36
            buffer.writeu32(v33, 0, p19[11])
            v68 = v67 + buffer.readf32(v33, 0) * v37
            buffer.writeu32(v33, 0, p19[30])
            v56 = v68 * buffer.readf32(v33, 0)
            v56 = math.abs(v56)
            buffer.writeu32(v33, 0, p19[13])
            v65 = buffer.readf32(v33, 0) * v35
            buffer.writeu32(v33, 0, p19[14])
            v67 = v65 + buffer.readf32(v33, 0) * v36
            buffer.writeu32(v33, 0, p19[15])
            v68 = v67 + buffer.readf32(v33, 0) * v37
            buffer.writeu32(v33, 0, p19[31])
            v57 = math.abs(v68 * buffer.readf32(v33, 0))
        end

        local v70 = v55 + v56 + v57

        v34, v42 = v34 - v70, v34 + v70
    else
        v34 = nil
        error("unreachable: PrimitiveKind " .. tostring(p20), 0)
    end

    if v34 ~= 0 and v34 > -1.1754943508222875E-38 and v34 < 1.1754943508222875E-38 then
        v34 = to_bits(v34)
    else
        buffer.writef32(v33, 0, v34)
        v34 = buffer.readu32(v33, 0)
    end

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        v37 = to_bits(v42)
    else
        buffer.writef32(v33, 0, v42)
        v37 = buffer.readu32(v33, 0)
    end

    p22[1] = v34
    p22[2] = v34
    p22[3] = v34
    p22[4] = v34
    p22[5] = v37
    p22[6] = v37
    p22[7] = v37
    p22[8] = v37
end

t1.project = project

local v71 = rt.filled(16, { 0, 0, 0, 0 })
local v72 = rt.filled(16, table.create(12, 0))
local v73 = rt.filled(16, table.create(12, 0))

function t1.best_separating_direction_reference(p24, p25, p26, p27) -- line: 184
    -- upvalues: rt (copy), v1 (copy), separating_axis_candidates (copy), project (ref), v71 (copy), v72 (copy), v73 (copy)
    local v74 = separating_axis_candidates(p24, p26, v71)

    if v74 == 0 then
        buffer.writef32(v1, 0, 1)
        v74 = 1
        v71[1] = {
            0, 0,
            buffer.readu32(v1, 0),
            0
        }
    end

    for i = 1, v74 do
        project(p24, p25, v71[i], v72[i], true)
    end

    for i = 1, v74 do
        project(p26, p27, v71[i], v73[i], true)
    end

    local v75 = v74 - 1
    local n1 = 0
    local n2 = 0
    local v76 = false

    for i = 0, v75 do
        buffer.writeu32(v1, 0, v72[i + 1][1])

        local v78 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v73[i + 1][5])

        local v80 = v78 - buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v73[i + 1][1])

        local v82 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v72[i + 1][5])

        local v84 = v82 - buffer.readf32(v1, 0)
        local v85 = false

        if v84 < v80 then
            v85 = true
        else
            v80 = v84
        end

        if i == 0 or n2 < v80 then
            v76 = v85
            n1 = i
            n2 = v80
        end
    end

    local v86 = rt.copy(v71[n1 + 1])

    if v76 then
        v86[1] = bit32.bxor(v86[1], 2147483648)
        v86[2] = bit32.bxor(v86[2], 2147483648)
        v86[3] = bit32.bxor(v86[3], 2147483648)
        v86[4] = bit32.bxor(v86[4], 2147483648)
    end

    local v91

    if n2 == 0 or not (n2 > -1.1754943508222875E-38) or not (n2 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, n2)
        v91 = buffer.readu32(v1, 0)

        return { v91, v91, v91, v91 }, v86
    end

    local v92 = math.abs(n2) * 7.1362384635298E+44
    local v93 = math.floor(v92)
    local v94 = v92 - v93

    v91 = if v94 > 0.5 or v94 == 0.5 and v93 % 2 == 1 then v93 + 1 else v93

    if n2 < 0 then
        v91 += 2147483648
    end

    return { v91, v91, v91, v91 }, v86
end

local function project_batch(p28, p29, p30, p31, p32, p33) -- line: 242
    -- upvalues: v33 (copy), to_bits (copy)
    if p29 == "Sphere" then
        buffer.writeu32(v33, 0, p28[1])

        local v96 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[2])

        local v97 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[3])

        local v98 = buffer.readf32(v33, 0)

        for i = 1, p31 do
            local v99 = p30[i]

            buffer.writeu32(v33, 0, v99[1])

            local v101 = v96 * buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v99[2])

            local v103 = v101 + v97 * buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v99[3])

            local v104 = v103 + v98 * buffer.readf32(v33, 0)

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v101 = to_bits(v104)
            else
                buffer.writef32(v33, 0, v104)
                v101 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v101)
            p32[i] = buffer.readf32(v33, 0)

            if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                v101 = to_bits(v104)
            else
                buffer.writef32(v33, 0, v104)
                v101 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v101)
            p33[i] = buffer.readf32(v33, 0)
        end
    elseif p29 == "Capsule" then
        buffer.writeu32(v33, 0, p28[1])

        local v106 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[2])

        local v107 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[3])

        local v108 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[17])

        local v110 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[18])

        local v111 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[19])

        local v112 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[29])

        local v114 = buffer.readf32(v33, 0)

        for i = 1, p31 do
            local v115 = p30[i]

            buffer.writeu32(v33, 0, v115[1])

            local v117 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v115[2])

            local v118 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v115[3])

            local v119 = buffer.readf32(v33, 0)

            v115 = v106 * v117 + v107 * v118 + v108 * v119

            local v116 = math.abs(v110 * v117 + v111 * v118 + v112 * v119) * v114
            local v121 = v115 - v116
            local v120

            if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
                v120 = to_bits(v121)
            else
                buffer.writef32(v33, 0, v121)
                v120 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v120)
            p32[i] = buffer.readf32(v33, 0)
            v121 = v115 + v116

            if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
                v120 = to_bits(v121)
            else
                buffer.writef32(v33, 0, v121)
                v120 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v120)
            p33[i] = buffer.readf32(v33, 0)
        end
    elseif p29 == "Triangle" then
        buffer.writeu32(v33, 0, p28[1])

        local v123 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[2])

        local v124 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[3])

        local v125 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[9])

        local v127 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[10])

        local v128 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[11])

        local v129 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[13])

        local v131 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[14])

        local v132 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[15])

        local v133 = buffer.readf32(v33, 0)

        for i = 1, p31 do
            local v134 = p30[i]

            buffer.writeu32(v33, 0, v134[1])

            local v136 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v134[2])

            local v137 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v134[3])

            local v138 = buffer.readf32(v33, 0)

            v134 = v123 * v136 + v124 * v137 + v125 * v138

            local v135 = v127 * v136 + v128 * v137 + v129 * v138

            v136 = v131 * v136 + v132 * v137 + v133 * v138

            local v139 = if v134 < v135 then v134 else v135

            if not (v135 < v134) then
                v134 = v135
            end

            if not (v139 < v136) then
                v139 = v136
            end

            local v140

            if v139 ~= 0 and v139 > -1.1754943508222875E-38 and v139 < 1.1754943508222875E-38 then
                v140 = to_bits(v139)
            else
                buffer.writef32(v33, 0, v139)
                v140 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v140)
            p32[i] = buffer.readf32(v33, 0)

            if not (v136 < v134) then
                v134 = v136
            end

            if v134 ~= 0 and v134 > -1.1754943508222875E-38 and v134 < 1.1754943508222875E-38 then
                v140 = to_bits(v134)
            else
                buffer.writef32(v33, 0, v134)
                v140 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v140)
            p33[i] = buffer.readf32(v33, 0)
        end
    elseif p29 == "Box" then
        buffer.writeu32(v33, 0, p28[1])

        local v142 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[2])

        local v143 = buffer.readf32(v33, 0)
        local v141 = p28[3]

        buffer.writeu32(v33, 0, v141)

        local v144 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[29])

        local v146 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[5])

        local v145 = buffer.readf32(v33, 0) * v146

        buffer.writeu32(v33, 0, p28[6])

        local v148 = buffer.readf32(v33, 0) * v146

        buffer.writeu32(v33, 0, p28[7])

        local v149 = buffer.readf32(v33, 0) * v146

        buffer.writeu32(v33, 0, p28[30])

        local v151 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[9])

        local v150 = buffer.readf32(v33, 0) * v151

        buffer.writeu32(v33, 0, p28[10])

        local v147 = buffer.readf32(v33, 0) * v151

        buffer.writeu32(v33, 0, p28[11])

        local v153 = buffer.readf32(v33, 0) * v151

        buffer.writeu32(v33, 0, p28[31])

        local v155 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, p28[13])

        local v154 = buffer.readf32(v33, 0) * v155

        buffer.writeu32(v33, 0, p28[14])

        local v152 = buffer.readf32(v33, 0) * v155

        buffer.writeu32(v33, 0, p28[15])

        local v157 = buffer.readf32(v33, 0) * v155

        for i = 1, p31 do
            v141 = p30[i]
            buffer.writeu32(v33, 0, v141[1])

            local v159 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v141[2])

            local v160 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, v141[3])

            local v161 = buffer.readf32(v33, 0)

            v141 = v142 * v159 + v143 * v160 + v144 * v161

            local v158 = math.abs(v145 * v159 + v148 * v160 + v149 * v161)
            local v162 = math.abs(v150 * v159 + v147 * v160 + v153 * v161)
            local v163 = math.abs(v154 * v159 + v152 * v160 + v157 * v161)
            local v165 = v158 + v162 + v163
            local v166 = v141 - v165
            local v167

            if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
                v167 = to_bits(v166)
            else
                buffer.writef32(v33, 0, v166)
                v167 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v167)
            p32[i] = buffer.readf32(v33, 0)
            v166 = v141 + v165

            if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
                v167 = to_bits(v166)
            else
                buffer.writef32(v33, 0, v166)
                v167 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v167)
            p33[i] = buffer.readf32(v33, 0)
        end
    else
        error("unreachable: PrimitiveKind " .. tostring(p29), 0)
    end
end

t1.project_batch = project_batch

local v168 = table.create(16, 0)
local v169 = table.create(16, 0)
local v170 = table.create(16, 0)
local v171 = table.create(16, 0)

function t1.best_separating_direction_into_wave1(p34, p35, p36, p37, p38) -- line: 311
    -- upvalues: v1 (copy), separating_axis_candidates (copy), project (ref), v33 (copy), to_bits2 (copy), v71 (copy), v72 (copy), v73 (copy)
    local v172 = separating_axis_candidates(p34, p36, v71)

    if v172 == 0 then
        buffer.writef32(v1, 0, 1)
        v172 = 1
        v71[1] = {
            0, 0,
            buffer.readu32(v1, 0),
            0
        }
    end

    for i = 1, v172 do
        project(p34, p35, v71[i], v72[i], true)
    end

    for i = 1, v172 do
        project(p36, p37, v71[i], v73[i], true)
    end

    local v173 = v172 - 1
    local n3 = 0
    local n4 = 0
    local v174 = false

    for i = 0, v173 do
        local v175 = v72[i + 1]
        local v176 = v73[i + 1]

        buffer.writeu32(v33, 0, v175[1])

        local v178 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, v176[5])

        local v180 = v178 - buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, v176[1])

        local v182 = buffer.readf32(v33, 0)

        buffer.writeu32(v33, 0, v175[5])

        local v184 = v182 - buffer.readf32(v33, 0)
        local v185 = false

        if v184 < v180 then
            v185 = true
        else
            v180 = v184
        end

        if i == 0 or n4 < v180 then
            v174 = v185
            n3 = i
            n4 = v180
        end
    end

    local v186 = v71[n3 + 1]

    if v174 then
        p38[1] = bit32.bxor(v186[1], 2147483648)
        p38[2] = bit32.bxor(v186[2], 2147483648)
        p38[3] = bit32.bxor(v186[3], 2147483648)
        p38[4] = bit32.bxor(v186[4], 2147483648)
    else
        local v191 = v186[1]
        local v192 = v186[2]
        local v193 = v186[3]
        local v194 = v186[4]

        p38[1] = v191
        p38[2] = v192
        p38[3] = v193
        p38[4] = v194
    end

    return to_bits2(n4)
end

local function best_separating_direction_into(p39, p40, p41, p42, p43) -- line: 367
    -- upvalues: v1 (copy), separating_axis_candidates (copy), to_bits2 (copy), v71 (copy), project_batch (copy), v168 (copy), v169 (copy), v170 (copy), v171 (copy)
    local v195 = separating_axis_candidates(p39, p41, v71)

    if v195 == 0 then
        buffer.writef32(v1, 0, 1)
        v195 = 1
        v71[1] = {
            0, 0,
            buffer.readu32(v1, 0),
            0
        }
    end

    project_batch(p39, p40, v71, v195, v168, v169)
    project_batch(p41, p42, v71, v195, v170, v171)

    local n5 = 0
    local n6 = 0
    local v196 = false

    for i = 1, v195 do
        local v197 = v168[i] - v171[i]
        local v198 = v170[i] - v169[i]
        local v199 = false

        if v198 < v197 then
            v199 = true
        else
            v197 = v198
        end

        if i == 1 or n6 < v197 then
            v196 = v199
            n5 = i
            n6 = v197
        end
    end

    local v200 = v71[n5]

    if v196 then
        p43[1] = bit32.bxor(v200[1], 2147483648)
        p43[2] = bit32.bxor(v200[2], 2147483648)
        p43[3] = bit32.bxor(v200[3], 2147483648)
        p43[4] = bit32.bxor(v200[4], 2147483648)
    else
        local v205 = v200[1]
        local v206 = v200[2]
        local v207 = v200[3]
        local v208 = v200[4]

        p43[1] = v205
        p43[2] = v206
        p43[3] = v207
        p43[4] = v208
    end

    return to_bits2(n6)
end

t1.best_separating_direction_into = best_separating_direction_into

local function interval_one(p44, p45, p46, p47, p48) -- line: 419
    -- upvalues: v33 (copy), to_bits (copy)
    local v209, v210, v211, v212, v213, v214

    if p45 == "Sphere" then
        v212 = p44[1]
        buffer.writeu32(v33, 0, v212)
        v211 = buffer.readf32(v33, 0) * p46
        v214 = p44[2]
        buffer.writeu32(v33, 0, v214)
        v209 = v211 + buffer.readf32(v33, 0) * p47
        v212 = p44[3]
        buffer.writeu32(v33, 0, v212)
        v210 = v209 + buffer.readf32(v33, 0) * p48

        if v210 ~= 0 and v210 > -1.1754943508222875E-38 and v210 < 1.1754943508222875E-38 then
            v211 = to_bits(v210)
        else
            buffer.writef32(v33, 0, v210)
            v211 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v211)
        v213 = buffer.readf32(v33, 0)

        local v215

        if v210 ~= 0 and v210 > -1.1754943508222875E-38 and v210 < 1.1754943508222875E-38 then
            v215 = to_bits(v210)
        else
            buffer.writef32(v33, 0, v210)
            v215 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v215)

        return v213, (buffer.readf32(v33, 0))
    end

    local v216, v217

    if p45 == "Capsule" then
        v212 = p44[1]
        buffer.writeu32(v33, 0, v212)
        v211 = buffer.readf32(v33, 0) * p46
        v214 = p44[2]
        buffer.writeu32(v33, 0, v214)
        v209 = v211 + buffer.readf32(v33, 0) * p47
        v212 = p44[3]
        buffer.writeu32(v33, 0, v212)
        v210 = v209 + buffer.readf32(v33, 0) * p48
        v217 = p44[17]
        buffer.writeu32(v33, 0, v217)
        v214 = buffer.readf32(v33, 0) * p46
        v216 = p44[18]
        buffer.writeu32(v33, 0, v216)
        v212 = v214 + buffer.readf32(v33, 0) * p47
        v217 = p44[19]
        buffer.writeu32(v33, 0, v217)
        v213 = v212 + buffer.readf32(v33, 0) * p48
        v211 = math.abs(v213)
        v212 = p44[29]
        buffer.writeu32(v33, 0, v212)
        v209 = v211 * buffer.readf32(v33, 0)
        v212 = v210 - v209

        if v212 ~= 0 and v212 > -1.1754943508222875E-38 and v212 < 1.1754943508222875E-38 then
            v213 = to_bits(v212)
        else
            buffer.writef32(v33, 0, v212)
            v213 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v213)
        v212 = buffer.readf32(v33, 0)
        v214 = v210 + v209

        local v218

        if v214 ~= 0 and v214 > -1.1754943508222875E-38 and v214 < 1.1754943508222875E-38 then
            v218 = to_bits(v214)
        else
            buffer.writef32(v33, 0, v214)
            v218 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v218)

        return v212, (buffer.readf32(v33, 0))
    end

    local v219, v220

    if p45 == "Triangle" then
        v212 = p44[1]
        buffer.writeu32(v33, 0, v212)
        v211 = buffer.readf32(v33, 0) * p46
        v214 = p44[2]
        buffer.writeu32(v33, 0, v214)
        v209 = v211 + buffer.readf32(v33, 0) * p47
        v212 = p44[3]
        buffer.writeu32(v33, 0, v212)
        v210 = v209 + buffer.readf32(v33, 0) * p48
        v214 = p44[9]
        buffer.writeu32(v33, 0, v214)
        v213 = buffer.readf32(v33, 0) * p46
        v220 = p44[10]
        buffer.writeu32(v33, 0, v220)
        v211 = v213 + buffer.readf32(v33, 0) * p47
        v214 = p44[11]
        buffer.writeu32(v33, 0, v214)
        v209 = v211 + buffer.readf32(v33, 0) * p48
        v220 = p44[13]
        buffer.writeu32(v33, 0, v220)
        v212 = buffer.readf32(v33, 0) * p46
        v217 = p44[14]
        buffer.writeu32(v33, 0, v217)
        v213 = v212 + buffer.readf32(v33, 0) * p47
        v220 = p44[15]
        buffer.writeu32(v33, 0, v220)
        v211 = v213 + buffer.readf32(v33, 0) * p48
        v217 = if v210 < v209 then v210 else v209

        if not (v209 < v210) then
            v210 = v209
        end

        if not (v217 < v211) then
            v217 = v211
        end

        if v217 ~= 0 and v217 > -1.1754943508222875E-38 and v217 < 1.1754943508222875E-38 then
            v220 = to_bits(v217)
        else
            buffer.writef32(v33, 0, v217)
            v220 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v220)
        v217 = buffer.readf32(v33, 0)

        if not (v211 < v210) then
            v210 = v211
        end

        if v210 ~= 0 and v210 > -1.1754943508222875E-38 and v210 < 1.1754943508222875E-38 then
            v219 = to_bits(v210)
        else
            buffer.writef32(v33, 0, v210)
            v219 = buffer.readu32(v33, 0)
        end

        buffer.writeu32(v33, 0, v219)

        return v217, (buffer.readf32(v33, 0))
    end

    if p45 ~= "Box" then
        return nil, nil
    end

    buffer.writeu32(v33, 0, p44[1])
    v211 = buffer.readf32(v33, 0) * p46
    buffer.writeu32(v33, 0, p44[2])
    v209 = v211 + buffer.readf32(v33, 0) * p47
    buffer.writeu32(v33, 0, p44[3])
    v210 = v209 + buffer.readf32(v33, 0) * p48
    buffer.writeu32(v33, 0, p44[29])
    v213 = buffer.readf32(v33, 0)
    buffer.writeu32(v33, 0, p44[5])
    v214 = buffer.readf32(v33, 0) * v213 * p46
    buffer.writeu32(v33, 0, p44[6])
    v212 = v214 + buffer.readf32(v33, 0) * v213 * p47
    buffer.writeu32(v33, 0, p44[7])
    v213 = v212 + buffer.readf32(v33, 0) * v213 * p48
    v211 = math.abs(v213)
    buffer.writeu32(v33, 0, p44[30])
    v212 = buffer.readf32(v33, 0)
    buffer.writeu32(v33, 0, p44[9])
    v220 = buffer.readf32(v33, 0) * v212 * p46
    buffer.writeu32(v33, 0, p44[10])
    v214 = v220 + buffer.readf32(v33, 0) * v212 * p47
    buffer.writeu32(v33, 0, p44[11])
    v212 = v214 + buffer.readf32(v33, 0) * v212 * p48
    v213 = math.abs(v212)
    buffer.writeu32(v33, 0, p44[31])
    v214 = buffer.readf32(v33, 0)
    buffer.writeu32(v33, 0, p44[13])
    v217 = buffer.readf32(v33, 0) * v214 * p46
    buffer.writeu32(v33, 0, p44[14])
    v220 = v217 + buffer.readf32(v33, 0) * v214 * p47
    buffer.writeu32(v33, 0, p44[15])
    v214 = v220 + buffer.readf32(v33, 0) * v214 * p48
    v212 = math.abs(v214)
    v209 = v211 + v213 + v212
    v217 = v210 - v209

    if v217 ~= 0 and v217 > -1.1754943508222875E-38 and v217 < 1.1754943508222875E-38 then
        v220 = to_bits(v217)
    else
        buffer.writef32(v33, 0, v217)
        v220 = buffer.readu32(v33, 0)
    end

    buffer.writeu32(v33, 0, v220)
    v217 = buffer.readf32(v33, 0)
    v216 = v210 + v209

    if v216 ~= 0 and v216 > -1.1754943508222875E-38 and v216 < 1.1754943508222875E-38 then
        v219 = to_bits(v216)
    else
        buffer.writef32(v33, 0, v216)
        v219 = buffer.readu32(v33, 0)
    end

    buffer.writeu32(v33, 0, v219)

    return v217, (buffer.readf32(v33, 0))
end

function t1.face_axis_rejects(p49, p50, p51, p52, p53) -- line: 471
    -- upvalues: v33 (copy), to_bits (copy), interval_one (copy)
    local v224 = p49[36]
    local v225 = p51[36]
    local v227 = bit32.band(bit32.rshift(v224, 16), 255) > 3
    local v228 = if not v227 then bit32.band(bit32.rshift(v225, 16), 255) > 3 else nil

    if not (v227 or v228) then
        local v230 = true
        local v231 = p49
        local v232 = bit32.rshift(v224, 24)

        for _ = 1, 2 do
            if v232 >= 1 and v232 <= 3 then
                for i = v232, 1, -1 do
                    local v233 = i * 4

                    buffer.writeu32(v33, 0, v231[v233 + 1])

                    local v235 = buffer.readf32(v33, 0)

                    buffer.writeu32(v33, 0, v231[v233 + 2])

                    local v237 = buffer.readf32(v33, 0)

                    buffer.writeu32(v33, 0, v231[v233 + 3])

                    local v239 = buffer.readf32(v33, 0)
                    local v240, v241 = interval_one(p49, p50, v235, v237, v239)
                    local v242, v243 = interval_one(p51, p52, v235, v237, v239)

                    if v240 == nil or v242 == nil then
                        return false
                    end

                    local v244 = v240 - v243
                    local v245 = v242 - v241

                    if not (v245 < v244) then
                        v244 = v245
                    end

                    if v230 then
                        if v244 ~= v244 then
                            return false
                        end

                        v230 = false
                    end

                    local v246

                    if v244 == 0 then
                        buffer.writef32(v33, 0, v244)
                        v246 = buffer.readu32(v33, 0)
                    elseif v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
                        v246 = to_bits(v244)
                    else
                        buffer.writef32(v33, 0, v244)
                        v246 = buffer.readu32(v33, 0)
                    end

                    buffer.writeu32(v33, 0, v246)

                    if p53 < buffer.readf32(v33, 0) then
                        return true
                    end
                end
            end

            v231 = p51
            v232 = bit32.rshift(v225, 24)
        end
    end

    return false
end

function t1.sphere_triangle_separation_into(p54, p55, p56) -- line: 518
    -- upvalues: v33 (copy), to_bits (copy), to_bits2 (copy)
    local v247 = p54[36]
    local v248 = p55[36]
    local v249 = bit32.rshift(v247, 24)

    if not (v249 >= 1 and v249 <= 3) then
        local v250 = bit32.rshift(v247, 16)
        local v251, v252, v253, v254, v255, v256, v257, v258, v259

        if bit32.band(v250, 255) == 0 and bit32.rshift(v248, 24) == 1 and not (bit32.band(bit32.rshift(v248, 16), 255) > 3) then
            v251 = p55[5]
            v252 = p55[6]
            v253 = p55[7]
            v254 = p55[8]
            buffer.writeu32(v33, 0, v251)
            v255 = buffer.readf32(v33, 0)
            buffer.writeu32(v33, 0, v252)
            v256 = buffer.readf32(v33, 0)
            buffer.writeu32(v33, 0, v253)
            v257 = buffer.readf32(v33, 0)
            buffer.writeu32(v33, 0, p54[1])

            local v262 = buffer.readf32(v33, 0) * v255

            buffer.writeu32(v33, 0, p54[2])

            local v264 = v262 + buffer.readf32(v33, 0) * v256

            buffer.writeu32(v33, 0, p54[3])
            v258 = v264 + buffer.readf32(v33, 0) * v257

            if v258 == 0 then
                buffer.writef32(v33, 0, v258)
                v259 = buffer.readu32(v33, 0)
            elseif v258 > -1.1754943508222875E-38 and v258 < 1.1754943508222875E-38 then
                v259 = to_bits(v258)
            else
                buffer.writef32(v33, 0, v258)
                v259 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v259)

            local v266 = buffer.readf32(v33, 0)
            local v267

            if v258 ~= 0 and v258 > -1.1754943508222875E-38 and v258 < 1.1754943508222875E-38 then
                v267 = to_bits(v258)
            else
                buffer.writef32(v33, 0, v258)
                v267 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v267)

            local v268 = buffer.readf32(v33, 0)

            buffer.writeu32(v33, 0, p55[1])

            local v270 = buffer.readf32(v33, 0) * v255

            buffer.writeu32(v33, 0, p55[2])

            local v272 = v270 + buffer.readf32(v33, 0) * v256

            buffer.writeu32(v33, 0, p55[3])

            local v274 = v272 + buffer.readf32(v33, 0) * v257

            buffer.writeu32(v33, 0, p55[9])

            local v276 = buffer.readf32(v33, 0) * v255

            buffer.writeu32(v33, 0, p55[10])

            local v278 = v276 + buffer.readf32(v33, 0) * v256

            buffer.writeu32(v33, 0, p55[11])

            local v280 = v278 + buffer.readf32(v33, 0) * v257

            buffer.writeu32(v33, 0, p55[13])

            local v282 = buffer.readf32(v33, 0) * v255

            buffer.writeu32(v33, 0, p55[14])

            local v284 = v282 + buffer.readf32(v33, 0) * v256

            buffer.writeu32(v33, 0, p55[15])

            local v286 = v284 + buffer.readf32(v33, 0) * v257
            local v287 = if v274 < v280 then v274 else v280

            if not (v280 < v274) then
                v274 = v280
            end

            if not (v287 < v286) then
                v287 = v286
            end

            local v288

            if v287 ~= 0 and v287 > -1.1754943508222875E-38 and v287 < 1.1754943508222875E-38 then
                v288 = to_bits(v287)
            else
                buffer.writef32(v33, 0, v287)
                v288 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v288)

            local v289 = buffer.readf32(v33, 0)

            if not (v286 < v274) then
                v274 = v286
            end

            local v290

            if v274 ~= 0 and v274 > -1.1754943508222875E-38 and v274 < 1.1754943508222875E-38 then
                v290 = to_bits(v274)
            else
                buffer.writef32(v33, 0, v274)
                v290 = buffer.readu32(v33, 0)
            end

            buffer.writeu32(v33, 0, v290)

            local v291 = v266 - buffer.readf32(v33, 0)
            local v292 = v289 - v268

            if v292 < v291 then
                p56[1] = bit32.bxor(v251, 2147483648)
                p56[2] = bit32.bxor(v252, 2147483648)
                p56[3] = bit32.bxor(v253, 2147483648)
                p56[4] = bit32.bxor(v254, 2147483648)

                return to_bits2(v291)
            end

            p56[1] = v251
            p56[2] = v252
            p56[3] = v253
            p56[4] = v254

            return to_bits2(v292)
        end
    end

    return nil
end

function t1.best_separating_direction(p57, p58, p59, p60) -- line: 557
    -- upvalues: best_separating_direction_into (copy)
    local t3 = {
        0, 0, 0, 0
    }
    local v293 = best_separating_direction_into(p57, p58, p59, p60, t3)

    return { v293, v293, v293, v293 }, t3
end

return t1
