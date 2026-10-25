-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function parent() -- line: 11
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind")
end

local function physics_grind() -- line: 14
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {}

function t1.surface(p1, p2) -- line: 21
    -- upvalues: rt (copy), import (copy)
    local raw = import("skate_game/physics/player_input/grind").raw

    p1.center_1360 = raw(p2.center)
    p1.far_points_1376_1392 = {
        raw(p2.far_points[1]),
        raw(p2.far_points[2])
    }
    p1.upmost_normal_1408 = raw(p2.upmost_normal)
    p1.surface_direction_1424 = raw(p2.direction)
    p1.high_side_1440 = raw(p2.high_side)
    p1.normal_limits_1456_1460 = rt.copy(p2.normal_limits)
    p1.geometry_kind_1464 = p2.kind
    p1.audio_surface_1468 = p2.audio_surface
    p1.physics_surface_1472 = p2.physics_surface
    p1.geometry_flags_1476 = p2.flags
end

function t1.observation(p3, p4, p5, p6) -- line: 37
    -- upvalues: rt (copy), import (copy), t1 (copy)
    local float = import("skate_game/physics/player_input/grind").float
    local grind = p3.grind

    t1.family(grind.family_1248)
    t1.family(p6.family)

    local v1 = if p5 == nil then nil else rt.copy(p5.spline_guids)

    return {
        geometry = {
            point_1120 = float(grind.point_1120),
            direction_1136 = float(grind.direction_1136),
            normal_1152 = float(grind.normal_1152),
            target_up_1168 = float(grind.target_up_1168),
            primitive_start_1264 = float(grind.primitive_start_1264),
            primitive_end_1280 = float(grind.primitive_end_1280),
            spline_guids_1296 = v1,
            upmost_normal_1408 = float(grind.upmost_normal_1408),
            high_side_1440 = float(grind.high_side_1440),
            kind_1464 = grind.geometry_kind_1464,
            flags_1476 = grind.geometry_flags_1476,
            impact_speed_1492 = grind.impact_speed_1492
        },
        surface = {
            audio_surface_1468 = grind.audio_surface_1468,
            material_1472 = grind.physics_surface_1472,
            friction_vs_time_1496 = grind.friction_1496,
            reckon_blend_selector_1500 = grind.exit_lean_1500,
            gravity_relief_1512 = grind.gravity_relief_1512
        },
        control = {
            flags_1516 = grind.flags_1516,
            flags_2488 = p3.flags_2488,
            translation_2796 = p4.translation_2796,
            balance_2800 = p4.stability_nudge_2800
        },
        engagement = {
            kind_1248 = grind.family_1248
        }
    }
end

function t1.family(p7) -- line: 81
    -- upvalues: import (copy)
    local Family = import("skate_game/physics/grind").Family

    if p7 == 0 then
        return Family.FiftyFifty
    end

    if p7 == 1 then
        return Family.Boardslide
    end

    if p7 == 2 then
        return Family.Tipslide
    end

    if p7 == 3 then
        return Family.FiveO
    end

    if p7 == 4 then
        return Family.Backslash
    end

    if p7 == 5 then
        return Family.Darkslide
    end

    error(string.format("Invalid published grind family %d", p7), 0)
end

return t1
