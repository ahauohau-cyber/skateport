-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local encode = import("skate_core/animation/skeleton_input/name").encode
local t1 = {}
local MotionAnimation = v1.MotionAnimation
local v2

local function motion_twist_lean() -- line: 25
    -- upvalues: import (copy), v2 (ref)
    local v3 = v2

    if v3 == nil then
        v3 = import("skate_game/graph_host/motion_offboard/twist_lean")
        v2 = v3
    end

    return v3
end

function t1.bounded(p1, p2) -- line: 35
    local v4 = if -p2 - p1 >= 0 then -p2 else p1

    if p2 - v4 >= 0 then
        return v4
    end

    return p2
end

function t1.positive_turn(p3) -- line: 48
    if p3 >= 0 then
        return p3
    end

    return p3 + 6.2831854820251465
end

t1.MotionHost = {}

function t1.MotionHost.execute_wipeout(p4, p5, p6, p7) -- line: 61
    -- upvalues: rt (copy), encode (copy), t1 (copy), MotionAnimation (copy)
    if p6 == "EnableGestures" then
        if p7 ~= 1 then
            p4.wipeout_controls.gestures_enabled = p7 == 0
        end
    elseif not (p7 > 1) then
        local v5 = p4.instances[p5 + 1]

        if v5 == nil then
            error("Unallocated Wipeout behavior", 0)
        end

        if v5.tag ~= "Wipeout" then
            error("Wipeout operation/instance mismatch", 0)
        end

        local v6 = v5[1]
        local wipeout_physical = p4.wipeout_physical

        if wipeout_physical == nil then
            error("Wipeout requires completed physical outputs", 0)
        end

        if p7 == 0 then
            local skater_animation_flags = p4.animation.skater_animation_flags

            if skater_animation_flags == nil then
                error("Wipeout requires animation stance", 0)
            end

            local v7 = bit32.band(skater_animation_flags, 1073741824) ~= 0

            v6.ticks = 0
            v6.lean = wipeout_physical.hips_right_angle_496

            local v8 = if not v7 then wipeout_physical.hips_up_angle_500 else -wipeout_physical.hips_up_angle_500

            v6.twist = t1.positive_turn(v8)
            v6.twist_velocity = 0
            v6.released = p4.wipeout_controls.seed_from_air_tweak

            if v6.released then
                p4.wipeout_controls.seed_from_air_tweak = false
                v6.gesture = {
                    p4.action_controls.wipeout.air_body_tweak[1],
                    p4.action_controls.wipeout.air_body_tweak[2]
                }
            else
                v6.gesture = { 0, 0 }
            end
        else
            if p4.action_controls.wipeout.request or rt.to_i32(v6.ticks) > 80 then
                v6.released = true
            end

            if p4.wipeout_controls.gestures_enabled then
                local skater_animation_flags = p4.animation.skater_animation_flags

                if skater_animation_flags == nil then
                    error("Wipeout requires animation stance", 0)
                end

                local v9 = bit32.band(skater_animation_flags, 1073741824) ~= 0
                local wipeout_settings = p4.wipeout_settings
                local threshold, twist_velocity, twist_acceleration, lean_velocity = wipeout_settings.threshold, wipeout_settings.twist_velocity, wipeout_settings.twist_acceleration, wipeout_settings.lean_velocity
                local twist_blend, lean_blend, gesture_y_blend, gesture_x_blend = wipeout_settings.twist_blend, wipeout_settings.lean_blend, wipeout_settings.gesture_y_blend, wipeout_settings.gesture_x_blend
                local v10 = (1 - lean_blend) * v6.lean + wipeout_physical.hips_right_angle_496 * lean_blend - v6.lean

                v6.lean += t1.bounded(v10, lean_velocity)
                t1.set(p4.animation, "Lean", v6.lean)

                local v11 = (if v9 then t1.positive_turn(-wipeout_physical.hips_up_angle_500) else t1.positive_turn(wipeout_physical.hips_up_angle_500)) - v6.twist

                if v11 > 3.1415927410125732 then
                    v11 -= 6.2831854820251465
                elseif v11 < -3.1415927410125732 then
                    v11 += 6.2831854820251465
                end

                local v12 = (v6.twist + v11) * twist_blend + (1 - twist_blend) * v6.twist - v6.twist
                local v13 = t1.bounded(v12, twist_velocity)

                if v6.ticks >= 2 then
                    v13 = t1.bounded(v13 - v6.twist_velocity, twist_acceleration) + v6.twist_velocity
                end

                local v14 = v6.twist + v13

                if v14 > 6.2831854820251465 then
                    v14 -= 6.2831854820251465
                end

                v6.twist_velocity = v13
                v6.twist = t1.positive_turn(v14)
                t1.set(p4.animation, "Twist", v6.twist)

                local gesture = p4.action_controls.wipeout.gesture
                local v15, v16

                if gesture ~= nil then
                    v15 = gesture[1]
                    v16 = gesture[2]
                end

                local v17 = if v15 == nil then 0 else v15
                local v18 = if v16 == nil then 0 else v16

                if not v6.released and v15 ~= nil and v16 ~= nil and math.abs(v17) < 0.1 and math.abs(v18) < 0.1 then
                    v6.released = true
                end

                if v6.released then
                    v6.gesture[1] = (1 - gesture_x_blend) * v6.gesture[1] + v17 * gesture_x_blend
                    v6.gesture[2] = (1 - gesture_y_blend) * v6.gesture[2] + v18 * gesture_y_blend
                end

                if v6.gesture[2] * v6.gesture[2] + v6.gesture[1] * v6.gesture[1] > threshold * threshold then
                    MotionAnimation.emit_packet(p4.animation, encode("ControlledWipeout"), 1)
                end

                p4.wipeout_controls.gesture = rt.copy(v6.gesture)
            end

            t1.set(p4.animation, "WipeoutGestureX", v6.gesture[1])
            t1.set(p4.animation, "WipeoutGestureY", v6.gesture[2])
            v6.ticks = rt.wrapping_add_u32(v6.ticks, 1)
        end
    end
end

function t1.set(p8, p9, p10) -- line: 189
    -- upvalues: encode (copy), MotionAnimation (copy)
    MotionAnimation.set_attribute(p8, {
        normalized = false,
        sequence_id = -1,
        name = encode(p9),
        value = p10
    })
end

function t1.MotionHost.execute_twist_lean(p11, p12, p13, p14) -- line: 200
    -- upvalues: import (copy), MotionAnimation (copy), v2 (ref)
    local v19 = p11.instances[p12 + 1]

    if v19 == nil then
        error("Unallocated MatchTwistAndLean behavior", 0)
    end

    if v19.tag ~= "TwistLean" then
        error("MatchTwistAndLean operation/instance mismatch", 0)
    end

    local v20 = v19[1]
    local t2

    if p14 == 0 or p14 == 1 and p13.always then
        local wipeout_physical = p11.wipeout_physical

        if wipeout_physical == nil then
            error("MatchTwistAndLean requires canonical physical angles", 0)
        end

        local skater_animation_flags = p11.animation.skater_animation_flags

        if skater_animation_flags == nil then
            error("MatchTwistAndLean requires live animation stance", 0)
        end

        t2 = {
            hips_right_angle = wipeout_physical.hips_right_angle_496,
            hips_up_angle = wipeout_physical.hips_up_angle_500,
            mirrored = bit32.band(skater_animation_flags, 1073741824) ~= 0
        }
    end

    local animation = p11.animation
    local t3 = {
        set_attribute = function(_, p16) -- set_attribute | line: 229
            -- upvalues: animation (copy), MotionAnimation (copy)
            return MotionAnimation.set_attribute(animation, p16)
        end
    }
    local v21 = v2

    if v21 == nil then
        v21 = import("skate_game/graph_host/motion_offboard/twist_lean")
        v2 = v21
    end

    v21.Operation.execute(p13, v20, t2, t3, p14)
end

return t1
