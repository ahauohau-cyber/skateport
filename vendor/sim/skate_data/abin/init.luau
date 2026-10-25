-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_data/abin/bank")
local v2 = import("skate_data/abin/reader")
local t1 = {
    Bank = v1.Bank,
    Reader = v2.Reader,
    Error = {}
}

function t1.Error.new(p1, p2) -- line: 28
    return {
        offset = p1,
        message = p2
    }
end

function t1.Error.to_string(p3) -- line: 35
    return string.format("ABIN at 0x%x: %s", p3.offset, p3.message)
end

function t1.Error.eq(p4, p5) -- line: 38
    if p4.offset == p5.offset then
        return p4.message == p5.message
    end

    return false
end

t1.Codec = {}

function t1.Codec.from_word(p6) -- line: 46
    if p6 == 17490 then
        return {
            tag = "Raw"
        }
    end

    if p6 == 5390934 then
        return {
            tag = "Vbr"
        }
    end

    return {
        tag = "Other",
        p6
    }
end

function t1.Codec.eq(p7, p8) -- line: 55
    if p7.tag == p8.tag then
        return p7[1] == p8[1]
    end

    return false
end

function t1.Codec.debug(p9) -- line: 59
    if p9.tag == "Other" then
        return string.format("Other(%d)", p9[1])
    end

    return p9.tag
end

t1.RecordHeader = {}

function t1.RecordHeader.codec(p10) -- line: 69
    -- upvalues: t1 (copy)
    return t1.Codec.from_word(p10.codec_word)
end

function t1.RecordHeader.range(p11) -- line: 73
    return {
        start = p11.offset,
        ["end"] = p11.offset + p11.size
    }
end

t1.Record = {}
t1.RecordData = {}
t1.Clip = {}

function t1.Clip.looping(p12) -- line: 89
    return bit32.band(p12.flags, 268435456) ~= 0
end

function t1.Clip.channel_animation(p13) -- line: 92
    return bit32.band(p13.flags, 536870912) ~= 0
end

function t1.Clip.phase_controlled(p14) -- line: 95
    return bit32.band(p14.flags, 1073741824) ~= 0
end

t1.Pose = {}
t1.PhysicsPose = {}
t1.PartEntry = {}
t1.AnimationPart = {}
t1.HierarchyPart = {}

function t1.HierarchyPart.eq(p15, p16) -- line: 124
    if p15.name == p16.name and p15.bone_count == p16.bone_count and p15.sqt_offset == p16.sqt_offset and p15.flags == p16.flags then
        return p15.encoded_id == p16.encoded_id
    end

    return false
end

local function list_eq(p17, p18) -- line: 133
    if #p17 ~= #p18 then
        return false
    end

    for i = 1, #p17 do
        if p17[i] ~= p18[i] then
            return false
        end
    end

    return true
end

t1.Hierarchy = {}

function t1.Hierarchy.eq(p19, p20) -- line: 148
    -- upvalues: t1 (copy)
    return p19.offset == p20.offset and t1.Hierarchy.compatible_with(p19, p20)
end

function t1.Hierarchy.compatible_with(p21, p22) -- line: 154
    -- upvalues: t1 (copy)
    if p21.bone_count ~= p22.bone_count or p21.has_trajectory ~= p22.has_trajectory then
        return false
    end

    local parents = p21.parents
    local parents2 = p22.parents
    local v3

    if #parents == #parents2 then
        local v5 = false

        for i = 1, #parents do
            if parents[i] ~= parents2[i] then
                v3 = false
                v5 = true
                break
            end
        end

        if not v5 then
            v3 = true
        end
    else
        v3 = false
    end

    if v3 then
        local mirrors = p21.mirrors
        local mirrors2 = p22.mirrors
        local v6

        if #mirrors == #mirrors2 then
            local v8 = false

            for i = 1, #mirrors do
                if mirrors[i] ~= mirrors2[i] then
                    v6 = false
                    v8 = true
                    break
                end
            end

            if not v8 then
                v6 = true
            end
        else
            v6 = false
        end

        if v6 then
            local bone_names = p21.bone_names
            local bone_names2 = p22.bone_names
            local v9

            if #bone_names == #bone_names2 then
                local v11 = false

                for i = 1, #bone_names do
                    if bone_names[i] ~= bone_names2[i] then
                        v9 = false
                        v11 = true
                        break
                    end
                end

                if not v11 then
                    v9 = true
                end
            else
                v9 = false
            end

            if v9 then
                if #p21.parts ~= #p22.parts then
                    return false
                end

                for i = 1, #p21.parts do
                    if not t1.HierarchyPart.eq(p21.parts[i], p22.parts[i]) then
                        return false
                    end
                end

                return true
            end
        end
    end

    return false
end

return t1
