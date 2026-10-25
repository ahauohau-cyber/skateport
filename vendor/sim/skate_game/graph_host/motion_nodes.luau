-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local Attributes = import("skate_data/state_graph/attributes").Attributes
local t1 = {}

local function gh(p4) -- line: 43
    -- upvalues: import (copy), t1 (copy)
    local v8 = t1[p4]

    if v8 == nil then
        v8 = import("skate_game/graph_host/" .. p4)
        t1[p4] = v8
    end

    return v8
end

local function attribute_name_eq(p5, p6) -- line: 53
    local v9 = p5[1]
    local v10 = p6[1]

    if v9[1] == v10[1] and v9[2] == v10[2] and v9[3] == v10[3] and v9[4] == v10[4] then
        return v9[5] == v10[5]
    end

    return false
end

local function trim_char_length(p7, p8) -- line: 65
    local v11 = string.byte(p7, p8)

    if v11 ~= nil then
        if v11 == 0 or v11 == 32 or v11 >= 9 and v11 <= 13 then
            return 1
        end

        local v13 = string.byte(p7, p8 + 1)
        local v15 = string.byte(p7, p8 + 2)

        if v11 == 194 then
            if v13 == 133 or v13 == 160 then
                return 2
            end
        elseif v11 == 225 then
            if v13 == 154 and v15 == 128 then
                return 3
            end
        elseif v11 == 226 then
            if v13 == 128 and v15 ~= nil and (v15 >= 128 and v15 <= 138 or v15 == 168 or v15 == 169 or v15 == 175) or v13 == 129 and v15 == 159 then
                return 3
            end
        elseif v11 == 227 and v13 == 128 and v15 == 128 then
            return 3
        end
    end

    return 0
end

local function trim_whitespace_and_nul(p9) -- line: 98
    -- upvalues: trim_char_length (copy)
    local v16 = #p9
    local n1 = 1

    while n1 <= v16 do
        local v17 = trim_char_length(p9, n1)

        if v17 == 0 or v16 < n1 + v17 - 1 then
            break
        end

        n1 += v17
    end

    while true do
        if n1 <= v16 then
            local v18 = false

            for i = 1, 3 do
                local v19 = v16 - i + 1

                if n1 <= v19 and trim_char_length(p9, v19) == i then
                    v16 -= i
                    v18 = true
                    break
                end
            end

            if v18 then
                continue
            end
        end

        break
    end

    return (string.sub(p9, n1, v16))
end

local t2 = {
    MotionOperation = {},
    MotionFactory = {}
}

function t2.MotionFactory.default() -- line: 158
    return {}
end

local function create_named(p10, p11) -- line: 165
    -- upvalues: v1 (copy), import (copy), encode (copy), Attributes (copy), t1 (copy), t2 (copy)
    local function text_or(p12, p13) -- line: 166
        -- upvalues: p11 (copy), Attributes (copy)
        local v20 = Attributes.text(p11, p12)

        if v20 == nil then
            return p13
        end

        return v20
    end

    if p10 == "SetDeckPitchAndYaw" then
        local t3 = {
            tag = "SetDeckPitchAndYaw"
        }
        local skateyaw = Attributes.text(p11, "skateyaw")

        if skateyaw == nil then
            skateyaw = "skateyaw"
        end

        t3.yaw = encode(skateyaw)

        local skatepitch = Attributes.text(p11, "skatepitch")

        if skatepitch == nil then
            skatepitch = "skatepitch"
        end

        t3.pitch = encode(skatepitch)

        return t3
    end

    if p10 == "ResetSkaterAnimation" or p10 == "ResetToGivenStance" then
        local v21 = t1["motion_offboard/reset"]

        if v21 == nil then
            v21 = import("skate_game/graph_host/motion_offboard/reset")
            t1["motion_offboard/reset"] = v21
        end

        local v22 = v21.Operation.parse(p11)

        if v22 == nil then
            error("Invalid reset operation", 0)
        end

        return {
            tag = "ResetAnimation",
            v22
        }
    end

    if p10 == "MatchTwistAndLean" then
        local v23 = t1["motion_offboard/twist_lean"]

        if v23 == nil then
            v23 = import("skate_game/graph_host/motion_offboard/twist_lean")
            t1["motion_offboard/twist_lean"] = v23
        end

        return {
            tag = "TwistLean",
            (v23.Operation.parse(p11))
        }
    end

    if p10 == "Wipeout" then
        return {
            tag = "Wipeout",
            "Wipeout"
        }
    end

    if p10 == "EnableWipeoutGestures" then
        return {
            tag = "Wipeout",
            "EnableGestures"
        }
    end

    if p10 == "FilterMotionGraphIntent" then
        local motion_intent_filter = t1.motion_intent_filter

        if motion_intent_filter == nil then
            motion_intent_filter = import("skate_game/graph_host/motion_intent_filter")
            t1.motion_intent_filter = motion_intent_filter
        end

        return {
            tag = "IntentFilter",
            (motion_intent_filter.Operation.parse(p11))
        }
    end

    if p10 == "ToggleBoard" then
        return {
            tag = "ToggleBoard"
        }
    end

    if p10 == "AddRunoutAttribs" then
        local v24 = t1["motion_offboard/runout"]

        if v24 == nil then
            v24 = import("skate_game/graph_host/motion_offboard/runout")
            t1["motion_offboard/runout"] = v24
        end

        local v25 = v24.Operation.parse(p11)

        return if v25 ~= nil then {
            tag = "Runout",
            v25
        } else nil
    end

    if p10 == "PlayAnimation" then
        return {
            tag = "Play",
            (t2.play(p11))
        }
    end

    if p10 == "PrintText2D" then
        return {
            tag = "PrintText2D"
        }
    end

    if p10 == "ApplyingBodyTilt" then
        return {
            tag = "ApplyingBodyTilt"
        }
    end

    if p10 == "SettingBodyTilt" then
        return {
            tag = "SettingBodyTilt",
            (t2.key(p11, "tilt_x", "tilt_x"))
        }
    end

    if p10 == "Crouching" then
        return {
            tag = "Crouching",
            (t2.key(p11, "crouchName", ""))
        }
    end

    if p10 == "Pumping" then
        return {
            tag = "Pumping"
        }
    end

    if p10 == "BipedCadence" then
        return {
            tag = "BipedCadence"
        }
    end

    if p10 == "MatchCadence" then
        return {
            tag = "MatchCadence"
        }
    end

    if p10 == "OffboardBodyTweakBlend" then
        local t6 = {
            tag = "OffboardBodyTweakBlend"
        }
        local v26 = t1["motion_offboard/body_tweak"]

        if v26 ~= nil then
            t6[1] = v26.Settings.parse(p11)

            return t6
        end

        v26 = import("skate_game/graph_host/motion_offboard/body_tweak")
        t1["motion_offboard/body_tweak"] = v26
        t6[1] = v26.Settings.parse(p11)

        return t6
    end

    if p10 == "BodySpin" then
        return {
            tag = "BodySpin"
        }
    end

    if p10 == "ControlAirLegExtension" then
        local t7 = {
            tag = "AirLeg"
        }
        local motion_air_leg = t1.motion_air_leg

        if motion_air_leg ~= nil then
            t7[1] = motion_air_leg.Operation.parse(p11)

            return t7
        end

        motion_air_leg = import("skate_game/graph_host/motion_air_leg")
        t1.motion_air_leg = motion_air_leg
        t7[1] = motion_air_leg.Operation.parse(p11)

        return t7
    end

    if p10 == "ClearTrickAttr" then
        return {
            tag = "ClearTrickAttr"
        }
    end

    if p10 ~= "SetTrickHeight" and p10 ~= "FootPlantAbsorb" and p10 ~= "SetHandPlantAnticLength" and p10 ~= "ScoringHandPlants" and p10 ~= "SetTrickAttr" and p10 ~= "MonitorUnderflip" and p10 ~= "SetDark" and p10 ~= "UpdateIsWeightOnNose" then
        if p10 ~= "ScoringTrick" then
            if p10 == "SetBumpCoefficients" then
                return {
                    tag = "SetBumpCoefficients",
                    x = t2.key(p11, "X", "BumpX"),
                    y = t2.key(p11, "Y", "BumpY")
                }
            end

            if p10 == "CharacterGesture" then
                return {
                    tag = "CharacterGesture"
                }
            end

            if p10 == "EndGesture" then
                return {
                    tag = "EndGesture"
                }
            end

            if p10 == "DisallowPumping" then
                return {
                    tag = "DisallowPumping"
                }
            end

            if p10 == "FakieHeadChannel" then
                return {
                    tag = "FakieHeadChannel"
                }
            end

            if p10 ~= "SetSpeed" then
                if p10 == "UpdateRidingFakie" then
                    local t9 = {}
                    local float_bits = Attributes.float_bits

                    buffer.writef32(v1, 0, 1)
                    buffer.writeu32(v1, 0, (float_bits(p11, "highSpeedThreshold", (buffer.readu32(v1, 0)))))
                    t9.high_speed = buffer.readf32(v1, 0)

                    local float_bits2 = Attributes.float_bits

                    buffer.writef32(v1, 0, 0.5)
                    buffer.writeu32(v1, 0, (float_bits2(p11, "lowSpeedThreshold", (buffer.readu32(v1, 0)))))
                    t9.low_speed = buffer.readf32(v1, 0)
                    buffer.writeu32(v1, 0, (Attributes.float_bits(p11, "timeSlowlyRollingBackwardsThreshold", 1045220557)))
                    t9.slowly_backwards_seconds = buffer.readf32(v1, 0)

                    local float_bits3 = Attributes.float_bits

                    buffer.writef32(v1, 0, 3)
                    buffer.writeu32(v1, 0, (float_bits3(p11, "timeFromTeleportThreshold", (buffer.readu32(v1, 0)))))
                    t9.after_teleport_seconds = buffer.readf32(v1, 0)

                    return {
                        tag = "UpdateRidingFakie",
                        t9
                    }
                end

                local motion_stock_gameplay = t1.motion_stock_gameplay

                if motion_stock_gameplay == nil then
                    motion_stock_gameplay = import("skate_game/graph_host/motion_stock_gameplay")
                    t1.motion_stock_gameplay = motion_stock_gameplay
                end

                if not motion_stock_gameplay.Operation.recognizes(p10) then
                    if p10 ~= "AttachIntent" then
                        return if p10 == "SetTurning" then {
                            tag = "SetTurning",
                            {
                                t2.key(p11, "angleName", "angle"),
                                t2.key(p11, "dirName", "dir"),
                                t2.key(p11, "quicknessName", "quickness"),
                                t2.key(p11, "speedName", "speedtuck"),
                                t2.key(p11, "holdingName", "holding")
                            }
                        } else nil
                    end

                    local t10 = {
                        tag = "AttachIntent"
                    }
                    local intent = Attributes.text(p11, "intent")

                    t10.intent = if intent == nil then "0" else intent

                    local attr = Attributes.text(p11, "attr")

                    if attr == nil then
                        attr = "0"
                    end

                    t10.attribute = encode(attr)
                    t10.set = Attributes.boolean_byte(p11, "set", 0) ~= 0

                    return t10
                end

                local motion_stock_gameplay2 = t1.motion_stock_gameplay

                if motion_stock_gameplay2 == nil then
                    motion_stock_gameplay2 = import("skate_game/graph_host/motion_stock_gameplay")
                    t1.motion_stock_gameplay = motion_stock_gameplay2
                end

                return {
                    tag = "StockGameplay",
                    (motion_stock_gameplay2.Operation.parse(p11))
                }
            end

            local v31 = t2.key(p11, "attribute", "")
            local setToValue = Attributes.get(p11, "setToValue")
            local t12 = {
                tag = "SetSpeed",
                name = v31
            }

            if setToValue ~= nil then
                buffer.writeu32(v1, 0, setToValue.float_bits)
                t12.value = buffer.readf32(v1, 0)
            else
                t12.value = nil
            end

            return t12
        end

        local motion_scoring_trick = t1.motion_scoring_trick

        if motion_scoring_trick == nil then
            motion_scoring_trick = import("skate_game/graph_host/motion_scoring_trick")
            t1.motion_scoring_trick = motion_scoring_trick
        end

        return {
            tag = "ScoringTrick",
            (motion_scoring_trick.Operation.parse(p11))
        }
    end

    local motion_tricks = t1.motion_tricks

    if motion_tricks == nil then
        motion_tricks = import("skate_game/graph_host/motion_tricks")
        t1.motion_tricks = motion_tricks
    end

    local v32 = motion_tricks.Operation.parse(p11)

    return if v32 ~= nil then {
        tag = "Trick",
        v32
    } else nil
end

function t2.MotionFactory.create(_, p15, _, p17) -- line: 308
    -- upvalues: import (copy), Attributes (copy), t1 (copy), trim_whitespace_and_nul (copy), create_named (copy)
    local name = Attributes.text(p17, "name")

    if name == nil then
        error("MotionGraph operation has no name", 0)
    end

    local v33 = trim_whitespace_and_nul(name)
    local v34

    if p15 == "Condition" then
        local motion_conditions = t1.motion_conditions

        if motion_conditions == nil then
            motion_conditions = import("skate_game/graph_host/motion_conditions")
            t1.motion_conditions = motion_conditions
        end

        local v35 = motion_conditions.MotionCondition.parse(p17)

        if v35 ~= nil then
            v34 = {
                tag = "Condition",
                v35
            }
        end
    elseif p15 == "Behavior" then
        local motion_grind = t1.motion_grind

        if motion_grind == nil then
            motion_grind = import("skate_game/graph_host/motion_grind")
            t1.motion_grind = motion_grind
        end

        local v36 = motion_grind.Operation.parse(p17)

        if v36 ~= nil then
            v34 = {
                tag = "Grind",
                v36
            }
        else
            local motion_landing = t1.motion_landing

            if motion_landing == nil then
                motion_landing = import("skate_game/graph_host/motion_landing")
                t1.motion_landing = motion_landing
            end

            local v37 = motion_landing.Operation.parse(p17)

            if v37 ~= nil then
                v34 = {
                    tag = "Landing",
                    v37
                }
            else
                local motion_hand_services = t1.motion_hand_services

                if motion_hand_services == nil then
                    motion_hand_services = import("skate_game/graph_host/motion_hand_services")
                    t1.motion_hand_services = motion_hand_services
                end

                local v38 = motion_hand_services.Operation.parse(p17)

                if v38 ~= nil then
                    v34 = {
                        tag = "HandService",
                        v38
                    }
                else
                    local pushing = t1.pushing

                    if pushing == nil then
                        pushing = import("skate_game/graph_host/pushing")
                        t1.pushing = pushing
                    end

                    local v39 = pushing.PushOperation.from_attributes(p17)

                    if v39 ~= nil then
                        v34 = {
                            tag = "Push",
                            v39
                        }
                    else
                        local motion_riding = t1.motion_riding

                        if motion_riding == nil then
                            motion_riding = import("skate_game/graph_host/motion_riding")
                            t1.motion_riding = motion_riding
                        end

                        local v40 = motion_riding.RidingOperation.parse(p17)

                        if v40 ~= nil then
                            v34 = {
                                tag = "Riding",
                                v40
                            }
                        else
                            local motion_native = t1.motion_native

                            if motion_native == nil then
                                motion_native = import("skate_game/graph_host/motion_native")
                                t1.motion_native = motion_native
                            end

                            local v41 = motion_native.Operation.parse(p17)

                            if v41 ~= nil then
                                v34 = {
                                    tag = "Native",
                                    v41
                                }
                            else
                                local motion_sliding = t1.motion_sliding

                                if motion_sliding == nil then
                                    motion_sliding = import("skate_game/graph_host/motion_sliding")
                                    t1.motion_sliding = motion_sliding
                                end

                                local v42 = motion_sliding.Operation.parse(p17)

                                if v42 ~= nil then
                                    v34 = {
                                        tag = "Slide",
                                        v42
                                    }
                                else
                                    local motion_kickturn = t1.motion_kickturn

                                    if motion_kickturn == nil then
                                        motion_kickturn = import("skate_game/graph_host/motion_kickturn")
                                        t1.motion_kickturn = motion_kickturn
                                    end

                                    local v43 = motion_kickturn.Operation.parse(p17)

                                    if v43 ~= nil then
                                        v34 = {
                                            tag = "KickTurn",
                                            v43
                                        }
                                    else
                                        local motion_shove = t1.motion_shove

                                        if motion_shove == nil then
                                            motion_shove = import("skate_game/graph_host/motion_shove")
                                            t1.motion_shove = motion_shove
                                        end

                                        local v44 = motion_shove.ShoveOperation.parse(p17)

                                        if v44 ~= nil then
                                            v34 = {
                                                tag = "Shove",
                                                v44
                                            }
                                        else
                                            v34 = create_named(v33, p17)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif p15 == "Hook" then
        local motion_hooks = t1.motion_hooks

        if motion_hooks == nil then
            motion_hooks = import("skate_game/graph_host/motion_hooks")
            t1.motion_hooks = motion_hooks
        end

        local v45 = motion_hooks.MotionHook.parse(p17)

        if v45 ~= nil then
            v34 = {
                tag = "Hook",
                v45
            }
        end
    end

    if v34 == nil then
        v34 = {
            tag = "Unsupported",
            kind = p15,
            name = v33
        }
    end

    return v34
end

function t2.MotionFactory.add_parameter(_, p19, p20) -- line: 386
    -- upvalues: v1 (copy), encode (copy), Attributes (copy), t2 (copy)
    if p19.tag == "Play" then
        local v46 = p19[1]
        local from = Attributes.text(p20, "from")

        if from == nil then
            from = ""
        end

        local t14

        if from == "intent" then
            local intent = Attributes.text(p20, "intent")

            if intent == nil then
                intent = ""
            end

            t14 = {
                tag = "MotionIntent",
                intent
            }
        elseif from == "lastAnim" then
            t14 = {
                tag = "LastAnimation",
                (t2.key(p20, "attribute", ""))
            }
        else
            local filteredIntent = Attributes.text(p20, "filteredIntent")

            if filteredIntent == nil then
                filteredIntent = ""
            end

            t14 = {
                tag = "FilteredIntent",
                filteredIntent
            }
        end

        local v47 = t14.tag == "LastAnimation"
        local rename = Attributes.text(p20, "rename")
        local v48

        if rename ~= nil then
            local v49 = encode(rename)
            local v50 = encode("")
            local v51 = v49[1]
            local v52 = v50[1]

            if v51[1] ~= v52[1] or v51[2] ~= v52[2] or v51[3] ~= v52[3] or v51[4] ~= v52[4] or v51[5] ~= v52[5] then
                v48 = v49
            end
        end

        local defaultValue = Attributes.get(p20, "defaultValue")
        local parameters = v46.parameters
        local t15 = {
            source = t14,
            rename = v48
        }

        if defaultValue ~= nil then
            buffer.writeu32(v1, 0, defaultValue.float_bits)
            t15.default_value = buffer.readf32(v1, 0)
        else
            t15.default_value = nil
        end

        t15.normalized = not v47 and Attributes.boolean_byte(p20, "normalize", 0) ~= 0
        table.insert(parameters, t15)
    end
end

function t2.key(p21, p22, p23) -- line: 432
    -- upvalues: encode (copy), Attributes (copy)
    local v53 = Attributes.text(p21, p22)

    if v53 == nil then
        v53 = p23
    end

    return encode(v53)
end

function t2.play(p24) -- line: 441
    -- upvalues: v1 (copy), Attributes (copy), t2 (copy)
    local anim = Attributes.text(p24, "anim")

    if anim == nil then
        anim = ""
    end

    local t16 = {
        animation = anim,
        switch_animation = Attributes.text(p24, "switchAnim"),
        mirror_animation = Attributes.text(p24, "mirrorAnim"),
        no_board_animation = Attributes.text(p24, "noBoardAnim")
    }
    local float_bits = Attributes.float_bits

    buffer.writef32(v1, 0, 1)
    buffer.writeu32(v1, 0, (float_bits(p24, "playBackSpeed", (buffer.readu32(v1, 0)))))
    t16.playback_speed = buffer.readf32(v1, 0)
    t16.apply_posture = Attributes.boolean_byte(p24, "applyPosture", 1) ~= 0
    t16.transition = t2.transition(p24)
    t16.parameters = {}

    return t16
end

function t2.transition(p25) -- line: 459
    -- upvalues: v1 (copy), Attributes (copy)
    local transType = Attributes.text(p25, "transType")

    if transType == nil then
        transType = ""
    end

    local v55 = if transType == "play" then 1
        elseif transType == "sequence" then 4
        elseif transType == "channelblend" then 3
        else 2

    buffer.writeu32(v1, 0, (Attributes.float_bits(p25, "time", 1045220557)))

    return {
        kind = v55,
        seconds = buffer.readf32(v1, 0),
        under = if Attributes.boolean_byte(p25, "transitionUnder", 0) == 0 then 0 else 1,
        matching = if Attributes.boolean_byte(p25, "blendWithCurrentFrame", 0) ~= 0 then 1
            elseif Attributes.boolean_byte(p25, "blendMatchPhase", 0) ~= 0 then 2
            elseif Attributes.boolean_byte(p25, "blendMatchFrame", 0) == 0 then 0
            else 3,
        use_channels_from_weights = Attributes.boolean_byte(p25, "useChannelFromWeights", 0) ~= 0
    }
end

return t2
