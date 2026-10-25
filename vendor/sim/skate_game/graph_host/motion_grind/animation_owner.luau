-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local IntentMap = import("skate_core/graph/intents").IntentMap
local v1

local function motion_animation() -- line: 22
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_animation")
        v1 = v2
    end

    return v2
end

local v3

local function PlaybackTree() -- line: 31
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v4
    end

    return v4
end

local t1 = {
    MotionAnimation = {}
}

function t1.MotionAnimation.apply_parameters(p1) -- line: 45
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v5 = v1

    if v5 == nil then
        v5 = import("skate_game/graph_host/motion_animation")
        v1 = v5
    end

    local apply_parameters = v5.MotionAnimation.apply_parameters

    if apply_parameters == t1.MotionAnimation.apply_parameters then
        error("animation_owner: inherent MotionAnimation.apply_parameters was overwritten by the trait forwarder", 0)
    end

    return apply_parameters(p1)
end

function t1.MotionAnimation.query_current_attribute(p2, p3, p4, p5) -- line: 55
    -- upvalues: import (copy), v3 (ref)
    local current = p2.current

    if current == nil then
        error("GrindControlFade requires a current animation tree", 0)
    end

    local v6 = v3

    if v6 == nil then
        v6 = import("skate_core/animation/playback_tree").PlaybackTree
        v3 = v6
    end

    return v6.query_attribute(current, p3, p4, p5)
end

function t1.MotionAnimation.emit_packet(p6, p7, p8) -- line: 65
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v7 = v1

    if v7 == nil then
        v7 = import("skate_game/graph_host/motion_animation")
        v1 = v7
    end

    local emit_packet = v7.MotionAnimation.emit_packet

    if emit_packet == t1.MotionAnimation.emit_packet then
        error("animation_owner: inherent MotionAnimation.emit_packet was overwritten by the trait forwarder", 0)
    end

    emit_packet(p6, p7, p8)
end

function t1.MotionAnimation.intent(p9, p10) -- line: 75
    -- upvalues: IntentMap (copy)
    return IntentMap.get(p9.motion_intents, p10)
end

return t1
