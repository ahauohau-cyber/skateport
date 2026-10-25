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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/animation/commands/batch")
local v10 = import("skate_core/animation/commands/buffers")
local CompletedSetData = v9.CompletedSetData
local BoneBuffers = v10.BoneBuffers
local t1 = {
    AnimationSignal = {},
    SkaterPublicationState = {},
    ActorPoseBuffers = {},
    PhysicsPosePacket = {}
}

function t1.publish(p3, p4, p5, p6, p7, p8) -- line: 77
    -- upvalues: CompletedSetData (copy), BoneBuffers (copy), t1 (copy)
    local bone_count = p6.bone_count

    if #p6.hierarchy < bone_count or #p6["local"] < bone_count then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    local v11 = BoneBuffers.read(CompletedSetData.buffers(p4).matrices, p5.hierarchy, bone_count)
    local v12 = BoneBuffers.read(CompletedSetData.buffers(p4).matrices, p5["local"], bone_count)

    return t1.publish_evaluated(p3, v11, v12, p6, p7, p8)
end

function t1.publish_evaluated(p9, p10, p11, p12, p13, p14) -- line: 91
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local bone_count = p12.bone_count

    if #p10 < bone_count or #p11 < bone_count or #p12.hierarchy < bone_count or #p12["local"] < bone_count then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    local v13

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v14 = math.abs(p13) * 7.1362384635298E+44
        local v15 = math.floor(v14)
        local v16 = v14 - v15

        v13 = (if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15) * 1.401298464324817E-45

        if p13 < 0 then
            v13 = -v13
        end
    else
        buffer.writef32(v1, 0, p13)
        v13 = buffer.readf32(v1, 0)
    end

    p12.timestep = v13
    p12.foot_surface_ids = { 0, 0 }
    p12.flags = t1.replace_flag(p12.flags, 27, p9.request_bit16)
    p9.request_bit16 = false
    p12.flags = t1.replace_flag(p12.flags, 23, p9.request_bit15)
    p9.request_bit15 = false
    p12.flags = bit32.band(p12.flags, 4194303999)

    local signal = p9.signal

    if signal ~= nil then
        signal.name_hash = t1.signal_hash(p14)
        signal.active = 0
    end

    for i = 1, bone_count do
        p12.hierarchy[i] = rt.copy(p10[i])
    end

    for i = 1, bone_count do
        p12["local"][i] = rt.copy(p11[i])
    end

    p12.board_flipped = p9.orientation_bit31 ~= p9.mirrored
    p12.mirrored = p9.mirrored
    p12.riding_switch = p9.relative_stance == 1
    p12.riding_fakie = p9.riding_fakie

    if p9.riding_fakie then
        p12.weight_forwards = not p9.weight_on_nose
    else
        p12.weight_forwards = p9.weight_on_nose
    end

    p12.regular_stance = p9.natural_stance == 0
    p12.flags = t1.replace_flag(p12.flags, 28, p9.air_dismount_revert_requested)
    p9.air_dismount_revert_requested = false
    p12.air_dismount_revert_frames = p9.air_dismount_revert_frames

    return p9.air_dismount_revert_frames
end

function t1.publish_evaluated_owned(p15, p16, p17, p18, p19, p20) -- line: 136
    -- upvalues: v1 (copy), t1 (copy)
    local bone_count = p18.bone_count

    if #p16 < bone_count or #p17 < bone_count or #p18.hierarchy < bone_count or #p18["local"] < bone_count then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    local v17

    if p19 ~= 0 and p19 > -1.1754943508222875E-38 and p19 < 1.1754943508222875E-38 then
        local v18 = math.abs(p19) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = (if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19) * 1.401298464324817E-45

        if p19 < 0 then
            v17 = -v17
        end
    else
        buffer.writef32(v1, 0, p19)
        v17 = buffer.readf32(v1, 0)
    end

    p18.timestep = v17
    p18.foot_surface_ids = { 0, 0 }
    p18.flags = t1.replace_flag(p18.flags, 27, p15.request_bit16)
    p15.request_bit16 = false
    p18.flags = t1.replace_flag(p18.flags, 23, p15.request_bit15)
    p15.request_bit15 = false
    p18.flags = bit32.band(p18.flags, 4194303999)

    local signal = p15.signal

    if signal ~= nil then
        signal.name_hash = t1.signal_hash(p20)
        signal.active = 0
    end

    local hierarchy = p18.hierarchy

    for i = 1, bone_count do
        hierarchy[i] = p16[i]
    end

    local v21 = p18["local"]

    for i = 1, bone_count do
        v21[i] = p17[i]
    end

    p18.board_flipped = p15.orientation_bit31 ~= p15.mirrored
    p18.mirrored = p15.mirrored
    p18.riding_switch = p15.relative_stance == 1
    p18.riding_fakie = p15.riding_fakie

    if p15.riding_fakie then
        p18.weight_forwards = not p15.weight_on_nose
    else
        p18.weight_forwards = p15.weight_on_nose
    end

    p18.regular_stance = p15.natural_stance == 0
    p18.flags = t1.replace_flag(p18.flags, 28, p15.air_dismount_revert_requested)
    p15.air_dismount_revert_requested = false
    p18.air_dismount_revert_frames = p15.air_dismount_revert_frames

    return p15.air_dismount_revert_frames
end

function t1.replace_flag(p21, p22, p23) -- line: 180
    return (bit32.bor(bit32.band(p21, (bit32.bnot((bit32.lshift(1, p22))))), (bit32.lshift(if p23 then 1 else 0, p22))))
end

function t1.signal_hash(p24) -- line: 186
    -- upvalues: rt (copy)
    local n1 = 0

    for i = 1, #p24 do
        local v28 = string.byte(p24, i)

        if v28 == 0 then
            break
        end

        if v28 >= 128 then
            v28 -= 256
        end

        n1 = rt.wrapping_add_u32(bit32.lshift(n1, 4), rt.to_u32(v28))

        local v29 = bit32.band(n1, 4026531840)

        if v29 ~= 0 then
            n1 = bit32.bxor(n1, (bit32.bxor(bit32.rshift(v29, 23), v29)))
        end
    end

    return n1
end

return t1
