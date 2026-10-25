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
local v2 = import("skate_core/animation/playback_clip")
local AnimationMetadata = import("skate_data/animation_metadata").AnimationMetadata
local t1 = {
    MotionAnimation = {}
}

local function path_file_stem(p2) -- line: 27
    local v3 = string.gsub(p2, "[/\\]+$", "")
    local v4 = string.match(v3, "([^/\\]*)$") or ""

    if v4 == "" or v4 == ".." then
        return ""
    end

    local v5 = string.match(v4, "^(.*)%.[^%.]*$")

    if v5 == nil or v5 == "" then
        return v4
    end

    return v5
end

function t1.MotionAnimation.stock_clip_translation_z(p3, p4, p5) -- line: 42
    -- upvalues: v1 (copy), v2 (copy), AnimationMetadata (copy), path_file_stem (copy)
    local v6 = AnimationMetadata.source_for(p3.metadata, p5)

    if v6 == nil then
        return 0
    end

    local v7 = path_file_stem(v6.source_bank)

    if string.lower(v7) ~= string.lower(p4) then
        return 0
    end

    local v8

    for _, v9 in AnimationMetadata.clip(p3.metadata, p5).attributes do
        if string.lower(v9.name) == "animtransz" then
            v8 = v9
            break
        end
    end

    if v8 == nil then
        return 0
    end

    local type_id = v8.type_id

    if type_id ~= 0 and type_id ~= 1 and type_id ~= 3 then
        if type_id == 2 then
            return v2.sample_curve(v8.payload_words, 0)
        end

        return 0
    end

    local v10 = v8.payload_words[1]

    if v10 == nil then
        error(string.format("%s/%s: truncated AnimTransZ", p4, p5), 0)
    end

    buffer.writeu32(v1, 0, v10)

    return (buffer.readf32(v1, 0))
end

return t1
