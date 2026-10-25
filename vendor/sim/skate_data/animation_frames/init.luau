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

local import = require(sim.import)
local v2 = import("skate_data/animation_metadata")
local v3 = import("skate_data/abin")
local v4 = import("skate_data/animation_frames/native")
local AnimationMetadata = v2.AnimationMetadata
local Bank = v3.Bank
local NativeFrames = v4.NativeFrames
local v5
local t1 = {}

t1.ClipFrames = {}
t1.ClipFrames.is_packed = v4.ClipFrames.is_packed
t1.ClipFrames.frame_count = v4.ClipFrames.frame_count
t1.ClipFrames.word = v4.ClipFrames.word
t1.ClipFrames.frames_table = v4.ClipFrames.frames_table
t1.ReferencePose = {}
t1.File = {}

local function check_fields(p3, p4, p5) -- line: 57
    if type(p3) ~= "table" then
        error(string.format("invalid type: expected struct %s", p4), 0)
    end

    local t2 = {}

    for _, v6 in p5 do
        t2[v6] = true

        if p3[v6] == nil then
            error(string.format("missing field `%s`", v6), 0)
        end
    end

    for v7 in p3 do
        if not t2[v7] then
            error(string.format("unknown field `%s`", (tostring(v7))), 0)
        end
    end
end

function t1.File.from_json(p6) -- line: 76
    -- upvalues: check_fields (copy)
    local function v8() -- line: 77
        -- upvalues: p6 (copy)
        return game:GetService("HttpService"):JSONDecode(p6)
    end

    local ok, result = pcall(v8)

    if not ok then
        error(tostring(result), 0)
    end

    check_fields(result, "File", {
        "version",
        "source_sha256",
        "decoder_sha256",
        "decoder_hardware_verified",
        "parents",
        "bone_names",
        "mirror_indices",
        "has_trajectory",
        "clips",
        "reference_poses"
    })

    for _, v9 in result.clips do
        check_fields(v9, "ClipFrames", { "name", "source_offset", "fps_bits", "loop_translation_bits", "loop_rotation_bits", "channel_animation", "channel_weights", "frames" })

        if #v9.loop_translation_bits ~= 3 then
            error("invalid length, expected an array of length 3", 0)
        end

        if #v9.loop_rotation_bits ~= 4 then
            error("invalid length, expected an array of length 4", 0)
        end

        for _, v10 in v9.frames do
            for _, v11 in v10 do
                if #v11 ~= 10 then
                    error("invalid length, expected an array of length 10", 0)
                end
            end
        end
    end

    for _, v12 in result.reference_poses do
        check_fields(v12, "ReferencePose", { "name", "source_offset", "samples" })

        for _, v13 in v12.samples do
            if #v13 ~= 10 then
                error("invalid length, expected an array of length 10", 0)
            end
        end
    end

    return result
end

t1.AnimationFrames = {}

function t1.AnimationFrames.from_banks(p7) -- line: 140
    -- upvalues: rt (copy), Bank (copy), NativeFrames (copy)
    local v14 = Bank.hierarchy(p7.banks[1])

    if v14 == nil then
        error("Missing animation hierarchy", 0)
    end

    return {
        decoder_sha256 = "",
        decoder_hardware_verified = false,
        source_sha256 = p7.identities[1],
        parents = rt.copy(v14.parents),
        bone_names = rt.copy(v14.bone_names),
        mirror_indices = rt.copy(v14.mirrors),
        has_trajectory = v14.has_trajectory,
        clips = {},
        reference_poses = {},
        native = NativeFrames.new(p7)
    }
end

function t1.AnimationFrames.load(p8, _) -- line: 161
    error(string.format("Cannot read %s: no file access in Roblox (use AnimationFrames.from_banks)", (tostring(p8))), 0)
end

function t1.AnimationFrames.parse(p10, p11) -- line: 166
    -- upvalues: v1 (copy), AnimationMetadata (copy), t1 (copy), v5 (ref)
    local v15 = t1.File.from_json(p10)

    if v15.version ~= 3 or v15.source_sha256 ~= p11.source_sha256 then
        error("Animation sample format or stock bank identity differs from metadata", 0)
    end

    if #v15.decoder_sha256 ~= 64 or string.match(v15.decoder_sha256, "^%x*$") == nil then
        error("Animation sample decoder identity is invalid", 0)
    end

    local v16 = #v15.parents

    if v16 == 0 or v16 > 255 then
        error("Animation sample hierarchy has invalid bone count", 0)
    end

    for v17, v18 in v15.parents do
        local v19 = v17 - 1

        if v18 < -1 or v19 <= v18 then
            error(string.format("Animation bone%d has invalid parent%d", v19, v18), 0)
        end
    end

    if #v15.bone_names ~= v16 or #v15.mirror_indices ~= v16 then
        error("Animation hierarchy names/mirrors are incomplete", 0)
    end

    local t3 = {}

    for i = 0, math.min(#v15.mirror_indices, #v15.bone_names) - 1 do
        local v22 = v15.mirror_indices[i + 1]
        local v23 = v15.bone_names[i + 1]
        local v24 = #v23 == 0

        if not v24 then
            if t3[v23] then
                v24 = true
            else
                t3[v23] = true
            end
        end

        if v24 or v22 < -1 or v16 <= v22 or v22 >= 0 and v15.mirror_indices[v22 + 1] ~= i then
            error(string.format("Animation bone%d has an invalid name/mirror mapping", i), 0)
        end
    end

    local t4 = {}

    for _, v25 in v15.clips do
        local v26 = AnimationMetadata.clip(p11, v25.name)

        if v26.source_offset == v25.source_offset and v26.fps_bits == v25.fps_bits then
            buffer.writeu32(v1, 0, v26.frames_bits)

            if buffer.readf32(v1, 0) ~= #v25.frames or v25.channel_animation ~= (bit32.band(v26.flags_word, 536870912) ~= 0) then
                error(string.format("%s: decoded samples disagree with stock clip header", v25.name), 0)
            end
        else
            error(string.format("%s: decoded samples disagree with stock clip header", v25.name), 0)
        end

        local v27 = #v25.channel_weights ~= v16

        if not v27 then
            for _, v28 in v25.channel_weights do
                buffer.writeu32(v1, 0, v28)

                local v29 = buffer.readf32(v1, 0)

                if v29 ~= v29 or v29 == 1e999 or v29 == (-1e999) then
                    v27 = true
                    break
                end
            end
        end

        if not v27 then
            for _, v30 in v25.loop_translation_bits do
                buffer.writeu32(v1, 0, v30)

                local v31 = buffer.readf32(v1, 0)

                if v31 ~= v31 or v31 == 1e999 or v31 == (-1e999) then
                    v27 = true
                    break
                end
            end
        end

        if not v27 then
            for _, v32 in v25.loop_rotation_bits do
                buffer.writeu32(v1, 0, v32)

                local v33 = buffer.readf32(v1, 0)

                if v33 ~= v33 or v33 == 1e999 or v33 == (-1e999) then
                    v27 = true
                    break
                end
            end
        end

        if v27 then
            error(string.format("%s: invalid loop transform or missing channel weights", v25.name), 0)
        end

        for _, v34 in v25.frames do
            v5(v34, v16)
        end

        local name = v25.name

        if t4[name] ~= nil then
            error(string.format("Duplicate decoded clip%s", name), 0)
        end

        t4[name] = v25
    end

    local t5 = {}

    for _, v35 in v15.reference_poses do
        v5(v35.samples, v16)

        if v35.name ~= "RIG_TPOSE" and v35.name ~= "BOARD_BACKWARDS" and v35.name ~= "BOARD_BACKWARDS_IK" or t5[v35.source_offset] ~= nil then
            error("Invalid or duplicated reference-pose source record", 0)
        end

        t5[v35.source_offset] = v35
    end

    return {
        native = nil,
        source_sha256 = v15.source_sha256,
        decoder_sha256 = v15.decoder_sha256,
        decoder_hardware_verified = v15.decoder_hardware_verified,
        parents = v15.parents,
        bone_names = v15.bone_names,
        mirror_indices = v15.mirror_indices,
        has_trajectory = v15.has_trajectory,
        clips = t4,
        reference_poses = t5
    }
end

function t1.AnimationFrames.clip(p12, p13) -- line: 283
    -- upvalues: NativeFrames (copy)
    if p12.native ~= nil then
        return NativeFrames.clip(p12.native, p13)
    end

    local v36 = p12.clips[string.upper(p13)]

    if v36 == nil then
        error(string.format("Required decoded stock clip is absent: %s", p13), 0)
    end

    return v36
end

function t1.AnimationFrames.warm(p14, p15, p16, p17) -- line: 304
    -- upvalues: t1 (copy)
    local t6 = {}

    p16 = p16 or 1

    local v40 = math.min(p17 or #p15, #p15)
    local n1 = 0

    for i = p16, v40 do
        local v41 = p15[i]
        local clip = t1.AnimationFrames.clip
        local ok, result = pcall(clip, p14, v41)

        if ok then
            n1 += 1
        else
            t6[v41] = tostring(result)
        end
    end

    return n1, t6
end

function t1.AnimationFrames.reference_pose(p18, p19) -- line: 321
    -- upvalues: NativeFrames (copy)
    if p18.native ~= nil then
        return NativeFrames.reference_pose(p18.native, 0, p19)
    end

    local v42 = p18.reference_poses[p19]

    if v42 == nil then
        error(string.format("Required reference-pose record0x%x is absent", p19), 0)
    end

    return v42
end

function t1.AnimationFrames.named_pose(p20, p21) -- line: 335
    -- upvalues: t1 (copy)
    return t1.AnimationFrames.named_pose_in(p20, 0, p21)
end

function t1.AnimationFrames.named_pose_in(p22, p23, p24) -- line: 339
    -- upvalues: NativeFrames (copy)
    if p22.native ~= nil then
        return NativeFrames.named_pose(p22.native, p23, p24)
    end

    if p23 ~= 0 then
        error("Converted animation data contains only one bank", 0)
    end

    local t7 = {}

    for v43 in p22.reference_poses do
        table.insert(t7, v43)
    end

    table.sort(t7)

    for i = #t7, 1, -1 do
        local v44 = p22.reference_poses[t7[i]]

        if string.upper(v44.name) == string.upper(p24) then
            return v44
        end
    end

    error(string.format("Required stock reference pose is absent: %s", p24), 0)
end

function t1.AnimationFrames.clip_count(p25) -- line: 362
    -- upvalues: NativeFrames (copy)
    if p25.native ~= nil then
        return NativeFrames.clip_count(p25.native)
    end

    local n2 = 0

    for _ in p25.clips do
        n2 += 1
    end

    return n2
end

function t1.AnimationFrames.clip_names(p26) -- line: 375
    -- upvalues: NativeFrames (copy)
    if p26.native ~= nil then
        return NativeFrames.clip_names(p26.native)
    end

    local t8 = {}

    for v45 in p26.clips do
        table.insert(t8, v45)
    end

    table.sort(t8)

    return t8
end

function t1.AnimationFrames.clip_bank(p27, p28) -- line: 387
    -- upvalues: NativeFrames (copy), t1 (copy)
    if p27.native ~= nil then
        return NativeFrames.clip_bank(p27.native, p28)
    end

    t1.AnimationFrames.clip(p27, p28)

    return 0
end

v5 = function(p29, p30) -- line: 398
    local v46 = #p29 ~= p30

    if not v46 then
        local v47 = v46

        for _, v48 in p29 do
            for i = 1, #v48 do
                if bit32.band(v48[i], 2139095040) == 2139095040 then
                    v47 = true
                    break
                end
            end

            if v47 then
                v46 = v47
                break
            end

            v46 = v47
        end
    end

    if v46 then
        error("Decoded stock frame is incomplete or nonfinite", 0)
    end
end

t1.validate_samples = v5

return t1
