-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local Reader = import("skate_data/abin/reader").Reader
local t1 = {}

local function Error() -- line: 30
    -- upvalues: import (copy)
    return import("skate_data/abin").Error
end

t1.Bank = {}

local v1 = table.create(256, 0)

for i = 1, 64 do
    v1[string.byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", i) + 1] = i - 1
end

local function b64_decode_into(p1, p2, p3) -- line: 52
    -- upvalues: v1 (copy)
    local v2 = #p1

    if v2 == 0 then
        return 0
    end

    if v2 % 4 ~= 0 then
        error("base64 length is not a multiple of 4", 0)
    end

    local v3 = buffer.fromstring(p1)
    local v4 = v2 - 1
    local v5 = if buffer.readu8(v3, v4) ~= 61 then 0 elseif buffer.readu8(v3, v2 - 2) == 61 then 2 else 1
    local v7 = v2 // 4

    if v5 > 0 then
        v7 -= 1
    end

    local v8 = v7 - 1
    local v9 = p3

    for i = 0, v8 do
        local v10 = buffer.readu32(v3, i * 4)
        local v11 = v1[bit32.band(v10, 255) + 1] * 262144 + v1[bit32.extract(v10, 8, 8) + 1] * 4096 + v1[bit32.extract(v10, 16, 8) + 1] * 64 + v1[bit32.rshift(v10, 24) + 1]

        buffer.writeu8(p2, v9, (bit32.rshift(v11, 16)))
        buffer.writeu8(p2, v9 + 1, (bit32.extract(v11, 8, 8)))
        buffer.writeu8(p2, v9 + 2, (bit32.band(v11, 255)))
        v9 += 3
    end

    if v5 > 0 then
        local v17 = v7 * 4
        local v22 = v1[buffer.readu8(v3, v17) + 1] * 262144 + v1[buffer.readu8(v3, v17 + 1) + 1] * 4096 + v1[buffer.readu8(v3, v17 + 2) + 1] * 64

        buffer.writeu8(p2, v9, (bit32.rshift(v22, 16)))
        v9 += 1

        if v5 == 1 then
            buffer.writeu8(p2, v9, (bit32.extract(v22, 8, 8)))
            v9 += 1
        end
    end

    return v9 - p3
end

local anim, v25
local t2 = {}
local t3 = {}

local function anim_data() -- line: 105
    -- upvalues: sim (copy), anim (ref), v25 (ref)
    if v25 ~= nil then
        return anim, v25
    end

    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local anim2 = sim_data and sim_data:FindFirstChild("anim")
    local index = anim2 and anim2:FindFirstChild("index")

    if not index then
        error("ReplicatedStorage.Skate3.sim_data.anim.index is not installed", 0)
    end

    local v26 = require(index)

    if v26.format ~= 1 and (v26.format ~= 2 or v26.compressed ~= "zstd") then
        error(("unsupported sim_data.anim format %*"):format(v26.format), 0)
    end

    anim = anim2
    v25 = v26

    return anim, v25
end

local function data_module(p4, p5) -- line: 124
    local v27 = p4:FindFirstChild(p5)

    if not v27 then
        error(("sim_data.anim.%* is not installed"):format(p5), 0)
    end

    return require(v27)
end

local function bank_entry(p6) -- line: 132
    -- upvalues: anim_data (copy)
    local _, v28 = anim_data()

    for _, v29 in v28.banks do
        if v29.name == p6 then
            return v29
        end
    end

    error(("no animation bank \"%*\" in sim_data.anim"):format(p6), 0)
end

local function open_source(p7) -- line: 143
    -- upvalues: sim (copy), b64_decode_into (copy), anim_data (copy)
    local v30, v31 = anim_data()
    local _, v32 = anim_data()
    local v33 = false
    local v34

    for _, v35 in v32.banks do
        if v35.name == p7 then
            v34 = v35
            v33 = true
            break
        end
    end

    if not v33 then
        v34 = nil
        error(("no animation bank \"%*\" in sim_data.anim"):format(p7), 0)
    end

    local v36 = buffer.create(v34.bytes)
    local v37 = if v31.compressed == "zstd" then buffer.create(0) else buffer.create(v34.skeleton_bytes)
    local t4 = {}
    local v38 = v31.compressed == "zstd"
    local t5 = {}
    local n1 = 0

    for _, v39 in v34.skeleton do
        local v40 = v30:FindFirstChild(v39)

        if not v40 then
            error(("sim_data.anim.%* is not installed"):format(v39), 0)
        end

        local v41 = require(v40)

        if type(v41[1]) ~= "string" then
            error(("sim_data.anim.%* was already consumed"):format(v39), 0)
        end

        if v38 then
            table.insert(t5, v41[1])
        else
            n1 += b64_decode_into(v41[1], v37, n1)
        end

        table.insert(t4, v41)
    end

    if v38 then
        v37 = require(sim.zdata).unpack_chunks(t5, v34.skeleton_bytes)
        n1 = buffer.len(v37)
    end

    if n1 ~= v34.skeleton_bytes then
        error(("sim_data.anim %*: skeleton is %* bytes, index says %*"):format(p7, n1, v34.skeleton_bytes), 0)
    end

    local v44 = buffer.readu32(v37, 0)
    local v45 = v44 * 8 + 4

    for i = 0, v44 - 1 do
        local v46 = buffer.readu32(v37, i * 8 + 4)
        local v47 = buffer.readu32(v37, i * 8 + 8)

        buffer.copy(v36, v46, v37, v45, v47)
        v45 += v47
    end

    if v45 ~= v34.skeleton_bytes then
        error(("sim_data.anim %*: skeleton ranges do not cover the stream"):format(p7), 0)
    end

    return v36, {
        loaded_count = 0,
        entry = v34,
        folder = v30,
        zstd = v38,
        part_bytes = v31.part_bytes,
        loaded = table.create(#v34.parts, false)
    }, t4
end

local function load_part(p8, p9, p10) -- line: 193
    -- upvalues: sim (copy), b64_decode_into (copy)
    local entry = p9.entry
    local v48 = entry.parts[p10 + 1]
    local v49 = p9.folder:FindFirstChild(v48)

    if not v49 then
        error(("sim_data.anim.%* is not installed"):format(v48), 0)
    end

    local v50 = require(v49)

    if type(v50[1]) ~= "string" then
        error(("sim_data.anim.%* was already consumed"):format(v48), 0)
    end

    local v52 = p10 * p9.part_bytes
    local v53

    if p9.zstd then
        v53 = math.min(p9.part_bytes, entry.bytes - v52)

        local v55 = require(sim.zdata).unpack(v50[1], v53)

        buffer.copy(p8.bytes, v52, v55, 0, v53)
    else
        v53 = b64_decode_into(v50[1], p8.bytes, v52)
    end

    if v53 ~= math.min(p9.part_bytes, entry.bytes - v52) then
        error(("sim_data.anim.%*: %* bytes, expected %*"):format(v48, v53, (math.min(p9.part_bytes, entry.bytes - v52))), 0)
    end

    v50[1] = nil
    p9.loaded[p10 + 1] = true
    p9.loaded_count += 1
end

function t1.Bank.ensure(p11, p12, p13) -- line: 219
    -- upvalues: load_part (copy)
    local source = p11.source

    if source == nil or p13 <= 0 then
        return
    end

    local part_bytes, loaded = source.part_bytes, source.loaded
    local v60 = math.min((p12 + p13 - 1) // part_bytes, #loaded - 1)

    for i = math.max(p12 // part_bytes, 0), v60 do
        if not loaded[i + 1] then
            load_part(p11, source, i)
        end
    end
end

function t1.Bank.ensure_all(p14) -- line: 234
    -- upvalues: t1 (copy)
    local source = p14.source

    if source ~= nil then
        t1.Bank.ensure(p14, 0, source.entry.bytes)
    end
end

function t1.Bank.source_sha256(p15) -- line: 242
    local source = p15.source

    return if source ~= nil then source.entry.sha256 else nil
end

function t1.Bank.loaded_parts(p16) -- line: 247
    local source = p16.source

    if source == nil then
        return 0, 0
    end

    return source.loaded_count, #source.loaded
end

function t1.Bank.clip_location(p17, p18) -- line: 256
    -- upvalues: t3 (copy), anim_data (copy)
    local v62 = t3[p17]

    if v62 == nil then
        local v63 = anim_data()
        local _, v64 = anim_data()
        local v65 = false
        local v66

        for _, v67 in v64.banks do
            if v67.name == p17 then
                v66 = v67
                v65 = true
                break
            end
        end

        if not v65 then
            v66 = nil
            error(("no animation bank \"%*\" in sim_data.anim"):format(p17), 0)
        end

        v62 = {}

        for _, v68 in v66.clip_index do
            local v69 = v63:FindFirstChild(v68)

            if not v69 then
                error(("sim_data.anim.%* is not installed"):format(v68), 0)
            end

            for v70, v71 in require(v69) do
                v62[v70] = v71
            end
        end

        t3[p17] = v62
    end

    local v72 = v62[string.upper(p18)]

    if v72 == nil then
        return nil
    end

    return v72[1], v72[2], v72[3]
end

function t1.Bank.sim_data_index() -- line: 276
    -- upvalues: anim_data (copy)
    local _, v73 = anim_data()

    return v73
end

local v74, v75, v76

function t1.Bank.load(p19) -- line: 288
    -- upvalues: import (copy), t1 (copy), t2 (copy), open_source (copy)
    local v77 = string.match(p19, "([^/\\]+)%.[Aa][Bb][Ii][Nn]$") or string.match(p19, "([^/\\]+)$") or p19
    local v78 = t2[v77]

    if v78 ~= nil then
        return v78
    end

    local v79, v80, v81, v82 = pcall(open_source, v77)

    if not v79 then
        error(import("skate_data/abin").Error.new(0, (("%*: %*"):format(p19, (tostring(v80))))), 0)
    end

    local v83 = t1.Bank.parse(v80)

    v83.source = v81

    for _, v84 in v82 do
        v84[1] = nil
    end

    t2[v77] = v83

    return v83
end

function t1.Bank.parse(p20) -- line: 308
    -- upvalues: import (copy), Reader (copy), v74 (ref), v75 (ref), v76 (ref)
    local v85 = Reader.new(p20)
    local v86 = Reader.u32(v85, 0)

    if Reader.u32(v85, 4) ~= 1 or v86 < 48 or buffer.len(p20) < v86 then
        error(import("skate_data/abin").Error.new(0, "invalid type1 bank wrapper"), 0)
    end

    local t6 = {}
    local t7 = {}
    local t8 = {}
    local t9 = {}
    local t10 = {}
    local n2 = 48
    local v87

    while n2 < v86 do
        local v88 = Reader.u32(v85, n2)

        if v88 < 48 or v88 % 16 ~= 0 or v86 - n2 < v88 then
            error(import("skate_data/abin").Error.new(n2, "invalid record size/alignment"), 0)
        end

        local v89 = Reader.bounded(v85, {
            start = n2,
            ["end"] = n2 + v88
        })
        local t11 = {
            name = Reader.name(v89, n2 + 16, 6),
            name_words = Reader.words(v89, n2 + 16, 6),
            offset = n2,
            size = v88,
            payload_offset = bit32.band(n2 + 55, 4294967280),
            type_id = Reader.u32(v89, n2 + 4),
            codec_word = Reader.u32(v89, n2 + 8),
            guid = Reader.u32(v89, n2 + 12)
        }
        local t12

        if t11.type_id == 2 then
            t12 = {
                tag = "Clip",
                (v74(v89, t11))
            }
        elseif t11.type_id == 3 then
            t12 = {
                tag = "Pose",
                {
                    parts = v75(v89, t11.payload_offset, 4, Reader.u32(v89, t11.payload_offset), false)
                }
            }
        elseif t11.type_id == 4 then
            t12 = {
                tag = "Hierarchy",
                (v76(v89, t11.payload_offset))
            }
        elseif t11.type_id == 5 then
            local v91 = Reader.u32(v89, t11.payload_offset)
            local v92 = v91 * 112

            t12 = {
                tag = "PhysicsPose",
                {
                    bone_count = v91,
                    records = Reader.relative(v89, t11.payload_offset, 16, v92)
                }
            }
        else
            t12 = {
                tag = "Opaque"
            }
        end

        local v93 = #t6
        local type_id = t11.type_id

        if type_id == 2 then
            t9[t11.name] = v93
            t8[t11.name] = v93
        elseif type_id == 3 then
            t10[t11.name] = v93
        elseif type_id == 4 then
            v87 = v93
        elseif type_id >= 6 and type_id <= 11 then
            t8[t11.name] = v93
        end

        t7[n2] = v93
        table.insert(t6, {
            header = t11,
            data = t12
        })
        n2 += v88
    end

    return {
        source = nil,
        bytes = p20,
        wrapper_bytes = v86,
        trailer = {
            start = v86,
            ["end"] = buffer.len(p20)
        },
        records = t6,
        offsets = t7,
        animations = t8,
        clips = t9,
        poses = t10,
        hierarchy = v87
    }
end

function t1.Bank.bytes(p21) -- line: 401
    return p21.bytes
end

function t1.Bank.records(p22) -- line: 404
    return p22.records
end

function t1.Bank.pack(p23) -- line: 415
    -- upvalues: import (copy)
    local packed = import("packed")

    if packed.is_view(p23.records) then
        return nil
    end

    local v94 = packed.pack(p23.records, {
        cache = 256
    })

    p23.records = packed.view(v94)

    return v94
end

function t1.Bank.record_at(p24, p25) -- line: 424
    local v95 = p24.offsets[p25]

    return if v95 ~= nil then p24.records[v95 + 1] else nil
end

function t1.Bank.animation(p26, p27) -- line: 431
    local v96 = p26.animations[string.upper(p27)]

    return if v96 ~= nil then p26.records[v96 + 1] else nil
end

function t1.Bank.clip(p28, p29) -- line: 439
    local v97 = p28.clips[string.upper(p29)]

    if v97 ~= nil then
        local v98 = p28.records[v97 + 1]

        if v98.data.tag == "Clip" then
            return v98.header, v98.data[1]
        end
    end

    return nil
end

function t1.Bank.pose(p30, p31) -- line: 452
    local v99 = p30.poses[string.upper(p31)]

    if v99 ~= nil then
        local v100 = p30.records[v99 + 1]

        if v100.data.tag == "Pose" then
            return v100.header, v100.data[1]
        end
    end

    return nil
end

function t1.Bank.hierarchy(p32) -- line: 464
    if p32.hierarchy ~= nil then
        local data = p32.records[p32.hierarchy + 1].data

        if data.tag == "Hierarchy" then
            return data[1]
        end
    end

    return nil
end

function t1.Bank.validate_positional_parts(p33) -- line: 479
    -- upvalues: import (copy), t1 (copy)
    local v101 = t1.Bank.hierarchy(p33)

    if v101 == nil then
        error(import("skate_data/abin").Error.new(0, "missing hierarchy"), 0)
    end

    for _, v102 in p33.records do
        if v102.data.tag == "Clip" or v102.data.tag == "Pose" then
            local parts = v102.data[1].parts

            if #parts ~= #v101.parts then
                error(import("skate_data/abin").Error.new(v102.header.offset, "part table differs from full hierarchy"), 0)
            end

            for i = 1, math.min(#parts, #v101.parts) do
                local v105 = parts[i]
                local v106 = v101.parts[i]
                local part = v105.part

                if part ~= nil and part.channel_count ~= v106.bone_count then
                    error(import("skate_data/abin").Error.new(part.offset, "part channel count differs from hierarchy"), 0)
                end
            end
        end
    end
end

v74 = function(p34, p35) -- line: 509
    -- upvalues: Reader (copy), v75 (ref)
    local payload_offset = p35.payload_offset

    Reader.take(p34, payload_offset, 56)

    local v107 = Reader.u32(p34, payload_offset + 52)
    local v108 = bit32.band(v107, 255)
    local start = Reader.relative(p34, payload_offset, Reader.u32(p34, payload_offset + 44), 0).start
    local t14 = {
        fps_bits = Reader.u32(p34, payload_offset + 32),
        frame_count_bits = Reader.u32(p34, payload_offset + 36),
        base_speed_bits = Reader.u32(p34, payload_offset + 40),
        flags = v107,
        loop_translation_words = Reader.words(p34, payload_offset, 4),
        loop_rotation_words = Reader.words(p34, payload_offset + 16, 4),
        attribute_offset = start,
        attribute_count = v108
    }

    t14.parts = v75(p34, payload_offset, 56, bit32.band(bit32.rshift(v107, 8), 31), bit32.band(v107, 536870912) ~= 0)

    return t14
end

v75 = function(p36, p37, p38, p39, p40) -- line: 540
    -- upvalues: Reader (copy)
    local v111 = p39 * 4

    Reader.take(p36, p37 + p38, v111)

    local v112 = table.create(p39)

    for i = 0, p39 - 1 do
        local v113 = p37 + p38 + i * 4
        local v114 = Reader.u32(p36, v113)
        local v115 = bit32.band(v114, 16777215)
        local t15

        if v115 ~= 0 then
            local start = Reader.relative(p36, p37, v115, 16).start
            local v116 = Reader.u32(p36, start)
            local v117 = Reader.u32(p36, start + 4)
            local v118 = Reader.u32(p36, start + 8)
            local v119 = Reader.u32(p36, start + 12)
            local v121 = bit32.band(bit32.rshift(v116, 6), 63) + 1

            t15 = {
                offset = start,
                header_word = v116,
                compressed_size = v117,
                compression_header_relative = v118,
                compressed_data_relative = v119,
                channel_count = v121,
                compression_header = Reader.relative(p36, start, v118, (bit32.rshift(v116, 12))),
                compressed_data = Reader.relative(p36, start, v119, v117),
                channel_weights = if p40 then Reader.relative(p36, start, 16, v121 * 4) else nil
            }
        end

        v112[i + 1] = {
            table_index = i,
            table_offset = v113,
            raw_word = v114,
            encoded_id = bit32.rshift(v114, 24),
            part = t15
        }
    end

    return v112
end

v76 = function(p41, p42) -- line: 590
    -- upvalues: import (copy), Reader (copy)
    local v122 = Reader.u16(p41, p42)
    local v123 = Reader.u32(p41, p42 + 4)
    local v124 = v123 * 36
    local v125 = p42 + 8 + 8 * v122

    Reader.take(p41, p42 + 8, 8 * v122)
    Reader.take(p41, v125, v124)

    local v126 = v125 + v124

    Reader.take(p41, v126, 20 * v122)

    local v127 = table.create(v122)
    local v128 = table.create(v122)
    local v129 = table.create(v122)

    for i = 0, v122 - 1 do
        local v130 = Reader.i32(p41, p42 + 8 + i * 4)
        local v131 = Reader.i32(p41, p42 + 8 + 4 * v122 + i * 4)

        if v130 < -1 or i <= v130 or v131 < -1 or v122 <= v131 then
            error(import("skate_data/abin").Error.new(p42 + 8 + i * 4, "invalid parent or mirror index"), 0)
        end

        table.insert(v127, v130)
        table.insert(v128, v131)
        table.insert(v129, Reader.name(p41, v126 + i * 20, 5))
    end

    local v133 = table.create(v123)

    for i = 0, v123 - 1 do
        local v134 = v125 + i * 36
        local v135 = Reader.u32(p41, v134 + 24)
        local v136 = Reader.i32(p41, v134 + 28)

        if v136 < 0 or v122 < v136 + v135 then
            error(import("skate_data/abin").Error.new(v134, "part extends outside skeleton output"), 0)
        end

        table.insert(v133, {
            name = Reader.name(p41, v134, 6),
            bone_count = v135,
            sqt_offset = v136,
            flags = Reader.u16(p41, v134 + 32),
            encoded_id = Reader.u16(p41, v134 + 34)
        })
    end

    return {
        offset = p42,
        bone_count = v122,
        has_trajectory = Reader.u16(p41, p42 + 2) ~= 0,
        parents = v127,
        mirrors = v128,
        bone_names = v129,
        parts = v133
    }
end

t1.read_clip = v74
t1.read_parts = v75
t1.read_hierarchy = v76

return t1
