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
local v8 = import("skate_core/point_graph")
local v9 = import("skate_core/input/angle")
local v10 = import("skate_core/input/controller")
local v11 = import("skate_core/trigonometry")
local t1 = {}
local PointGraph = v8.PointGraph

local function round_ties_even(p4) -- line: 43
    local v12 = math.floor(p4)
    local v13 = p4 - v12

    if v13 < 0.5 or not (v13 > 0.5) and v12 % 2 == 0 then
        return v12
    end

    return v12 + 1
end

t1.TurnRemap = {}

function t1.clamp(p5) -- line: 57
    local v14 = if -1 - p5 >= 0 then -1 else p5

    if 1 - v14 >= 0 then
        return v14
    end

    return 1
end

function t1.angle(p6, p7, p8) -- line: 66
    -- upvalues: v1 (copy), v9 (copy)
    if not (p8 > 1.52587890625E-05) then
        return 0
    end

    local v15 = v9.reciprocal_estimate(p6)
    local v16 = v15 * (-v15 * p6 + 1) + v15
    local v17 = v9.atan(p7 * v16 + 0)
    local v18

    if p7 ~= 0 and p7 > -1.1754943508222875E-38 and p7 < 1.1754943508222875E-38 then
        local v19 = math.abs(p7) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20

        if p7 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p7)
        v18 = buffer.readu32(v1, 0)
    end

    local v22 = bit32.band(v18, 2147483648)

    if p6 < 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1078530011, v22)))
        v17 = buffer.readf32(v1, 0) + v17
    end

    if p6 ~= 0 then
        return v17
    end

    buffer.writeu32(v1, 0, (bit32.bor(1070141403, v22)))

    return (buffer.readf32(v1, 0))
end

local from_bits = rt.from_bits
local v25 = from_bits(1042479491)
local v26 = from_bits(1086918619)
local v27 = from_bits(1026206379)
local v28 = from_bits(3132492641)
local v29 = from_bits(936381697)
local v30 = from_bits(3029594750)
local v31 = from_bits(823097032)
local v32 = from_bits(2907294629)
local v33 = from_bits(693583775)
local v34 = from_bits(2771653571)
local v35 = from_bits(552771933)
local v36 = from_bits(2626056651)
local v37 = false

function t1.set_reference(p9) -- line: 109
    -- upvalues: v37 (ref)
    v37 = p9
end

function t1.cosine(p10) -- line: 113
    -- upvalues: t1 (copy), v25 (copy), v26 (copy), v27 (copy), v28 (copy), v29 (copy), v30 (copy), v31 (copy), v32 (copy), v33 (copy), v34 (copy), v35 (copy), v36 (copy), v37 (ref)
    if v37 then
        return t1.cosine_reference(p10)
    end

    local v38 = p10 * v25
    local v39 = math.floor(v38)
    local v40 = v38 - v39

    if not (v40 < 0.5) and (v40 > 0.5 or v39 % 2 ~= 0) then
        v39 += 1
    end

    local v41 = -v26 * v39 + p10
    local v42 = v41 * v41
    local v43 = v42 * v42
    local v44 = v43 * v42
    local v45 = v43 * v43
    local v46 = v44 * v43
    local v47 = v44 * v44
    local v48 = v45 * v44
    local v49 = v45 * v45
    local v50 = v46 * v45
    local v51 = v47 * v46
    local v52 = v46 * v46
    local v53 = -0.5 * v42 + 1
    local v54 = v27 * v43 + v53
    local v55 = v28 * v44 + v54
    local v56 = v29 * v45 + v55
    local v57 = v30 * v46 + v56
    local v58 = v31 * v47 + v57
    local v59 = v32 * v48 + v58
    local v60 = v33 * v49 + v59
    local v61 = v34 * v50 + v60
    local v62 = v35 * v52 + v61

    return v36 * v51 + v62
end

function t1.cosine_reference(p11) -- line: 145
    -- upvalues: v1 (copy)
    local v63 = p11 * 0.15915493667125702
    local v64 = math.floor(v63)
    local v65 = v63 - v64

    if not (v65 < 0.5) and (v65 > 0.5 or v64 % 2 ~= 0) then
        v64 += 1
    end

    local v66 = v64 * -6.2831854820251465 + p11
    local v67 = v66 * v66
    local v68 = v67 * v67
    local v69 = v68 * v67
    local v70 = v68 * v68
    local v71 = v69 * v68
    local v72 = v69 * v69
    local v73 = v70 * v69
    local v74 = v70 * v70
    local v75 = v71 * v70
    local v76 = v72 * v71
    local t2 = {
        v68,
        v69,
        v70,
        v71,
        v72,
        v73,
        v74,
        v75,
        v71 * v71,
        v76
    }
    local t3 = {
        1026206379, 3132492641, 936381697, 3029594750, 823097032, 2907294629, 693583775, 2771653571,
        552771933, 2626056651
    }
    local v77 = v67 * -0.5 + 1

    for i = 1, 10 do
        buffer.writeu32(v1, 0, t3[i])
        v77 = buffer.readf32(v1, 0) * t2[i] + v77
    end

    return v77
end

function t1.TurnRemap.apply(p12, p13) -- line: 180
    -- upvalues: v10 (copy), v11 (copy), t1 (copy), PointGraph (copy)
    local v79 = v10.magnitude(p13[1] * p13[1] + p13[2] * p13[2])
    local v80 = t1.angle(p13[1], p13[2], v79)
    local v81 = if v80 >= 0 then v80 else v80 + 3.1415927410125732
    local v82 = v79 * PointGraph.evaluate(p12.magnitude, v81)
    local v83 = t1.clamp(t1.cosine(v80) * v82)
    local v84 = t1.clamp(v11.sin(v80) * v82)
    local v85 = v10.magnitude(v83 * v83 + v84 * v84)
    local v86 = t1.angle(v83, v84, v85)
    local v87 = if v86 >= 0 then v86 else v86 + 3.1415927410125732
    local v88 = PointGraph.evaluate(p12.angle, v87)

    if not (v86 >= 0) then
        v88 += 3.1415927410125732
    end

    local v89 = p12.angle_offset + v88

    return {
        t1.clamp(t1.cosine(v89) * v85),
        t1.clamp(v11.sin(v89) * v85),
        0, 0
    }
end

return t1
