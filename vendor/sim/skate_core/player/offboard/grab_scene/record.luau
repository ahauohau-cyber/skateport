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

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local v8 = require(sim.import)("skate_core/player/offboard/grab_scene/math")
local point, direction, sub, length = v8.point, v8.direction, v8.sub, v8.length
local reciprocal = v8.reciprocal
local t1 = {}

t1.Geometry = {}

function t1.Geometry.eq(p4, p5) -- line: 47
    if p4.id ~= p5.id or p4.word_60 ~= p5.word_60 or #p4.points ~= #p5.points or #p4.approach_vectors ~= #p5.approach_vectors then
        return false
    end

    for i = 1, #p4.points do
        for j = 1, 4 do
            if p4.points[i][j] ~= p5.points[i][j] then
                return false
            end
        end
    end

    for i = 1, #p4.approach_vectors do
        for j = 1, 4 do
            if p4.approach_vectors[i][j] ~= p5.approach_vectors[i][j] then
                return false
            end
        end
    end

    return true
end

t1.AssemblyData = {}
t1.PartData = {}
t1.RatesData = {}
t1.RecordInput = {}
t1.Record = {}

function t1.Record.from_geometry(p6) -- line: 93
    -- upvalues: rt (copy), v1 (copy), t1 (copy), point (copy), direction (copy), sub (copy), length (copy), reciprocal (copy)
    local geometry = p6.geometry

    if geometry.id == 0 or #geometry.points == 0 or #geometry.points > 255 or #geometry.approach_vectors > 255 then
        error("Grab geometry needs a real identity and native byte-sized point counts", 0)
    end

    local v9 = false

    for _, v10 in geometry.points do
        local v11 = v10[1]

        if v11 ~= v11 or v11 == 1e999 or v11 == (-1e999) then
            v9 = true
        end

        local v12 = v10[2]

        if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) then
            v9 = true
        end

        local v13 = v10[3]

        if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
            v9 = true
        end

        local v14 = v10[4]

        if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) then
            v9 = true
        end
    end

    for _, v15 in geometry.approach_vectors do
        local v16 = v15[1]

        if v16 ~= v16 or v16 == 1e999 or v16 == (-1e999) then
            v9 = true
        end

        local v17 = v15[2]

        if v17 ~= v17 or v17 == 1e999 or v17 == (-1e999) then
            v9 = true
        end

        local v18 = v15[3]

        if v18 ~= v18 or v18 == 1e999 or v18 == (-1e999) then
            v9 = true
        end

        local v19 = v15[4]

        if v19 ~= v19 or v19 == 1e999 or v19 == (-1e999) then
            v9 = true
        end
    end

    for i = 1, 4 do
        for j = 1, 4 do
            local v20 = p6.frame[i][j]

            if v20 ~= v20 or v20 == 1e999 or v20 == (-1e999) then
                v9 = true
            end
        end
    end

    for i = 1, 4 do
        local v21 = p6.object_vector_128[i]

        if v21 ~= v21 or v21 == 1e999 or v21 == (-1e999) then
            v9 = true
        end
    end

    if v9 then
        error("Nonfinite authored grab geometry/frame", 0)
    end

    local t2 = {
        table.create(72, 0),
        geometry
    }
    local v22 = t2[1]

    t1.Record.set_vector(t2, 0, p6.frame[1])
    t1.Record.set_vector(t2, 16, p6.frame[2])
    t1.Record.set_vector(t2, 32, p6.frame[3])
    t1.Record.set_vector(t2, 48, p6.frame[4])
    v22[48] = p6.descriptor.kind
    v22[49] = p6.descriptor.id
    v22[50] = geometry.id
    v22[51] = 2147483648
    v22[52] = geometry.word_60
    v22[69] = p6.word_272

    local v23 = point(p6.frame, geometry.points[1])
    local v24 = point(p6.frame, geometry.points[#geometry.points])
    local v25 = if geometry.approach_vectors[1] == nil then { 0, 1, 0, 0 } else rt.copy(geometry.approach_vectors[1])

    t1.Record.set_vector(t2, 64, v23)
    t1.Record.set_vector(t2, 80, v24)
    t1.Record.set_vector(t2, 96, direction(p6.frame, v25))
    t1.Record.set_vector(t2, 128, p6.object_vector_128)
    t1.Record.set_vector(t2, 224, { 1, 1, 1, 1 })
    buffer.writef32(v1, 0, 1)
    v22[61] = buffer.readu32(v1, 0)
    buffer.writef32(v1, 0, 1)
    v22[62] = buffer.readu32(v1, 0)

    local F32_MAX = rt.F32_MAX
    local v26

    if F32_MAX ~= 0 and F32_MAX > -1.1754943508222875E-38 and F32_MAX < 1.1754943508222875E-38 then
        local v27 = math.abs(F32_MAX) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if F32_MAX < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, F32_MAX)
        v26 = buffer.readu32(v1, 0)
    end

    v22[63] = v26

    local F32_MAX2 = rt.F32_MAX
    local v30

    if F32_MAX2 ~= 0 and F32_MAX2 > -1.1754943508222875E-38 and F32_MAX2 < 1.1754943508222875E-38 then
        local v31 = math.abs(F32_MAX2) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if F32_MAX2 < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, F32_MAX2)
        v30 = buffer.readu32(v1, 0)
    end

    v22[64] = v30

    local assembly = p6.assembly

    if assembly ~= nil then
        if assembly.identity == 0 then
            error("Zero assembly identity is reserved for native null", 0)
        end

        v22[53] = assembly.identity

        local first_part = assembly.first_part

        if first_part ~= nil then
            if first_part.identity == 0 then
                error("Zero part identity is reserved for native null", 0)
            end

            v22[54] = first_part.identity

            for i = 0, 9 do
                local v34 = i + 56 + 1
                local v35 = first_part.coefficients_0_to_36[i + 1]

                if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
                    local v36 = math.abs(v35) * 7.1362384635298E+44
                    local v37 = math.floor(v36)
                    local v38 = v36 - v37
                    local v39 = if v38 > 0.5 or v38 == 0.5 and v37 % 2 == 1 then v37 + 1 else v37

                    if v35 < 0 then
                        v22[v34] = v39 + 2147483648
                    else
                        v22[v34] = v39
                    end
                else
                    buffer.writef32(v1, 0, v35)
                    v22[v34] = buffer.readu32(v1, 0)
                end
            end

            local rates = first_part.rates

            if rates ~= nil then
                if rates.identity == 0 then
                    error("Zero rates identity is reserved for native null", 0)
                end

                v22[55] = rates.identity
                v22[51] = bit32.bor(v22[51], 1073741824)
                t1.Record.set_vector(t2, 144, rates.vector_48)
                t1.Record.set_vector(t2, 160, rates.transform_position_48)
            end
        end
    end

    local v41 = sub(v24, v23)
    local v42 = length(v41)
    local v43 = reciprocal(v42)

    t1.Record.set_vector(t2, 112, {
        v41[1] * v43,
        v41[2] * v43,
        v41[3] * v43,
        v41[4] * v43
    })

    local v44 = v42 * 0.5
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

    v22[46] = v45

    local v49 = #geometry.points - 2
    local n1 = 0

    for i = 0, v49 do
        n1 += length(sub(geometry.points[i + 2], geometry.points[i + 1]))
    end

    local v50

    if n1 ~= 0 and n1 > -1.1754943508222875E-38 and n1 < 1.1754943508222875E-38 then
        local v51 = math.abs(n1) * 7.1362384635298E+44
        local v52 = math.floor(v51)
        local v53 = v51 - v52

        v50 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

        if n1 < 0 then
            v50 += 2147483648
        end
    else
        buffer.writef32(v1, 0, n1)
        v50 = buffer.readu32(v1, 0)
    end

    v22[45] = v50

    return t2
end

function t1.Record.set_vector(p7, p8, p9) -- line: 201
    -- upvalues: rt (copy), v1 (copy)
    local v54 = rt.idiv(p8, 4)
    local v55 = p7[1]
    local v56 = v54 + 0 + 1
    local v57 = p9[1]
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

    v55[v56] = v58

    local v62 = v54 + 1 + 1
    local v63 = p9[2]
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

    v55[v62] = v64

    local v68 = v54 + 2 + 1
    local v69 = p9[3]
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

    v55[v68] = v70

    local v74 = v54 + 3 + 1
    local v75 = p9[4]
    local v76

    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
        local v77 = math.abs(v75) * 7.1362384635298E+44
        local v78 = math.floor(v77)
        local v79 = v77 - v78

        v76 = if v79 > 0.5 or v79 == 0.5 and v78 % 2 == 1 then v78 + 1 else v78

        if v75 < 0 then
            v76 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v75)
        v76 = buffer.readu32(v1, 0)
    end

    v55[v74] = v76
end

return t1
