-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_data/abin")
local v2 = import("skate_data/animation_metadata/blend_space")
local v3 = import("skate_data/animation_metadata/selection_space")
local Bank, Error, Reader, RecordHeader = v1.Bank, v1.Error, v1.Reader, v1.RecordHeader
local t1 = {}

local function parent() -- line: 22
    -- upvalues: import (copy)
    return import("skate_data/animation_metadata")
end

local v4, v5, v6

local function stringified(p1, ...) -- line: 29
    -- upvalues: Error (copy)
    local ok, result = pcall(p1, ...)

    if not ok then
        if type(result) == "table" and result.message ~= nil and result.offset ~= nil then
            error(Error.to_string(result), 0)
        end

        error(result, 0)
    end

    return result
end

t1.AnimationMetadata = {}

function t1.AnimationMetadata.from_bank(p2, p3, p4) -- line: 45
    -- upvalues: import (copy), v2 (copy), v3 (copy), Bank (copy), Reader (copy), RecordHeader (copy), v4 (ref), v5 (ref), v6 (ref), stringified (copy)
    local t2 = {
        version = 1,
        source_bank = p3,
        source_sha256 = p4,
        source_bytes = buffer.len(Bank.bytes(p2)),
        clips = {},
        phase_blends = {},
        blend_spaces = {},
        selectors = {},
        selection_spaces = {},
        unsupported_trees = {}
    }
    local v7 = Reader.new(Bank.bytes(p2))

    for _, v8 in Bank.records(p2) do
        local header = v8.header
        local v9 = stringified(Reader.bounded, v7, RecordHeader.range(header))
        local tag = v8.data.tag

        if tag == "Clip" then
            local clips = t2.clips
            local v10 = v4

            table.insert(clips, stringified(v10, v9, header, v8.data[1]))
        elseif tag ~= "Pose" and tag ~= "Hierarchy" and tag ~= "PhysicsPose" then
            local type_id = header.type_id

            if type_id == 6 then
                table.insert(t2.blend_spaces, stringified(v2.read, v9, header))
            elseif type_id == 7 then
                table.insert(t2.phase_blends, stringified(v5, v9, header))
            elseif type_id == 8 then
                table.insert(t2.selectors, stringified(v6, v9, header))
            elseif type_id == 11 then
                table.insert(t2.selection_spaces, stringified(v3.read, v9, header))
            else
                table.insert(t2.unsupported_trees, {
                    name = header.name,
                    source_offset = header.offset,
                    type_id = type_id
                })
            end
        end
    end

    return import("skate_data/animation_metadata").AnimationMetadata.from_file(t2)
end

v4 = function(p5, p6, p7) -- line: 90
    -- upvalues: Error (copy), Reader (copy)
    local v14 = p7.attribute_offset
    local v15 = table.create(p7.attribute_count)

    for _ = 0, p7.attribute_count - 1 do
        local v16 = Reader.u32(p5, v14)

        if v16 < 48 then
            error(Error.new(v14, "attribute record smaller than header"), 0)
        end

        local v17 = v14 + v16
        local v18 = Reader.bounded(p5, {
            start = v14,
            ["end"] = v17
        })
        local v20 = bit32.band(v14 + 51, 4294967280)

        if v17 - v20 < 0 then
            error(Error.new(v14, "attribute payload outside record"), 0)
        end

        local v21 = Reader.take(v18, v20, v17 - v20)
        local v22 = buffer.len(v21)

        if v22 % 4 ~= 0 then
            error(Error.new(v14, "unaligned attribute payload"), 0)
        end

        local v23 = Reader.name(v18, v14 + 12, 5)
        local v24 = Reader.u8(v18, v14 + 32)
        local v25 = Reader.u32(v18, v14 + 4)
        local v26 = Reader.u32(v18, v14 + 8)
        local v27 = table.create(v22 // 4)

        for i = 0, v22 // 4 - 1 do
            local v28 = buffer.readu32(v21, i * 4)

            v27[i + 1] = bit32.byteswap(v28)
        end

        local t4 = {
            name = v23,
            type_id = v24,
            begin_bits = v25,
            end_bits = v26,
            payload_words = v27,
            source_offset = v14
        }

        v14 = v17
        table.insert(v15, t4)
    end

    return {
        name = p6.name,
        source_offset = p6.offset,
        fps_bits = p7.fps_bits,
        frames_bits = p7.frame_count_bits,
        base_speed_bits = p7.base_speed_bits,
        flags_word = p7.flags,
        attributes = v15
    }
end

v5 = function(p8, p9) -- line: 140
    -- upvalues: Reader (copy)
    local payload_offset = p9.payload_offset
    local v29 = Reader.u32(p8, payload_offset + 8)
    local v30 = v29 * 24

    Reader.take(p8, payload_offset + 36, v30)

    local v31 = table.create(v29)

    for i = 0, v29 - 1 do
        v31[i + 1] = Reader.name(p8, payload_offset + 36 + i * 24, 6)
    end

    return {
        name = p9.name,
        source_offset = p9.offset,
        parameter = Reader.name(p8, payload_offset + 16, 5),
        children = v31
    }
end

v6 = function(p10, p11) -- line: 159
    -- upvalues: Reader (copy)
    local payload_offset = p11.payload_offset
    local v32 = Reader.u32(p10, payload_offset + 28)
    local v33 = math.max(v32, 1) * 24
    local v34 = v32 * 20
    local start = Reader.relative(p10, payload_offset, Reader.u32(p10, payload_offset + 20), v33).start
    local start2 = Reader.relative(p10, payload_offset, Reader.u32(p10, payload_offset + 24), v34).start
    local v35 = Reader.name(p10, payload_offset, 5)
    local v36 = Reader.name(p10, start, 6)
    local v37 = table.create(v32)

    for i = 0, v32 - 1 do
        v37[i + 1] = Reader.name(p10, start + i * 24, 6)
    end

    local v38 = table.create(v32)

    for i = 0, v32 - 1 do
        v38[i + 1] = Reader.name(p10, start2 + i * 20, 5)
    end

    return {
        name = p11.name,
        source_offset = p11.offset,
        parameter = v35,
        default = v36,
        children = v37,
        values = v38
    }
end

t1.read_clip = v4
t1.read_phase_blend = v5
t1.read_selector = v6

return t1
