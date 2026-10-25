-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    BUCKET_COUNT = 61,
    ENTRY_CAPACITY = 64,
    IntentName = {}
}

function t1.IntentName.eq(p1, p2) -- line: 23
    local v1 = p1[1]
    local v2 = p2[1]

    if v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3] and v1[4] == v2[4] and v1[5] == v2[5] then
        return v1[6] == v2[6]
    end

    return false
end

t1.Intent = {}

function t1.Intent.eq(p3, p4) -- line: 37
    -- upvalues: t1 (copy)
    return t1.IntentName.eq(p3.name, p4.name) and p3.value == p4.value
end

t1.IntentCapacityExceeded = {}
t1.IntentMap = {}

function t1.IntentMap.default() -- line: 53
    -- upvalues: rt (copy), t1 (copy)
    return {
        len = 0,
        buckets = rt.from_fn(t1.BUCKET_COUNT, function(_) -- line: 55
            return {}
        end)
    }
end

local function hash_name(p6) -- line: 63
    -- upvalues: rt (copy)
    local v3 = p6[1]
    local n1 = 0

    for i = 1, 6 do
        n1 = rt.wrapping_add_u32(n1, v3[i])
    end

    return n1
end

function t1.IntentMap.len(p7) -- line: 72
    return p7.len
end

function t1.IntentMap.is_empty(p8) -- line: 75
    return p8.len == 0
end

function t1.IntentMap.get(p9, p10) -- line: 79
    -- upvalues: rt (copy), t1 (copy), hash_name (copy)
    local v4 = hash_name(p10)
    local v5 = p9.buckets[rt.irem(v4, t1.BUCKET_COUNT) + 1]

    for _, v6 in ipairs(v5) do
        if t1.IntentName.eq(v6.name, p10) then
            return v6.value
        end
    end

    return nil
end

function t1.IntentMap.entries(p11) -- line: 92
    -- upvalues: t1 (copy)
    local t3 = {}

    for i = 1, t1.BUCKET_COUNT do
        for _, v7 in ipairs(p11.buckets[i]) do
            table.insert(t3, v7)
        end
    end

    return t3
end

function t1.IntentMap.insert(p12, p13) -- line: 106
    -- upvalues: rt (copy), t1 (copy), hash_name (copy)
    local v8 = hash_name(p13.name)
    local v9 = p12.buckets[rt.irem(v8, t1.BUCKET_COUNT) + 1]

    for _, v10 in ipairs(v9) do
        if t1.IntentName.eq(v10.name, p13.name) then
            return false
        end
    end

    if p12.len == t1.ENTRY_CAPACITY then
        error("IntentCapacityExceeded", 0)
    end

    table.insert(v9, 1, p13)
    p12.len += 1

    return true
end

function t1.IntentMap.set(p14, p15, p16) -- line: 126
    -- upvalues: rt (copy), t1 (copy), hash_name (copy)
    local v11 = hash_name(p15)
    local v12 = p14.buckets[rt.irem(v11, t1.BUCKET_COUNT) + 1]

    for _, v13 in ipairs(v12) do
        if t1.IntentName.eq(v13.name, p15) then
            v13.value = p16

            return false
        end
    end

    return t1.IntentMap.insert(p14, {
        name = rt.copy(p15),
        value = p16
    })
end

function t1.IntentMap.remove(p17, p18) -- line: 141
    -- upvalues: rt (copy), t1 (copy), hash_name (copy)
    local v14 = hash_name(p18)
    local v15 = p17.buckets[rt.irem(v14, t1.BUCKET_COUNT) + 1]
    local v16

    for v17, v18 in ipairs(v15) do
        if t1.IntentName.eq(v18.name, p18) then
            v16 = v17
            break
        end
    end

    if v16 == nil then
        return false
    end

    table.remove(v15, v16)
    p17.len -= 1

    return true
end

function t1.IntentMap.apply(p19, p20, p21) -- line: 162
    -- upvalues: t1 (copy)
    if p21.tag == "None" then
        return false
    end

    if p21.tag == "Remove" then
        return t1.IntentMap.remove(p19, p20)
    end

    return t1.IntentMap.set(p19, p20, p21[1])
end

function t1.IntentMap.clear(p22) -- line: 173
    -- upvalues: t1 (copy)
    for i = 1, t1.BUCKET_COUNT do
        table.clear(p22.buckets[i])
    end

    p22.len = 0
end

function t1.IntentMap.replace_from(p23, p24) -- line: 184
    -- upvalues: rt (copy), t1 (copy)
    t1.IntentMap.clear(p23)

    for _, v19 in ipairs(t1.IntentMap.entries(p24)) do
        local insert = t1.IntentMap.insert
        local copy = rt.copy

        if not pcall(insert, p23, copy(v19)) then
            error("bounded intent map assignment", 0)
        end
    end
end

return t1
