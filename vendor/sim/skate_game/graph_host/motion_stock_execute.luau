-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local v2 = import("skate_game/graph_host/motion_stock_gameplay")
local encode = import("skate_core/animation/skeleton_input/name").encode
local MotionAnimation = v1.MotionAnimation
local MovingObjectRegistry = v2.MovingObjectRegistry

return {
    execute = function(p1, p2, p3) -- execute | line: 21
        -- upvalues: rt (copy), v2 (copy), encode (copy), MotionAnimation (copy), MovingObjectRegistry (copy)
        local tag = p2.tag

        if tag == "InitMovingObjects" then
            if p3 == 0 then
                MovingObjectRegistry.register(p1.moving_objects, p2.path)
            end
        elseif tag == "MovingObject" then
            local path = p2.path

            if p3 == 0 then
                MovingObjectRegistry.begin(p1.moving_objects, path)
            elseif p3 ~= 1 then
                MovingObjectRegistry["end"](p1.moving_objects)
            elseif not MovingObjectRegistry.update(p1.moving_objects, path) then
                error("MovingObject is not active: " .. path, 0)
            end
        elseif tag == "SetGrabType" then
            local v3 = v2.GrabType.parse(p2.grab)

            if p3 == 0 then
                MotionAnimation.set_grab_type(p1.animation, v3)
            elseif p3 == 2 then
                MotionAnimation.clear_grab_type(p1.animation)
            end
        elseif tag == "ScoringGrabs" then
            if p3 == 1 then
                local v4 = MotionAnimation.filtered_intent(p1.animation, p2.intent_x)

                if v4 == nil then
                    v4 = 0
                end

                local v5 = MotionAnimation.filtered_intent(p1.animation, p2.intent_y)

                if v5 == nil then
                    v5 = 0
                end

                local v6 = v4

                if p2.polar then
                    v6 = v5 * math.sin(v4)
                    v5 *= math.cos(v4)

                    if p2.invert_y then
                        v5 = -v5
                    end
                end

                local v7 = v2.select_grab_score(p2.grab_name, {
                    p2.up,
                    p2.left,
                    p2.down,
                    p2.right
                }, v6, v5)

                p1.score_packet.grab = {
                    encode(v7),
                    { v6, v5 }
                }
            end
        elseif tag == "TweakProject" and p3 == 1 then
            local v8 = MotionAnimation.filtered_intent(p1.animation, p2.intent_x)
            local v9 = MotionAnimation.filtered_intent(p1.animation, p2.intent_y)

            if v8 == nil and v9 == nil then
                return
            end

            if v8 == nil then
                v8 = 0
            end

            if v9 == nil then
                v9 = 0
            end

            local v10 = math.abs(v8) + math.abs(v9)

            if v10 > 1 then
                local v11 = 1 / v10

                v8 *= v11
                v9 *= v11
            end

            MotionAnimation.set_attribute(p1.animation, {
                normalized = false,
                sequence_id = -1,
                name = rt.copy(p2.attribute_x),
                value = v8
            })
            MotionAnimation.set_attribute(p1.animation, {
                normalized = false,
                sequence_id = -1,
                name = rt.copy(p2.attribute_y),
                value = v9
            })
        end
    end
}
