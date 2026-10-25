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

function t1.reciprocal_estimate(p4) -- line: 36
    -- upvalues: v8 (copy)
    return v8.reciprocal_estimate(p4)
end

function t1.refined_reciprocal(p5) -- line: 40
    -- upvalues: t1 (copy)
    local v9 = t1.reciprocal_estimate(p5)
    local v10 = v9 * (-p5 * v9 + 1) + v9
    local v11 = v10 * (-p5 * v10 + 1) + v10

    if v10 == v10 then
        return v11
    end

    return v9
end

local from_bits = rt.from_bits
local reciprocal_estimate = v8.reciprocal_estimate
local v12 = from_bits(1049178275)
local v13 = from_bits(1065749138)
local v14 = from_bits(1057360530)
local v15 = from_bits(1070141403)
local v16 = from_bits(1060857775)
local v17 = from_bits(1071494103)
local v18 = from_bits(3210111959)
local v19 = from_bits(3238521339)
local v20 = from_bits(3248753662)
local v21 = from_bits(3243967795)
local v22 = from_bits(1097884239)
local v23 = from_bits(1114525778)
local v24 = from_bits(1118589072)
local v25 = from_bits(1109672934)
local v26 = from_bits(964689920)
local v27 = from_bits(2122317824)

local function refined(p6) -- line: 80
    -- upvalues: reciprocal_estimate (copy)
    local v28 = reciprocal_estimate(p6)
    local v29 = v28 * (-p6 * v28 + 1) + v28
    local v30 = v29 * (-p6 * v29 + 1) + v29

    if v29 == v29 then
        return v30
    end

    return v28
end

local v31 = false

function t1.set_reference(p7) -- line: 93
    -- upvalues: v31 (ref)
    v31 = p7
end

function t1.atan(p8) -- line: 97
    -- upvalues: t1 (copy), reciprocal_estimate (copy), v12 (copy), v13 (copy), v14 (copy), v15 (copy), v16 (copy), v17 (copy), v18 (copy), v19 (copy), v20 (copy), v21 (copy), v22 (copy), v23 (copy), v24 (copy), v25 (copy), v26 (copy), v27 (copy), v31 (ref)
    if v31 then
        return t1.atan_reference(p8)
    end

    local v32 = math.abs(p8)
    local v33 = v32 > 1

    if v33 then
        local v34 = reciprocal_estimate(v32)
        local v35 = v34 * (-v32 * v34 + 1) + v34

        v32 = v35 * (-v32 * v35 + 1) + v35

        if v35 ~= v35 then
            v32 = v34
        end
    end

    local v36 = v12 < v32
    local v37 = if v36 then if v33 then v13 else v14 elseif v33 then v15 else 0
    local v38 = v32 * v16 + v32 - 1
    local v39 = v32 + v17
    local v40 = reciprocal_estimate(v39)
    local v41 = v40 * (-v39 * v40 + 1) + v40
    local v42 = v41 * (-v39 * v41 + 1) + v41

    if v41 ~= v41 then
        v42 = v40
    end

    local v43 = v38 * v42

    if not v36 then
        v43 = v32
    end

    local v44 = v43 * v43
    local v45 = v44 * (v44 * (v44 * v18 + v19) + v20) + v21
    local v46 = v44 * (v44 * (v44 * (v44 + v22) + v23) + v24) + v25
    local v47 = v45 * v44
    local v48 = reciprocal_estimate(v46)
    local v49 = v48 * (-v46 * v48 + 1) + v48
    local v50 = v49 * (-v46 * v49 + 1) + v49

    if v49 ~= v49 then
        v50 = v48
    end

    local v51 = v43 * (v47 * v50) + v43

    if not (v26 > math.abs(v43)) then
        v43 = v51
    end

    if v33 then
        v43 = -v43
    end

    local v52 = v43 + v37

    if p8 < 0 then
        v52 = -v52
    end

    if v27 < p8 then
        v52 = v15
    end

    if p8 < -v27 then
        return -v15
    end

    return v52
end

function t1.atan_reference(p9) -- line: 150
    -- upvalues: t1 (copy)
    local v53 = math.abs(p9)
    local v54 = v53 > 1

    if v54 then
        v53 = t1.refined_reciprocal(v53)
    end

    local v55 = v53 > 0.2679491937160492
    local v56 = if v55 then if v54 then 1.0471975803375244 else 0.5235987901687622 elseif v54 then 1.5707963705062866 else 0
    local v57 = (v53 * 0.7320508360862732 + v53 - 1) * t1.refined_reciprocal(v53 + 1.7320507764816284)

    if not v55 then
        v57 = v53
    end

    local v58 = v57 * v57
    local v59 = v58 * (v58 * (v58 * -0.8375830054283142 + -8.494624137878418) + -20.505855560302734) + -13.688769340515137
    local v60 = v58 * (v58 * (v58 * (v58 + 15.024001121520996) + 59.57843780517578) + 86.1573486328125) + 41.066307067871094
    local v61 = v57 * (v59 * v58 * t1.refined_reciprocal(v60)) + v57

    if not (math.abs(v57) < 0.000244140625) then
        v57 = v61
    end

    if v54 then
        v57 = -v57
    end

    local v62 = v57 + v56

    if p9 < 0 then
        v62 = -v62
    end

    if p9 > 8.507059173023462E+37 then
        v62 = 1.5707963705062866
    end

    if p9 < -8.507059173023462E+37 then
        return -1.5707963705062866
    end

    return v62
end

function t1.left_stick_angle(p10, p11) -- line: 201
    -- upvalues: v1 (copy), t1 (copy)
    if p10 == 0 and p11 == 0 then
        return 0
    end

    local v63 = -p11
    local v64 = t1.reciprocal_estimate(v63)
    local v65 = v64 * (-v64 * v63 + 1) + v64
    local v66 = t1.atan(p10 * v65 + 0)
    local v67

    if p10 ~= 0 and p10 > -1.1754943508222875E-38 and p10 < 1.1754943508222875E-38 then
        local v68 = math.abs(p10) * 7.1362384635298E+44
        local v69 = math.floor(v68)
        local v70 = v68 - v69

        v67 = if v70 > 0.5 or v70 == 0.5 and v69 % 2 == 1 then v69 + 1 else v69

        if p10 < 0 then
            v67 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p10)
        v67 = buffer.readu32(v1, 0)
    end

    local v71 = bit32.band(v67, 2147483648)

    buffer.writeu32(v1, 0, (bit32.bor(1078530011, v71)))

    local v73 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, (bit32.bor(1070141403, v71)))

    local v75 = buffer.readf32(v1, 0)

    if v63 < 0 then
        v66 = v73 + v66
    end

    if v63 == 0 then
        return v75
    end

    return v66
end

return t1
