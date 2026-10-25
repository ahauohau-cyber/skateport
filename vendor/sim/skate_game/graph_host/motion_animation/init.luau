-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/posture")
local v2 = import("skate_core/animation/output/attributes")
local v3 = import("skate_core/animation/playback_parameters")
local PlaybackTransition = import("skate_core/animation/playback_transition").PlaybackTransition
local PlaybackTree = import("skate_core/animation/playback_tree").PlaybackTree
local SelectionSpace = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
local encode = import("skate_core/animation/skeleton_input/name").encode
local IntentMap = import("skate_core/graph/intents").IntentMap
local v4 = import("skate_core/player/offboard/reset_animation")
local v5 = import("skate_game/graph_host/motion_channels")
local v6 = import("skate_game/graph_host/outputs")
local v7 = import("skate_game/graph_host/motion_animation/selection_space_host")
local v8 = import("skate_game/graph_host/motion_animation/tree_builder")
local v9 = import("skate_game/graph_host/motion_animation/stock_clip_query")
local v10

local function motion_stock_gameplay() -- line: 28
    -- upvalues: import (copy), v10 (ref)
    local v11 = v10

    if v11 == nil then
        v11 = import("skate_game/graph_host/motion_stock_gameplay")
        v10 = v11
    end

    return v11
end

local build = v8.build
local is_static = v7.is_static
local v12 = false
local t1 = {}

function t1.set_reference(p1) -- line: 46
    -- upvalues: v12 (ref)
    v12 = p1
end

local AttributeName, MotionGraphAttribute = v2.AttributeName, v2.MotionGraphAttribute
local SettableAttributes = v3.SettableAttributes
local PendingPosture = v1.PendingPosture
local MotionChannels = v5.MotionChannels

t1.MotionAnimation = {}

function t1.MotionAnimation.seek_current_fraction(p2, p3) -- line: 77
    -- upvalues: PlaybackTree (copy)
    local current = p2.current

    if current ~= nil then
        PlaybackTree.set_time(current, PlaybackTree.length(current) * p3)
    end
end

function t1.MotionAnimation.metadata(p4) -- line: 85
    return p4.metadata
end

function t1.MotionAnimation.pending_parameter(p5, p6) -- line: 91
    -- upvalues: AttributeName (copy), SettableAttributes (copy)
    for _, v13 in SettableAttributes.entries(p5.settable) do
        if AttributeName.eq(v13.name, p6) then
            return v13.value
        end
    end

    return nil
end

function t1.MotionAnimation.accept_action_graph(p7, p8) -- line: 101
    -- upvalues: v6 (copy)
    v6.MotionEffects.apply_to(p8.motion_effects, p7.motion_intents)
end

function t1.MotionAnimation.reset_from_stock(p9) -- line: 105
    -- upvalues: IntentMap (copy), SettableAttributes (copy), MotionChannels (copy)
    p9.current = nil
    p9.current_name = nil
    MotionChannels.reset_from_stock(p9.channels)
    p9.grab_type = nil
    IntentMap.clear(p9.motion_intents)
    IntentMap.clear(p9.filtered_intents)
    table.clear(p9.motion_attributes)
    table.clear(p9.tree_attributes)
    SettableAttributes.clear(p9.settable)

    if p9.skater_animation_flags ~= nil then
        p9.skater_animation_flags = bit32.band(p9.skater_animation_flags, 267911167)
    end

    p9.relative_stance = 0
    p9.reset_action_intents = true
    p9.property = {
        crossed_end = false,
        overshoot = -1,
        remaining_before_wrap = -1
    }
end

function t1.MotionAnimation.reset_to_given_stance(p10) -- line: 125
    -- upvalues: v4 (copy)
    local skater_animation_flags = p10.skater_animation_flags

    if skater_animation_flags == nil then
        error("Stance reset requires SkaterAnim flags", 0)
    end

    local v14 = p10.relative_stance ~= 0
    local v15, v16, v17 = v4.given_stance(p10.natural_stance, p10.requested_stance, skater_animation_flags, v14)

    p10.requested_stance = v15
    p10.skater_animation_flags = v16
    p10.relative_stance = v17 and 1 or 0
end

function t1.MotionAnimation.from_metadata(p11) -- line: 141
    -- upvalues: IntentMap (copy), SettableAttributes (copy), PendingPosture (copy), MotionChannels (copy)
    return {
        current = nil,
        current_name = nil,
        grab_type = nil,
        posture_bank_valid = false,
        skater_animation_flags = nil,
        air_dismount_revert_frames = nil,
        natural_stance = 1,
        relative_stance = 0,
        requested_stance = 0,
        reset_action_intents = false,
        metadata = p11,
        channels = MotionChannels.default(),
        motion_intents = IntentMap.new(),
        filtered_intents = IntentMap.new(),
        motion_attributes = {},
        construction_values = {},
        posture = PendingPosture.default(),
        attribute_mirror = { {} },
        settable = SettableAttributes.default(),
        tree_attributes = {},
        property = {
            crossed_end = false,
            overshoot = -1,
            remaining_before_wrap = -1
        }
    }
end

function t1.MotionAnimation.set_hierarchy(p12, p13, p14) -- line: 173
    -- upvalues: encode (copy)
    if #p13 ~= #p14 then
        error("Animation hierarchy mirror count differs from bone count", 0)
    end

    local v18 = table.create(#p13)

    for v19, v20 in p13 do
        local v21 = p14[v19 - 1 + 1]
        local v22

        if v21 == -1 then
            v22 = v20
        elseif v21 >= 0 then
            v22 = p13[v21 + 1]

            if v22 == nil then
                error("Invalid mirrored bone index", 0)
            end
        else
            error("Invalid negative mirrored bone index", 0)
        end

        table.insert(v18, {
            encode(v20),
            encode(v22)
        })
    end

    p12.attribute_mirror = { v18 }
end

function t1.MotionAnimation.tree_attributes(p15) -- line: 198
    return p15.tree_attributes
end

function t1.MotionAnimation.property(p16) -- line: 203
    -- upvalues: rt (copy)
    return rt.copy(p16.property)
end

function t1.MotionAnimation.current_time(p17) -- line: 208
    -- upvalues: PlaybackTree (copy)
    if p17.current == nil then
        error("No current animation tree", 0)
    end

    return PlaybackTree.time(p17.current)
end

function t1.MotionAnimation.current_length(p18) -- line: 216
    -- upvalues: PlaybackTree (copy)
    if p18.current == nil then
        error("No current animation tree", 0)
    end

    return PlaybackTree.length(p18.current)
end

function t1.MotionAnimation.synchronize_air_time(p19, p20) -- line: 225
    -- upvalues: PlaybackTree (copy)
    local current = p19.current

    if current ~= nil then
        PlaybackTree.set_time(current, PlaybackTree.length(current) * p20)
    end
end

function t1.MotionAnimation.in_transition(p21) -- line: 232
    -- upvalues: t1 (copy)
    return p21.current ~= nil and (t1.has_transition(p21.current))
end

function t1.MotionAnimation.jump_into(p22, p23) -- line: 240
    -- upvalues: rt (copy), PlaybackTree (copy), t1 (copy), MotionGraphAttribute (copy)
    t1.MotionAnimation.apply_parameters(p22)

    local current = p22.current

    if current == nil then
        error("JumpInto requires a current animation tree", 0)
    end

    local v23 = MotionGraphAttribute.to_animation({
        value = 0,
        name = rt.copy(p23)
    })

    if PlaybackTree.query_attribute(current, p23, 31, v23) then
        PlaybackTree.set_time(current, v23.begin_time)
    end
end

function t1.MotionAnimation.advance(p24, p25, p26) -- line: 255
    -- upvalues: PlaybackTree (copy), t1 (copy), MotionChannels (copy)
    MotionChannels.retire(p24.channels)

    local current = p24.current

    p24.current = nil

    if current ~= nil then
        p24.current = t1.prune(current)
    end

    p24.property = {
        crossed_end = false,
        overshoot = -1,
        remaining_before_wrap = -1
    }

    local current2 = p24.current

    if current2 ~= nil then
        PlaybackTree.advance(current2, p25, p26, p24.property)
    end

    MotionChannels.advance(p24.channels, p25, p26)
end

function t1.MotionAnimation.apply_parameters_reference(p27) -- line: 276
    -- upvalues: rt (copy), PlaybackTree (copy), t1 (copy), SettableAttributes (copy), MotionChannels (copy)
    local v24 = rt.copy(SettableAttributes.entries(p27.settable))
    local current = p27.current

    p27.current = nil

    if current ~= nil then
        local prepare_selection_spaces = t1.MotionAnimation.prepare_selection_spaces
        local ok, result = pcall(prepare_selection_spaces, p27, current, v24)

        p27.current = current

        if not ok then
            error(result, 0)
        end
    end

    local channels = p27.channels

    p27.channels = MotionChannels.default()

    local prepare_trees = MotionChannels.prepare_trees

    local function v25(p28) -- line: 291
        -- upvalues: p27 (copy), v24 (copy), t1 (copy)
        t1.MotionAnimation.prepare_selection_spaces(p27, p28, v24)
    end

    local ok, result = pcall(prepare_trees, channels, v25)

    p27.channels = channels

    if not ok then
        error(result, 0)
    end

    local current2 = p27.current

    if current2 ~= nil then
        PlaybackTree.set_attributes(current2, SettableAttributes.entries(p27.settable))
    end

    MotionChannels.set_attributes(p27.channels, SettableAttributes.entries(p27.settable))
    SettableAttributes.clear(p27.settable)
end

function t1.MotionAnimation.apply_parameters(p29) -- line: 319
    -- upvalues: PlaybackTree (copy), t1 (copy), v12 (ref), SettableAttributes (copy), MotionChannels (copy)
    if v12 then
        return t1.MotionAnimation.apply_parameters_reference(p29)
    end

    local v26 = SettableAttributes.entries(p29.settable)
    local current = p29.current

    p29.current = nil

    if current ~= nil then
        local prepare_selection_spaces = t1.MotionAnimation.prepare_selection_spaces
        local ok, result = pcall(prepare_selection_spaces, p29, current, v26)

        p29.current = current

        if not ok then
            error(result, 0)
        end
    end

    local channels = p29.channels

    p29.channels = MotionChannels.default()

    local prepare_trees = MotionChannels.prepare_trees

    local function v27(p30) -- line: 337
        -- upvalues: p29 (copy), v26 (copy), t1 (copy)
        t1.MotionAnimation.prepare_selection_spaces(p29, p30, v26)
    end

    local ok, result = pcall(prepare_trees, channels, v27)

    p29.channels = channels

    if not ok then
        error(result, 0)
    end

    local current2 = p29.current

    if current2 ~= nil then
        PlaybackTree.set_attributes(current2, SettableAttributes.entries(p29.settable))
    end

    MotionChannels.set_attributes(p29.channels, SettableAttributes.entries(p29.settable))
    SettableAttributes.clear(p29.settable)
end

function t1.MotionAnimation.evaluate_pose(p31, p32) -- line: 353
    -- upvalues: PlaybackTree (copy), MotionChannels (copy)
    local t3 = {}
    local current = p31.current

    if current == nil then
        error("MotionGraph has not selected an animation", 0)
    end

    PlaybackTree.evaluate(current, p32, true, t3)
    MotionChannels.evaluate(p31.channels, p32, t3)

    return t3
end

function t1.MotionAnimation.refresh_tree_attributes(p33) -- line: 365
    -- upvalues: PlaybackTree (copy), MotionChannels (copy)
    local v28 = if p33.current == nil then {} else PlaybackTree.attributes(p33.current, 15)

    p33.tree_attributes = MotionChannels.attributes(p33.channels, v28, 15)
end

function t1.MotionAnimation.begin_graph_update(p34) -- line: 375
    table.clear(p34.motion_attributes)
end

function t1.MotionAnimation.attach(p35, p36, p37, p38) -- line: 380
    -- upvalues: rt (copy), t1 (copy)
    local v29 = t1.MotionAnimation.motion_intent(p35, p36)

    if v29 == nil then
        return
    end

    table.insert(p35.motion_attributes, {
        name = rt.copy(p37),
        value = v29
    })

    if p38 then
        t1.MotionAnimation.set_attribute(p35, {
            normalized = false,
            sequence_id = -1,
            name = rt.copy(p37),
            value = v29
        })
    end
end

function t1.MotionAnimation.emit_packet(p39, p40, p41) -- line: 399
    table.insert(p39.motion_attributes, {
        name = p40,
        value = p41
    })
end

function t1.MotionAnimation.set_grab_type(p42, p43) -- line: 404
    -- upvalues: import (copy), encode (copy), v10 (ref), t1 (copy)
    p42.grab_type = p43

    local emit_packet = t1.MotionAnimation.emit_packet
    local GrabType = encode("GrabType")
    local v30 = v10

    if v30 == nil then
        v30 = import("skate_game/graph_host/motion_stock_gameplay")
        v10 = v30
    end

    emit_packet(p42, GrabType, v30.GrabType.as_value(p43))
end

function t1.MotionAnimation.clear_grab_type(p44) -- line: 409
    p44.grab_type = nil
end

function t1.MotionAnimation.build_tree(p45, p46) -- line: 414
    -- upvalues: build (copy)
    return build(p45.metadata, p46, p45.construction_values, {})
end

function t1.MotionAnimation.new_channel(p47, p48, p49, p50) -- line: 419
    -- upvalues: PlaybackTree (copy), t1 (copy), MotionChannels (copy)
    if MotionChannels.has(p47.channels, p48) then
        return false
    end

    local v31 = t1.MotionAnimation.build_tree(p47, p49)

    PlaybackTree.set_speed(v31, p50.speed)

    local v32 = t1.MotionAnimation.add_bind_pose(p47, v31, nil)

    if p50.mirrored and v32.tag == "BindPose" then
        table.insert(v32.mirror_modes, 2)
    end

    MotionChannels.insert(p47.channels, p48, v32, p50)

    return true
end

function t1.MotionAnimation.transition_channel(p51, p52, p53, p54, p55, p56, p57) -- line: 436
    -- upvalues: PlaybackTree (copy), t1 (copy), MotionChannels (copy)
    if MotionChannels.has(p51.channels, p52) then
        if not MotionChannels.can_transition(p51.channels, p52, p56) then
            return false
        end

        local v33 = t1.MotionAnimation.build_tree(p51, p53)

        PlaybackTree.set_speed(v33, p54.speed)

        local v34 = t1.MotionAnimation.add_bind_pose(p51, v33, nil)

        if p54.mirrored and v34.tag == "BindPose" then
            table.insert(v34.mirror_modes, 2)
        end

        MotionChannels.transition(p51.channels, p52, v34, p54, p55, p56)

        return true
    end

    if p57 then
        return t1.MotionAnimation.new_channel(p51, p52, p53, p54)
    end

    return false
end

function t1.MotionAnimation.add_bind_pose(p58, p59, p60) -- line: 468
    local skater_animation_flags = p58.skater_animation_flags

    if skater_animation_flags == nil then
        error("Animation construction requires actual SkaterAnim flags", 0)
    end

    local t6 = {}

    if bit32.band(skater_animation_flags, 1073741824) ~= 0 then
        table.insert(t6, 2)
    end

    if bit32.band(skater_animation_flags, 4194304) ~= 0 then
        table.insert(t6, (if bit32.band(skater_animation_flags, 2097152) == 0 then 1 else 0) + 1)
    end

    p58.skater_animation_flags = bit32.band(skater_animation_flags, 4288675839)

    if #t6 ~= 0 and #p58.attribute_mirror[1] == 0 then
        error("Mirrored animation requires the stock bone hierarchy", 0)
    end

    return {
        tag = "BindPose",
        motion = p59,
        posture = p60,
        board_backwards = bit32.band(skater_animation_flags, 2147483648) ~= 0,
        mirror_modes = t6,
        attribute_mirror = p58.attribute_mirror
    }
end

function t1.has_transition(p61) -- line: 495
    -- upvalues: SelectionSpace (copy), t1 (copy)
    local tag = p61.tag

    if tag == "Transition" then
        return true
    end

    if tag == "PhaseBlend" or tag == "BlendSpace" then
        for _, v36 in p61[1].children do
            if t1.has_transition(v36) then
                return true
            end
        end
    else
        if tag == "SelectionSpace" then
            local v38 = SelectionSpace.current(p61[1])

            return v38 ~= nil and (t1.has_transition(v38))
        end

        if tag == "BindPose" then
            return t1.has_transition(p61.motion)
        end
    end

    return false
end

function t1.prune(p62) -- line: 527
    -- upvalues: PlaybackTransition (copy), t1 (copy), is_static (copy), v12 (ref)
    if v12 then
        return t1.prune_reference(p62)
    end

    if not is_static(p62) then
        local tag = p62.tag

        if tag == "Transition" then
            local v39 = p62[1]

            if PlaybackTransition.complete(v39) then
                return t1.prune(v39.to)
            end

            v39.from = t1.prune(v39.from)
            v39.to = t1.prune(v39.to)
        elseif tag == "BlendSpace" or tag == "PhaseBlend" then
            local v40 = p62[1]

            for v41, v42 in v40.children do
                v40.children[v41] = t1.prune(v42)
            end
        elseif tag == "SelectionSpace" then
            for _, v46 in p62[1].candidates do
                v46.tree = t1.prune(v46.tree)
            end
        elseif tag == "BindPose" then
            p62.motion = t1.prune(p62.motion)
        end
    end

    return p62
end

function t1.prune_reference(p63) -- line: 571
    -- upvalues: PlaybackTransition (copy), t1 (copy)
    local tag = p63.tag

    if tag == "Transition" then
        local v47 = p63[1]

        if PlaybackTransition.complete(v47) then
            return t1.prune_reference(v47.to)
        end

        v47.from = t1.prune_reference(v47.from)
        v47.to = t1.prune_reference(v47.to)
    elseif tag == "BlendSpace" or tag == "PhaseBlend" then
        local v48 = p63[1]

        for v49, v50 in v48.children do
            v48.children[v49] = t1.prune_reference(v50)
        end
    elseif tag == "SelectionSpace" then
        for _, v54 in p63[1].candidates do
            v54.tree = t1.prune_reference(v54.tree)
        end
    elseif tag == "BindPose" then
        p63.motion = t1.prune_reference(p63.motion)
    end

    return p63
end

function t1.MotionAnimation.motion_intent(p64, p65) -- line: 609
    -- upvalues: IntentMap (copy)
    return IntentMap.get(p64.motion_intents, p65)
end

function t1.MotionAnimation.filtered_intent(p66, p67) -- line: 613
    -- upvalues: IntentMap (copy)
    return IntentMap.get(p66.filtered_intents, p67)
end

function t1.MotionAnimation.last_attribute(p68, p69) -- line: 618
    -- upvalues: rt (copy), AttributeName (copy)
    for _, v55 in p68.tree_attributes do
        if AttributeName.eq(v55.name, p69) then
            return rt.copy(v55)
        end
    end

    return nil
end

function t1.MotionAnimation.push_set_attribute(p70, p71) -- line: 631
    -- upvalues: encode (copy), t1 (copy)
    t1.MotionAnimation.set_attribute(p70, {
        name = encode(p71.name),
        value = p71.value,
        normalized = p71.normalized,
        sequence_id = p71.sequence_id
    })
end

function t1.MotionAnimation.set_attribute(p72, p73) -- line: 642
    -- upvalues: t1 (copy), SettableAttributes (copy)
    if type(p73.name) == "string" then
        t1.MotionAnimation.push_set_attribute(p72, p73)
    else
        SettableAttributes.set_attribute(p72.settable, p73)
    end
end

function t1.MotionAnimation.set_construction_value(p74, p75, p76) -- line: 653
    -- upvalues: AttributeName (copy)
    local v56

    for _, v57 in p74.construction_values do
        if AttributeName.eq(v57[1], p75) then
            v56 = v57
            break
        end
    end

    if v56 ~= nil then
        v56[2] = p76

        return
    end

    table.insert(p74.construction_values, {
        p75,
        p76
    })
end

function t1.MotionAnimation.set_posture_enabled(p77, p78) -- line: 668
    -- upvalues: PendingPosture (copy)
    PendingPosture.set_requested(p77.posture, p78)
end

function t1.MotionAnimation.play(p79, p80) -- line: 673
    -- upvalues: rt (copy), PlaybackTransition (copy), PlaybackTree (copy), t1 (copy), PendingPosture (copy)
    if not (p80.transition.kind >= 1 and p80.transition.kind <= 4) then
        return false
    end

    if p80.transition.kind == 1 then
        p79.current = nil
    end

    local v58 = t1.MotionAnimation.build_tree(p79, p80.animation)
    local v59

    if p79.posture_bank_valid then
        local v60 = PendingPosture.apply(p79.posture, {
            v58,
            nil
        }, function(p81, p82) -- line: 686
            return {
                p81[1],
                p82
            }
        end)

        v58 = v60[1]
        v59 = v60[2]
    end

    local v61 = t1.MotionAnimation.add_bind_pose(p79, v58, v59)

    PlaybackTree.set_speed(v61, p80.speed)

    local current = p79.current

    p79.current = nil

    if p80.start_time > 0 and (p80.transition.kind == 1 or current ~= nil) then
        PlaybackTree.set_time(v61, p80.start_time)
    end

    if current ~= nil then
        if p80.transition.under == 0 then
            p79.current = {
                tag = "Transition",
                (PlaybackTransition.new(current, v61, rt.copy(p80.transition)))
            }
        elseif current.tag == "Transition" then
            local v62 = current[1]
            local to = v62.to

            v62.to = {
                tag = "Transition",
                (PlaybackTransition.new(to, v61, rt.copy(p80.transition)))
            }
            p79.current = current
        else
            p79.current = {
                tag = "Transition",
                (PlaybackTransition.new(current, v61, rt.copy(p80.transition)))
            }
        end
    else
        p79.current = v61
    end

    p79.current_name = p80.animation

    return true
end

for _, v63 in { v7, v9 } do
    for v64, v65 in v63.MotionAnimation do
        t1.MotionAnimation[v64] = v65
    end
end

local v66 = import("skate_game/graph_host/motion_grind/animation_owner")

if v66.MotionAnimation ~= nil then
    for v67, v68 in v66.MotionAnimation do
        if t1.MotionAnimation[v67] == nil then
            t1.MotionAnimation[v67] = v68
        end
    end
end

return t1
