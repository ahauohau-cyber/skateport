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

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local AnimationMetadata = require(sim.import)("skate_data/animation_metadata").AnimationMetadata
local t1 = {
    CLIPS = { "NB_WALK_FWD_CYC", "NB_RUN_FWD_CYC", "NB_SPRINT_FWD_CYC" }
}
local CLIPS = t1.CLIPS

function t1.metric(p5) -- line: 49
    -- upvalues: v1 (copy)
    local v9

    for _, v10 in ipairs(p5.attributes) do
        if v10.name == "ANIMTRANSZ" then
            v9 = v10
            break
        end
    end

    if v9 == nil then
        return nil
    end

    if v9.type_id ~= 0 then
        error(string.format("%s: AnimTransZ expected scalar stock record", p5.name), 0)
    end

    local v11 = v9.payload_words[1]

    if v11 == nil then
        error(string.format("%s: truncated AnimTransZ", p5.name), 0)
    end

    buffer.writeu32(v1, 0, v11)

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5.frames_bits)

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5.fps_bits)

    local v14 = v13 / buffer.readf32(v1, 0)
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

    buffer.writeu32(v1, 0, v9.end_bits)

    local v19 = buffer.readf32(v1, 0) * v15
    local v20

    if v19 ~= 0 and v19 > -1.1754943508222875E-38 and v19 < 1.1754943508222875E-38 then
        local v21 = math.abs(v19) * 7.1362384635298E+44
        local v22 = math.floor(v21)
        local v23 = v21 - v22

        v20 = (if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22) * 1.401298464324817E-45

        if v19 < 0 then
            v20 = -v20
        end
    else
        buffer.writef32(v1, 0, v19)
        v20 = buffer.readf32(v1, 0)
    end

    if v12 ~= v12
        or v12 == 1e999
        or v12 == (-1e999)
        or v20 ~= v20
        or v20 == 1e999
        or v20 == (-1e999)
        or v20 == 0 then
        error(string.format("%s: invalid AnimTransZ metric", p5.name), 0)
    end

    return {
        translation_z = v12,
        end_time = v20
    }
end

function t1.load(p6) -- line: 85
    -- upvalues: AnimationMetadata (copy), t1 (copy), CLIPS (copy)
    local function one(p7) -- line: 86
        -- upvalues: p6 (copy), AnimationMetadata (copy), t1 (copy)
        local v24 = AnimationMetadata.clip(p6, p7)
        local v25 = AnimationMetadata.source_for(p6, p7)

        if v25 == nil then
            error(string.format("Missing bank identity for %s", p7), 0)
        end

        if string.lower(v25.source_bank) ~= string.lower("OffBoard.abin") then
            error(string.format("%s: expected actual OffBoard.abin source", p7), 0)
        end

        return t1.metric(v24)
    end

    local v26 = one(CLIPS[1])
    local v27 = one(CLIPS[2])
    local v28 = one(CLIPS[3])
    local v29 = table.create(3)

    v29[1] = v26
    v29[2] = v27
    v29[3] = v28

    return v29
end

return t1
