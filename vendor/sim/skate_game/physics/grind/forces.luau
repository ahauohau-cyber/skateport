-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local apply_world_force = import("skate_game/physics/grind/board").apply_world_force
local v1 = import("skate_core/physics/grind_forces")
local v2 = import("skate_core/physics/grind_forces/slide")
local v3 = import("skate_core/physics/grind_forces/release")

return {
    friction = function(p1, p2, p3, p4, p5, p6) -- friction | line: 20
        -- upvalues: apply_world_force (copy), v1 (copy)
        local v4 = v1.friction(p4, p5, p2.geometry.upmost_normal_1408, p2.surface.friction_vs_time_1496, bit32.band(p2.geometry.flags_1476, 1073741824) ~= 0, v1.material_multiplier(p2.surface.material_1472), p2.geometry.kind_1464, p6)

        if v1.friction_applies(p4, p5) then
            apply_world_force(p1, v4, p3)
        end
    end,
    lateral_pin = function(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16) -- lateral_pin | line: 39
        -- upvalues: apply_world_force (copy), v1 (copy)
        local v5 = v1.pin_slope(p11, p8.geometry.upmost_normal_1408, p8.surface.gravity_relief_1512, p16)
        local v6 = v1.lateral_pin(p9, p8.geometry.point_1120, p10, p12, p13, p14, p15, bit32.band(p8.control.flags_1516, 536870912) ~= 0, v5)

        if v6 ~= nil then
            apply_world_force(p7, v6, p9[4])
        end
    end,
    slide = function(p17, p18, p19) -- slide | line: 74
        -- upvalues: apply_world_force (copy), v2 (copy)
        local v7 = v2.control(p18, p19)

        for i = 1, #v7 do
            apply_world_force(p17, v7[i], p19.position)
        end
    end,
    release = function(p20, p21) -- release | line: 82
        -- upvalues: apply_world_force (copy), v3 (copy)
        local v8 = v3.force(p21)

        if v8 ~= nil then
            apply_world_force(p20, v8, p21.position)
        end
    end
}
