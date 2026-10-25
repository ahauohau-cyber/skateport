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

local ShakeSamples = require(sim.import)("skate_core/camera").ShakeSamples
local t1 = {}

local function parse_usize(p3) -- line: 34
    if p3 == "" or p3 == "+" or p3 == "-" then
        error(p3 == "" and "cannot parse integer from empty string" or "invalid digit found in string", 0)
    end

    if string.find(p3, "^%+?%d+$") == nil then
        error("invalid digit found in string", 0)
    end

    return (tonumber(p3))
end

local function parse_f32(p4) -- line: 46
    -- upvalues: v1 (copy)
    local v9, v10 = string.match(p4, "^([+-]?)(.*)$")
    local v11 = string.lower(v10)

    if v11 == "inf" or v11 == "infinity" then
        if v9 == "-" then
            return (-1e999)
        end

        return 1e999
    end

    if v11 == "nan" then
        return (0/0)
    end

    local v12, v13 = string.match(v10, "^([%d%.]+)(.*)$")

    if v12 == nil or string.find(v12, "^%d+%.?%d*$") == nil and string.find(v12, "^%.%d+$") == nil or v13 ~= "" and string.find(v13, "^[eE][+-]?%d+$") == nil then
        error("invalid float literal", 0)
    end

    local v14 = tonumber(v10)

    if v9 == "-" then
        v14 = -v14
    end

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v16 = math.abs(v14) * 7.1362384635298E+44
        local v15 = math.floor(v16)
        local v17 = v16 - v15

        if v17 > 0.5 or v17 == 0.5 and v15 % 2 == 1 then
            v15 += 1
        end

        local v18 = v15 * 1.401298464324817E-45

        if v14 < 0 then
            return -v18
        end

        return v18
    end

    buffer.writef32(v1, 0, v14)

    return (buffer.readf32(v1, 0))
end

function t1.parse(p5) -- line: 67
    -- upvalues: ShakeSamples (copy), parse_usize (copy), parse_f32 (copy)
    local t2 = {}

    for match in string.gmatch(p5, "%S+") do
        table.insert(t2, match)
    end

    local v19 = t2[1]
    local v20 = 1 + 1

    if v19 == nil then
        error("Empty camera .shk file", 0)
    end

    local ok, result = pcall(parse_usize, v19)

    if not ok then
        error(("Invalid camera shake sample count: %*"):format(result), 0)
    end

    local v21 = table.create(result)

    for i = 0, result - 1 do
        local v22 = table.create(8, 0)

        for j = 1, 8 do
            local v23 = t2[v20]

            v20 += 1

            if v23 == nil then
                error(("Truncated camera shake sample %*"):format(i), 0)
            end

            local ok, result = pcall(parse_f32, v23)

            if not ok then
                error(("Invalid camera shake sample %*: %*"):format(i, result), 0)
            end

            v22[j] = result
        end

        table.insert(v21, v22)
    end

    if t2[v20] ~= nil then
        error("Camera shake has extra sample data", 0)
    end

    return ShakeSamples.from_rows(v21)
end

return t1
