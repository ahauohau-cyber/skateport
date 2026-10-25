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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local v8 = import("skate_data/abin")
local Bank, Reader, RecordHeader, Clip = v8.Bank, v8.Reader, v8.RecordHeader, v8.Clip
local v9 = import("skate_data/animation_frames/native")
local AnimationFrames = import("skate_data/animation_frames").AnimationFrames
local VbrDecoder = import("skate_core/animation/vbr").VbrDecoder
local t2 = {
    __mode = "v"
}
local t1 = {}

t1.stats = {
    opened = 0,
    blocks = 0,
    completed = 0,
    fallbacks = 0
}

function t1.open(p5, p6, p7, p8) -- line: 83
    -- upvalues: rt (copy), v1 (copy), Bank (copy), Reader (copy), RecordHeader (copy), Clip (copy), v9 (copy), VbrDecoder (copy), t1 (copy), t2 (copy)
    local v10 = Bank.record_at(p7, p8)

    if v10 == nil then
        error("Missing clip source record", 0)
    end

    if v10.data.tag ~= "Clip" then
        error("Source record is not a clip", 0)
    end

    local v11 = v10.data[1]

    Bank.ensure(p7, v10.header.offset, v10.header.size)
    v9.require_vbr(RecordHeader.codec(v10.header))
    buffer.writeu32(v1, 0, v11.frame_count_bits)

    local v12 = buffer.readf32(v1, 0)

    if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) or v12 < 1 or rt.fract(v12) ~= 0 then
        error("invalid frame count", 0)
    end

    local v13 = rt.f_to_usize(v12)
    local v14 = Bank.hierarchy(p7)

    if v14 == nil then
        error("Missing stock hierarchy", 0)
    end

    local bone_count = v14.bone_count
    local parts = v11.parts

    if #parts ~= #v14.parts then
        error("Animation part count differs from hierarchy", 0)
    end

    local v15 = table.create(bone_count, false)
    local v16 = table.create(#parts)
    local v17 = table.create(#parts)
    local v18 = Bank.bytes(p7)

    for i = 1, #parts do
        local v19 = parts[i]
        local v20 = v14.parts[i]
        local part = v19.part

        if part == nil then
            error("Required stock animation part is absent", 0)
        end

        local v21 = VbrDecoder.new(v18, part.offset, part.compression_header_relative, part.compressed_data_relative)

        if VbrDecoder.frame_count(v21) ~= v13 or VbrDecoder.channel_count(v21) ~= v20.bone_count then
            error("codec frame/channel count disagrees with bank header", 0)
        end

        if v20.sqt_offset < 0 then
            error("Negative animation part offset", 0)
        end

        local sqt_offset = v20.sqt_offset
        local v22 = sqt_offset + v20.bone_count

        if bone_count < v22 then
            error("Overlapping animation parts", 0)
        end

        for j = sqt_offset, v22 - 1 do
            if v15[j + 1] then
                error("Overlapping animation parts", 0)
            end
        end

        for k = sqt_offset, v22 - 1 do
            v15[k + 1] = true
        end

        if not VbrDecoder.prepare_blocks(v21) then
            error("no block plan", 0)
        end

        v16[i] = v21
        v17[i] = sqt_offset * 40
    end

    for i = 1, bone_count do
        if not v15[i] then
            error("Incomplete animation hierarchy channels", 0)
        end
    end

    local create = table.create

    buffer.writef32(v1, 0, 1)

    local v23 = create(bone_count, (buffer.readu32(v1, 0)))

    if Clip.channel_animation(v11) then
        local v24 = Reader.new(v18)
        local parts2 = v14.parts

        for i = 1, math.min(#parts, #parts2) do
            local v27 = parts[i]
            local v28 = parts2[i]
            local part = v27.part

            if part == nil then
                error("Channel animation part is absent", 0)
            end

            local channel_weights = part.channel_weights

            if channel_weights == nil then
                error("Channel animation weights are absent", 0)
            end

            for j = 0, v28.bone_count - 1 do
                local v29 = Reader.u32(v24, channel_weights.start + j * 4)

                buffer.writeu32(v1, 0, v29)

                local v30 = buffer.readf32(v1, 0)

                if v30 ~= v30 or v30 == 1e999 or v30 == (-1e999) then
                    error("Nonfinite channel weight", 0)
                end

                v23[v28.sqt_offset + j + 1] = v29
            end
        end
    end

    local v32 = math.ceil(v13 / 8)

    t1.stats.opened += 1

    return {
        words = nil,
        name = v10.header.name,
        source_offset = p8,
        fps_bits = v11.fps_bits,
        loop_translation_bits = rt.slice(v11.loop_translation_words, 0, 3),
        loop_rotation_bits = rt.copy(v11.loop_rotation_words),
        channel_animation = Clip.channel_animation(v11),
        channel_weights = v23,
        block_words = table.create(v32),
        frame_count = v13,
        bone_count = bone_count,
        pending = {
            frames = setmetatable({
                p5
            }, t2),
            request = p6,
            decoders = v16,
            bases = v17,
            remaining = v32,
            block_count = v32
        }
    }
end

local function decode_block(p9, p10, p11) -- line: 208
    -- upvalues: VbrDecoder (copy)
    local v33 = p9.bone_count * 40
    local v35 = math.min(8, p9.frame_count - p11 * 8) * v33
    local v36 = buffer.create(v35)
    local decoders, bases = p10.decoders, p10.bases
    local n1 = 0

    for i = 1, #decoders do
        if VbrDecoder.decode_block_into(decoders[i], p11, v36, bases[i], v33) ~= 0 then
            n1 += 1
        end
    end

    if n1 ~= 0 then
        for i = 0, v35 - 4, 4 do
            if bit32.band(buffer.readu32(v36, i), 2139095040) == 2139095040 then
                error("Decoded stock frame is incomplete or nonfinite", 0)
            end
        end
    end

    return v36
end

function t1.ensure(p12, p13, p14) -- line: 234
    -- upvalues: AnimationFrames (copy), t1 (copy), decode_block (copy)
    local pending, block_words = p12.pending, p12.block_words
    local v39 = bit32.rshift(p13, 3)

    for _ = 1, 2 do
        if v39 < pending.block_count and block_words[v39 + 1] == nil then
            local ok, result = pcall(decode_block, p12, pending, v39)

            if not ok then
                t1.stats.fallbacks += 1

                local v40 = pending.frames[1]

                if v40 == nil then
                    error("Lazy clip outlived its animation frames", 0)
                end

                p12.words = AnimationFrames.clip(v40, pending.request).words
                p12.block_words = nil
                p12.pending = nil

                return
            end

            block_words[v39 + 1] = result
            t1.stats.blocks += 1
            pending.remaining -= 1
        end

        v39 = bit32.rshift(p14, 3)
    end

    if pending.remaining ~= 0 then
        return
    end

    p12.pending = nil
    t1.stats.completed += 1
end

function t1.complete(p15) -- line: 267
    -- upvalues: t1 (copy)
    local pending = p15.pending

    if pending ~= nil then
        for i = 0, pending.block_count - 1 do
            if p15.pending == nil then
                break
            end

            t1.ensure(p15, i * 8, i * 8)
        end
    end
end

function t1.words(p16) -- line: 281
    if p16.block_words == nil then
        return p16.words
    end

    local v41 = p16.bone_count * 40
    local v42 = buffer.create(p16.frame_count * v41)

    for v43, v44 in p16.block_words do
        buffer.copy(v42, (v43 - 1) * 8 * v41, v44, 0, buffer.len(v44))
    end

    return v42
end

return t1
