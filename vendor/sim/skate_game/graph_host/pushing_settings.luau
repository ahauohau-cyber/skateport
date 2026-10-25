-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local ClipClock = import("skate_core/animation/clip_clock").ClipClock
local encode = import("skate_core/animation/skeleton_input/name").encode
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local PushAttributes = import("skate_core/riding/push_behaviors").PushAttributes
local Collections = import("skate_data/collections").Collections
local AnimationMetadata = import("skate_data/animation_metadata").AnimationMetadata
local t1 = {
    PushTreeAttribute = {},
    PushTreeMetadata = {},
    PushTreeSource = {},
    AnimationMetadata = {}
}

function t1.AnimationMetadata.metadata(p2, p3, p4) -- line: 46
    -- upvalues: v1 (copy), ClipClock (copy), AnimationMetadata (copy)
    local v2 = AnimationMetadata.clip(p2, p3)

    buffer.writeu32(v1, 0, v2.frames_bits)

    local v3 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2.fps_bits)

    local v4 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2.base_speed_bits)

    local v5 = buffer.readf32(v1, 0)
    local v6 = (v3 - 1) / (v5 * 1 * v4)
    local t2 = {
        speed = 1,
        time = 0,
        previous_time = 0,
        loops_since_evaluation = 0,
        frames = v3,
        fps = v4,
        base_speed = v5,
        length = v6,
        looping = bit32.band(v2.flags_word, 268435456) ~= 0,
        phase_controlled = bit32.band(v2.flags_word, 1073741824) ~= 0
    }
    local t3 = {}

    for _, v7 in v2.attributes do
        buffer.writeu32(v1, 0, v7.begin_bits)

        local v8 = buffer.readf32(v1, 0)

        if v8 == -1 then
            if v7.type_id ~= 0 and v7.type_id ~= 1 and v7.type_id ~= 3 then
                error(string.format("%s: attribute %s needs type%d evaluation", p3, v7.name, v7.type_id), 0)
            end

            if v7.payload_words[1] == nil then
                error("index out of bounds: the len is 0 but the index is 0", 0)
            end

            local t4 = {}

            t4.name = v7.name
            buffer.writeu32(v1, 0, v7.payload_words[1])
            t4.first_payload = buffer.readf32(v1, 0)
            table.insert(t3, t4)
        else
            local attribute_status = ClipClock.attribute_status

            buffer.writeu32(v1, 0, v7.end_bits)

            local v10 = attribute_status(t2, v8, (buffer.readf32(v1, 0)))

            if bit32.band(p4, 28, v10) ~= 0 and bit32.band(p4, 3, v10) ~= 0 then
                if v7.type_id ~= 0 and v7.type_id ~= 1 and v7.type_id ~= 3 then
                    error(string.format("%s: attribute %s needs type%d evaluation", p3, v7.name, v7.type_id), 0)
                end

                if v7.payload_words[1] == nil then
                    error("index out of bounds: the len is 0 but the index is 0", 0)
                end

                local t5 = {}

                t5.name = v7.name
                buffer.writeu32(v1, 0, v7.payload_words[1])
                t5.first_payload = buffer.readf32(v1, 0)
                table.insert(t3, t5)
            end
        end
    end

    return {
        length = v6,
        attributes = t3
    }
end

t1.PushingSettings = {}

function t1.PushingSettings.load_stock(p5, p6) -- line: 113
    -- upvalues: import (copy), t1 (copy)
    local AnimationBanks = import("skate_data/animation_banks").AnimationBanks
    local v12 = AnimationBanks.metadata(AnimationBanks.load(p6))

    return t1.PushingSettings.load(p5, {
        metadata = function(_, p8, p9) -- metadata | line: 119
            -- upvalues: v12 (copy), t1 (copy)
            return t1.AnimationMetadata.metadata(v12, p8, p9)
        end
    })
end

function t1.PushingSettings.load(p10, p11) -- line: 126
    -- upvalues: Collections (copy), t1 (copy)
    local function float(p12) -- line: 127
        -- upvalues: p10 (copy), Collections (copy)
        return Collections.float(p10, "anim_motion", "pushing", p12)
    end

    return {
        curves = {
            button_time_max = t1.curve(p10, "button_time_max"),
            button_time_to_dv = t1.curve(p10, "button_time_to_dv"),
            blend_speed_over_frames = t1.curve(p10, "blend_speed_over_frames"),
            blend_acc_over_frames = t1.curve(p10, "blend_acc_over_frames")
        },
        teleport_window = Collections.float(p10, "anim_motion", "pushing", "pushing_usemaxpushfromteleporttime"),
        maximum_holding_acceleration = Collections.float(p10, "anim_motion", "pushing", "max_holding_acc"),
        out_speed_weight = Collections.float(p10, "anim_motion", "pushing", "dynamic_out_factor_speed_vs_acc"),
        maximum_out_factor = Collections.float(p10, "anim_motion", "pushing", "last_push_out_time"),
        regular = t1.attributes(p11, { "R_PUSHLSP_HSTR_N_0_CYC1", "R_PUSHHSP_HSTR_N_0_CYC1", "R_PUSHLSP_LSTR_N_0_CYC1", "R_PUSHHSP_LSTR_N_0_CYC1" }),
        mongo = t1.attributes(p11, { "R_PUSHLSP_HSTR_MONGO_0_CYC1", "R_PUSHHSP_HSTR_MONGO_0_CYC1", "R_PUSHLSP_LSTR_MONGO_0_CYC1", "R_PUSHHSP_LSTR_MONGO_0_CYC1" })
    }
end

function t1.PushingSettings.attributes(p13, p14, p15) -- line: 160
    if p14 == p15 then
        return p13.mongo
    end

    return p13.regular
end

function t1.curve(p16, p17) -- line: 169
    -- upvalues: v1 (copy), Collections (copy)
    local v13 = Collections.words(p16, "anim_motion", "pushing", p17, 20)
    local t7 = {}

    buffer.writeu32(v1, 0, v13[5])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[6])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[7])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[8])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[9])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[10])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[11])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[12])
    t7.x = {
        v15,
        v17,
        v19,
        v21,
        v23,
        v25,
        v27,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v13[13])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[14])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[15])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[16])

    local v36 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[17])

    local v38 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[18])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[19])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v13[20])
    t7.y = {
        v30,
        v32,
        v34,
        v36,
        v38,
        v40,
        v42,
        (buffer.readf32(v1, 0))
    }

    return t7
end

function t1.attributes(p18, p19) -- line: 196
    -- upvalues: encode (copy), AttributeName (copy), PushAttributes (copy)
    local t8 = {}
    local HStr_Vel_B = encode("HStr_Vel_B")
    local LStr_Vel_B = encode("LStr_Vel_B")
    local Vel_E = encode("Vel_E")

    for _, v44 in p19 do
        local v45 = p18.metadata(p18, v44, 15)
        local first_payload, first_payload2

        for _, v46 in v45.attributes do
            local v47 = encode(v46.name)

            if AttributeName.eq(v47, HStr_Vel_B) or AttributeName.eq(v47, LStr_Vel_B) then
                first_payload = v46.first_payload
            elseif AttributeName.eq(v47, Vel_E) then
                first_payload2 = v46.first_payload
            end
        end

        if first_payload == nil then
            error(v44 .. ": missing begin-velocity attribute", 0)
        end

        if first_payload2 == nil then
            error(v44 .. ": missing Vel_E attribute", 0)
        end

        table.insert(t8, {
            length = v45.length,
            begin_velocity = first_payload,
            end_velocity = first_payload2
        })
    end

    return PushAttributes.from_clips(t8)
end

return t1
