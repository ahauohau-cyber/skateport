-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/bump")
local Collections = import("skate_data/collections").Collections
local t1 = {
    Settings = {}
}

function t1.Settings.load(p1) -- line: 17
    -- upvalues: Collections (copy)
    local function value(p2) -- line: 18
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, "anim_motion", "bumps", p2)
    end

    return {
        scale_x_acc = Collections.float(p1, "anim_motion", "bumps", "scale_x_acc"),
        min_bump_mag = Collections.float(p1, "anim_motion", "bumps", "min_bump_mag"),
        max_bump_mag = Collections.float(p1, "anim_motion", "bumps", "max_bump_mag"),
        min_bump_blend_value = Collections.float(p1, "anim_motion", "bumps", "min_bump_blend_value")
    }
end

function t1.Settings.coefficients(p3, p4, p5) -- line: 35
    -- upvalues: rt (copy), v1 (copy)
    return v1.coefficients(rt.copy(p4), p5, {
        scale_x_acc = p3.scale_x_acc,
        min_bump_mag = p3.min_bump_mag,
        max_bump_mag = p3.max_bump_mag,
        min_bump_blend_value = p3.min_bump_blend_value
    })
end

return t1
