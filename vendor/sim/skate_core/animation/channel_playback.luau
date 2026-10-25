-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

local function bool_u32(p1) -- line: 13
    if p1 then
        return 1
    end

    return 0
end

local function words_cmp(p2, p3) -- line: 18
    for i = 1, 5 do
        if p2[i] < p3[i] then
            return -1
        end

        if p2[i] > p3[i] then
            return 1
        end
    end

    return 0
end

t1.ChannelSettings = {}

function t1.ChannelSettings.eq(p4, p5) -- line: 36
    if p4.priority == p5.priority and p4.keep_alive == p5.keep_alive and p4.mirrored == p5.mirrored and p4.speed == p5.speed and p4.blend_in == p5.blend_in and p4.hold_during_blend_in == p5.hold_during_blend_in and p4.blend_out == p5.blend_out and p4.hold_during_blend_out == p5.hold_during_blend_out then
        return p4.use_attributes == p5.use_attributes
    end

    return false
end

t1.ChannelPlayback = {}

local unit

function t1.ChannelPlayback.new(p6) -- line: 57
    -- upvalues: rt (copy)
    local v11 = bit32.bor(bit32.lshift(if p6.keep_alive then 1 else 0, 28), bit32.lshift(if p6.hold_during_blend_in then 1 else 0, 31), bit32.lshift(if p6.hold_during_blend_out then 1 else 0, 30), bit32.lshift(if p6.blend_out > 0 then 1 else 0, 27), (bit32.lshift(if p6.use_attributes then 1 else 0, 25)))

    return {
        weight = 0,
        influence = 1,
        blend_in_elapsed = 0,
        blend_out_elapsed = 0,
        resurrection_elapsed = 0,
        resurrection_duration = 0,
        settings = rt.copy(p6),
        flags = v11
    }
end

function t1.ChannelPlayback.expired(p7) -- line: 78
    if bit32.band(p7.flags, 134217728) ~= 0 then
        return p7.blend_out_elapsed >= p7.settings.blend_out
    end

    if bit32.band(p7.flags, 268435456) ~= 0 then
        return false
    end

    return bit32.band(p7.flags, 67108864) ~= 0
end

t1.ChannelPlayback["end"] = function(p8) -- line: 86
    if p8.blend_out_elapsed == 0 then
        p8.flags = bit32.bor(p8.flags, 671088640)
    end
end

function t1.ChannelPlayback.end_with(p9, p10, p11) -- line: 92
    if p9.blend_out_elapsed ~= 0 then
        return
    end

    p9.settings.blend_out = p10
    p9.settings.hold_during_blend_out = p11
    p9.flags = bit32.bor(bit32.band(p9.flags, 3221225471), bit32.lshift(if p11 then 1 else 0, 30), 671088640)
end

function t1.ChannelPlayback.can_transition(p12, p13) -- line: 104
    return not (p12.blend_out_elapsed > 0) or p13
end

function t1.ChannelPlayback.transition(p14, p15, p16) -- line: 111
    -- upvalues: unit (ref)
    if p14.blend_out_elapsed > 0 and p16 then
        p14.resurrection_duration = p15.blend_in
        p14.resurrection_elapsed = unit(1 - p14.blend_out_elapsed / p14.settings.blend_out) * p15.blend_in
    end

    p14.blend_out_elapsed = 0
    p14.settings.keep_alive = p15.keep_alive
    p14.settings.blend_out = p15.blend_out
    p14.settings.hold_during_blend_out = p15.hold_during_blend_out
    p14.settings.use_attributes = p15.use_attributes
    p14.flags = bit32.bor(bit32.band(p14.flags, 2248146943), bit32.lshift(if p15.keep_alive then 1 else 0, 28), bit32.lshift(if p15.hold_during_blend_out then 1 else 0, 30), bit32.lshift(if p15.blend_out > 0 then 1 else 0, 27), (bit32.lshift(if p15.use_attributes then 1 else 0, 25)))
end

function t1.ChannelPlayback.advance(p17, p18, p19, p20) -- line: 132
    -- upvalues: unit (ref)
    local v24

    if p17.settings.blend_in > 0 and p17.blend_in_elapsed < p17.settings.blend_in then
        v24 = unit(p17.blend_in_elapsed / p17.settings.blend_in)
        p17.blend_in_elapsed += p18
    else
        v24 = 1
    end

    local v25 = p19 - p20

    if not (v25 >= 0) then
        v25 = 0
    end

    local v26 = bit32.band(p17.flags, 1073741824) ~= 0
    local v27 = bit32.band(p17.flags, 67108864) ~= 0

    if not v26 then
        v27 = v25 < p17.settings.blend_out
    end

    local v28

    if p17.settings.blend_out > 0 then
        if bit32.band(p17.flags, 536870912) ~= 0 or bit32.band(p17.flags, 268435456) == 0 and v27 then
            v28 = unit(1 - p17.blend_out_elapsed / p17.settings.blend_out)
            p17.blend_out_elapsed += p18
        else
            v28 = 1
        end
    else
        v28 = 1
    end

    local v30

    if p17.resurrection_duration > 0 and p17.resurrection_elapsed < p17.resurrection_duration then
        v30 = unit(p17.resurrection_elapsed / p17.resurrection_duration)
        p17.resurrection_elapsed += p18
    else
        v30 = 1
    end

    if not (v24 - v28 >= 0) then
        v28 = v24
    end

    if not (v28 - v30 >= 0) then
        v30 = v28
    end

    p17.weight = unit(v30 * p17.influence)

    return not (bit32.band(p17.flags, 2147483648) ~= 0 and p17.blend_in_elapsed < p17.settings.blend_in) and not (v26 and p17.blend_out_elapsed > 0)
end

function t1.ChannelPlayback.did_advance(p21, p22) -- line: 172
    p21.flags = bit32.bor(bit32.band(p21.flags, 4227858431), (bit32.lshift(if p22.crossed_end then 1 else 0, 26)))
end

function t1.ChannelPlayback.merge_attributes(p23, p24, p25) -- line: 180
    -- upvalues: rt (copy), words_cmp (copy)
    if not p23.settings.use_attributes then
        return p24
    end

    local v34 = table.create(#p24 + #p25)
    local n1 = 0
    local n2 = 0

    while n1 < #p24 and n2 < #p25 do
        local v35 = words_cmp(p24[n1 + 1].name[1], p25[n2 + 1].name[1])
        local v36, v37

        if v35 < 0 then
            v37 = n2
            table.insert(v34, rt.copy(p24[n1 + 1]))
            v36 = n1 + 1
        else
            if v35 > 0 then
                table.insert(v34, rt.copy(p25[n2 + 1]))
                v36 = n1
            else
                table.insert(v34, rt.copy(p25[n2 + 1]))
                v36 = n1 + 1
            end

            v37 = n2 + 1
        end

        n2 = v37
        n1 = v36
    end

    for i = n1, #p24 - 1 do
        table.insert(v34, rt.copy(p24[i + 1]))
    end

    for i = n2, #p25 - 1 do
        table.insert(v34, rt.copy(p25[i + 1]))
    end

    return v34
end

function t1.unit(p26) -- line: 211
    local v43 = if -p26 >= 0 then 0 else p26

    if 1 - v43 >= 0 then
        return v43
    end

    return 1
end

unit = t1.unit

return t1
