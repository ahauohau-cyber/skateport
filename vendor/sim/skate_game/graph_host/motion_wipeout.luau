-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local NumericCondition = import("skate_core/graph/conditions").NumericCondition
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Collections = import("skate_data/collections").Collections
local v1 = import("skate_game/graph_host/condition_nodes")
local t1 = {}

local function debug_option_str(p1) -- line: 16
    if p1 == nil then
        return "None"
    end

    return "Some(\"" .. string.gsub(p1, "[\\\"\n\r\t]", function(p2) -- line: 20
        if p2 == "\\" then
            return "\\\\"
        end

        if p2 == "\"" then
            return "\\\""
        end

        if p2 == "\n" then
            return "\\n"
        end

        if p2 == "\r" then
            return "\\r"
        end

        return "\\t"
    end) .. "\")"
end

t1.Operation = {}
t1.Controls = {}

function t1.Controls.default() -- line: 42
    return {
        seed_from_air_tweak = false,
        gestures_enabled = false,
        gesture = { 0, 0 }
    }
end

t1.State = {}

function t1.State.default() -- line: 50
    return {
        ticks = 0,
        lean = 0,
        twist = 0,
        twist_velocity = 0,
        released = false,
        gesture = { 0, 0 }
    }
end

t1.Settings = {}

function t1.Settings.load(p3) -- line: 68
    -- upvalues: Collections (copy)
    local function f(p4) -- line: 70
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "anim_wipeout", "default", p4)
    end

    return {
        threshold = Collections.float(p3, "anim_wipeout", "default", "controlled_drives_thresh"),
        twist_velocity = Collections.float(p3, "anim_wipeout", "default", "clamp_twist_vel"),
        twist_acceleration = Collections.float(p3, "anim_wipeout", "default", "clamp_twist_acc"),
        lean_velocity = Collections.float(p3, "anim_wipeout", "default", "clamp_lean_vel"),
        twist_blend = Collections.float(p3, "anim_wipeout", "default", "blend_twist"),
        lean_blend = Collections.float(p3, "anim_wipeout", "default", "blend_lean"),
        gesture_y_blend = Collections.float(p3, "anim_wipeout", "default", "blend_gesture_y"),
        gesture_x_blend = Collections.float(p3, "anim_wipeout", "default", "blend_gesture_x")
    }
end

t1.Physical = {}
t1.Condition = {}

function t1.Condition.eq(p5, p6) -- line: 98
    if p5.tag ~= p6.tag then
        return false
    end

    if p5.tag == "TimeToLand" or p5.tag == "TimeSinceContact" then
        local v2 = p5[1]
        local v3 = p6[1]

        if v2.comparison == v3.comparison and v2.threshold == v3.threshold then
            return v2.absolute == v3.absolute
        end

        return false
    end

    if p5.tag == "GestureType" or p5.tag == "InWater" then
        return p5[1] == p6[1]
    end

    return true
end

function t1.Condition.parse(p7) -- line: 112
    -- upvalues: Attributes (copy), v1 (copy)
    local name = Attributes.text(p7, "name")

    if name == nil then
        name = ""
    end

    if name == "IsDoneWipingOut" then
        return {
            tag = "Done"
        }
    end

    if name == "WipeoutTimeToLand" then
        return {
            tag = "TimeToLand",
            (v1.numeric(p7))
        }
    end

    if name == "WipeoutTimeSinceContact" then
        return {
            tag = "TimeSinceContact",
            (v1.numeric(p7))
        }
    end

    if name == "GestureType" then
        local gesture = Attributes.text(p7, "gesture")
        local v4

        if gesture == "Freefall" then
            v4 = 0
        elseif gesture == "CannonBall" then
            v4 = 1
        elseif gesture == "JudoKick" then
            v4 = 2
        elseif gesture == "SwanDive" then
            v4 = 3
        elseif gesture == "Torpedo" then
            v4 = 4
        else
            error("Invalid Wipeout gesture type " .. (if gesture == nil then "None" else "Some(\"" .. string.gsub(gesture, "[\\\"\n\r\t]", function(p8) -- line: 20
                if p8 == "\\" then
                    return "\\\\"
                end

                if p8 == "\"" then
                    return "\\\""
                end

                if p8 == "\n" then
                    return "\\n"
                end

                if p8 == "\r" then
                    return "\\r"
                end

                return "\\t"
            end) .. "\")"), 0)
        end

        return {
            tag = "GestureType",
            v4
        }
    end

    if name ~= "IsInWater" then
        return nil
    end

    local orientation = Attributes.text(p7, "orientation")
    local v5

    if orientation == "onback" then
        v5 = 0
    elseif orientation == "onfront" then
        v5 = 1
    elseif orientation == "either" then
        v5 = 2
    else
        error("Invalid water orientation " .. (if orientation == nil then "None" else "Some(\"" .. string.gsub(orientation, "[\\\"\n\r\t]", function(p9) -- line: 20
            if p9 == "\\" then
                return "\\\\"
            end

            if p9 == "\"" then
                return "\\\""
            end

            if p9 == "\n" then
                return "\\n"
            end

            if p9 == "\r" then
                return "\\r"
            end

            return "\\t"
        end) .. "\")"), 0)
    end

    return {
        tag = "InWater",
        v5
    }
end

function t1.Condition.evaluate(p10, p11) -- line: 160
    -- upvalues: NumericCondition (copy)
    if p11 == nil then
        error("Wipeout condition requires completed physical output", 0)
    end

    local tag = p10.tag

    if tag == "Done" then
        return p11.over_599
    end

    if tag == "TimeToLand" then
        return NumericCondition.matches(p10[1], p11.collision_time_144)
    end

    if tag == "TimeSinceContact" then
        return NumericCondition.matches(p10[1], p11.no_support_time_548)
    end

    if tag == "GestureType" then
        return p11.profile_148 == p10[1]
    end

    if tag == "InWater" then
        local v6 = p10[1]

        if not p11.below_surface_82 then
            return false
        end

        local orientation_y = p11.orientation_y

        if orientation_y == nil then
            error("IsInWater requires skeleton output80.Y", 0)
        end

        if (if orientation_y > 0 then 0 else 1) == v6 then
            return true
        end

        return v6 == 2
    end

    error("internal error: entered unreachable code", 0)
end

return t1
