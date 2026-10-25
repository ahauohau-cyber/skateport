-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ChannelPlayback = import("skate_core/animation/channel_playback").ChannelPlayback
local intent_key = import("skate_core/animation/playback_parameters").intent_key
local PlaybackTree = import("skate_core/animation/playback_tree").PlaybackTree
local PlaybackTransition = import("skate_core/animation/playback_transition").PlaybackTransition
local encode = import("skate_core/animation/skeleton_input/name").encode
local v1

local function motion_animation() -- line: 18
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_animation")
        v1 = v2
    end

    return v2
end

local t1 = {}

local function key_eq(p1, p2) -- line: 32
    if p1[1] == p2[1] and p1[2] == p2[2] and p1[3] == p2[3] and p1[4] == p2[4] and p1[5] == p2[5] then
        return p1[6] == p2[6]
    end

    return false
end

t1.Channel = {}
t1.MotionChannels = {}

function t1.MotionChannels.default() -- line: 47
    return {
        channels = {}
    }
end

function t1.MotionChannels.reset_from_stock(p3) -- line: 51
    table.clear(p3.channels)
end

function t1.MotionChannels.prepare_trees(p4, p5) -- line: 56
    for _, v3 in p4.channels do
        p5(v3.tree)
    end
end

function t1.MotionChannels.has(p6, p7) -- line: 64
    -- upvalues: intent_key (copy), key_eq (copy)
    for _, v4 in p6.channels do
        if key_eq(intent_key(v4.name), intent_key(p7)) then
            return true
        end
    end

    return false
end

function t1.MotionChannels.remaining(p8, p9) -- line: 74
    -- upvalues: intent_key (copy), PlaybackTree (copy), key_eq (copy)
    for _, v5 in p8.channels do
        if key_eq(intent_key(v5.name), intent_key(p9)) then
            local v6 = PlaybackTree.length(v5.tree) - PlaybackTree.time(v5.tree)

            if v6 >= 0 then
                return v6
            end

            return 0
        end
    end

    return 0
end

function t1.MotionChannels.elapsed(p10, p11) -- line: 89
    -- upvalues: intent_key (copy), PlaybackTree (copy), key_eq (copy)
    for _, v7 in p10.channels do
        if key_eq(intent_key(v7.name), intent_key(p11)) then
            local v8 = PlaybackTree.time(v7.tree)

            if -v8 >= 0 then
                v8 = 0
            end

            local v9 = PlaybackTree.length(v7.tree)

            if v9 - v8 >= 0 then
                return v8
            end

            return v9
        end
    end

    return 0
end

function t1.MotionChannels.in_transition(p12, p13) -- line: 106
    -- upvalues: intent_key (copy), key_eq (copy)
    for _, v10 in p12.channels do
        if key_eq(intent_key(v10.name), intent_key(p13)) then
            return v10.tree.tag == "Transition"
        end
    end

    return false
end

function t1.MotionChannels.insert(p14, p15, p16, p17) -- line: 116
    -- upvalues: rt (copy), ChannelPlayback (copy)
    local v11 = 0
    local v12 = #p14.channels

    while v11 < v12 do
        local v13 = v11 + rt.idiv(v12 - v11, 2)

        if p14.channels[v13 + 1].playback.settings.priority <= p17.priority then
            v11 = v13 + 1
        else
            v12 = v13
        end
    end

    table.insert(p14.channels, v11 + 1, {
        name = p15,
        tree = p16,
        playback = ChannelPlayback.new(p17)
    })
end

t1.MotionChannels["end"] = function(p18, p19) -- line: 137
    -- upvalues: ChannelPlayback (copy), t1 (copy)
    local v15 = t1.MotionChannels.find_mut(p18, p19)

    if v15 ~= nil then
        ChannelPlayback["end"](v15.playback)
    end
end

function t1.MotionChannels.end_with(p20, p21, p22, p23) -- line: 144
    -- upvalues: ChannelPlayback (copy), t1 (copy)
    local v16 = t1.MotionChannels.find_mut(p20, p21)

    if v16 ~= nil then
        ChannelPlayback.end_with(v16.playback, p22, p23)
    end
end

function t1.MotionChannels.influence(p24, p25, p26) -- line: 151
    -- upvalues: t1 (copy)
    local v17 = t1.MotionChannels.find_mut(p24, p25)

    if v17 == nil then
        return false
    end

    v17.playback.influence = p26

    return true
end

function t1.MotionChannels.can_transition(p27, p28, p29) -- line: 161
    -- upvalues: ChannelPlayback (copy), t1 (copy)
    local v18 = t1.MotionChannels.find_mut(p27, p28)

    return v18 ~= nil and (ChannelPlayback.can_transition(v18.playback, p29))
end

function t1.MotionChannels.transition(p30, p31, p32, p33, p34, p35) -- line: 167
    -- upvalues: ChannelPlayback (copy), intent_key (copy), PlaybackTransition (copy), key_eq (copy)
    local v19

    for v20, v21 in p30.channels do
        if key_eq(intent_key(v21.name), intent_key(p31)) then
            v19 = v20 - 1
            break
        end
    end

    if v19 == nil then
        return
    end

    local v22 = table.remove(p30.channels, v19 + 1)
    local v23 = if v22.tree.tag == "Transition" then v22.tree[1].to else v22.tree

    v22.tree = {
        tag = "Transition",
        (PlaybackTransition.new(v23, p32, p34))
    }
    ChannelPlayback.transition(v22.playback, p33, p35)
    table.insert(p30.channels, v19 + 1, v22)
end

function t1.MotionChannels.find_mut(p36, p37) -- line: 192
    -- upvalues: intent_key (copy), key_eq (copy)
    for _, v25 in p36.channels do
        if key_eq(intent_key(v25.name), intent_key(p37)) then
            return v25
        end
    end

    return nil
end

function t1.MotionChannels.retire(p38) -- line: 201
    -- upvalues: rt (copy), ChannelPlayback (copy), PlaybackTransition (copy)
    for _, v26 in p38.channels do
        if v26.tree.tag == "Transition" then
            local v27 = v26.tree[1]

            if PlaybackTransition.complete(v27) then
                v26.tree = rt.copy(v27.to)
            end
        end
    end

    local v28 = #p38.channels
    local n1 = 0

    for i = 1, v28 do
        local v29 = p38.channels[i]

        if not ChannelPlayback.expired(v29.playback) then
            n1 += 1
            p38.channels[n1] = v29
        end
    end

    for i = v28, n1 + 1, -1 do
        p38.channels[i] = nil
    end
end

function t1.MotionChannels.advance(p39, p40, p41) -- line: 227
    -- upvalues: ChannelPlayback (copy), PlaybackTree (copy)
    for _, v30 in p39.channels do
        if ChannelPlayback.advance(v30.playback, p40, PlaybackTree.length(v30.tree), PlaybackTree.time(v30.tree)) then
            local t3 = {
                crossed_end = false,
                overshoot = -1,
                remaining_before_wrap = -1
            }

            PlaybackTree.advance(v30.tree, p40, p41, t3)
            ChannelPlayback.did_advance(v30.playback, t3)
        end
    end
end

function t1.MotionChannels.set_attributes(p42, p43) -- line: 242
    -- upvalues: PlaybackTree (copy)
    for _, v31 in p42.channels do
        PlaybackTree.set_attributes(v31.tree, p43)
    end
end

function t1.MotionChannels.attributes(p44, p45, p46) -- line: 251
    -- upvalues: ChannelPlayback (copy), PlaybackTree (copy)
    for _, v33 in p44.channels do
        if v33.playback.settings.use_attributes then
            p45 = ChannelPlayback.merge_attributes(v33.playback, p45, PlaybackTree.attributes(v33.tree, p46))
        end
    end

    return p45
end

function t1.MotionChannels.query_attribute(p47, p48, p49, p50) -- line: 261
    -- upvalues: PlaybackTree (copy)
    for i = #p47.channels, 1, -1 do
        local v34 = p47.channels[i]

        if PlaybackTree.query_attribute(v34.tree, p48, p49, p50) then
            return true
        end
    end

    return false
end

function t1.MotionChannels.evaluate(p51, p52, p53) -- line: 273
    -- upvalues: PlaybackTree (copy)
    for _, v35 in p51.channels do
        local v36 = v35.playback.weight > 0

        if PlaybackTree.evaluate(v35.tree, p52, v36, p53) and v36 then
            table.insert(p53, {
                tag = "ChannelBlend",
                use_channels_from_weights = false,
                weight = v35.playback.weight
            })
        end
    end
end

t1.FakieHead = {}

function t1.FakieHead.default() -- line: 290
    return {
        value = 0,
        was_fakie = false
    }
end

function t1.FakieHead.update(p54, p55, p56, p57, p58) -- line: 295
    -- upvalues: import (copy), encode (copy), v1 (ref), t1 (copy)
    local v37 = v1

    if v37 == nil then
        v37 = import("skate_game/graph_host/motion_animation")
        v1 = v37
    end

    local MotionAnimation = v37.MotionAnimation
    local v38 = if p56 then 1 elseif p57 then 0 else 0.5

    if p54.was_fakie or not p58 then
        if p54.was_fakie and not p58 then
            t1.MotionChannels["end"](p55.channels, "fakie")
        end
    else
        local t5 = {
            priority = 0,
            keep_alive = true,
            mirrored = false,
            speed = 1,
            blend_in = 0.30000001192092896,
            hold_during_blend_in = false,
            blend_out = 0.30000001192092896,
            hold_during_blend_out = false,
            use_attributes = false
        }
        local t6 = {
            kind = 2,
            seconds = 0.10000000149011612,
            under = 0,
            matching = 0,
            use_channels_from_weights = false
        }

        MotionAnimation.transition_channel(p55, "fakie", "B_FAKIE_CHANNEL", t5, t6, true, true)
        p54.value = v38
    end

    p54.was_fakie = p58

    if not p58 then
        return
    end

    local v39 = v38 - p54.value

    if -0.009999999776482582 - v39 >= 0 then
        v39 = -0.009999999776482582
    end

    if not (0.009999999776482582 - v39 >= 0) then
        v39 = 0.009999999776482582
    end

    p54.value += v39
    MotionAnimation.set_attribute(p55, {
        normalized = false,
        sequence_id = -1,
        name = encode("torso"),
        value = p54.value
    })
end

return t1
