-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local intent_key = require(sim.import)("skate_core/animation/playback_parameters").intent_key
local t1 = {
    IntentMap = {}
}
local t2 = {}

local function key_string(p1) -- line: 29
    -- upvalues: intent_key (copy), t2 (copy)
    local v1 = t2[p1]

    if v1 ~= nil then
        return v1
    end

    local v2 = intent_key(p1)
    local v3 = string.format("%08X%08X%08X%08X%08X%08X", v2[1], v2[2], v2[3], v2[4], v2[5], v2[6])

    if type(p1) == "string" then
        t2[p1] = v3
    end

    return v3
end

function t1.IntentMap.default() -- line: 42
    return {
        values = {}
    }
end

function t1.IntentMap.eq(p2, p3) -- line: 47
    for v4, v5 in p2.values do
        if p3.values[v4] ~= v5 then
            return false
        end
    end

    for v6 in p3.values do
        if p2.values[v6] == nil then
            return false
        end
    end

    return true
end

function t1.IntentMap.new() -- line: 61
    -- upvalues: t1 (copy)
    return t1.IntentMap.default()
end

function t1.IntentMap.insert(p4, p5, p6) -- line: 66
    -- upvalues: intent_key (copy), t2 (copy)
    local v7 = t2[p5]

    if v7 == nil then
        local v8 = intent_key(p5)

        v7 = string.format("%08X%08X%08X%08X%08X%08X", v8[1], v8[2], v8[3], v8[4], v8[5], v8[6])

        if type(p5) == "string" then
            t2[p5] = v7
        end
    end

    local v10 = p4.values[v7]

    p4.values[v7] = p6

    return v10
end

function t1.IntentMap.get(p7, p8) -- line: 74
    -- upvalues: intent_key (copy), t2 (copy)
    local values = p7.values
    local v11 = t2[p8]

    if v11 == nil then
        local v12 = intent_key(p8)

        v11 = string.format("%08X%08X%08X%08X%08X%08X", v12[1], v12[2], v12[3], v12[4], v12[5], v12[6])

        if type(p8) == "string" then
            t2[p8] = v11
        end
    end

    return values[v11]
end

function t1.IntentMap.remove(p9, p10) -- line: 79
    -- upvalues: intent_key (copy), t2 (copy)
    local v14 = t2[p10]

    if v14 == nil then
        local v15 = intent_key(p10)

        v14 = string.format("%08X%08X%08X%08X%08X%08X", v15[1], v15[2], v15[3], v15[4], v15[5], v15[6])

        if type(p10) == "string" then
            t2[p10] = v14
        end
    end

    local v17 = p9.values[v14]

    p9.values[v14] = nil

    return v17
end

function t1.IntentMap.contains_key(p11, p12) -- line: 86
    -- upvalues: intent_key (copy), t2 (copy)
    local values = p11.values
    local v18 = t2[p12]

    if v18 == nil then
        local v19 = intent_key(p12)

        v18 = string.format("%08X%08X%08X%08X%08X%08X", v19[1], v19[2], v19[3], v19[4], v19[5], v19[6])

        if type(p12) == "string" then
            t2[p12] = v18
        end
    end

    return values[v18] ~= nil
end

function t1.IntentMap.clear(p13) -- line: 90
    table.clear(p13.values)
end

function t1.IntentMap.len(p14) -- line: 94
    local n1 = 0

    for _ in p14.values do
        n1 += 1
    end

    return n1
end

function t1.IntentMap.is_empty(p15) -- line: 102
    return next(p15.values) == nil
end

return t1
