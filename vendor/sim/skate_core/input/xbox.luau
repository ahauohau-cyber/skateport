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

local magnitude = require(sim.import)("skate_core/input/controller").magnitude
local t1 = {}

t1.XboxState = {}

function t1.convert(p3, p4) -- line: 40
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v10 = table.create(24, 0)

    for i = 0, 9 do
        if bit32.band(p3.buttons, (bit32.lshift(1, i))) == 0 then
            v10[i + 1] = 0
        else
            v10[i + 1] = 1
        end
    end

    local v12 = p3.triggers[1] * 0.003921568859368563
    local v13

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        local v14 = math.abs(v12) * 7.1362384635298E+44
        local v15 = math.floor(v14)
        local v16 = v14 - v15

        v13 = (if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15) * 1.401298464324817E-45

        if v12 < 0 then
            v13 = -v13
        end
    else
        buffer.writef32(v1, 0, v12)
        v13 = buffer.readf32(v1, 0)
    end

    v10[11] = v13

    local v17 = p3.triggers[2] * 0.003921568859368563
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = (if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20) * 1.401298464324817E-45

        if v17 < 0 then
            v18 = -v18
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readf32(v1, 0)
    end

    v10[12] = v18

    for _, v22 in {
            { 12, 12 },
            { 13, 13 },
            { 14, 14 },
            { 15, 15 }
        } do
        local v23 = v22[1]
        local v24 = v22[2]

        if bit32.band(p3.buttons, (bit32.lshift(1, v24))) == 0 then
            v10[v23 + 1] = 0
        else
            v10[v23 + 1] = 1
        end
    end

    local v26 = t1.condition(rt.copy(p3.left))
    local v27 = t1.condition(rt.copy(p3.right))

    v10[17] = v26[1]
    v10[18] = v26[2]
    v10[19] = v26[3]
    v10[20] = v26[4]
    v10[21] = v27[1]
    v10[22] = v27[2]
    v10[23] = v27[3]
    v10[24] = v27[4]

    if p4 ~= 0 then
        for _, v28 in { 10, 11, 21, 22 } do
            v10[v28 + 1] = 0
        end
    end

    return v10
end

function t1.condition(p5) -- line: 78
    -- upvalues: t1 (copy), magnitude (copy)
    local v29 = p5[1] * 3.0517578125E-05
    local v30 = p5[2] * 3.0517578125E-05
    local v32 = magnitude(v30 * v30 + v29 * v29)
    local v33

    if v32 < 0.0010000000474974513 then
        v33 = 0
    else
        local v34 = (v32 - 0.25) * 1.4285714626312256

        if v34 < 0 then
            v34 = 0
        elseif v34 > 1 then
            v34 = 1
        end

        v33 = v34 / v32
    end

    local v35 = v33 * v29
    local v36 = v33 * v30

    return {
        t1.positive(v35),
        t1.positive(-v35),
        t1.positive(v36),
        t1.positive(-v36)
    }
end

function t1.positive(p6) -- line: 103
    if -p6 >= 0 then
        return 0
    end

    return p6
end

return t1
