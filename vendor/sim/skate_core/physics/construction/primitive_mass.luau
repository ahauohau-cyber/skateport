-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {}

local function struct_eq(p1, p2) -- line: 16
    -- upvalues: struct_eq (copy)
    if type(p1) ~= "table" or type(p2) ~= "table" then
        return p1 == p2
    end

    for v1, v2 in p1 do
        if not struct_eq(v2, p2[v1]) then
            return false
        end
    end

    for v3 in p2 do
        if p1[v3] == nil then
            return false
        end
    end

    return true
end

t1.MassShape = {}
t1.MassShape.eq = struct_eq
t1.PrimitiveMass = {}
t1.PrimitiveMass.eq = struct_eq
t1.MIN_RADIUS = 1.0000000116860974E-07
t1.SPHERE_VOLUME = 4.188790321350098
t1.FOUR_THIRDS = 1.3333333730697632
t1.TWO_THIRDS = 0.6666666865348816
t1.ONE_THIRD = 0.3333333432674408
t1.ONE_TWELFTH = 0.0833333358168602
t1.PI = 3.1415927410125732
t1.TWO_PI = 6.2831854820251465

function t1.greater_extent(p3, p4) -- line: 58
    if p3 - p4 >= 0 then
        return p3
    end

    return p4
end

function t1.primitive_mass(p5) -- line: 69
    -- upvalues: Vector3 (copy), t1 (copy)
    if p5.tag == "Unsupported" then
        return nil
    end

    if p5.tag == "Sphere" then
        local v4 = t1.greater_extent(p5.radius, t1.MIN_RADIUS)
        local v5 = v4 * v4
        local v6 = v5 * 0.4

        return {
            moments_per_unit_mass = Vector3.new(v6, v6, v6),
            volume = v5 * v4 * t1.SPHERE_VOLUME
        }
    end

    if p5.tag == "Capsule" then
        local half_length = p5.half_length
        local v7 = half_length * half_length
        local v8 = t1.greater_extent(t1.greater_extent(p5.radius, t1.MIN_RADIUS), half_length * 0.05)
        local v9 = (((v8 * 1.6 + half_length * 0.75) * v8 + v7 * 4) * v8 + v7 * half_length) / (v8 * 4 + half_length * 3)
        local v10 = v8 * v8 * 0.4

        return {
            moments_per_unit_mass = Vector3.new(v9, v9, v10),
            volume = (v8 * t1.FOUR_THIRDS + half_length * 2) * v8 * v8 * t1.PI
        }
    end

    if p5.tag == "RoundedBox" then
        return t1.rounded_box_mass(p5.half_extents, p5.radius)
    end

    if p5.tag == "Cylinder" then
        local v11 = p5.radius + p5.padding
        local v12 = p5.half_length + p5.padding
        local v13 = v11 * v11
        local v14 = (v12 * v12 * 4 + v13 * 3) * t1.ONE_TWELFTH

        return {
            moments_per_unit_mass = Vector3.new(v14, v14, v13 * 0.5),
            volume = v12 * v11 * v11 * t1.TWO_PI
        }
    end

    error("unreachable: unknown MassShape tag", 0)
end

function t1.rounded_box_mass(p6, p7) -- line: 109
    -- upvalues: Vector3 (copy), t1 (copy)
    local v15 = t1.greater_extent(p6.x, t1.greater_extent(p6.y, p6.z))
    local v16 = t1.greater_extent((v15 + p7) * 0.05, t1.MIN_RADIUS) - p7
    local v17 = t1.greater_extent(p6.x, v16)
    local v18 = t1.greater_extent(p6.y, v16)
    local v19 = t1.greater_extent(p6.z, v16)
    local v20 = p7 * p7 * 0.5
    local v21 = v17 * v17
    local v22 = v18 * v18
    local v23 = v19 * v19
    local v24 = (v17 + v18) * p7
    local v25 = (v18 + v19) * p7
    local v26 = (v17 + v19) * p7
    local v27 = (v25 * 2 + v23 + v22) * t1.ONE_THIRD + v20
    local v28 = (v26 * 2 + v21 + v23) * t1.ONE_THIRD + v20
    local v29 = (v24 * 2 + v21 + v22) * t1.ONE_THIRD + v20
    local v30 = (p7 * t1.TWO_THIRDS + v17 + v18 + v19) * p7 * t1.TWO_PI
    local v31 = (v18 + v19) * v17 + v18 * v19
    local v32 = v17 * v18 * v19 * 8

    return {
        moments_per_unit_mass = Vector3.new(v27, v28, v29),
        volume = (v31 * 8 + v30) * p7 + v32
    }
end

return t1
