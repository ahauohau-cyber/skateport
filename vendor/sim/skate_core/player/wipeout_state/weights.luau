-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/player/wipeout_state/math")
local t1 = {
    Settings = {},
    Output = {}
}

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 26
    -- upvalues: v1 (copy), t1 (copy)
    local v2 = t1.fade(p2.remove_target_time, p1.time)

    if not p1.special_surface and (not (math.abs(p6[1]) < 0.2) or not (math.abs(p6[2]) < 0.2)) then
        p1.collision_weight = 0
    else
        local v6 = if p3 then p2.collision_step else -p2.collision_step

        p1.collision_weight = v1.clamp(p1.collision_weight + v6, 0, 1)
    end

    local v7 = t1.fade(p2.remove_drives_time, p1.time)
    local v8 = v7 * v7
    local v9 = if (p4 or bit32.band(p5, 524288) ~= 0) and not p1.special_surface then p2.controlled_step else -p2.controlled_step

    p1.controlled_weight = v1.clamp(p1.controlled_weight + v9, 0, 1)

    local v10 = 1 - p1.collision_weight
    local v11 = v10 * v8

    return {
        target_weight = v2,
        start = v11,
        ["end"] = p1.collision_weight,
        controlled = (v10 - v11) * p1.controlled_weight,
        extra = p1.extra_weight * 0.03
    }
end

function t1.fade(p7, p8) -- line: 60
    -- upvalues: v1 (copy)
    local v12 = if p7 == 0 then 0.01 else p7

    return v1.clamp((p7 - p8) / v12, 0, 1)
end

return t1
