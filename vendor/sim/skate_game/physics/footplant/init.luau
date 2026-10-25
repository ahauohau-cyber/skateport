-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/air/trajectory")
local v2 = import("skate_game/physics/footplant/settings")
local v3 = import("skate_game/physics/footplant/pose")
local v4 = import("skate_game/physics/footplant/update")
local v5 = import("skate_game/physics/footplant/ground")
local QueryResult = v1.QueryResult
local Settings = v2.Settings
local t1 = {
    FootplantFrame = v4.FootplantFrame,
    Footplant = {}
}

function t1.Footplant.load(p1) -- line: 64
    -- upvalues: QueryResult (copy), Settings (copy), t1 (copy)
    local t2 = {
        enabled = false,
        result = QueryResult.miss(),
        settings = Settings.load(p1),
        selected_toe = nil,
        candidate = false,
        hit = false,
        perform = false,
        flag_627 = false,
        launch_valid = false,
        lock_valid = false,
        contact_active = false,
        requested = false,
        contact_time = -1,
        scalar_596 = -1,
        scalar_600 = 0,
        target_blend = 0,
        active_elapsed = 0,
        scalar_612 = 0,
        surface = 0,
        contact = { 0, 0, 0, 0 },
        adjusted_contact = { 0, 0, 0, 0 },
        current_up = { 0, 0, 0, 0 },
        selected_world = { 0, 0, 0, 0 },
        selected_record = { 0, 0, 0, 0 },
        leg_direction = { 0, 0, 0, 0 },
        vectors_352_368 = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        curve = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        physical_com = { 0, 0, 0, 0 },
        animation_com = { 0, 0, 0, 0 },
        launch_direction = { 0, 0, 0, 0 },
        locked_target = { 0, 0, 0, 0 },
        request = {
            duration = -1,
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        },
        completed_trajectory = {
            duration = -1,
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        }
    }

    t1.Footplant.reset(t2)

    return t2
end

function t1.Footplant.reset(p2) -- line: 125
    p2.contact_time = -1
    p2.scalar_596 = -1
    p2.selected_toe = nil
    p2.scalar_600 = 0
    p2.target_blend = 0
    p2.active_elapsed = 0
    p2.scalar_612 = 0
    p2.candidate = false
    p2.hit = false
    p2.perform = false
    p2.flag_627 = false
    p2.launch_valid = false
    p2.lock_valid = false
    p2.contact_active = false
    p2.requested = false
    p2.request = {
        duration = -1,
        position = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 },
        acceleration = { 0, 0, 0, 0 }
    }
    p2.contact = { 0, 0, 0, 0 }
    p2.adjusted_contact = { 0, 0, 0, 0 }
    p2.vectors_352_368 = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
    p2.animation_com = { 0, 0, 0, 0 }
    p2.locked_target = { 0, 0, 0, 0 }
    p2.launch_direction = { 0, 0, 0, 0 }
    p2.physical_com = { 0, 0, 0, 0 }
end

function t1.Footplant.full_reset(p3) -- line: 156
    -- upvalues: t1 (copy)
    p3.enabled = false
    t1.Footplant.reset(p3)
end

function t1.Footplant.publish(p4, p5) -- line: 163
    if p4.hit then
        p5.footplant_contact_time_208 = p4.contact_time
        p5.footplant_duration_212 = p4.scalar_596
        p5.flag_447 = p4.perform and 1 or 0
        p5.flag_448 = (p4.perform or p4.flag_627) and 1 or 0
        p5.footplant_surface_224 = p4.surface
        p5.footplant_left_449 = not (p4.flag_627 and p4.selected_toe == 15) and 0 or 1
        p5.footplant_right_450 = not (p4.flag_627 and p4.selected_toe == 19) and 0 or 1
        p5.footplant_surface_height_216 = p4.contact[2]
    end
end

for _, v6 in {
        v4.Footplant,
        v3.Footplant,
        v5.Footplant
    } do
    for v7, v8 in v6 do
        t1.Footplant[v7] = v8
    end
end

return t1
