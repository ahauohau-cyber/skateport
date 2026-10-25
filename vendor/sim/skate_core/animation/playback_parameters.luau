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

local import = require(sim.import)
local v2 = import("skate_core/animation/skeleton_input/name")
local eq = import("skate_core/animation/output/attributes").AttributeName.eq
local t1 = {}

t1.ParameterSource = {}
t1.PlaybackParameter = {}
t1.SettableAttribute = {}

function t1.SettableAttribute.eq(p2, p3) -- line: 37
    -- upvalues: eq (copy)
    return eq(p2.name, p3.name) and p2.value == p3.value and p2.normalized == p3.normalized and p2.sequence_id == p3.sequence_id
end

t1.ParameterInputs = {}
t1.AttributeSink = {}
t1.SettableAttributes = {}

function t1.SettableAttributes.default() -- line: 60
    return {
        entries = {}
    }
end

function t1.SettableAttributes.entries(p4) -- line: 64
    return p4.entries
end

function t1.SettableAttributes.clear(p5) -- line: 68
    table.clear(p5.entries)
end

function t1.SettableAttributes.set_attribute(p6, p7) -- line: 73
    -- upvalues: rt (copy), eq (copy)
    local v3

    for _, v4 in p6.entries do
        if eq(v4.name, p7.name) and v4.sequence_id == p7.sequence_id then
            v3 = v4
            break
        end
    end

    if v3 ~= nil then
        rt.assign(v3, p7)
    else
        table.insert(p6.entries, rt.copy(p7))
    end
end

function t1.PlaybackParameter.update(p8, p9, p10, p11) -- line: 91
    -- upvalues: rt (copy), v1 (copy), v2 (copy)
    local encode = v2.encode
    local tag = p8.source.tag
    local v5, v6, v7

    if tag == "MotionIntent" then
        local v8 = p8.source[1]
        local v9 = if p8.rename == nil then encode(v8) else rt.copy(p8.rename)

        v5 = p10.motion_intent(p10, v8)

        if v5 == nil then
            v5 = p8.default_value
        end

        v7 = v9
        v6 = p8.normalized
    elseif tag == "FilteredIntent" then
        local v10 = p8.source[1]
        local v11 = p10.filtered_intent(p10, v10)

        v7 = if p8.rename ~= nil then rt.copy(p8.rename) else encode(v10)
        v5 = if v11 ~= nil then v11 else p8.default_value
        v6 = v11 ~= nil and p8.normalized
    else
        local v12 = p8.source[1]

        if not p9 then
            return
        end

        local v13 = p10.last_attribute(p10, rt.copy(v12))

        if v13 ~= nil then
            if v13.kind ~= 0 and v13.kind ~= 2 then
                return
            end

            local v14 = v13.payload[1][1]

            if v14 == nil then
                error("Last animation scalar payload is uninitialized", 0)
            end

            buffer.writeu32(v1, 0, v14)
            v5 = buffer.readf32(v1, 0)
        else
            v5 = p8.default_value
        end

        v7 = if p8.rename ~= nil then rt.copy(p8.rename) else rt.copy(v12)
        v6 = false
    end

    if v5 ~= nil then
        p11.set_attribute(p11, {
            sequence_id = -1,
            name = v7,
            value = v5,
            normalized = v6
        })
    end
end

function t1.intent_key(p12) -- line: 148
    -- upvalues: v2 (copy)
    local v15 = v2.encode(p12)[1]
    local v16 = if not (#p12 > 30) or string.find(string.sub(p12, 1, 30), "\000", 1, true) ~= nil then 0 else v2.encode((string.sub(p12, 31)))[1][1]

    return {
        v15[1],
        v15[2],
        v15[3],
        v15[4],
        v15[5],
        v16
    }
end

return t1
