-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local BoardRuntime = require(sim.import)("skate_core/physics/board_runtime").BoardRuntime
local t1 = {
    GrindMaterials = {}
}

function t1.GrindMaterials.new(p1) -- line: 19
    -- upvalues: rt (copy)
    return {
        standard = {
            rt.copy(p1.standard_wheel_material),
            rt.copy(p1.truck_material),
            rt.copy(p1.deck_material)
        }
    }
end

function t1.GrindMaterials.apply(p2, p3, p4, p5) -- line: 31
    -- upvalues: rt (copy), BoardRuntime (copy)
    if p3 == "Unchanged" then
        return
    end

    local v1

    if p3 == "Standard" then
        v1 = rt.copy(p2.standard)
    elseif p3 == "Grind" then
        v1 = rt.filled(3, {
            static_friction = 0,
            dynamic_friction = 0,
            restitution = 0
        })
    else
        error("GrindMaterials.apply: unknown MaterialMode " .. tostring(p3), 0)
    end

    BoardRuntime.set_collision_group(p4, 4)
    p5.wheel_material = v1[1]
    p5.truck_material = v1[2]
    p5.deck_material = v1[3]
end

return t1
