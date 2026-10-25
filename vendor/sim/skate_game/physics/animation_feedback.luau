-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/animation_feedback_settings")
local v2 = import("skate_core/animation/ground_acceleration")
local v3 = import("skate_core/animation/physical_feedback")
local v4 = import("skate_core/input/turn_conditioner")
local Collections = import("skate_data/collections").Collections
local t1 = {
    AnimationFeedback = {}
}

function t1.AnimationFeedback.load(p1) -- line: 29
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    return {
        previous_lateral_tilt = { 0, 0, 0, 0 },
        published_previous_lateral_tilt = { 0, 0, 0, 0 },
        settings = v1.load(p1),
        bump_settings = {
            scale_x_acc = Collections.float(p1, "anim_motion", "bumps", "scale_x_acc"),
            min_bump_mag = Collections.float(p1, "anim_motion", "bumps", "min_bump_mag")
        },
        state = {
            history = table.create(8, 0),
            filters = rt.filled(3, table.create(9, 0))
        }
    }
end

function t1.AnimationFeedback.reset(p2) -- line: 51
    -- upvalues: v4 (copy)
    v4.State.reset_history(p2.state)
    p2.previous_lateral_tilt = { 0, 0, 0, 0 }
    p2.published_previous_lateral_tilt = { 0, 0, 0, 0 }
end

function t1.AnimationFeedback.update(p3, p4, p5, p6, p7, p8, p9, p10) -- line: 60
    -- upvalues: rt (copy), v2 (copy), v3 (copy)
    p3.published_previous_lateral_tilt = rt.copy(p3.previous_lateral_tilt)
    p3.previous_lateral_tilt = rt.copy(p10)

    return v3.publish(p3.state, p3.settings, p4, p5, p6, p7, p8, v2.publish(p9, p3.bump_settings))
end

return t1
