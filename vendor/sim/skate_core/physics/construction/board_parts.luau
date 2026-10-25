-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")

local function mass() -- line: 13
    -- upvalues: import (copy)
    return import("skate_core/physics/mass")
end

local Vector3 = v1.Vector3
local t1 = {}

local function struct_eq(p1, p2) -- line: 21
    -- upvalues: struct_eq (copy)
    if type(p1) ~= "table" or type(p2) ~= "table" then
        return p1 == p2
    end

    for v2, v3 in p1 do
        if not struct_eq(v3, p2[v2]) then
            return false
        end
    end

    for v4 in p2 do
        if p1[v4] == nil then
            return false
        end
    end

    return true
end

t1.WheelMassSettings = {}
t1.WheelMassSettings.eq = struct_eq
t1.WheelMassSettings.STOCK = {
    radius = 0.03099999949336052,
    mass = 0.08299999684095383,
    mass_factor = 5
}
t1.TruckMassSettings = {}
t1.TruckMassSettings.eq = struct_eq
t1.TruckMassSettings.STOCK = {
    wheel_radius = 0.03099999949336052,
    wheel_x_distance = 0.0949999988079071,
    radius_scalar = 0.5375000238418579,
    half_height_scalar = 1.350000023841858,
    mass = 0.38999998569488525,
    mass_factor = 5
}
t1.PartMassInput = {}
t1.PartMassInput.eq = struct_eq

function t1.wheel_mass_input(p3) -- line: 75
    return {
        shape = {
            tag = "Sphere",
            radius = p3.radius
        },
        requested_mass = p3.mass * p3.mass_factor
    }
end

function t1.truck_mass_input(p4) -- line: 87
    return {
        shape = {
            tag = "Capsule",
            radius = p4.wheel_radius * p4.radius_scalar * 0.5,
            half_length = p4.wheel_x_distance * p4.half_height_scalar * 0.5
        },
        requested_mass = p4.mass * p4.mass_factor
    }
end

t1.ForwardMassProperties = {}
t1.ForwardMassProperties.eq = struct_eq

function t1.forward_mass_properties(p5) -- line: 106
    -- upvalues: rt (copy), import (copy), Vector3 (copy)
    local v5 = import("skate_core/physics/mass").primitive_mass(p5.shape)

    if v5 == nil then
        return nil
    end

    local v6 = if p5.requested_mass < rt.F32_MIN_POSITIVE then v5.volume else p5.requested_mass
    local moments_per_unit_mass = v5.moments_per_unit_mass

    return {
        primitive = v5,
        mass = v6,
        principal_moments = Vector3.new(moments_per_unit_mass.x * v6, moments_per_unit_mass.y * v6, moments_per_unit_mass.z * v6)
    }
end

return t1
