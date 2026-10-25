-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local accumulate_point_force = import("skate_core/physics/point_force").accumulate_point_force
local t1 = {}

function t1.apply_world_force(p1, p2, p3) -- line: 18
    -- upvalues: BodyId (copy), BoardRuntime (copy), t1 (copy)
    local v1 = BoardRuntime.bodies_mut(p1)[BodyId.index(BodyId.Deck) + 1]

    t1.apply_to_deck(v1, p2, p3)
end

function t1.apply_to_deck(p4, p5, p6) -- line: 24
    -- upvalues: rt (copy), Vector3 (copy), accumulate_point_force (copy)
    local rates = p4.rates
    local v2 = Vector3.new(p6[1] - rates.position.x, p6[2] - rates.position.y, p6[3] - rates.position.z)
    local v3 = accumulate_point_force({
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        cool_down = rates.cool_down
    }, Vector3.new(p5[1], p5[2], p5[3]), v2, {
        columns = {
            { 1, 0, 0 },
            { 0, 1, 0 },
            { 0, 0, 1 }
        }
    }, p4.inertia.inverse_mass, rt.copy(rates.world_inverse_inertia))

    rates.force_acceleration = v3.force_acceleration
    rates.torque_acceleration = v3.torque_acceleration
    rates.cool_down = v3.cool_down
end

return t1
