-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local v8 = require(sim.import)("skate_core/physics/world_contact/prism_math")
local load, dot, sub, madd = v8.load, v8.dot, v8.sub, v8.madd
local reciprocal = v8.reciprocal
local intersect
local t1 = {}

function t1.quad_triangle(p4, p5, p6, p7, p8) -- line: 44
    -- upvalues: intersect (ref)
    return intersect(p4, p5, p6, p7, p8)
end

function t1.quad_quad(p9, p10, p11, p12) -- line: 50
    -- upvalues: intersect (ref)
    return intersect(p9, p10, p11, p12, true)
end

local function vertex(p13, p14) -- line: 54
    -- upvalues: load (copy)
    return load(p13, 4 + p14 * 16)
end

local function project_to_face(p15, p16) -- line: 58
    -- upvalues: load (copy), dot (copy), sub (copy), madd (copy), vertex (copy)
    local v9 = load(p15, 132)

    return madd(v9, dot(v9, sub(vertex(p15, 0), p16)), p16)
end

local function append(p17, p18, p19, p20, p21, p22) -- line: 64
    -- upvalues: v1 (copy), project_to_face (copy)
    if not (p18 < 16) then
        error("feature prism point capacity exceeded", 0)
    end

    local v10 = if p22 then 0 else 64
    local v11 = if p22 then 64 else 0
    local v12 = p18 * 4
    local v13 = project_to_face(p19, p21)
    local v14 = v10 + v12 + 1
    local v15 = v13[1]
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

    p17[v14] = v16

    local v20 = v10 + v12 + 2
    local v21 = v13[2]
    local v22

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v21 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readu32(v1, 0)
    end

    p17[v20] = v22

    local v26 = v10 + v12 + 3
    local v27 = v13[3]
    local v28

    if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
        local v29 = math.abs(v27) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

        if v27 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v27)
        v28 = buffer.readu32(v1, 0)
    end

    p17[v26] = v28

    local v32 = v10 + v12 + 4
    local v33 = v13[4]
    local v34

    if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
        local v35 = math.abs(v33) * 7.1362384635298E+44
        local v36 = math.floor(v35)
        local v37 = v35 - v36

        v34 = if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36

        if v33 < 0 then
            v34 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v33)
        v34 = buffer.readu32(v1, 0)
    end

    p17[v32] = v34

    local v38 = project_to_face(p20, p21)
    local v39 = v11 + v12 + 1
    local v40 = v38[1]
    local v41

    if v40 ~= 0 and v40 > -1.1754943508222875E-38 and v40 < 1.1754943508222875E-38 then
        local v42 = math.abs(v40) * 7.1362384635298E+44
        local v43 = math.floor(v42)
        local v44 = v42 - v43

        v41 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

        if v40 < 0 then
            v41 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v40)
        v41 = buffer.readu32(v1, 0)
    end

    p17[v39] = v41

    local v45 = v11 + v12 + 2
    local v46 = v38[2]
    local v47

    if v46 ~= 0 and v46 > -1.1754943508222875E-38 and v46 < 1.1754943508222875E-38 then
        local v48 = math.abs(v46) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

        if v46 < 0 then
            v47 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v46)
        v47 = buffer.readu32(v1, 0)
    end

    p17[v45] = v47

    local v51 = v11 + v12 + 3
    local v52 = v38[3]
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

    p17[v51] = v53

    local v57 = v11 + v12 + 4
    local v58 = v38[4]
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

    p17[v57] = v59

    return p18 + 1
end

local function containment_dot(p23, p24) -- line: 89
    return p23[3] * p24[3] + (p23[1] * p24[1] + p23[2] * p24[2])
end

function intersect(p25, p26, p27, p28, p29) -- line: 94
    -- upvalues: v1 (copy), load (copy), dot (copy), sub (copy), madd (copy), reciprocal (copy), vertex (copy), append (copy), containment_dot (copy)
    local v63 = p27[141]
    local n1 = 0

    for i = 0, 3 do
        local v64 = vertex(p26, i)
        local v65 = load(p26, i * 16 + 8)
        local v66 = load(p26, i * 16 + 12)

        buffer.writeu32(v1, 0, p26[i * 16 + 16 + 1])

        local v68 = buffer.readf32(v1, 0)

        for j = 0, v63 - 1 do
            local v69 = vertex(p27, j)
            local v70 = load(p27, j * 16 + 8)

            buffer.writeu32(v1, 0, p27[j * 16 + 16 + 1])

            local v72 = buffer.readf32(v1, 0)
            local v73 = dot(v70, v66)
            local v74 = dot(sub(v64, v69), v66)
            local v75 = madd(v70, reciprocal(v73) * v74, v69)
            local v76 = dot(sub(v75, v64), v65)

            if math.abs(v73) > 1.1920928955078125E-07 and not (math.abs(v74) > math.abs(v72 * v73)) and not (v74 * v73 < 0) and not (v68 < v76) and not (v76 < 0) then
                n1 = append(p25, n1, p26, p27, v75, p29)
            end
        end
    end

    buffer.writeu32(v1, 0, p28[1])

    local v80 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[2])

    local v82 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[3])

    local v84 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[4])

    local t2 = {
        v80,
        v82,
        v84,
        (buffer.readf32(v1, 0))
    }

    for _, v86 in {
            { p26, p27, 4, v63 },
            { p27, p26, v63, 4 }
        } do
        local v87 = v86[1]
        local v88 = v86[2]
        local v89 = v86[3]
        local v90 = v86[4]

        for k = 0, v89 - 1 do
            local v91 = vertex(v87, k)
            local v93 = madd(t2, containment_dot(sub(vertex(v88, 0), v91), t2), v91)

            v93[4] = 1

            local v94 = v90 - 1
            local v95 = true

            for n = 0, v94 do
                if not (containment_dot(sub(v93, vertex(v88, n)), load(v88, n * 16 + 12)) < 0) then
                    v95 = false
                    break
                end
            end

            if v95 then
                n1 = append(p25, n1, p26, p27, v93, p29)
            end
        end
    end

    p25[133] = n1

    if n1 == 0 then
        return 0
    end

    return 1
end

t1.vertex = vertex
t1.project_to_face = project_to_face
t1.append = append
t1.containment_dot = containment_dot
t1.intersect = intersect

return t1
