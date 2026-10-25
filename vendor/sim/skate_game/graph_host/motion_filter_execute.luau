-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Operation = require(sim.import)("skate_game/graph_host/motion_intent_filter").Operation
local t1 = {
    MotionHost = {}
}

function t1.MotionHost.execute_intent_filter(p1, p2, p3, p4, p5) -- line: 21
    -- upvalues: Operation (copy)
    local v2 = p1.instances[p2 + 1]

    if v2 == nil then
        error("Unallocated intent-filter behavior", 0)
    end

    if v2.tag ~= "IntentFilter" then
        error("Intent-filter operation/instance mismatch", 0)
    end

    local v3 = v2[1]

    if p5 == 0 then
        Operation.begin(p3, v3, p1.animation.filtered_intents)
    elseif p5 == 1 then
        local skater_animation_flags = p1.animation.skater_animation_flags

        if skater_animation_flags == nil then
            error("FilterMotionGraphIntent requires live animation stance flags", 0)
        end

        Operation.update(p3, v3, p1.animation.motion_intents, p1.animation.filtered_intents, p4.dt, {
            bit32.band(skater_animation_flags, 536870912) ~= 0,
            bit32.band(skater_animation_flags, 1073741824) ~= 0
        })
    else
        Operation["end"](p3, p1.animation.filtered_intents)
    end
end

return t1
