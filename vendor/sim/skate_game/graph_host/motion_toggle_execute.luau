-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local IntentMap = import("skate_core/graph/intents").IntentMap
local t1 = {}
local v1

local function motion_toggle_board() -- line: 22
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_offboard/toggle_board")
        v1 = v2
    end

    return v2
end

t1.MotionHost = {}

function t1.MotionHost.execute_toggle_board(p1, p2, p3) -- line: 34
    -- upvalues: rt (copy), import (copy), IntentMap (copy), v1 (ref)
    local v3 = p1.instances[p2 + 1]

    if v3 == nil then
        error("Unallocated ToggleBoard behavior", 0)
    end

    if v3.tag ~= "ToggleBoard" then
        error("ToggleBoard operation/instance mismatch", 0)
    end

    local v4 = v3[1]
    local skater_animation_flags = p1.animation.skater_animation_flags
    local v5 = if skater_animation_flags == nil then nil else bit32.band(skater_animation_flags, 1073741824) ~= 0
    local motion_intents = p1.animation.motion_intents
    local t2 = {
        drop_requested = IntentMap.contains_key(motion_intents, "OB_DropBoard"),
        throw_requested = IntentMap.contains_key(motion_intents, "OB_ThrowBoard"),
        retrieve_requested = IntentMap.contains_key(motion_intents, "OB_RetrieveBoard")
    }
    local v6 = v1

    if v6 == nil then
        v6 = import("skate_game/graph_host/motion_offboard/toggle_board")
        v1 = v6
    end

    return v6.execute(v4, p1.animation, t2, rt.copy(p1.toggle_board_physical), v5, p3)
end

return t1
