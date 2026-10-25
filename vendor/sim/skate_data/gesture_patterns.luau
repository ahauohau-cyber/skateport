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

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local v9 = require(sim.import)("skate_core/input/gesture")
local t1 = {}

local function lines(p4) -- line: 42
    local t2 = {}
    local n1 = 1

    while true do
        if not (n1 <= #p4) then
            return t2
        end

        local v10 = string.find(p4, "\n", n1, true)

        if v10 == nil then
            break
        end

        local v12 = string.sub(p4, n1, v10 - 1)

        if string.sub(v12, -1) == "\r" then
            v12 = string.sub(v12, 1, -2)
        end

        table.insert(t2, v12)
        n1 = v10 + 1
    end

    table.insert(t2, (string.sub(p4, n1)))

    return t2
end

local function ascii_whitespace(p5) -- line: 62
    if string.find(p5, "[\194\225\226\227]") == nil then
        return p5
    end

    local v14 = string.gsub(p5, "\194[\133\160]", " ")
    local v15 = string.gsub(v14, " ", " ")
    local v16 = string.gsub(v15, "\226\128[\128-\138\168\169\175]", " ")
    local v17 = string.gsub(v16, " ", " ")

    return (string.gsub(v17, "　", " "))
end

local function parse_f32(p6) -- line: 77
    -- upvalues: v1 (copy)
    local v18 = string.match(p6, "^[+-]?(.*)$")
    local v19 = string.lower(v18)

    if v19 == "inf" or v19 == "infinity" then
        if string.sub(p6, 1, 1) == "-" then
            return (-1e999)
        end

        return 1e999
    end

    if v19 == "nan" then
        return (0/0)
    end

    local v20 = string.match(v18, "^([%d%.]+)$") or string.match(v18, "^([%d%.]+)[eE][+-]?%d+$")

    if v20 == nil or string.find(v20, "^%d+%.?%d*$") == nil and string.find(v20, "^%.%d+$") == nil then
        return nil
    end

    local v21 = tonumber(v18)

    if v21 == nil then
        return nil
    end

    if string.sub(p6, 1, 1) == "-" then
        v21 = -v21
    end

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v22 = math.floor(v23)
        local v24 = v23 - v22

        if v24 > 0.5 or v24 == 0.5 and v22 % 2 == 1 then
            v22 += 1
        end

        local v25 = v22 * 1.401298464324817E-45

        if v21 < 0 then
            return -v25
        end

        return v25
    end

    buffer.writef32(v1, 0, v21)

    return (buffer.readf32(v1, 0))
end

function t1.load(p7) -- line: 103
    -- upvalues: sim (copy), t1 (copy)
    local v26 = string.match(p7, "([^/\\]+)$") or p7
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local gesture_patterns = sim_data and sim_data:FindFirstChild("gesture_patterns")
    local v27 = gesture_patterns and require(gesture_patterns)[v26]

    if v27 == nil then
        error(string.format("%s: not found in ReplicatedStorage.Skate3.sim_data.gesture_patterns", p7), 0)
    end

    local parse = t1.parse
    local ok, result = pcall(parse, v27)

    if not ok then
        error(string.format("%s: %s", p7, (tostring(result))), 0)
    end

    return result
end

function t1.parse(p8) -- line: 119
    -- upvalues: rt (copy), v9 (copy), lines (copy), ascii_whitespace (copy), parse_f32 (copy)
    local t3 = {}
    local v28

    for v29, v30 in lines(p8) do
        local t4 = {}
        local v31 = string.find(v30, "//", 1, true)
        local v32 = if v31 == nil then v30 else string.sub(v30, 1, v31 - 1)

        for match in string.gmatch(ascii_whitespace(v32), "%S+") do
            table.insert(t4, match)
        end

        if #t4 ~= 0 then
            local function fail() -- line: 133
                -- upvalues: v30 (copy), v29 (copy)
                return string.format("invalid PAT directive at line %d: %s", v29, v30)
            end

            local function number(p9) -- line: 137
                -- upvalues: t4 (copy), v30 (copy), v29 (copy), parse_f32 (copy)
                local v34 = t4[p9 + 1]

                if v34 == nil then
                    error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
                end

                local v35 = parse_f32(v34)

                if v35 == nil then
                    error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
                end

                if v35 ~= v35 or v35 == 1e999 or v35 == (-1e999) then
                    error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
                end

                return v35
            end

            local v36 = t4[1]

            if v36 == "global_tolerance_dist" and #t4 == 2 then
                local v37 = number(1)

                v28 = v37 * v37
            elseif (v36 == "global_tolerance_time" or v36 == "global_tolerance_speed" or v36 == "global_anticipation_delay" or v36 == "tolerance_time") and #t4 == 2 then
                number(1)
            elseif v36 == "pattern" and #t4 == 2 then
                if v28 == nil then
                    error("PAT lacks global_tolerance_dist", 0)
                end

                table.insert(t3, {
                    name = t4[2],
                    points = {},
                    tolerance_squared = v28
                })
            elseif v36 == "tolerance_dist" and #t4 == 2 then
                local v38 = number(1)
                local v39 = t3[#t3]

                if v39 == nil then
                    error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
                end

                v39.tolerance_squared = v38 * v38
            elseif v36 == "coord" and #t4 == 3 then
                local t6 = {
                    number(1),
                    (number(2))
                }
                local v40 = t3[#t3]

                if v40 == nil then
                    error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
                end

                table.insert(v40.points, t6)
            else
                error(string.format("invalid PAT directive at line %d: %s", v29, v30), 0)
            end
        end
    end

    v9.Recognizer.new(rt.copy(t3))

    return t3
end

return t1
