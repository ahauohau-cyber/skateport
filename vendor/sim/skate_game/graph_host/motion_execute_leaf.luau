-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local v2 = import("skate_game/graph_host/motion_channels")
local v3 = import("skate_game/graph_host/motion_kickturn")
local v4 = import("skate_game/graph_host/motion_offboard/cadence")
local v5 = import("skate_game/graph_host/motion_offboard/body_tweak")
local v6 = import("skate_game/graph_host/motion_offboard/match_air_time")
local v7 = import("skate_game/graph_host/motion_shove")
local v8 = import("skate_game/graph_host/motion_character_gesture")
local v9 = import("skate_game/graph_host/motion_native")
local v10 = import("skate_game/graph_host/motion_stock_gameplay")
local v11 = import("skate_game/graph_host/motion_air_dismounting")
local v12 = import("skate_game/graph_host/motion_finger_flip")
local v13 = import("skate_game/graph_host/motion_hippy_jump")
local v14 = import("skate_game/graph_host/motion_riding")
local v15 = import("skate_game/graph_host/pushing")
local v16 = import("skate_core/animation/skeleton_input/name")
local v17 = import("skate_core/animation/playback")
local v18 = import("skate_core/animation/pumping_channel")
local v19 = import("skate_core/animation/riding_fakie")
local v20 = import("skate_core/animation/manual")
local v21 = import("skate_core/animation/body_tilt")
local v22 = import("skate_core/animation/crouching")
local v23 = import("skate_core/graph/intents")
local v24 = import("skate_core/input/set_turning")
local t1 = {}
local v25

local function motion() -- line: 42
    -- upvalues: import (copy), v25 (ref)
    local v26 = v25

    if v26 == nil then
        v26 = import("skate_game/graph_host/motion")
        v25 = v26
    end

    return v26
end

local MotionAnimation = v1.MotionAnimation
local MotionChannels = v2.MotionChannels
local IntentMap = v23.IntentMap
local encode = v16.encode

local function as_attribute_sink(p1) -- line: 57
    -- upvalues: MotionAnimation (copy)
    return {
        set_attribute = function(_, p3) -- set_attribute | line: 59
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.set_attribute(p1, p3)
        end
    }
end

local function as_playback_service(p4) -- line: 66
    -- upvalues: MotionAnimation (copy)
    return {
        set_construction_value = function(_, p6, p7) -- set_construction_value | line: 68
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.set_construction_value(p4, p6, p7)
        end,
        set_posture_enabled = function(_, p9) -- set_posture_enabled | line: 71
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.set_posture_enabled(p4, p9)
        end,
        play = function(_, p11) -- play | line: 74
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.play(p4, p11)
        end,
        motion_intent = function(_, p13) -- motion_intent | line: 77
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.motion_intent(p4, p13)
        end,
        filtered_intent = function(_, p15) -- filtered_intent | line: 80
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.filtered_intent(p4, p15)
        end,
        last_attribute = function(_, p17) -- last_attribute | line: 83
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.last_attribute(p4, p17)
        end,
        set_attribute = function(_, p19) -- set_attribute | line: 86
            -- upvalues: p4 (copy), MotionAnimation (copy)
            return MotionAnimation.set_attribute(p4, p19)
        end
    }
end

local function as_push_animation_sink(p20) -- line: 97
    -- upvalues: MotionAnimation (copy), encode (copy)
    return {
        set_attribute = function(_, p22) -- set_attribute | line: 99
            -- upvalues: p20 (copy), MotionAnimation (copy), encode (copy)
            return MotionAnimation.set_attribute(p20, {
                name = encode(p22.name),
                value = p22.value,
                normalized = p22.normalized,
                sequence_id = p22.sequence_id
            })
        end
    }
end

local function debug_fmt(p23) -- line: 111
    -- upvalues: debug_fmt (copy)
    local v27 = type(p23)

    if p23 == nil then
        return "None"
    end

    if v27 == "string" then
        return "\"" .. p23 .. "\""
    end

    if v27 ~= "table" then
        return (tostring(p23))
    end

    local t5 = {}

    for v28 in p23 do
        if type(v28) == "string" and v28 ~= "tag" then
            table.insert(t5, v28)
        end
    end

    table.sort(t5)

    local t6 = {}

    if #t5 > 0 then
        for _, v29 in t5 do
            table.insert(t6, v29 .. ": " .. debug_fmt(p23[v29]))
        end

        local v31 = "{ " .. table.concat(t6, ", ") .. " }"

        if p23.tag == nil then
            return v31
        end

        return p23.tag .. " " .. v31
    end

    for _, v32 in ipairs(p23) do
        table.insert(t6, debug_fmt(v32))
    end

    if p23.tag == nil then
        return "[" .. table.concat(t6, ", ") .. "]"
    end

    if #t6 > 0 then
        return p23.tag .. "(" .. table.concat(t6, ", ") .. ")"
    end

    return p23.tag
end

local t7 = {
    "PUMP0",
    "PUMP1",
    "PUMP2",
    "PUMP3",
    "PUMP4"
}

function t1.execute(p24, p25, p26, p27, p28) -- line: 147
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), v6 (copy), v7 (copy), v8 (copy), v9 (copy), v10 (copy), v11 (copy), v12 (copy), v13 (copy), v14 (copy), v15 (copy), v17 (copy), v18 (copy), v19 (copy), v20 (copy), v21 (copy), v22 (copy), v24 (copy), v25 (ref), MotionAnimation (copy), MotionChannels (copy), IntentMap (copy), encode (copy), as_playback_service (copy), debug_fmt (copy), t7 (copy)
    local v33 = p24.instances[p25 + 1]

    if v33 == nil then
        error("Unallocated MotionGraph behavior", 0)
    end

    local tag = p26.tag
    local tag2 = v33.tag

    if tag == "BipedCadence" then
        if p28 == 1 then
            p24.animation_phase = v4.biped_cadence(p24.offboard_cadence_phase, p24.animation_phase, p28)
        end

        return
    end

    local v34, physical, skater_animation_flags, v35

    if tag == "MatchCadence" and tag2 == "MatchCadence" then
        v34 = v33[1]
        v35 = v4.MatchCadence

        if p28 == 0 then
            v35.begin(v34, p24.offboard_cadence_phase, true)
        elseif p28 == 1 then
            physical = v35.update

            local animation = p24.animation

            skater_animation_flags = {}

            function skater_animation_flags.set_attribute(_, p30) -- line: 59
                -- upvalues: animation (copy), MotionAnimation (copy)
                return MotionAnimation.set_attribute(animation, p30)
            end

            physical(v34, skater_animation_flags)
        else
            v35["end"](v34)
        end

        return
    end

    local v36

    if tag == "OffboardBodyTweakBlend" and tag2 == "OffboardBodyTweak" then
        v34 = p26[1]
        v35 = v33[1]

        if p28 == 0 then
            v5.State.begin(v35)
        elseif p28 == 1 then
            physical = p24.gameplay_conditions

            if physical == nil then
                error("OffboardBodyTweakBlend requires completed OffBoard output", 0)
            end

            v36 = p24.playback_context.board_available

            if v36 == nil then
                error("OffboardBodyTweakBlend requires OffBoard311", 0)
            end

            v5.State.update(v35, v34, p24.animation, p24.wipeout_controls, {
                time_to_land = physical.offboard_time_to_land,
                scalar_92 = physical.offboard_air_scalar_92,
                board_held = v36
            })
        else
            v5.State["end"](v35, p24.animation)
        end

        return
    end

    if tag == "SetDeckPitchAndYaw" then
        if p28 == 0 then
            v34 = p24.deck_yaw_pitch

            if v34 == nil then
                error("SetDeckPitchAndYaw requires completed Skeleton output", 0)
            end

            v35 = {
                p26.yaw,
                p26.pitch
            }

            for i = 1, 2 do
                MotionAnimation.set_attribute(p24.animation, {
                    normalized = false,
                    sequence_id = -1,
                    name = v35[i],
                    value = v34[i]
                })
            end
        end

        return
    end

    if tag == "PrintText2D" then
        return
    end

    if tag == "Shove" and tag2 == "Shove" then
        v34 = p26[1]
        v35 = v33[1]

        if p28 == 0 then
            v7.ShoveState.begin(v35)
        elseif p28 == 1 then
            physical = p24.shove_physical

            if physical == nil then
                error("Shove requires actual interaction output", 0)
            end

            v36 = p24.playback_context.is_mirrored

            if v36 == nil then
                error("Shove requires animation stance", 0)
            end

            v7.ShoveState.update(v35, v34, p24.animation, rt.copy(physical), rt.copy(p24.hand_services.busy_hands), v36)
        else
            v7.ShoveState["end"](v35, p24.animation, p24.hand_services.keep_shove_channels)
        end

        return
    end

    local v37, update

    if tag == "CharacterGesture" and tag2 == "CharacterGesture" then
        v34 = v33[1]

        if p28 == 1 then
            v35 = p24.gesture_physical

            if v35 == nil then
                error("CharacterGesture requires original physical and hostgesture publication", 0)
            end

            physical = rt.copy(p24.animation.motion_intents)
            v36 = p24.condition_inputs.physical_state

            if v36 == nil then
                error("CharacterGesture requires filteredcategory", 0)
            end

            skater_animation_flags = p24.playback_context.board_available

            if skater_animation_flags == nil then
                error("CharacterGesture requires boardheldbyte311", 0)
            end

            update = p24.crouching_physical

            if update == nil then
                error("CharacterGesture requires actualheight", 0)
            end

            v37 = {
                motion_intents = physical,
                busy_hands = rt.copy(p24.hand_services.busy_hands),
                filtered_state = v36.category,
                ground321 = v35.ground321,
                board_held311 = skater_animation_flags,
                state_offboard75 = v35.state_offboard75,
                distance_to_cog = update.animation_height_72,
                selections = rt.copy(v35.selections),
                suppress_up = v35.suppress_up,
                force_brake_bypass = v35.force_brake_bypass
            }
            p24.gesture_publication = v8.CharacterGesture.update(v34, p24.animation, v37)
        end

        return
    end

    if tag == "EndGesture" then
        if p28 == 0 then
            v34 = v25

            if v34 == nil then
                v34 = import("skate_game/graph_host/motion")
                v25 = v34
            end

            v34.MotionHost.end_gesture_channels(p24)
        end

        return
    end

    if tag == "Native" and p26[1].tag == "StoreLandingData" and tag2 == "LandingData" then
        v34 = v33[1]

        if p28 == 1 then
            v35 = p24.condition_inputs.physical_state

            if v35 == nil then
                error("StoreLandingData requires physical category", 0)
            end

            physical = p24.native_physical

            if physical == nil then
                error("StoreLandingData requires raw physical COM velocity/up", 0)
            end

            v9.LandingData.update(v34, v35.category, rt.copy(physical), p24.riding)
        end

        return
    end

    if tag == "Native" and p26[1].tag == "EndShimmy" then
        v34 = p26[1][1]

        if p28 == 0 then
            v9.end_shimmy(p24.animation, v34)
        end

        return
    end

    if tag == "Native" and p26[1].tag == "Score" then
        v34 = p26[1].regular
        v35 = p26[1].mirrored

        if p28 == 1 then
            physical = p24.playback_context.is_mirrored

            if physical == nil then
                error("Score augmentation requires animation stance", 0)
            end

            v36 = v9.ScorePacket.set
            skater_animation_flags = p24.score_packet

            if not physical then
                v35 = v34
            end

            v36(skater_animation_flags, v35)
        end
    elseif tag == "KickTurn" and p26[1].tag == "ResetTimer" then
        if p28 == 0 or p28 == 2 then
            p24.riding.time_since_kickturn = 0
        end
    elseif tag == "KickTurn" and p26[1].tag == "Steering" and tag2 == "KickTurn" then
        v34 = p26[1][1]
        v35 = v33[1]
        v3.execute(v35, v34, p24.kickturn, p24.animation, p27.dt, p28)
    elseif tag == "FakieHeadChannel" and tag2 == "FakieHead" then
        v34 = v33[1]

        if p28 == 1 then
            v35 = p24.animation.skater_animation_flags

            if v35 == nil then
                error("FakieHeadChannel requires actual animation flags", 0)
            end

            physical = bit32.band(v35, 536870912) ~= 0
            v2.FakieHead.update(v34, p24.animation, p24.flags.manualing, p24.is_power_sliding, physical)
        end
    elseif tag == "Pumping" and tag2 == "Pumping" then
        v34 = v33[1]

        if p28 == 2 then
            for _, v38 in t7 do
                MotionChannels["end"](p24.animation.channels, v38)
            end
        else
            if p28 ~= 1 or not p24.allow_pumping then
                return
            end

            physical = {
                MotionChannels.has(p24.animation.channels, t7[1]),
                MotionChannels.has(p24.animation.channels, t7[2]),
                MotionChannels.has(p24.animation.channels, t7[3]),
                MotionChannels.has(p24.animation.channels, t7[4]),
                MotionChannels.has(p24.animation.channels, t7[5])
            }
            v36 = p24.pumping_acceleration

            if v36 == nil then
                error("Pumping requires actual ground pumping acceleration", 0)
            end

            skater_animation_flags = v18.State.update(v34, v36, physical, p24.pumping)

            if skater_animation_flags.start ~= nil then
                v36 = skater_animation_flags.start
                physical = {
                    priority = 0,
                    keep_alive = false,
                    mirrored = false,
                    speed = 1,
                    hold_during_blend_in = false,
                    hold_during_blend_out = true,
                    use_attributes = false,
                    blend_in = p24.pumping.blend_in,
                    blend_out = p24.pumping.blend_out
                }
                MotionAnimation.new_channel(p24.animation, t7[v36 + 1], "B_PUMP", physical)
            end

            if skater_animation_flags.influence ~= nil then
                update = skater_animation_flags.influence[1]
                v37 = skater_animation_flags.influence[2]
                MotionChannels.influence(p24.animation.channels, t7[update + 1], v37)
            end
        end
    elseif tag == "DisallowPumping" then
        if p28 == 0 then
            for _, v39 in { "PUMP0", "PUMP1", "PUMP2", "PUMP3", "PUMP4" } do
                MotionChannels.end_with(p24.animation.channels, v39, 0.10000000149011612, false)
            end

            p24.allow_pumping = false
        elseif p28 == 2 then
            p24.allow_pumping = true
        end
    elseif tag == "SetSpeed" then
        if p28 == 1 then
            local physical_state = p26.value

            if physical_state ~= nil then
                v34 = physical_state
            else
                v35 = p24.crouching_physical

                if v35 == nil then
                    error("SetSpeed requires actual ground-projected speed", 0)
                end

                v34 = v35.body_164
            end

            MotionAnimation.set_attribute(p24.animation, {
                normalized = false,
                sequence_id = -1,
                name = p26.name,
                value = math.abs(v34)
            })
        end
    elseif tag == "UpdateRidingFakie" and tag2 == "RidingFakie" then
        v34 = p26[1]
        v35 = v33[1]

        if p28 ~= 1 then
            return
        end

        if p24.fakie_physical == nil then
            error("UpdateRidingFakie requires actual physical outputs", 0)
        end

        local v40 = rt.copy(p24.fakie_physical)

        v40.doing_trick = p24.flags.doing_trick
        v36 = v19.State.update(v35, v40, p27.dt, v34)

        if v36 ~= nil then
            physical = p24.animation.skater_animation_flags

            if physical == nil then
                error("UpdateRidingFakie requires actual animation flags", 0)
            end

            skater_animation_flags = p24.animation
            v37 = bit32.band(physical, 3758096383)
            skater_animation_flags.skater_animation_flags = bit32.bor(v37, v36 and 536870912 or 0)
        end
    elseif tag == "StockGameplay" then
        v34 = p26[1]
        v35 = v34.tag

        if v35 == "AirDismounting" then
            if tag2 ~= "AirDismounting" then
                error("AirDismounting operation/instance mismatch", 0)
            end

            physical = v33[1]

            if p28 == 0 then
                v36 = MotionAnimation.current_length(p24.animation)
                skater_animation_flags = MotionAnimation.current_time(p24.animation)
                v11.State.begin(physical, v36, skater_animation_flags)
            else
                if p28 ~= 1 then
                    return
                end

                v36 = v11.State.request(physical, MotionAnimation.tree_attributes(p24.animation))

                if v36 ~= nil then
                    skater_animation_flags = p24.animation.skater_animation_flags

                    if skater_animation_flags == nil then
                        error("AirDismounting requires SkaterAnim flags", 0)
                    end

                    p24.animation.skater_animation_flags = bit32.bor(skater_animation_flags, 1048576)
                    p24.animation.air_dismount_revert_frames = v36
                end
            end
        else
            if v35 == "FingerFlipOut" then
                physical = v34.grab_intent

                if tag2 ~= "FingerFlipOut" then
                    error("FingerFlipOut operation/instance mismatch", 0)
                end

                v36 = v33[1]

                if p28 == 0 then
                    v12.State.begin(v36)
                elseif p28 == 1 then
                    skater_animation_flags = v12.State.update(v36, IntentMap.contains_key(p24.animation.motion_intents, physical), p27.dt, p24.finger_flip)
                    MotionAnimation.set_attribute(p24.animation, {
                        normalized = false,
                        sequence_id = -1,
                        name = encode("Grabbing"),
                        value = skater_animation_flags
                    })
                end

                return
            end

            if v35 == "MatchAirTime" then
                if tag2 ~= "MatchAirTime" then
                    error("MatchAirTime operation/instance mismatch", 0)
                end

                physical = v33[1]

                if p28 ~= 2 then
                    v36 = p24.gameplay_conditions

                    if v36 == nil then
                        error("MatchAirTime requires completed OffBoard output", 0)
                    end

                    if p28 == 0 then
                        skater_animation_flags = p24.offboard_cadence_phase

                        if skater_animation_flags == nil then
                            error("MatchAirTime requires completed OffBoard80", 0)
                        end

                        v6.State.begin(physical, skater_animation_flags, v36.offboard_air_scalar_92, rt.copy(v36.offboard_air_translation))
                    else
                        v6.State.update(physical, p24.animation, v36.offboard_time_to_land, v36.offboard_air_scalar_92, rt.copy(v36.offboard_air_translation))
                    end
                end

                return
            end

            if v35 == "InitMovingObjects" then
                if p28 == 0 then
                    v10.MovingObjectRegistry.register(p24.moving_objects, v34.path)
                end

                return
            end

            if v35 == "MovingObject" then
                physical = v34.path

                if p28 == 0 then
                    v10.MovingObjectRegistry.begin(p24.moving_objects, physical)
                elseif p28 == 1 then
                    if not v10.MovingObjectRegistry.update(p24.moving_objects, physical) then
                        error(("MovingObject is not active: %*"):format(physical), 0)
                    end
                else
                    v10.MovingObjectRegistry["end"](p24.moving_objects)
                end

                return
            end

            if v35 == "LandOnBoard" then
                if p28 == 0 then
                    v36 = p24.gameplay_conditions

                    if v36 == nil then
                        error("LandOnBoard requires completed physical output", 0)
                    end

                    physical = v36.landing_turning
                else
                    physical = false
                end

                if physical then
                    v36 = p24.animation.skater_animation_flags

                    if v36 == nil then
                        error("LandOnBoard requires SkaterAnim orientation", 0)
                    end

                    p24.animation.skater_animation_flags = bit32.bxor(v36, 2147483648)
                end

                return
            end

            if v35 == "UpdateStandingOnCar" then
                return
            end

            if v35 == "SetGrabType" then
                physical = v10.GrabType.parse(v34.grab)

                if p28 == 0 then
                    MotionAnimation.set_grab_type(p24.animation, physical)
                elseif p28 == 2 then
                    MotionAnimation.clear_grab_type(p24.animation)
                end

                return
            end

            local v41

            if v35 == "ScoringGrabs" then
                if p28 == 1 then
                    physical = MotionAnimation.filtered_intent(p24.animation, v34.intent_x)

                    if physical == nil then
                        physical = 0
                    end

                    v36 = MotionAnimation.filtered_intent(p24.animation, v34.intent_y)

                    if v36 == nil then
                        v36 = 0
                    end

                    if v34.polar then
                        skater_animation_flags = v36 * math.sin(physical)
                        v36 *= math.cos(physical)

                        if v34.invert_y then
                            v36 = -v36
                        end
                    else
                        skater_animation_flags = physical
                    end

                    v41 = {
                        v34.up,
                        v34.left,
                        v34.down,
                        v34.right
                    }
                    v37 = v10.select_grab_score(v34.grab_name, v41, skater_animation_flags, v36)
                    p24.score_packet.grab = {
                        encode(v37),
                        { skater_animation_flags, v36 }
                    }
                end

                return
            end

            if v35 == "TweakProject" then
                if p28 == 1 then
                    physical = MotionAnimation.filtered_intent(p24.animation, v34.intent_x)
                    v36 = MotionAnimation.filtered_intent(p24.animation, v34.intent_y)

                    if physical ~= nil or v36 ~= nil then
                        if physical == nil then
                            physical = 0
                        end

                        if v36 == nil then
                            v36 = 0
                        end

                        v41 = math.abs(physical) + math.abs(v36)

                        if v41 > 1 then
                            update = 1 / v41
                            physical *= update
                            v36 *= update
                        end

                        MotionAnimation.set_attribute(p24.animation, {
                            normalized = false,
                            sequence_id = -1,
                            name = v34.attribute_x,
                            value = physical
                        })
                        MotionAnimation.set_attribute(p24.animation, {
                            normalized = false,
                            sequence_id = -1,
                            name = v34.attribute_y,
                            value = v36
                        })
                    end
                end
            elseif v35 == "JumpInto" then
                if tag2 ~= "JumpInto" then
                    error("JumpInto instance was not allocated", 0)
                end

                if p28 ~= 1 then
                    return
                end

                if v33.first_update then
                    MotionAnimation.jump_into(p24.animation, v34.attribute)
                    v33.first_update = false
                end
            elseif v35 ~= "SetManualAngle" then
                if v35 == "HippyJumpAntic" then
                    if tag2 ~= "HippyJumpAntic" then
                        error("HippyJumpAntic instance was not allocated", 0)
                    end

                    physical = v33[1]

                    if p28 == 0 then
                        v13.State.begin(physical)
                    elseif p28 == 1 then
                        v13.State.update(physical, p24.animation, p24.hippy_jump)
                    elseif p28 == 2 then
                        v13.State["end"](physical)
                    else
                        error("internal error: entered unreachable code", 0)
                    end
                else
                    error(("MotionGraph stock gameplay producer %* is not implemented"):format((debug_fmt(v34))), 0)
                end
            else
                if tag2 ~= "SetManualAngle" then
                    error("SetManualAngle instance was not allocated", 0)
                end

                physical = v33[1]

                if p28 == 0 then
                    v20.State.begin(physical)
                elseif p28 == 1 then
                    v36 = v20.State.update(physical, MotionAnimation.motion_intent(p24.animation, "Manual"), p24.manual)
                    MotionAnimation.set_attribute(p24.animation, {
                        normalized = false,
                        sequence_id = -1,
                        name = v34.attribute,
                        value = v36
                    })
                end
            end
        end
    elseif tag ~= "SettingBodyTilt" or tag2 ~= "BodyTilt" then
        if tag == "Play" and tag2 == "Play" then
            v34 = p26[1]
            v35 = v33[1]
            physical = v17.PlayAnimationInstance

            if p28 == 0 then
                physical.begin(v35, v34, p24.playback_context, (as_playback_service(p24.animation)))
            elseif p28 == 1 then
                physical.update(v35, v34, (as_playback_service(p24.animation)))
            else
                physical["end"](v35)
            end
        elseif tag == "AttachIntent" then
            if p28 == 1 then
                MotionAnimation.attach(p24.animation, p26.intent, p26.attribute, p26.set)
            end
        elseif tag == "Riding" then
            local physical_state = p24.condition_inputs.physical_state

            v35 = if physical_state ~= nil then physical_state.category else nil
            v34 = p24.crouching_physical
            physical = if v34 ~= nil then v34.animation_height_72 else nil
            v14.RidingState.execute(p24.riding, p26[1], p28, p27, p24.animation, v35, physical, p24.flags.manualing)
        elseif tag == "ApplyingBodyTilt" then
            if p28 == 0 then
                p24.applying_body_tilt = true
            elseif p28 == 2 then
                p24.applying_body_tilt = false
            end
        elseif tag == "Crouching" and tag2 == "Crouching" then
            v34 = p26[1]

            if p28 == 0 then
                local crouching_physical = p24.crouching_physical

                if crouching_physical == nil then
                    error("Crouching Begin requires real physical height and speed", 0)
                end

                v33[1] = v22.State.begin(rt.copy(crouching_physical), p24.crouching)
            elseif p28 == 1 then
                local t8 = {
                    auto_pump_angle = MotionAnimation.motion_intent(p24.animation, "AutoPumpAngle"),
                    auto_pump_magnitude = MotionAnimation.motion_intent(p24.animation, "AutoPumpMag"),
                    crouch = MotionAnimation.motion_intent(p24.animation, "Crouch"),
                    hard_turn_crouch = MotionAnimation.motion_intent(p24.animation, "HardTurnCrouch"),
                    manual = MotionAnimation.motion_intent(p24.animation, "Manual"),
                    motion_flag_108 = p24.is_power_sliding
                }

                physical = v33[1]

                if physical == nil then
                    error("Crouching updated before Begin", 0)
                end

                v36 = p24.crouching_physical

                if v36 == nil then
                    error("Crouching requires actual physical outputs", 0)
                end

                skater_animation_flags = v22.State.update(physical, rt.copy(v36), t8, p27.dt, p24.crouching)

                if skater_animation_flags.new_auto_pump then
                    MotionAnimation.emit_packet(p24.animation, encode("NewAutoPump"), 1)
                end

                if skater_animation_flags.player_controlled_pump then
                    MotionAnimation.emit_packet(p24.animation, encode("PlayerControlledPump"), 1)
                end

                MotionAnimation.set_attribute(p24.animation, {
                    normalized = false,
                    sequence_id = -1,
                    name = v34,
                    value = skater_animation_flags.height
                })
            end
        elseif tag == "SetTurning" and tag2 == "Turning" then
            local v42 = p26[1]

            v35 = v33[1]

            if p28 == 0 then
                v24.State.enter(v35)
            elseif p28 == 1 then
                physical = p24.physical

                if physical == nil then
                    error("SetTurning requires actual PhysOutAnimation and stance outputs", 0)
                end

                v36 = {
                    fakie_turn = MotionAnimation.motion_intent(p24.animation, "FakieTurn"),
                    mode_0_slide = MotionAnimation.motion_intent(p24.animation, "LeftSlide"),
                    mode_1_slide = MotionAnimation.motion_intent(p24.animation, "RightSlide")
                }
                skater_animation_flags = p24.animation.skater_animation_flags

                if skater_animation_flags == nil then
                    error("SetTurning requires actual animation stance flags", 0)
                end

                update = v24.update
                update(v35, p24.slide_latch, rt.copy(physical.turning), {
                    bit32.band(skater_animation_flags, 536870912) ~= 0,
                    bit32.band(skater_animation_flags, 1073741824) ~= 0
                }, p27.dt, p24.turning, v36, function(p31, p32) -- line: 803
                    -- upvalues: p24 (copy), v42 (copy), rt (copy), MotionAnimation (copy), encode (copy)
                    local v44

                    if p31 == "Angle" then
                        v44 = 0
                    elseif p31 == "Direction" then
                        v44 = 1
                    elseif p31 == "Quickness" then
                        v44 = 2
                    elseif p31 == "Speed" then
                        v44 = 3
                    elseif p31 == "Holding" then
                        v44 = 4
                    end

                    if v44 ~= nil then
                        MotionAnimation.set_attribute(p24.animation, {
                            normalized = false,
                            sequence_id = -1,
                            name = rt.copy(v42[v44 + 1]),
                            value = p32
                        })
                    else
                        MotionAnimation.emit_packet(p24.animation, encode(p31 == "Turn" and "Turn" or "Slide"), p32)
                    end
                end)
            end
        elseif tag == "Push" and tag2 == "Push" then
            v34 = v33[1]

            local physical2 = p24.physical

            if physical2 == nil then
                error("Push behavior requires actual skater physical outputs", 0)
            end

            physical = rt.copy(p24.animation.motion_intents)
            v36 = p24.push_state

            if v36 == nil then
                error("Native push state initialization has not been published", 0)
            end

            skater_animation_flags = {
                settings = p24.pushing,
                shared = v36,
                motion_intents = physical,
                forward_speed = physical2.forward_speed,
                delta_seconds = p27.dt,
                time_since_teleport = p24.riding.time_since_teleport,
                is_switch = physical2.is_switch,
                foot_frame = rt.copy(physical2.foot_frame)
            }
            v36 = v15.PushInstance

            if p28 == 0 then
                update = v36.begin

                local animation = p24.animation

                update(v34, skater_animation_flags, {
                    set_attribute = function(_, p34) -- set_attribute | line: 99
                        -- upvalues: animation (copy), MotionAnimation (copy), encode (copy)
                        return MotionAnimation.set_attribute(animation, {
                            name = encode(p34.name),
                            value = p34.value,
                            normalized = p34.normalized,
                            sequence_id = p34.sequence_id
                        })
                    end
                })
            elseif p28 == 1 then
                update = v36.update

                local animation = p24.animation

                update(v34, skater_animation_flags, {
                    set_attribute = function(_, p36) -- set_attribute | line: 99
                        -- upvalues: animation (copy), MotionAnimation (copy), encode (copy)
                        return MotionAnimation.set_attribute(animation, {
                            name = encode(p36.name),
                            value = p36.value,
                            normalized = p36.normalized,
                            sequence_id = p36.sequence_id
                        })
                    end
                })
            else
                v36["end"](v34, skater_animation_flags)
            end
        elseif tag == "Unsupported" then
            error(("Unsupported MotionGraph %* %*"):format(p26.kind, p26.name), 0)
        else
            error(("Invalid MotionGraph behavior instance %*"):format((debug_fmt(p26))), 0)
        end
    else
        v34 = p26[1]
        v35 = v33[1]

        if p28 == 1 and p24.applying_body_tilt then
            physical = p24.playback_context.is_mirrored

            if physical == nil then
                error("SettingBodyTilt needs actual mirrored stance", 0)
            end

            v36 = p24.body_tilt_physical

            if v36 == nil then
                error("SettingBodyTilt needs actual PhysOut tilt and spin", 0)
            end

            skater_animation_flags = v21.State.update(v35, true, physical, rt.copy(v36), p24.body_tilt)

            if skater_animation_flags ~= nil then
                MotionAnimation.set_attribute(p24.animation, {
                    normalized = false,
                    sequence_id = -1,
                    name = v34,
                    value = skater_animation_flags
                })
            end
        elseif p28 == 1 then
            v21.State.disable(v35)
        end
    end
end

return t1
