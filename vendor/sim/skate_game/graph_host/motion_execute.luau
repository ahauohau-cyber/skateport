-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local v2 = import("skate_game/graph_host/motion_grind")
local v3 = import("skate_game/graph_host/motion_tricks")
local v4 = import("skate_game/graph_host/motion_offboard/runout")
local v5 = import("skate_game/graph_host/motion_landing")
local v6 = import("skate_game/graph_host/motion_landing_execute")
local v7 = import("skate_game/graph_host/motion_hand_services")
local v8 = import("skate_game/graph_host/outputs")
local v9 = import("skate_core/graph/intents")
local v10 = import("skate_game/graph_host/motion_execute_leaf")
local t1 = {}
local v11

local function motion() -- line: 30
    -- upvalues: import (copy), v11 (ref)
    local v12 = v11

    if v12 == nil then
        v12 = import("skate_game/graph_host/motion")
        v11 = v12
    end

    return v12
end

local MotionAnimation = v1.MotionAnimation
local IntentMap = v9.IntentMap

local function as_grind_animation(p1) -- line: 43
    -- upvalues: MotionAnimation (copy)
    return {
        set_attribute = function(_, p3) -- set_attribute | line: 45
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.set_attribute(p1, p3)
        end,
        apply_parameters = function(_) -- apply_parameters | line: 48
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.apply_parameters(p1)
        end,
        query_current_attribute = function(_, p6, p7, p8) -- query_current_attribute | line: 51
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.query_current_attribute(p1, p6, p7, p8)
        end,
        emit_packet = function(_, p10, p11) -- emit_packet | line: 54
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.emit_packet(p1, p10, p11)
        end,
        intent = function(_, p13) -- intent | line: 57
            -- upvalues: p1 (copy), MotionAnimation (copy)
            return MotionAnimation.intent(p1, p13)
        end
    }
end

local function as_attribute_sink(p14) -- line: 64
    -- upvalues: MotionAnimation (copy)
    return {
        set_attribute = function(_, p16) -- set_attribute | line: 66
            -- upvalues: p14 (copy), MotionAnimation (copy)
            return MotionAnimation.set_attribute(p14, p16)
        end
    }
end

t1.MotionHost = {}

local v13 = false

function t1.set_reference(p17) -- line: 76
    -- upvalues: v13 (ref)
    v13 = p17
end

function t1.MotionHost.execute(p18, p19, p20, p21) -- line: 96
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), v6 (copy), v7 (copy), v8 (copy), v10 (copy), v11 (ref), MotionAnimation (copy), IntentMap (copy), as_grind_animation (copy), v13 (ref)
    local v14 = p18.remap.behaviors[p19 + 1]

    if v14 == nil then
        error("Unbound MotionGraph behavior", 0)
    end

    local v15 = p18.operations[v14 + 1]

    if v15 == nil then
        error("index out of bounds", 0)
    end

    if v15.tag ~= "AttachIntent" or v13 then
        local v17 = rt.copy(v15)

        if v17.tag == "Grind" then
            local v18 = v17[1]

            if p21 ~= 2 and (p21 ~= 0 or v18.tag ~= "Attributes") then
                if p18.grind_physical == nil then
                    error("Grind graph requires completed physical grind observations", 0)
                end

                local v19 = rt.copy(p18.grind_physical)

                if p21 == 0 and v18.tag == "Fade" or p21 == 1 and v19.grinding and v18.tag == "Attributes" then
                    local skater_animation_flags = p18.animation.skater_animation_flags

                    if skater_animation_flags == nil then
                        error("Grind graph requires live animation stance", 0)
                    end

                    v19.animation_mirrored = bit32.band(skater_animation_flags, 1073741824) ~= 0
                end

                local v20 = p18.instances[p19 + 1]

                if v20 == nil then
                    error("Unallocated grind behavior", 0)
                end

                if v20.tag ~= "Grind" then
                    error("Grind operation/instance mismatch", 0)
                end

                local v21 = v20[1]

                return v2.execute(v21, v18, p21, p20.dt, p18.grind_settings, v19, (as_grind_animation(p18.animation)))
            end
        elseif v17.tag == "Trick" then
            local v22 = v17[1]
            local v23 = p18.instances[p19 + 1]

            if v23 == nil then
                error("index out of bounds", 0)
            end

            p18.instances[p19 + 1] = {
                tag = "Stateless"
            }

            if v23.tag ~= "Trick" then
                error("Trick operation/instance mismatch", 0)
            end

            local v24 = v23[1]
            local execute = v3.execute
            local ok, result = pcall(execute, p18, v22, v24, p21)

            if ok then
                v24 = result
            end

            p18.instances[p19 + 1] = {
                tag = "Trick",
                v24
            }

            if not ok then
                error(result, 0)
            end
        else
            if v17.tag == "ToggleBoard" then
                local v25 = v11

                if v25 == nil then
                    v25 = import("skate_game/graph_host/motion")
                    v11 = v25
                end

                return v25.MotionHost.execute_toggle_board(p18, p19, p21)
            end

            if v17.tag == "Runout" then
                local v26 = p18.instances[p19 + 1]

                if v26 == nil then
                    error("Unallocated runout behavior", 0)
                end

                if v26.tag ~= "Runout" then
                    error("Runout operation/instance mismatch", 0)
                end

                local v27 = v26[1]

                if p21 == 0 then
                    v4.State.begin(v27, rt.copy(p18.runout_physical))

                    return
                end

                local update = v4.State.update
                local animation = p18.animation

                return update(v27, {
                    set_attribute = function(_, p23) -- set_attribute | line: 66
                        -- upvalues: animation (copy), MotionAnimation (copy)
                        return MotionAnimation.set_attribute(animation, p23)
                    end
                })
            end

            local v28 = v11

            if v28 == nil then
                v28 = import("skate_game/graph_host/motion")
                v11 = v28
            end

            if v28.MotionHost.execute_score_or_bump(p18, v17, p21) then
                return
            end

            if v17.tag == "Slide" then
                local v29 = v11

                if v29 == nil then
                    v29 = import("skate_game/graph_host/motion")
                    v11 = v29
                end

                return v29.MotionHost.execute_slide(p18, p19, v17[1], p20, p21)
            end

            if v17.tag == "ClearTrickAttr" or v17.tag == "AirLeg" or v17.tag == "BodySpin" then
                local v30 = v11

                if v30 == nil then
                    v30 = import("skate_game/graph_host/motion")
                    v11 = v30
                end

                return v30.MotionHost.execute_air(p18, p19, v17, p20, p21)
            end

            if v17.tag == "TwistLean" then
                local v31 = v11

                if v31 == nil then
                    v31 = import("skate_game/graph_host/motion")
                    v11 = v31
                end

                return v31.MotionHost.execute_twist_lean(p18, p19, v17[1], p21)
            end

            if v17.tag == "Wipeout" then
                local v32 = v11

                if v32 == nil then
                    v32 = import("skate_game/graph_host/motion")
                    v11 = v32
                end

                return v32.MotionHost.execute_wipeout(p18, p19, v17[1], p21)
            end

            if v17.tag == "IntentFilter" then
                local v33 = v11

                if v33 == nil then
                    v33 = import("skate_game/graph_host/motion")
                    v11 = v33
                end

                return v33.MotionHost.execute_intent_filter(p18, p19, v17[1], p20, p21)
            end

            local v34 = false
            local v35 = false
            local v36 = false
            local v37 = false
            local v38 = false

            if v17.tag == "ResetAnimation" then
                v34 = true
            else
                v38 = true
            end

            local v39

            if v34 then
                v39 = v17[1]

                if p21 == 0 then
                    v35 = true
                else
                    v38 = false
                end
            end

            v34 = false

            if v35 then
                if v39 == "SkaterAnimation" then
                    v36 = true
                else
                    v34 = true
                end
            end

            v35 = false

            if v34 then
                if v39 == "GivenStance" then
                    v35 = true
                else
                    v37 = true
                end
            end

            v34 = false

            if v35 then
                v37 = true
                MotionAnimation.reset_to_given_stance(p18.animation)
            end

            v35 = false

            if v36 then
                IntentMap.clear(p18.action_intents)
                p18.action_controls = v8.ActionControls.default()
                IntentMap.clear(p18.animation.motion_intents)
                IntentMap.clear(p18.animation.filtered_intents)
                p18.flags = v5.Flags.default()
                p18.is_power_sliding = false
                p18.riding.last_good_landing_velocity = 0
                p18.riding.manual_out_timer = 0
                p18.hand_services.busy_hands = { 0, 0 }
                p18.gesture_publication = nil
                v37 = true
                MotionAnimation.reset_from_stock(p18.animation)
            end

            v36 = false

            local skater_animation_flags

            if v37 then
                skater_animation_flags = p18.animation.skater_animation_flags

                if skater_animation_flags ~= nil then
                    v35 = true
                else
                    v36 = true
                end
            end

            v37 = false

            local playback_context

            if v35 then
                playback_context = p18.playback_context

                if bit32.band(skater_animation_flags, 1073741824) == 0 then
                    v34 = true
                else
                    v37 = true
                end
            end

            v35 = false

            local v40

            if v37 then
                v40 = true
                v35 = true
            end

            if v34 then
                v40 = false
                v35 = true
            end

            v34 = false

            if v35 then
                v34 = true
                playback_context.is_mirrored = v40
            end

            v35 = false

            if v36 then
                v34 = true
                p18.playback_context.is_mirrored = nil
            end

            v36 = false

            local playback_context2

            if v34 then
                playback_context2 = p18.playback_context

                if p18.animation.relative_stance == 1 then
                    v36 = true
                else
                    v35 = true
                end
            end

            v34 = false

            local v41

            if v35 then
                v41 = false
                v34 = true
            end

            if v36 then
                v41 = true
                v34 = true
            end

            if v34 then
                v38 = false
                playback_context2.is_switch = v41
            end

            if v38 then
                if v17.tag ~= "HandService" then
                    if v17.tag ~= "Landing" then
                        return v10.execute(p18, p19, v17, p20, p21)
                    end

                    local v42 = v17[1]
                    local v43 = p18.instances[p19 + 1]

                    if v43 == nil then
                        error("Unallocated landing behavior", 0)
                    end

                    if v43.tag ~= "Landing" then
                        error("Landing operation/instance mismatch", 0)
                    end

                    local v44 = v43[1]
                    local v45

                    if p18.landing_physical == nil then
                        return v6.execute(v42, v44, p18.flags, p18.animation, p18.condition_random, v45, p18.playback_context.is_mirrored, p20.dt, p21)
                    end

                    v45 = rt.copy(p18.landing_physical)
                    v45.last_good_landing_velocity = p18.riding.last_good_landing_velocity

                    return v6.execute(v42, v44, p18.flags, p18.animation, p18.condition_random, v45, p18.playback_context.is_mirrored, p20.dt, p21)
                end

                v7.HandServices.execute(p18.hand_services, v17[1], p21, p18.animation)
            end
        end
    else
        if p18.instances[p19 + 1] == nil then
            error("Unallocated MotionGraph behavior", 0)
        end

        if p21 == 1 then
            MotionAnimation.attach(p18.animation, v15.intent, v15.attribute, v15.set)
        end
    end
end

return t1
