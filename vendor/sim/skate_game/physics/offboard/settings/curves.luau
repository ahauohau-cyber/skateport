-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {}

local function u32_from_str_radix_16(p3) -- line: 27
    local v2 = if string.sub(p3, 1, 1) == "+" then string.sub(p3, 2) else p3

    if #v2 == 0 then
        error(#p3 == 0 and "cannot parse integer from empty string" or "invalid digit found in string", 0)
    end

    if string.find(v2, "^%x+$") == nil then
        error("invalid digit found in string", 0)
    end

    local v3 = tonumber(v2, 16)

    if v3 == nil then
        error("invalid digit found in string", 0)
    end

    if v3 > 4294967295 then
        error("number too large to fit in target type", 0)
    end

    return v3
end

function t1.parse(p4, p5) -- line: 52
    -- upvalues: rt (copy), v1 (copy), u32_from_str_radix_16 (copy)
    local v4, v5, v6

    if type(p4) == "number" then
        v4 = p4
        v5 = p4
        v6 = p5
    else
        v4 = p5
        v5 = p5
        v6 = p4
    end

    if type(v5) ~= "number" then
        error("curves.parse: the knot count N is required", 0)
    end

    local v7 = string.gsub(v6, "[ \t\n\011\012\r]", "")

    if v5 == 0 or string.find(v7, "[\128-\255]") ~= nil or #v7 ~= (v5 * 2 + 4) * 8 then
        error("Invalid native graph payload length", 0)
    end

    local v8 = table.create(v5 * 2 + 4)

    for i = 0, v5 * 2 + 4 - 1 do
        local v9 = i + 1

        buffer.writeu32(v1, 0, (u32_from_str_radix_16((string.sub(v7, i * 8 + 1, i * 8 + 8)))))
        v8[v9] = buffer.readf32(v1, 0)
    end

    for _, v11 in ipairs(v8) do
        if v11 ~= v11 or v11 == 1e999 or v11 == (-1e999) then
            error("Non-finite native graph value", 0)
        end
    end

    local t2 = {
        x = rt.from_fn(v5, function(p6) -- line: 78
            -- upvalues: v8 (copy)
            return v8[4 + p6 + 1]
        end),
        y = rt.from_fn(v5, function(p7) -- line: 81
            -- upvalues: v4 (ref), v8 (copy)
            return v8[v4 + 4 + p7 + 1]
        end)
    }

    for i = 1, v4 - 1 do
        if t2.x[i] > t2.x[i + 1] then
            error("Native graph X values are not ordered", 0)
        end
    end

    return t2, {
        v8[1],
        v8[2],
        v8[3],
        v8[4]
    }
end

function t1.load(p8, p9, p10, p11) -- line: 99
    -- upvalues: Collections (copy), t1 (copy)
    local v12, v13, v14, v15

    if type(p8) == "number" then
        v12 = p8
        v13 = p9
        v14 = p10
        v15 = p11
    else
        v12 = p11
        v13 = p8
        v14 = p9
        v15 = p10
    end

    if type(v12) ~= "number" then
        error("curves.load: the knot count N is required", 0)
    end

    local v16 = Collections.field(v13, v14, "default", v15)

    if v16.type_name ~= string.format("Sk8::PointNegGraphData%d", v12) then
        error(string.format("Expected PointNegGraphData%d at %s/default/%s", v12, v14, v15), 0)
    end

    local parse = t1.parse
    local data = v16.data
    local v17, v18, v19 = pcall(parse, v12, data)

    if not v17 then
        error(string.format("%s/default/%s: %s", v14, v15, (tostring(v18))), 0)
    end

    return v18, v19
end

return t1
