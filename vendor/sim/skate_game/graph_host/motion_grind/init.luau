-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_grind/animation")
local v2 = import("skate_game/graph_host/motion_grind/settings")
local v3 = import("skate_core/animation/grind_control")
local v4 = import("skate_core/animation/grind_control/facing")
local v5 = import("skate_core/animation/skeleton_input/name")
local v6 = import("skate_data/state_graph/attributes")
local endpoints, set = v1.endpoints, v1.set
local Fade, crouch, mirrored_twist = v3.Fade, v3.crouch, v3.mirrored_twist
local encode = v5.encode
local Attributes = v6.Attributes
local t1 = {
    Settings = v2.Settings,
    Operation = {}
}

function t1.Operation.eq(p1, p2) -- line: 40
    -- upvalues: import (copy)
    if p1.tag ~= p2.tag then
        return false
    end

    local eq = import("skate_core/animation/output/attributes").AttributeName.eq

    if p1.tag == "Crouch" then
        return eq(p1.height, p2.height)
    end

    if p1.tag ~= "Fade" then
        return true
    end

    return eq(p1.height, p2.height) and eq(p1.twist, p2.twist) and p1.intent == p2.intent
end

function t1.Operation.parse(p3) -- line: 54
    -- upvalues: encode (copy), Attributes (copy)
    local function required(p4) -- line: 55
        -- upvalues: p3 (copy), Attributes (copy)
        local v7 = Attributes.text(p3, p4)

        if v7 == nil then
            error(("GrindControlFade requires %*"):format(p4), 0)
        end

        return v7
    end

    local name = Attributes.text(p3, "name")

    if name == "CreateGrindAttributes" then
        return {
            tag = "Attributes"
        }
    end

    if name == "ControlGrindCrouch" then
        local driveDistToCom = Attributes.text(p3, "driveDistToCom")

        if driveDistToCom == nil then
            driveDistToCom = "disttocog"
        end

        return {
            tag = "Crouch",
            height = encode(driveDistToCom)
        }
    end

    if name ~= "GrindControlFade" then
        return nil
    end

    local distBoardToCogAnimAttribute = Attributes.text(p3, "distBoardToCogAnimAttribute")

    if distBoardToCogAnimAttribute == nil then
        error("GrindControlFade requires distBoardToCogAnimAttribute", 0)
    end

    local v8 = encode(distBoardToCogAnimAttribute)
    local twistAnimAttribute = Attributes.text(p3, "twistAnimAttribute")

    if twistAnimAttribute == nil then
        error("GrindControlFade requires twistAnimAttribute", 0)
    end

    local v9 = encode(twistAnimAttribute)
    local twistMGIntent = Attributes.text(p3, "twistMGIntent")

    if twistMGIntent == nil then
        error("GrindControlFade requires twistMGIntent", 0)
    end

    return {
        tag = "Fade",
        height = v8,
        twist = v9,
        intent = twistMGIntent
    }
end

t1.State = {}

function t1.State.default() -- line: 85
    return {
        fade = nil,
        height = nil
    }
end

t1.Physical = {}

function t1.execute(p5, p6, p7, p8, p9, p10, p11) -- line: 105
    -- upvalues: rt (copy), v4 (copy), endpoints (copy), set (copy), Fade (copy), crouch (copy), mirrored_twist (copy), encode (copy)
    if p6.tag == "Attributes" and p7 == 1 and p10.grinding then
        p11.emit_packet(p11, rt.copy(p10.grind_name), 1)

        local v10 = v4.backwards(rt.copy(p10.ground_axis), rt.copy(p10.board_axis), p10.ground_flag_273, p10.animation_mirrored) and "GrindFacingBackwards" or "GrindFacingForwards"

        p11.emit_packet(p11, encode(v10), 1)
    elseif p6.tag == "Crouch" and p7 == 0 then
        p5.height = p10.height
    elseif p6.tag == "Crouch" and p7 == 1 then
        local height = p6.height
        local height2 = p5.height

        if height2 == nil then
            error("ControlGrindCrouch Update before Begin", 0)
        end

        local v11 = p9.height[1]
        local v12 = p9.height[2]
        local v13 = p9.height[3]
        local Crouch = p11.intent(p11, "Crouch")

        if Crouch == nil then
            Crouch = 0
        end

        local v14 = crouch(height2, Crouch, p10.crouch, v11, v12, v13, p8)

        p5.height = v14
        set(p11, rt.copy(height), v14, false)
    elseif p6.tag == "Fade" then
        local height, twist, intent = p6.height, p6.twist, p6.intent

        if p7 == 0 then
            set(p11, rt.copy(height), p10.height, false)

            local v15 = endpoints(p11, rt.copy(twist))
            local v16 = Fade.default()
            local v17 = Fade.begin(v16, v15[1], v15[2], mirrored_twist(p10.twist, p10.animation_mirrored))

            set(p11, rt.copy(twist), v17, false)
            p5.fade = v16
        elseif p7 == 1 then
            local fade = p5.fade

            if fade == nil then
                error("GrindControlFade Update before Begin", 0)
            end

            local v18 = p11.intent(p11, intent)

            if v18 == nil then
                v18 = 0
            end

            local v19 = Fade.update(fade, p8, v18, p9.fade)

            if v19 ~= nil then
                set(p11, rt.copy(twist), v19, false)
            end
        end
    end
end

return t1
