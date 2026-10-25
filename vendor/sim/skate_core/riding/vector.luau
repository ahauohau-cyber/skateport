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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/reciprocal_sqrt")
local v10 = import("skate_core/physics/native_arithmetic")
local t1 = {}

function t1.dot3(p3, p4) -- line: 32
    -- upvalues: v10 (copy)
    return v10.dot3(p3, p4)
end

function t1.normalize(p5, p6) -- line: 44
    -- upvalues: v1 (copy)
    local v11 = p5[1]
    local v12 = p5[2]
    local v13 = p5[3]
    local v14 = v11 * v11 + v12 * v12 + v13 * v13
    local v15

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v16 = math.abs(v14) * 7.1362384635298E+44
        local v17 = math.floor(v16)
        local v18 = v16 - v17

        v15 = (if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17) * 1.401298464324817E-45

        if v14 < 0 then
            v15 = -v15
        end
    else
        buffer.writef32(v1, 0, v14)
        v15 = buffer.readf32(v1, 0)
    end

    local v19 = 1 / math.sqrt(v15)
    local v20 = -v15 * (v19 * v19) + 1
    local v21 = v19 * 0.5 * v20 + v19
    local v22 = -v15 * (v21 * v21) + 1
    local v23 = v21 * 0.5 * v22 + v21
    local v24 = if v15 == 0 then 0 else v15 * v23

    return {
        if p6[1] < v24 then v11 * v23 else 0,
        if p6[2] < v24 then v12 * v23 else 0,
        if p6[3] < v24 then v13 * v23 else 0,
        if p6[4] < v24 then p5[4] * v23 else 0
    }
end

function t1.normalize_reference(p7, p8) -- line: 69
    -- upvalues: rt (copy), v1 (copy), v9 (copy), t1 (copy)
    local v29 = t1.dot3(p7, p7)
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = (if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32) * 1.401298464324817E-45

        if v29 < 0 then
            v30 = -v30
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readf32(v1, 0)
    end

    local v34 = v9.estimate(v30)
    local v35 = -v30 * (v34 * v34) + 1
    local v36 = v34 * 0.5 * v35 + v34
    local v37 = -v30 * (v36 * v36) + 1
    local v38 = v36 * 0.5 * v37 + v36
    local v39 = if v30 == 0 then 0 else v30 * v38

    return rt.from_fn(4, function(p9) -- line: 82
        -- upvalues: p7 (copy), p8 (copy), v38 (copy), v39 (copy)
        if v39 > p8[p9 + 1] then
            return p7[p9 + 1] * v38
        end

        return 0
    end)
end

function t1.clamp(p10, p11, p12) -- line: 91
    local v40 = if p11 - p10 >= 0 then p11 else p10

    if p12 - v40 >= 0 then
        return v40
    end

    return p12
end

function t1.cross(p13, p14) -- line: 107
    return {
        -p13[3] * p14[2] + p13[2] * p14[3],
        -p13[1] * p14[3] + p13[3] * p14[1],
        -p13[2] * p14[1] + p13[1] * p14[2],
        -p13[4] * p14[4] + p13[4] * p14[4]
    }
end

function t1.cross_reference(p15, p16) -- line: 119
    -- upvalues: rt (copy)
    return rt.from_fn(4, function(p17) -- line: 120
        -- upvalues: p15 (copy), p16 (copy), rt (copy)
        local v41 = if p17 == 3 then 3 else rt.irem(p17 + 1, 3)
        local v42 = if p17 == 3 then 3 else rt.irem(p17 + 2, 3)

        return -p15[v42 + 1] * p16[v41 + 1] + p15[v41 + 1] * p16[v42 + 1]
    end)
end

return t1
