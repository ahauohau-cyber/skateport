-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {
    Settings = {}
}

function t1.Settings.load(p1) -- line: 16
    -- upvalues: Collections (copy)
    local function f(p2) -- line: 17
        -- upvalues: p1 (copy), Collections (copy)
        return Collections.float(p1, "anim_motion", "grind_twist", p2)
    end

    local twist_smoothing = Collections.float(p1, "anim_motion", "grind_twist", "twist_smoothing")
    local twist_sensitivity = Collections.float(p1, "anim_motion", "grind_twist", "twist_sensitivity")
    local twist_max_delta_delta = Collections.float(p1, "anim_motion", "grind_twist", "twist_max_delta_delta")
    local twist_max_delta = Collections.float(p1, "anim_motion", "grind_twist", "twist_max_delta")
    local min_grind_disttocog = Collections.float(p1, "anim_motion", "grind_height", "min_grind_disttocog")
    local max_grind_disttocog = Collections.float(p1, "anim_motion", "grind_height", "max_grind_disttocog")
    local grind_disttocog_speed = Collections.float(p1, "anim_motion", "grind_height", "grind_disttocog_speed")

    return {
        fade = {
            response = twist_smoothing,
            input_scale = twist_sensitivity,
            acceleration = twist_max_delta_delta,
            maximum_step = twist_max_delta
        },
        height = { min_grind_disttocog, max_grind_disttocog, grind_disttocog_speed }
    }
end

return t1
