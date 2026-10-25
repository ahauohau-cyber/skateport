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

local import = require(sim.import)
local State = import("skate_core/animation/intent_filter").State
local IntentMap = import("skate_core/graph/intents").IntentMap
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v8 = import("skate_core/animation/playback_parameters")
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p4) -- line: 45
    -- upvalues: v1 (copy), Attributes (copy), t1 (copy)
    local function number(p5, p6) -- line: 46
        -- upvalues: p4 (copy), v1 (copy), Attributes (copy)
        local float_bits = Attributes.float_bits
        local v9

        if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
            local v10 = math.abs(p6) * 7.1362384635298E+44
            local v11 = math.floor(v10)
            local v12 = v10 - v11

            v9 = if v12 > 0.5 or v12 == 0.5 and v11 % 2 == 1 then v11 + 1 else v11

            if p6 < 0 then
                v9 += 2147483648
            end
        else
            buffer.writef32(v1, 0, p6)
            v9 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (float_bits(p4, p5, v9)))

        return (buffer.readf32(v1, 0))
    end

    local function optional(p7) -- line: 49
        -- upvalues: p4 (copy), v1 (copy), Attributes (copy)
        local v14 = Attributes.get(p4, p7)

        if v14 == nil then
            return nil
        end

        buffer.writeu32(v1, 0, v14.float_bits)

        return (buffer.readf32(v1, 0))
    end

    local float_bits = Attributes.float_bits

    buffer.writef32(v1, 0, 1)
    buffer.writeu32(v1, 0, (float_bits(p4, "blend", (buffer.readu32(v1, 0)))))

    local v16 = buffer.readf32(v1, 0)
    local intent = Attributes.text(p4, "intent")

    if intent == nil then
        intent = ""
    end

    local filteredIntent = Attributes.text(p4, "filteredIntent")

    if filteredIntent == nil then
        filteredIntent = ""
    end

    local float_bits2 = Attributes.float_bits

    buffer.writef32(v1, 0, 0)
    buffer.writeu32(v1, 0, (float_bits2(p4, "startingValue", (buffer.readu32(v1, 0)))))

    local v18 = buffer.readf32(v1, 0)
    local float_bits3 = Attributes.float_bits

    buffer.writef32(v1, 0, 0)
    buffer.writeu32(v1, 0, (float_bits3(p4, "defaultValue", (buffer.readu32(v1, 0)))))

    local v20 = buffer.readf32(v1, 0)
    local float_bits4 = Attributes.float_bits

    buffer.writef32(v1, 0, 1)
    buffer.writeu32(v1, 0, (float_bits4(p4, "scale", (buffer.readu32(v1, 0)))))

    local v22 = buffer.readf32(v1, 0)
    local filter1 = Attributes.text(p4, "filter1")

    if filter1 == nil then
        filter1 = Attributes.text(p4, "filter")
    end

    local t2 = {
        t1.filter(filter1),
        t1.filter(Attributes.text(p4, "filter2")),
        t1.filter(Attributes.text(p4, "fakieFilter")),
        t1.filter(Attributes.text(p4, "mirrorFilter"))
    }
    local t3 = {
        intent = intent,
        filtered_intent = filteredIntent
    }
    local t4 = {
        starting_value = v18,
        default_value = v20,
        scale = v22,
        filters = t2
    }
    local rampTime = Attributes.get(p4, "rampTime")

    if rampTime ~= nil then
        buffer.writeu32(v1, 0, rampTime.float_bits)
        t4.ramp_time = buffer.readf32(v1, 0)
    else
        t4.ramp_time = nil
    end

    local float_bits5 = Attributes.float_bits
    local v23

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v24 = math.abs(v16) * 7.1362384635298E+44
        local v25 = math.floor(v24)
        local v26 = v24 - v25

        v23 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

        if v16 < 0 then
            v23 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v23 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (float_bits5(p4, "blendRising", v23)))
    t4.blend_rising = buffer.readf32(v1, 0)

    local float_bits6 = Attributes.float_bits
    local v28

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v29 = math.abs(v16) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

        if v16 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v28 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (float_bits6(p4, "blendFalling", v28)))
    t4.blend_falling = buffer.readf32(v1, 0)

    local blendOut = Attributes.get(p4, "blendOut")

    if blendOut ~= nil then
        buffer.writeu32(v1, 0, blendOut.float_bits)
        t4.blend_out = buffer.readf32(v1, 0)
    else
        t4.blend_out = nil
    end

    local clampVel = Attributes.get(p4, "clampVel")

    if clampVel ~= nil then
        buffer.writeu32(v1, 0, clampVel.float_bits)
        t4.clamp_velocity = buffer.readf32(v1, 0)
    else
        t4.clamp_velocity = nil
    end

    local clampAcc = Attributes.get(p4, "clampAcc")

    if clampAcc ~= nil then
        buffer.writeu32(v1, 0, clampAcc.float_bits)
        t4.clamp_acceleration = buffer.readf32(v1, 0)
    else
        t4.clamp_acceleration = nil
    end

    t3.settings = t4

    return t3
end

function t1.Operation.begin(p8, p9, p10) -- line: 98
    -- upvalues: State (copy), IntentMap (copy)
    IntentMap.insert(p10, p8.filtered_intent, State.begin(p9, p8.settings))
end

function t1.Operation.update(p11, p12, p13, p14, p15, p16) -- line: 103
    -- upvalues: State (copy), IntentMap (copy)
    local v33 = State.update(p12, p11.settings, IntentMap.get(p13, p11.intent), p15, p16)

    IntentMap.insert(p14, p11.filtered_intent, v33)
end

t1.Operation["end"] = function(p17, p18) -- line: 110
    -- upvalues: IntentMap (copy)
    IntentMap.remove(p18, p17.filtered_intent)
end

function t1.filter(p19) -- line: 115
    -- upvalues: v8 (copy)
    local intent_key = v8.intent_key
    local v34 = intent_key(if p19 == nil then "none" else p19)
    local t5 = {
        "negate",
        "abs",
        "oneMinus",
        "clamp",
        "angleFlip",
        "angleRot90",
        "angleRotN90"
    }

    for i = 0, #t5 - 1 do
        local v35 = intent_key(t5[i + 1])
        local v36 = true

        for j = 1, 6 do
            if v35[j] ~= v34[j] then
                v36 = false
                break
            end
        end

        if v36 then
            return i + 1
        end
    end

    return 0
end

return t1
