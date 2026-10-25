-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/playback")
local v2 = import("skate_core/player/offboard/toggle_board")
local v3 = import("skate_core/animation/intent_filter")
local v4 = import("skate_core/player/offboard/twist_lean")
local v5 = import("skate_core/animation/body_tilt")
local v6 = import("skate_core/animation/riding_fakie")
local v7 = import("skate_core/animation/pumping_channel")
local v8 = import("skate_core/animation/kickturn")
local v9 = import("skate_core/animation/air_leg_extension")
local v10 = import("skate_core/animation/manual")
local t1 = {}

local function gh(p1) -- line: 26
    -- upvalues: import (copy), t1 (copy)
    local v11 = t1[p1]

    if v11 == nil then
        v11 = import("skate_game/graph_host/" .. p1)
        t1[p1] = v11
    end

    return v11
end

local t2 = {
    Instance = {}
}

function t2.Instance.new(p2) -- line: 54
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), v6 (copy), v7 (copy), v8 (copy), v9 (copy), v10 (copy), t1 (copy)
    local tag = p2.tag

    if tag == "Grind" then
        local motion_grind = t1.motion_grind

        if motion_grind == nil then
            motion_grind = import("skate_game/graph_host/motion_grind")
            t1.motion_grind = motion_grind
        end

        return {
            tag = "Grind",
            (motion_grind.State.default())
        }
    end

    if tag == "Trick" then
        return {
            tag = "Trick",
            0
        }
    end

    if tag == "ToggleBoard" then
        return {
            tag = "ToggleBoard",
            (v2.State.default())
        }
    end

    if tag == "Runout" then
        local v12 = t1["motion_offboard/runout"]

        if v12 == nil then
            v12 = import("skate_game/graph_host/motion_offboard/runout")
            t1["motion_offboard/runout"] = v12
        end

        return {
            tag = "Runout",
            (v12.State.default())
        }
    end

    if tag == "IntentFilter" then
        return {
            tag = "IntentFilter",
            (v3.State.default())
        }
    end

    if tag == "Landing" then
        local motion_landing = t1.motion_landing

        if motion_landing == nil then
            motion_landing = import("skate_game/graph_host/motion_landing")
            t1.motion_landing = motion_landing
        end

        return {
            tag = "Landing",
            (motion_landing.State.default())
        }
    end

    if tag == "Wipeout" then
        local motion_wipeout = t1.motion_wipeout

        if motion_wipeout == nil then
            motion_wipeout = import("skate_game/graph_host/motion_wipeout")
            t1.motion_wipeout = motion_wipeout
        end

        return {
            tag = "Wipeout",
            (motion_wipeout.State.default())
        }
    end

    if tag == "TwistLean" then
        return {
            tag = "TwistLean",
            (v4.State.default())
        }
    end

    if tag == "Play" then
        return {
            tag = "Play",
            (v1.PlayAnimationInstance.default())
        }
    end

    if tag == "Push" then
        local pushing = t1.pushing

        if pushing == nil then
            pushing = import("skate_game/graph_host/pushing")
            t1.pushing = pushing
        end

        return {
            tag = "Push",
            (pushing.PushInstance.new(rt.copy(p2[1])))
        }
    end

    if tag == "SetTurning" then
        return {
            tag = "Turning",
            {
                elapsed = 0,
                smoothed = 0,
                mode = 2
            }
        }
    end

    if tag == "Crouching" then
        return {
            tag = "Crouching",
            nil
        }
    end

    if tag == "SettingBodyTilt" then
        return {
            tag = "BodyTilt",
            (v5.State.default())
        }
    end

    if tag == "UpdateRidingFakie" then
        return {
            tag = "RidingFakie",
            (v6.State.default())
        }
    end

    if tag == "Pumping" then
        return {
            tag = "Pumping",
            (v7.State.default())
        }
    end

    if tag == "BipedCadence" then
        return {
            tag = "Stateless"
        }
    end

    if tag == "MatchCadence" then
        local t8 = {
            tag = "MatchCadence"
        }
        local v13 = t1["motion_offboard/cadence"]

        if v13 ~= nil then
            t8[1] = v13.MatchCadence.default()

            return t8
        end

        v13 = import("skate_game/graph_host/motion_offboard/cadence")
        t1["motion_offboard/cadence"] = v13
        t8[1] = v13.MatchCadence.default()

        return t8
    end

    if tag == "OffboardBodyTweakBlend" then
        local t9 = {
            tag = "OffboardBodyTweak"
        }
        local v14 = t1["motion_offboard/body_tweak"]

        if v14 ~= nil then
            t9[1] = v14.State.default()

            return t9
        end

        v14 = import("skate_game/graph_host/motion_offboard/body_tweak")
        t1["motion_offboard/body_tweak"] = v14
        t9[1] = v14.State.default()

        return t9
    end

    if tag == "StockGameplay" and p2[1].tag == "MatchAirTime" then
        local v15 = t1["motion_offboard/match_air_time"]

        if v15 == nil then
            v15 = import("skate_game/graph_host/motion_offboard/match_air_time")
            t1["motion_offboard/match_air_time"] = v15
        end

        return {
            tag = "MatchAirTime",
            (v15.State.default())
        }
    end

    if tag == "FakieHeadChannel" then
        local t11 = {
            tag = "FakieHead"
        }
        local motion_channels = t1.motion_channels

        if motion_channels ~= nil then
            t11[1] = motion_channels.FakieHead.default()

            return t11
        end

        motion_channels = import("skate_game/graph_host/motion_channels")
        t1.motion_channels = motion_channels
        t11[1] = motion_channels.FakieHead.default()

        return t11
    end

    if tag == "Native" and p2[1].tag == "StoreLandingData" then
        local motion_native = t1.motion_native

        if motion_native == nil then
            motion_native = import("skate_game/graph_host/motion_native")
            t1.motion_native = motion_native
        end

        return {
            tag = "LandingData",
            (motion_native.LandingData.default())
        }
    end

    if tag == "Slide" and p2[1].tag == "Update" then
        local motion_sliding = t1.motion_sliding

        if motion_sliding == nil then
            motion_sliding = import("skate_game/graph_host/motion_sliding")
            t1.motion_sliding = motion_sliding
        end

        return {
            tag = "Sliding",
            (motion_sliding.State.default())
        }
    end

    if tag == "Slide" and p2[1].tag == "Deceleration" then
        return {
            tag = "SlideDeceleration",
            0
        }
    end

    if tag == "KickTurn" and p2[1].tag == "Steering" then
        return {
            tag = "KickTurn",
            (v8.State.new())
        }
    end

    if tag == "BodySpin" then
        local t14 = {
            tag = "BodySpin"
        }
        local motion_spin = t1.motion_spin

        if motion_spin ~= nil then
            t14[1] = motion_spin.State.default()

            return t14
        end

        motion_spin = import("skate_game/graph_host/motion_spin")
        t1.motion_spin = motion_spin
        t14[1] = motion_spin.State.default()

        return t14
    end

    if tag == "AirLeg" then
        return {
            tag = "AirLeg",
            (v9.State.default())
        }
    end

    if tag == "CharacterGesture" then
        local t15 = {
            tag = "CharacterGesture"
        }
        local motion_character_gesture = t1.motion_character_gesture

        if motion_character_gesture ~= nil then
            t15[1] = motion_character_gesture.CharacterGesture.new()

            return t15
        end

        motion_character_gesture = import("skate_game/graph_host/motion_character_gesture")
        t1.motion_character_gesture = motion_character_gesture
        t15[1] = motion_character_gesture.CharacterGesture.new()

        return t15
    end

    if tag == "Shove" then
        local t16 = {
            tag = "Shove"
        }
        local motion_shove = t1.motion_shove

        if motion_shove ~= nil then
            t16[1] = motion_shove.ShoveState.new()

            return t16
        end

        motion_shove = import("skate_game/graph_host/motion_shove")
        t1.motion_shove = motion_shove
        t16[1] = motion_shove.ShoveState.new()

        return t16
    end

    if tag == "StockGameplay" and p2[1].tag == "SetManualAngle" then
        return {
            tag = "SetManualAngle",
            (v10.State.default())
        }
    end

    if tag == "StockGameplay" and p2[1].tag == "HippyJumpAntic" then
        local motion_hippy_jump = t1.motion_hippy_jump

        if motion_hippy_jump == nil then
            motion_hippy_jump = import("skate_game/graph_host/motion_hippy_jump")
            t1.motion_hippy_jump = motion_hippy_jump
        end

        return {
            tag = "HippyJumpAntic",
            (motion_hippy_jump.State.default())
        }
    end

    if tag == "StockGameplay" and p2[1].tag == "FingerFlipOut" then
        local motion_finger_flip = t1.motion_finger_flip

        if motion_finger_flip == nil then
            motion_finger_flip = import("skate_game/graph_host/motion_finger_flip")
            t1.motion_finger_flip = motion_finger_flip
        end

        return {
            tag = "FingerFlipOut",
            (motion_finger_flip.State.default())
        }
    end

    if tag == "StockGameplay" and p2[1].tag == "JumpInto" then
        return {
            tag = "JumpInto",
            first_update = true
        }
    end

    if tag ~= "StockGameplay" or p2[1].tag ~= "AirDismounting" then
        return {
            tag = "Stateless"
        }
    end

    local motion_air_dismounting = t1.motion_air_dismounting

    if motion_air_dismounting == nil then
        motion_air_dismounting = import("skate_game/graph_host/motion_air_dismounting")
        t1.motion_air_dismounting = motion_air_dismounting
    end

    return {
        tag = "AirDismounting",
        (motion_air_dismounting.State.default())
    }
end

return t2
