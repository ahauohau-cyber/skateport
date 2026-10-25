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
local Codec = v8.Codec
local t1 = {}

local function validate_samples(p5, p6) -- line: 47
    -- upvalues: import (copy)
    return import("skate_data/animation_frames").validate_samples(p5, p6)
end

local function VbrDecoder() -- line: 52
    -- upvalues: import (copy)
    return import("skate_core/animation/vbr").VbrDecoder
end

local v9, v10, v11, v12, v13, v14

t1.Entry = {}

function t1.Entry.new(p7, p8) -- line: 62
    return {
        decoded = nil,
        bank = p7,
        offset = p8
    }
end

local function get_or_init(p9, p10, ...) -- line: 71
    -- upvalues: v8 (copy)
    local decoded = p9.decoded

    if decoded == nil then
        local ok, result = pcall(p10, ...)
        local t2

        if ok then
            t2 = {
                ok = true,
                value = result
            }
        else
            if type(result) == "table" and result.message ~= nil and result.offset ~= nil then
                result = v8.Error.to_string(result)
            end

            t2 = {
                ok = false,
                err = result
            }
        end

        decoded = t2
        p9.decoded = t2
    end

    if not decoded.ok then
        error(decoded.err, 0)
    end

    return decoded.value
end

local function sorted_keys(p11) -- line: 91
    local t3 = {}

    for v15 in p11 do
        table.insert(t3, v15)
    end

    table.sort(t3)

    return t3
end

t1.NativeFrames = {}

function t1.NativeFrames.new(p12) -- line: 107
    -- upvalues: Bank (copy), t1 (copy)
    local t4 = {}
    local t5 = {}
    local t6 = {}

    for v16, v17 in p12.banks do
        local v18 = v16 - 1

        for _, v19 in Bank.records(v17) do
            local name, offset = v19.header.name, v19.header.offset
            local tag = v19.data.tag

            if tag == "Clip" then
                local v20 = t4[name]

                if v20 ~= nil and v20.bank ~= v18 then
                    error(string.format("Ambiguous clip %s in multiple animation banks", name), 0)
                end

                t4[name] = t1.Entry.new(v18, offset)
            elseif tag == "Pose" then
                t5[v18 .. ":" .. offset] = t1.Entry.new(v18, offset)
                t6[v18 .. ":" .. name] = offset
            end
        end
    end

    return {
        banks = table.clone(p12.banks),
        clips = t4,
        poses = t5,
        pose_names = t6
    }
end

function t1.NativeFrames.clip_count(p13) -- line: 136
    local n1 = 0

    for _ in p13.clips do
        n1 += 1
    end

    return n1
end

function t1.NativeFrames.clip_names(p14) -- line: 144
    if p14.clip_name_list ~= nil then
        return p14.clip_name_list
    end

    local t7 = {}

    for v21 in p14.clips do
        table.insert(t7, v21)
    end

    table.sort(t7)
    p14.clip_name_list = t7

    return p14.clip_name_list
end

function t1.NativeFrames.clip_bank(p15, p16) -- line: 150
    local v22 = p15.clips[string.upper(p16)]

    if v22 == nil then
        error(string.format("Missing stock animation clip %s", p16), 0)
    end

    return v22.bank
end

function t1.NativeFrames.clip(p17, p18) -- line: 157
    -- upvalues: v9 (ref), get_or_init (copy)
    local v23 = p17.clips[string.upper(p18)]

    if v23 == nil then
        error(string.format("Missing stock animation clip %s", p18), 0)
    end

    return get_or_init(v23, v9, p17.banks[v23.bank + 1], v23.offset)
end

function t1.NativeFrames.named_pose(p19, p20, p21) -- line: 164
    -- upvalues: t1 (copy)
    local v24 = p19.pose_names[p20 .. ":" .. string.upper(p21)]

    if v24 == nil then
        error(string.format("Missing reference pose %s in bank %d", p21, p20), 0)
    end

    return t1.NativeFrames.reference_pose(p19, p20, v24)
end

function t1.NativeFrames.reference_pose(p22, p23, p24) -- line: 171
    -- upvalues: v10 (ref), get_or_init (copy)
    local v25 = p22.poses[p23 .. ":" .. p24]

    if v25 == nil then
        error(string.format("Missing reference pose %d:0x%x", p23, p24), 0)
    end

    return get_or_init(v25, v10, p22.banks[p23 + 1], v25.offset)
end

local function v26(p25, p26) -- line: 180
    -- upvalues: rt (copy), v1 (copy), v8 (copy), Bank (copy), Reader (copy), RecordHeader (copy), Clip (copy), v11 (ref), v12 (ref)
    local v27 = Bank.record_at(p25, p26)

    if v27 == nil then
        error("Missing clip source record", 0)
    end

    if v27.data.tag ~= "Clip" then
        error("Source record is not a clip", 0)
    end

    local v28 = v27.data[1]

    Bank.ensure(p25, v27.header.offset, v27.header.size)
    v11(RecordHeader.codec(v27.header))
    buffer.writeu32(v1, 0, v28.frame_count_bits)

    local v29 = buffer.readf32(v1, 0)

    if v29 ~= v29 or v29 == 1e999 or v29 == (-1e999) or v29 < 1 or rt.fract(v29) ~= 0 then
        error(string.format("%s: invalid frame count", v27.header.name), 0)
    end

    local v30 = v12
    local parts = v28.parts
    local f_to_usize = rt.f_to_usize
    local ok, result = pcall(v30, p25, parts, f_to_usize(v29))

    if not ok then
        error(string.format("%s: %s", v27.header.name, (tostring(result))), 0)
    end

    local v31 = Bank.hierarchy(p25)

    if v31 == nil then
        error("No bank hierarchy", 0)
    end

    local bone_count = v31.bone_count
    local create = table.create

    buffer.writef32(v1, 0, 1)

    local v32 = create(bone_count, (buffer.readu32(v1, 0)))

    if Clip.channel_animation(v28) then
        local v33 = Reader.new(Bank.bytes(p25))
        local parts = v31.parts

        for i = 1, math.min(#v28.parts, #parts) do
            local v36 = v28.parts[i]
            local v37 = parts[i]
            local part = v36.part

            if part == nil then
                error("Channel animation part is absent", 0)
            end

            local channel_weights = part.channel_weights

            if channel_weights == nil then
                error("Channel animation weights are absent", 0)
            end

            for j = 0, v37.bone_count - 1 do
                local u32 = Reader.u32
                local v38 = channel_weights.start + j * 4
                local ok, result = pcall(u32, v33, v38)

                if not ok then
                    error(v8.Error.to_string(result), 0)
                end

                buffer.writeu32(v1, 0, result)

                local v39 = buffer.readf32(v1, 0)

                if v39 ~= v39 or v39 == 1e999 or v39 == (-1e999) then
                    error("Nonfinite channel weight", 0)
                end

                v32[v37.sqt_offset + j + 1] = result
            end
        end
    end

    return {
        name = v27.header.name,
        source_offset = p26,
        fps_bits = v28.fps_bits,
        loop_translation_bits = rt.slice(v28.loop_translation_words, 0, 3),
        loop_rotation_bits = rt.copy(v28.loop_rotation_words),
        channel_animation = Clip.channel_animation(v28),
        channel_weights = v32,
        frames = result
    }
end

v9 = function(p27, p28) -- line: 252
    -- upvalues: rt (copy), v1 (copy), v8 (copy), Bank (copy), Reader (copy), RecordHeader (copy), Clip (copy), v11 (ref), v13 (ref), v14 (ref)
    local v40 = Bank.record_at(p27, p28)

    if v40 == nil then
        error("Missing clip source record", 0)
    end

    if v40.data.tag ~= "Clip" then
        error("Source record is not a clip", 0)
    end

    local v41 = v40.data[1]

    Bank.ensure(p27, v40.header.offset, v40.header.size)
    v11(RecordHeader.codec(v40.header))
    buffer.writeu32(v1, 0, v41.frame_count_bits)

    local v42 = buffer.readf32(v1, 0)

    if v42 ~= v42 or v42 == 1e999 or v42 == (-1e999) or v42 < 1 or rt.fract(v42) ~= 0 then
        error(string.format("%s: invalid frame count", v40.header.name), 0)
    end

    local v43 = rt.f_to_usize(v42)
    local v44 = v13
    local parts = v41.parts
    local ok, result = pcall(v44, p27, parts, v43)

    if not ok then
        error(string.format("%s: %s", v40.header.name, (tostring(result))), 0)
    end

    local v45 = Bank.hierarchy(p27)

    if v45 == nil then
        error("No bank hierarchy", 0)
    end

    local bone_count = v45.bone_count
    local create = table.create

    buffer.writef32(v1, 0, 1)

    local v46 = create(bone_count, (buffer.readu32(v1, 0)))

    if Clip.channel_animation(v41) then
        local v47 = Reader.new(Bank.bytes(p27))
        local parts = v45.parts

        for i = 1, math.min(#v41.parts, #parts) do
            local v50 = v41.parts[i]
            local v51 = parts[i]
            local part = v50.part

            if part == nil then
                error("Channel animation part is absent", 0)
            end

            local channel_weights = part.channel_weights

            if channel_weights == nil then
                error("Channel animation weights are absent", 0)
            end

            for j = 0, v51.bone_count - 1 do
                local u32 = Reader.u32
                local v52 = channel_weights.start + j * 4
                local ok, result = pcall(u32, v47, v52)

                if not ok then
                    error(v8.Error.to_string(result), 0)
                end

                buffer.writeu32(v1, 0, result)

                local v53 = buffer.readf32(v1, 0)

                if v53 ~= v53 or v53 == 1e999 or v53 == (-1e999) then
                    error("Nonfinite channel weight", 0)
                end

                v46[v51.sqt_offset + j + 1] = result
            end
        end
    end

    return {
        name = v40.header.name,
        source_offset = p28,
        fps_bits = v41.fps_bits,
        loop_translation_bits = rt.slice(v41.loop_translation_words, 0, 3),
        loop_rotation_bits = rt.copy(v41.loop_rotation_words),
        channel_animation = Clip.channel_animation(v41),
        channel_weights = v46,
        frames = v14(result, v43, bone_count),
        words = result,
        frame_count = v43,
        bone_count = bone_count
    }
end

v10 = function(p29, p30) -- line: 323
    -- upvalues: Bank (copy), RecordHeader (copy), v11 (ref), v12 (ref)
    local v54 = Bank.record_at(p29, p30)

    if v54 == nil then
        error("Missing pose source record", 0)
    end

    if v54.data.tag ~= "Pose" then
        error("Source record is not a pose", 0)
    end

    local v55 = v54.data[1]

    Bank.ensure(p29, v54.header.offset, v54.header.size)
    v11(RecordHeader.codec(v54.header))

    local v56 = v12
    local parts = v55.parts
    local ok, result = pcall(v56, p29, parts, 1)

    if not ok then
        error(string.format("%s: %s", v54.header.name, (tostring(result))), 0)
    end

    return {
        name = v54.header.name,
        source_offset = p30,
        samples = table.remove(result, 1)
    }
end

v11 = function(p31) -- line: 346
    -- upvalues: Codec (copy)
    if p31.tag ~= "Vbr" then
        error(string.format("Unsupported native animation codec %s", Codec.debug(p31)), 0)
    end
end

local function v57(p32, p33, p34) -- line: 352
    -- upvalues: import (copy), Bank (copy)
    local v58 = Bank.hierarchy(p32)

    if v58 == nil then
        error("Missing stock hierarchy", 0)
    end

    local bone_count = v58.bone_count

    if #p33 ~= #v58.parts then
        error("Animation part count differs from hierarchy", 0)
    end

    local v59 = table.create(p34)

    for i = 1, p34 do
        local v60 = table.create(bone_count)

        for j = 1, bone_count do
            v60[j] = {
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0
            }
        end

        v59[i] = v60
    end

    local v61 = table.create(bone_count, false)
    local VbrDecoder = import("skate_core/animation/vbr").VbrDecoder

    for i = 1, #p33 do
        local v62 = p33[i]
        local v63 = v58.parts[i]
        local part = v62.part

        if part == nil then
            error("Required stock animation part is absent", 0)
        end

        local v64 = VbrDecoder.new(Bank.bytes(p32), part.offset, part.compression_header_relative, part.compressed_data_relative)

        if VbrDecoder.frame_count(v64) ~= p34 or VbrDecoder.channel_count(v64) ~= v63.bone_count then
            error(string.format("%s: codec frame/channel count disagrees with bank header", v63.name), 0)
        end

        if v63.sqt_offset < 0 then
            error("Negative animation part offset", 0)
        end

        local sqt_offset = v63.sqt_offset
        local v65 = sqt_offset + v63.bone_count
        local v66 = bone_count < v65

        if not v66 then
            for j = sqt_offset, v65 - 1 do
                if v61[j + 1] then
                    v66 = true
                    break
                end
            end
        end

        if v66 then
            error("Overlapping animation parts", 0)
        end

        for k = sqt_offset, v65 - 1 do
            v61[k + 1] = true
        end

        for n = 0, p34 - 1 do
            local v67 = v59[n + 1]
            local v68 = VbrDecoder.decode_frame(v64, n)

            if #v68 ~= v65 - sqt_offset then
                error("source slice length does not match destination slice length", 0)
            end

            for n2 = 1, v65 - sqt_offset do
                v67[sqt_offset + n2] = v68[n2]
            end
        end
    end

    for i = 1, bone_count do
        if not v61[i] then
            error("Incomplete animation hierarchy channels", 0)
        end
    end

    for _, v69 in v59 do
        import("skate_data/animation_frames").validate_samples(v69, bone_count)
    end

    return v59
end

v12 = function(p35, p36, p37) -- line: 438
    -- upvalues: import (copy), Bank (copy)
    local v70 = Bank.hierarchy(p35)

    if v70 == nil then
        error("Missing stock hierarchy", 0)
    end

    local bone_count = v70.bone_count

    if #p36 ~= #v70.parts then
        error("Animation part count differs from hierarchy", 0)
    end

    local v71 = table.create(p37)

    for i = 1, p37 do
        v71[i] = table.create(bone_count)
    end

    local v72 = table.create(bone_count, false)
    local VbrDecoder = import("skate_core/animation/vbr").VbrDecoder

    for i = 1, #p36 do
        local v73 = p36[i]
        local v74 = v70.parts[i]
        local part = v73.part

        if part == nil then
            error("Required stock animation part is absent", 0)
        end

        local v75 = VbrDecoder.new(Bank.bytes(p35), part.offset, part.compression_header_relative, part.compressed_data_relative)

        if VbrDecoder.frame_count(v75) ~= p37 or VbrDecoder.channel_count(v75) ~= v74.bone_count then
            error(string.format("%s: codec frame/channel count disagrees with bank header", v74.name), 0)
        end

        if v74.sqt_offset < 0 then
            error("Negative animation part offset", 0)
        end

        local sqt_offset = v74.sqt_offset
        local v76 = sqt_offset + v74.bone_count
        local v77 = bone_count < v76

        if not v77 then
            for j = sqt_offset, v76 - 1 do
                if v72[j + 1] then
                    v77 = true
                    break
                end
            end
        end

        if v77 then
            error("Overlapping animation parts", 0)
        end

        for k = sqt_offset, v76 - 1 do
            v72[k + 1] = true
        end

        for n = 0, p37 - 1 do
            local v78 = v71[n + 1]
            local v79 = VbrDecoder.decode_frame(v75, n)

            if #v79 ~= v76 - sqt_offset then
                error("source slice length does not match destination slice length", 0)
            end

            for n2 = 1, v76 - sqt_offset do
                v78[sqt_offset + n2] = v79[n2]
            end
        end
    end

    for i = 1, bone_count do
        if not v72[i] then
            error("Incomplete animation hierarchy channels", 0)
        end
    end

    for _, v80 in v71 do
        import("skate_data/animation_frames").validate_samples(v80, bone_count)
    end

    return v71
end

v13 = function(p38, p39, p40) -- line: 522
    -- upvalues: import (copy), Bank (copy)
    local v81 = Bank.hierarchy(p38)

    if v81 == nil then
        error("Missing stock hierarchy", 0)
    end

    local bone_count = v81.bone_count

    if #p39 ~= #v81.parts then
        error("Animation part count differs from hierarchy", 0)
    end

    local v82 = bone_count * 40
    local v83 = buffer.create(p40 * v82)
    local v84 = table.create(bone_count, false)
    local VbrDecoder = import("skate_core/animation/vbr").VbrDecoder

    for i = 1, #p39 do
        local v85 = p39[i]
        local v86 = v81.parts[i]
        local part = v85.part

        if part == nil then
            error("Required stock animation part is absent", 0)
        end

        local v87 = VbrDecoder.new(Bank.bytes(p38), part.offset, part.compression_header_relative, part.compressed_data_relative)

        if VbrDecoder.frame_count(v87) ~= p40 or VbrDecoder.channel_count(v87) ~= v86.bone_count then
            error(string.format("%s: codec frame/channel count disagrees with bank header", v86.name), 0)
        end

        if v86.sqt_offset < 0 then
            error("Negative animation part offset", 0)
        end

        local sqt_offset = v86.sqt_offset
        local v88 = sqt_offset + v86.bone_count
        local v89 = bone_count < v88

        if not v89 then
            for j = sqt_offset, v88 - 1 do
                if v84[j + 1] then
                    v89 = true
                    break
                end
            end
        end

        if v89 then
            error("Overlapping animation parts", 0)
        end

        for k = sqt_offset, v88 - 1 do
            v84[k + 1] = true
        end

        local v90 = sqt_offset * 40

        for n = 0, p40 - 1 do
            VbrDecoder.decode_frame_into(v87, n, v83, n * v82 + v90)
        end
    end

    for i = 1, bone_count do
        if not v84[i] then
            error("Incomplete animation hierarchy channels", 0)
        end
    end

    for i = 0, p40 * v82 - 4, 4 do
        if bit32.band(buffer.readu32(v83, i), 2139095040) == 2139095040 then
            error("Decoded stock frame is incomplete or nonfinite", 0)
        end
    end

    return v83, bone_count
end

local function frame_table(p41, p42, p43) -- line: 597
    local v92 = table.create(p43)
    local v93 = p42 * p43 * 40

    for i = 1, p43 do
        local v94 = table.create(10)

        for j = 1, 10 do
            v94[j] = buffer.readu32(p41, v93)
            v93 += 4
        end

        v92[i] = v94
    end

    return v92
end

v14 = function(p44, p45, p46) -- line: 615
    -- upvalues: frame_table (copy)
    return (setmetatable({}, {
        __len = function() -- __len | line: 617
            -- upvalues: p45 (copy)
            return p45
        end,
        __index = function(_, p48) -- __index | line: 620
            -- upvalues: p44 (copy), p45 (copy), p46 (copy), frame_table (copy)
            return if type(p48) == "number" and p48 >= 1 and p48 <= p45 and p48 % 1 == 0 then frame_table(p44, p48 - 1, p46) else nil
        end,
        __newindex = function() -- __newindex | line: 626
            error("ClipFrames.frames of a packed clip is read-only (use ClipFrames.frames_table for a copy)", 0)
        end,
        __iter = function() -- __iter | line: 629
            -- upvalues: p44 (copy), p45 (copy), p46 (copy), frame_table (copy)
            local n2 = 0

            return function() -- line: 631
                -- upvalues: n2 (ref), p44 (copy), p45 (copy), p46 (copy), frame_table (copy)
                n2 += 1

                if n2 <= p45 then
                    return n2, (frame_table(p44, n2 - 1, p46))
                end

                return nil
            end
        end
    }))
end

t1.ClipFrames = {}

function t1.ClipFrames.is_packed(p49) -- line: 645
    return p49.words ~= nil
end

function t1.ClipFrames.frame_count(p50) -- line: 648
    if p50.words == nil then
        return #p50.frames
    end

    return p50.frame_count
end

function t1.ClipFrames.word(p51, p52, p53, p54) -- line: 655
    local words = p51.words

    if words == nil then
        return p51.frames[p52 + 1][p53 + 1][p54 + 1]
    end

    return (buffer.readu32(words, ((p52 * p51.bone_count + p53) * 10 + p54) * 4))
end

function t1.ClipFrames.frames_table(p55) -- line: 663
    -- upvalues: rt (copy), frame_table (copy)
    local words = p55.words

    if words == nil then
        return rt.copy(p55.frames)
    end

    local frame_count, bone_count = p55.frame_count, p55.bone_count
    local v96 = table.create(frame_count)

    for i = 1, frame_count do
        v96[i] = frame_table(words, i - 1, bone_count)
    end

    return v96
end

t1.decode_clip = v9
t1.decode_pose = v10
t1.require_vbr = v11
t1.decode_parts = v12
t1.decode_parts_reference = v57
t1.decode_clip_reference = v26
t1.decode_parts_buffer = v13
t1.frames_view = v14

return t1
