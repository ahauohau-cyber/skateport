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

require(sim.import)

local t1 = {
    AttributeName = {}
}

function t1.AttributeName.eq_reference(p3, p4) -- line: 39
    local v8 = p3[1]
    local v9 = p4[1]

    if v8[1] == v9[1] and v8[2] == v9[2] and v8[3] == v9[3] and v8[4] == v9[4] then
        return v8[5] == v9[5]
    end

    return false
end

function t1.AttributeName.eq(p5, p6) -- line: 49
    local v10 = p5[1]
    local v11 = p6[1]

    if v10[1] == v11[1] and v10[2] == v11[2] and v10[3] == v11[3] and v10[4] == v11[4] then
        return v10[5] == v11[5]
    end

    return false
end

t1.AttributePayload = {}

function t1.AttributePayload.eq(p7, p8) -- line: 65
    local v12 = p7[1]
    local v13 = p8[1]

    if v12[1] == v13[1] and v12[2] == v13[2] and v12[3] == v13[3] and v12[4] == v13[4] and v12[5] == v13[5] then
        return v12[6] == v13[6]
    end

    return false
end

t1.AnimationAttribute = {}

function t1.AnimationAttribute.eq(p9, p10) -- line: 82
    -- upvalues: t1 (copy)
    return t1.AttributePayload.eq(p9.payload, p10.payload) and p9.begin_time == p10.begin_time and p9.end_time == p10.end_time and t1.AttributeName.eq(p9.name, p10.name) and p9.status == p10.status and p9.kind == p10.kind and p9.sequence_id == p10.sequence_id
end

function t1.AnimationAttribute.copy_from(p11, p12) -- line: 94
    -- upvalues: rt (copy)
    p11.kind = p12.kind
    p11.name = rt.copy(p12.name)
    p11.begin_time = p12.begin_time
    p11.end_time = p12.end_time
    p11.status = p12.status
    p11.sequence_id = p12.sequence_id

    local v15 = if p11.kind == 0 or p11.kind == 2 then 1
        elseif p11.kind == 1 then 4
        elseif p11.kind == 3 then 6
        else 0
    local v16 = p11.payload[1]
    local v17 = p12.payload[1]

    for i = 1, v15 do
        v16[i] = v17[i]
    end
end

function t1.AnimationAttribute.copy_construct(p13) -- line: 120
    -- upvalues: rt (copy), t1 (copy)
    local v18 = rt.copy(p13)

    v18.payload = { {} }
    t1.AnimationAttribute.copy_from(v18, p13)

    return v18
end

t1.MotionGraphAttribute = {}

function t1.MotionGraphAttribute.eq(p14, p15) -- line: 132
    -- upvalues: t1 (copy)
    return t1.AttributeName.eq(p14.name, p15.name) and p14.value == p15.value
end

function t1.MotionGraphAttribute.to_animation(p16) -- line: 137
    -- upvalues: rt (copy), v1 (copy)
    local t2 = {
        {}
    }
    local v19 = t2[1]
    local value = p16.value
    local v20

    if value ~= 0 and value > -1.1754943508222875E-38 and value < 1.1754943508222875E-38 then
        local v21 = math.abs(value) * 7.1362384635298E+44
        local v22 = math.floor(v21)
        local v23 = v21 - v22

        v20 = if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22

        if value < 0 then
            v20 += 2147483648
        end
    else
        buffer.writef32(v1, 0, value)
        v20 = buffer.readu32(v1, 0)
    end

    v19[1] = v20

    return {
        begin_time = -1,
        end_time = -1,
        status = 6,
        kind = 0,
        sequence_id = -1,
        payload = t2,
        name = rt.copy(p16.name)
    }
end

t1.PacketAttributes = {}

function t1.PacketAttributes.default() -- line: 157
    return {
        active_len = 0,
        slots = {}
    }
end

function t1.PacketAttributes.entries(p17) -- line: 162
    -- upvalues: rt (copy)
    return rt.slice(p17.slots, 0, p17.active_len)
end

function t1.PacketAttributes.clear(p18) -- line: 166
    p18.active_len = 0
end

function t1.PacketAttributes.append(p19, p20) -- line: 170
    -- upvalues: t1 (copy)
    local v24 = p19.slots[p19.active_len + 1]

    if v24 ~= nil then
        t1.AnimationAttribute.copy_from(v24, p20)
    else
        table.insert(p19.slots, t1.AnimationAttribute.copy_construct(p20))
    end

    p19.active_len += 1
end

function t1.PacketAttributes.replace_from_reference(p21, p22, p23) -- line: 183
    -- upvalues: t1 (copy)
    t1.PacketAttributes.clear(p21)

    for _, v25 in ipairs(p22) do
        t1.PacketAttributes.append(p21, t1.MotionGraphAttribute.to_animation(v25))
    end

    for _, v26 in ipairs(p23) do
        t1.PacketAttributes.append(p21, v26)
    end
end

function t1.PacketAttributes.replace_from(p24, p25, p26) -- line: 202
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    t1.PacketAttributes.clear(p24)

    local slots = p24.slots

    for _, v27 in ipairs(p25) do
        local v28 = slots[p24.active_len + 1]

        if v28 ~= nil then
            local value = v27.value
            local v29

            if value == 0 then
                buffer.writef32(v1, 0, value)
                v29 = buffer.readu32(v1, 0)
            elseif value > -1.1754943508222875E-38 and value < 1.1754943508222875E-38 then
                local v30 = math.abs(value) * 7.1362384635298E+44

                v29 = math.floor(v30)

                local v31 = v30 - v29

                if v31 > 0.5 or v31 == 0.5 and v29 % 2 == 1 then
                    v29 += 1
                end

                if value < 0 then
                    v29 += 2147483648
                end
            else
                buffer.writef32(v1, 0, value)
                v29 = buffer.readu32(v1, 0)
            end

            local v32 = rt.copy(v27.name)

            v28.kind = 0
            v28.name = v32
            v28.begin_time = -1
            v28.end_time = -1
            v28.status = 6
            v28.sequence_id = -1
            v28.payload[1][1] = v29
            p24.active_len += 1
        else
            t1.PacketAttributes.append(p24, t1.MotionGraphAttribute.to_animation(v27))
        end
    end

    for _, v33 in ipairs(p26) do
        t1.PacketAttributes.append(p24, v33)
    end
end

return t1
