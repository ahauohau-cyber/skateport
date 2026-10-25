-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local v2 = import("skate_game/graph_host/motion_channels")
local v3 = import("skate_core/animation/skeleton_input/name")
local v4 = import("skate_core/graph/intents")
local MotionAnimation = v1.MotionAnimation
local MotionChannels = v2.MotionChannels
local IntentMap = v4.IntentMap
local encode = v3.encode
local t1 = {}

t1.CHANNELS = { "GestureBoth", "GestureRight", "GestureLeft" }
t1.TENTH = 0.10000000149011612
t1.CharacterGestureInputs = {}
t1.GesturePublication = {}
t1.CharacterGesture = {}

function t1.CharacterGesture.default() -- line: 45
    -- upvalues: t1 (copy)
    return t1.CharacterGesture.new()
end

function t1.CharacterGesture.new() -- line: 50
    return {
        active = false,
        stage = -1,
        direction = -1,
        hands = -1
    }
end

t1.CharacterGesture["end"] = function(p1, p2) -- line: 63
    -- upvalues: t1 (copy)
    t1.end_all(p2)
    t1.CharacterGesture.clear_active(p1)
    p1.stage = -1
end

function t1.CharacterGesture.update(p3, p4, p5) -- line: 70
    -- upvalues: t1 (copy), MotionAnimation (copy), MotionChannels (copy), encode (copy)
    local v5 = false

    for _, v6 in t1.CHANNELS do
        if MotionChannels.has(p4.channels, v6) then
            v5 = true
            break
        end
    end

    if not p3.active or v5 then
        if not p3.active and v5 then
            t1.end_all(p4)
            t1.CharacterGesture.clear_active(p3)
        end
    else
        p3.stage = -1
        t1.CharacterGesture.clear_active(p3)
    end

    local t2 = {
        t1.has(p5.motion_intents, "GestureLeftHeld"),
        t1.has(p5.motion_intents, "GestureRightHeld"),
        t1.has(p5.motion_intents, "GestureUpHeld"),
        t1.has(p5.motion_intents, "GestureDownHeld")
    }
    local v7 = t1.select_start(p5.motion_intents)
    local v8 = t1.select_hands(p4, p5)

    if v7 == -1 and p3.direction ~= -1 and not t2[p3.direction + 1] then
        v7 = -1

        for _, v9 in { 3, 0, 2, 1 } do
            if t2[v9 + 1] then
                v7 = v9
                break
            end

            v7 = -1
        end
    end

    local v10 = t1.has(p5.motion_intents, "ForceBrake") and not p5.force_brake_bypass
    local v11

    if v7 == -1 or v8 == -1 then
        v11 = false
    else
        local v12 = not v10

        if v12 then
            if p5.suppress_up and v7 == 2 then
                v11 = false
            else
                local v13 = p3.direction == -1
                local v14 = if not v13 then not t2[p3.direction + 1] else nil

                v11 = if v13 or v14 then not p3.active or v7 ~= p3.direction else v14
            end
        else
            v11 = v12
        end
    end

    if v11 then
        local v15 = t1.animation_name(v7, v8, 0, p5.selections)

        p3.direction = v7
        p3.stage = 0

        local t3 = {
            kind = 2,
            seconds = 0.20000000298023224,
            under = 0,
            matching = 0,
            use_channels_from_weights = false
        }

        MotionAnimation.transition_channel(p4, t1.CHANNELS[v8 + 1], v15, t1.settings(false, true), t3, true, true)

        if v8 == 0 then
            MotionChannels["end"](p4.channels, t1.CHANNELS[3])
            MotionChannels["end"](p4.channels, t1.CHANNELS[2])
        elseif v8 == 1 then
            MotionChannels["end"](p4.channels, t1.CHANNELS[3])
            MotionChannels["end"](p4.channels, t1.CHANNELS[1])
        elseif v8 == 2 then
            MotionChannels["end"](p4.channels, t1.CHANNELS[1])
            MotionChannels["end"](p4.channels, t1.CHANNELS[2])
        else
            error("internal error: entered unreachable code", 0)
        end

        p3.hands = v8
        p3.active = true
    elseif p3.active then
        if p3.hands == v8 then
            local v16 = t1.CHANNELS[p3.hands + 1]

            if not MotionChannels.in_transition(p4.channels, v16) and MotionChannels.remaining(p4.channels, v16) < t1.TENTH then
                if p3.stage == 0 then
                    t1.CharacterGesture.next_stage(p3, p4, p5, 1)
                elseif p3.stage ~= 1 or t2[p3.direction + 1] then
                    if p3.stage == 2 then
                        p3.stage = -1
                        t1.CharacterGesture.clear_active(p3)
                    end
                else
                    t1.CharacterGesture.next_stage(p3, p4, p5, 2)
                end
            end
        else
            t1.end_all(p4)
            t1.CharacterGesture.clear_active(p3)
        end
    end

    if not p3.active then
        return nil
    end

    local v17 = t1.selection(p3.direction, p5.selections)

    MotionAnimation.set_attribute(p4, {
        normalized = false,
        sequence_id = -1,
        name = encode("GstrDistToCog"),
        value = if p5.state_offboard75 then 1 else p5.distance_to_cog
    })

    return {
        gesture = v17,
        down = p3.direction == 3
    }
end

function t1.CharacterGesture.next_stage(p6, p7, p8, p9) -- line: 182
    -- upvalues: t1 (copy), MotionAnimation (copy)
    local v18 = t1.animation_name(p6.direction, p6.hands, p9, p8.selections)

    p6.stage = p9

    local t5 = {
        kind = 4,
        seconds = 0,
        under = 0,
        matching = 0,
        use_channels_from_weights = false
    }

    MotionAnimation.transition_channel(p7, t1.CHANNELS[p6.hands + 1], v18, t1.settings(p9 == 1, false), t5, true, true)
end

function t1.CharacterGesture.clear_active(p10) -- line: 206
    p10.active = false
    p10.direction = -1
    p10.hands = -1
end

function t1.settings(p11, p12) -- line: 213
    -- upvalues: t1 (copy)
    return {
        priority = 0,
        mirrored = false,
        speed = 1,
        hold_during_blend_out = true,
        use_attributes = false,
        keep_alive = p11,
        blend_in = t1.TENTH,
        hold_during_blend_in = p12,
        blend_out = t1.TENTH
    }
end

function t1.end_all(p13) -- line: 227
    -- upvalues: t1 (copy), MotionChannels (copy)
    for _, v19 in { 2, 1, 0 } do
        MotionChannels["end"](p13.channels, t1.CHANNELS[v19 + 1])
    end
end

function t1.has(p14, p15) -- line: 233
    -- upvalues: IntentMap (copy)
    return IntentMap.contains_key(p14, p15)
end

function t1.select_start(p16) -- line: 237
    -- upvalues: t1 (copy)
    for _, v20 in {
            { 3, "GestureDownStart" },
            { 0, "GestureLeftStart" },
            { 2, "GestureUpStart" },
            { 1, "GestureRightStart" }
        } do
        if t1.has(p16, v20[2]) then
            return v20[1]
        end
    end

    return -1
end

function t1.select_hands(p17, p18) -- line: 254
    -- upvalues: t1 (copy), MotionChannels (copy)
    local v21 = false

    for _, v22 in { "RetrieveBoard", "Shove", "WipeoutPushOff" } do
        if MotionChannels.has(p17.channels, v22) then
            v21 = true
            break
        end
    end

    if v21 or t1.has(p18.motion_intents, "OB_Mount") or t1.has(p18.motion_intents, "OB_Dismount") then
        return -1
    end

    if (p18.filtered_state == 6 or p18.filtered_state == 7) and not p18.ground321 then
        if p18.board_held311 then
            return 2
        end

        return 0
    end

    local v23 = p18.busy_hands[1] ~= 0
    local v24 = p18.busy_hands[2] ~= 0

    if v23 or v24 then
        if not v23 and v24 then
            return 1
        end

        if not v23 or v24 then
            return -1
        end

        return 2
    end

    return 0
end

function t1.selection(p19, p20) -- line: 282
    local n1 = 1

    if p19 == 0 then
        n1 = 2
    elseif p19 == 1 then
        n1 = 3
    elseif p19 == 2 then
        n1 = 0
    elseif p19 ~= 3 then
        return 37
    end

    if p20 == nil then
        error("CharacterGesture needs the actual skater gesture selections", 0)
    end

    return p20[n1 + 1]
end

function t1.animation_name(p21, p22, p23, p24) -- line: 302
    -- upvalues: t1 (copy)
    local v25 = t1.selection(p21, p24)
    local v26 = t1.NAMES[v25 + 1]

    if v26 == nil then
        error(("Invalid stock gesture selection %*"):format(v25), 0)
    end

    local t6 = {
        "INTO",
        "CYC",
        "OUT"
    }
    local v27 = ({ "BOTH", "RIGHT", "LEFT" })[p22 + 1]
    local v28 = t6[p23 + 1]

    if v27 == nil or v28 == nil then
        error("index out of bounds", 0)
    end

    return (("%*_%*_%*"):format(v26, v27, v28))
end

t1.NAMES = {
    "B_GSTR_AIRGUITAR",
    "B_GSTR_AIRPLANE",
    "B_GSTR_BOXING",
    "B_GSTR_BRUCE_LEE",
    "B_GSTR_CHECKTIME",
    "B_GSTR_DEVIL",
    "B_GSTR_DBLE_GUN",
    "B_GSTR_DUNNO",
    "B_GSTR_FINGERWAG",
    "B_GSTR_FISTS",
    "B_GSTR_BICEPFLEX",
    "B_GSTR_FLIPTABLE",
    "B_GSTR_FONZ_EH",
    "B_GSTR_FREEDOM",
    "B_GSTR_FU_FIST",
    "B_GSTR_GETAWAY",
    "B_GSTR_GETOUTTAHERE",
    "B_GSTR_HANDCUFFS",
    "B_GSTR_HIGHPUMP",
    "B_GSTR_LOWPUMP",
    "B_GSTR_PREWIND",
    "B_GSTR_PEACE",
    "B_GSTR_POINT",
    "B_GSTR_RAISEROOF",
    "B_GSTR_SHAKA",
    "B_GSTR_SHRUG",
    "B_GSTR_POINT_SKY",
    "B_GSTR_SNAP",
    "B_GSTR_SOULARCH",
    "B_GSTR_SPOCK",
    "B_GSTR_SURFSUP",
    "B_GSTR_SWINGHIGH",
    "B_GSTR_SWINGLOW",
    "B_GSTR_THROWARMS",
    "B_GSTR_THMB_DWN",
    "B_GSTR_WINGS",
    "B_GSTR_YARDSALE"
}

return t1
