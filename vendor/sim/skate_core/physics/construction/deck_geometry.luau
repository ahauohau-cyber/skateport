-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/math")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/trigonometry")

local function mass() -- line: 41
    -- upvalues: import (copy)
    return import("skate_core/physics/mass")
end

local function drive_frames() -- line: 46
    -- upvalues: import (copy)
    return import("skate_core/physics/drive_frames")
end

local Vector3 = v9.Vector3
local t1 = {}

local function struct_eq(p4, p5) -- line: 54
    -- upvalues: struct_eq (copy)
    if type(p4) ~= "table" or type(p5) ~= "table" then
        return p4 == p5
    end

    for v12, v13 in p4 do
        if not struct_eq(v13, p5[v12]) then
            return false
        end
    end

    for v14 in p5 do
        if p4[v14] == nil then
            return false
        end
    end

    return true
end

local function round_ties_even(p6) -- line: 72
    -- upvalues: rt (copy)
    local v15 = rt.round(p6)

    if math.abs(p6 - rt.trunc(p6)) == 0.5 then
        v15 = 2 * rt.round(p6 / 2)
    end

    return v15
end

t1.DeckGeometrySettings = {}
t1.DeckGeometrySettings.eq = struct_eq
t1.DeckGeometrySettings.STOCK = {
    width = 0.23999999463558197,
    mid_length = 0.5899999737739563,
    thickness = 0.014999999664723873,
    back_end_size = 0.16500000655651093,
    front_end_angle_degrees = 13,
    back_end_angle_degrees = 12.5,
    end_capsule_count = 5,
    enable_deck_volume_collisions = true,
    enable_end_volume_collisions = true
}
t1.DeckShape = {}
t1.DeckShape.eq = struct_eq
t1.DeckChild = {}
t1.DeckChild.eq = struct_eq
t1.DeckGeometry = {}
t1.DeckGeometry.eq = struct_eq

function t1.DeckGeometry.new(p7) -- line: 119
    -- upvalues: rt (copy), import (copy), v11 (copy), Vector3 (copy), t1 (copy)
    local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
    local v17 = p7.width * 0.5
    local v18 = p7.mid_length * 0.5
    local v19 = p7.thickness * 0.5
    local v20 = v19 * 0.8999999761581421
    local t2 = {
        {
            shape = {
                tag = "RoundedBox",
                half_extents = Vector3.new(v17 - v20, v19 - v20, v18 - v20),
                radius = v20
            },
            transform = rt.copy(RetailAffineTransform.IDENTITY),
            collision_enabled = p7.enable_deck_volume_collisions
        }
    }
    local v21 = (-v18 - v18) * 0.5
    local v22 = t1.vector_length_z(v21)
    local v23 = v18 + v21
    local v24 = v17 - v19

    for _, v25 in {
            v24,
            v19 - v17
        } do
        table.insert(t2, {
            shape = {
                tag = "Capsule",
                radius = v19,
                half_length = v22
            },
            transform = t1.translated(Vector3.new(v25, 0, v23)),
            collision_enabled = p7.enable_end_volume_collisions
        })
    end

    for _, v26 in { 0.23499999940395355, -0.23499999940395355 } do
        table.insert(t2, {
            collision_enabled = true,
            shape = {
                tag = "Sphere",
                radius = 0.035
            },
            transform = t1.translated(Vector3.new(0, -0.019999999552965164, v26))
        })
    end

    local v27 = p7.back_end_angle_degrees * 0.01745329238474369
    local v28 = p7.front_end_angle_degrees * 0.01745329238474369
    local t5 = {
        v11.sin(v27),
        t1.cosine(v27)
    }
    local t6 = {
        v11.sin(v28),
        t1.cosine(v28)
    }
    local v29 = p7.back_end_size - v19
    local t7 = {
        v11.sin(0),
        t1.cosine(0)
    }
    local v30 = rt.copy(t7)

    for i = 1, p7.end_capsule_count do
        local v31 = i * -3.1415927410125732 / p7.end_capsule_count
        local t8 = {
            v11.sin(v31),
            t1.cosine(v31)
        }

        table.insert(t2, t1.fan_triangle(t7, t8, t5, v24, v29, -v18, v19, false, p7.enable_deck_volume_collisions))

        local v33 = i * 3.1415927410125732 / p7.end_capsule_count
        local t9 = {
            v11.sin(v33),
            t1.cosine(v33)
        }

        table.insert(t2, t1.fan_triangle(v30, t9, t6, v24, v29, v18, v19, true, p7.enable_deck_volume_collisions))
        v30 = t9
        t7 = t8
    end

    return {
        children = t2
    }
end

function t1.DeckGeometry.mass_moments(p8) -- line: 212
    -- upvalues: rt (copy), import (copy), Vector3 (copy), t1 (copy)
    local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
    local MassMoments = import("skate_core/physics/mass").MassMoments
    local v34 = rt.copy(MassMoments.ZERO)

    for i = 1, #p8.children do
        MassMoments.add(v34, t1.DeckChild.mass_moments(p8.children[i]))
    end

    MassMoments.transform(v34, rt.copy(RetailAffineTransform.IDENTITY.basis), rt.copy(Vector3.ZERO))

    return v34
end

function t1.DeckChild.mass_moments(p9) -- line: 224
    -- upvalues: rt (copy), import (copy), v10 (copy), Vector3 (copy), t1 (copy)
    local MassMoments = import("skate_core/physics/mass").MassMoments
    local shape = p9.shape
    local t10, v35

    if shape.tag == "Sphere" then
        t10 = {
            tag = "Sphere",
            radius = shape.radius
        }
        v35 = rt.copy(p9.transform)
    elseif shape.tag == "Capsule" then
        t10 = {
            tag = "Capsule",
            radius = shape.radius,
            half_length = shape.half_length
        }
        v35 = rt.copy(p9.transform)
    elseif shape.tag == "RoundedBox" then
        t10 = {
            tag = "RoundedBox",
            half_extents = rt.copy(shape.half_extents),
            radius = shape.radius
        }
        v35 = rt.copy(p9.transform)
    elseif shape.tag == "Triangle" then
        local vertices, fatness = shape.vertices, shape.fatness

        local function axis(p10) -- line: 253
            -- upvalues: vertices (copy), fatness (copy), v10 (copy)
            local v36 = p10(vertices[1])
            local v37 = p10(vertices[2])
            local v38 = p10(vertices[3])
            local v39 = v10.vector_min(v36, v10.vector_min(v37, v38)) - fatness
            local v40 = (v10.vector_max(v36, v10.vector_max(v37, v38)) + fatness - v39) * 0.5

            return {
                v40,
                v39 + v40
            }
        end

        local v41 = axis(function(p11) -- line: 262
            return p11.x
        end)
        local v42 = axis(function(p12) -- line: 265
            return p12.y
        end)
        local v43 = axis(function(p13) -- line: 268
            return p13.z
        end)

        t10 = {
            tag = "RoundedBox",
            radius = 0,
            half_extents = Vector3.new(v41[1], v42[1], v43[1])
        }
        v35 = t1.translated(Vector3.new(v41[2], v42[2], v43[2]))
    else
        error("unreachable: unknown DeckShape tag", 0)
    end

    local v44 = import("skate_core/physics/mass").primitive_mass(t10)

    if v44 == nil then
        error("every deck child follows a supported source mass branch", 0)
    end

    local v45 = MassMoments.from_primitive(v44)

    MassMoments.transform(v45, v35.basis, v35.translation)

    return v45
end

function t1.translated(p14) -- line: 289
    -- upvalues: rt (copy), import (copy)
    local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform

    return {
        translation = p14,
        basis = rt.copy(RetailAffineTransform.IDENTITY.basis)
    }
end

function t1.fan_triangle(p15, p16, p17, p18, p19, p20, p21, p22, p23) -- line: 298
    -- upvalues: rt (copy), import (copy), Vector3 (copy)
    local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform

    local function point(p24) -- line: 300
        -- upvalues: p17 (copy), p18 (copy), p19 (copy), p20 (copy), p22 (copy), Vector3 (copy)
        local v46 = p24[1] * p19
        local v47 = if p22 then v46 else -v46

        return Vector3.new(p24[2] * p18, p17[1] * v47, v46 * p17[2] + p20)
    end

    local t11 = {}
    local t12 = {
        tag = "Triangle",
        volume_flags = 994
    }
    local v48 = Vector3.new(0, 0, p20)
    local v49 = p15[1] * p19
    local v50 = if p22 then v49 else -v49

    t12.vertices = {
        v48,
        Vector3.new(p15[2] * p18, p17[1] * v50, v49 * p17[2] + p20),
        point(p16)
    }
    t12.fatness = p21
    t12.edge_cosines = { 1, -1, 1 }
    t11.shape = t12
    t11.transform = rt.copy(RetailAffineTransform.IDENTITY)
    t11.collision_enabled = p23

    return t11
end

function t1.vector_length_z(p25) -- line: 329
    -- upvalues: v1 (copy), v10 (copy)
    local v51 = v10.dot3({ 0, 0, p25, 0 }, { 0, 0, p25, 0 })
    local v52

    if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
        local v53 = math.abs(v51) * 7.1362384635298E+44
        local v54 = math.floor(v53)
        local v55 = v53 - v54

        v52 = (if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54) * 1.401298464324817E-45

        if v51 < 0 then
            v52 = -v52
        end
    else
        buffer.writef32(v1, 0, v51)
        v52 = buffer.readf32(v1, 0)
    end

    local v56 = v10.reciprocal_square_root_estimate(v52)
    local v57 = -v52 * (v56 * v56) + 1
    local v58 = v56 * 0.5 * v57 + v56
    local v59 = -v52 * (v58 * v58) + 1
    local v60 = v58 * 0.5 * v59 + v58

    if v52 == 0 then
        return 0
    end

    return v52 * v60
end

function t1.cosine(p26) -- line: 344
    -- upvalues: rt (copy), v1 (copy)
    local v61 = p26 * 0.15915493667125702
    local v62 = rt.round(v61)

    if math.abs(v61 - rt.trunc(v61)) == 0.5 then
        v62 = 2 * rt.round(v61 / 2)
    end

    local v64 = -6.2831854820251465 * v62 + p26
    local v65 = v64 * v64
    local v66 = v65 * v65
    local v67 = v66 * v65
    local v68 = v66 * v66
    local v69 = v67 * v66
    local v70 = v67 * v67
    local v71 = v68 * v67
    local v72 = v68 * v68
    local v73 = v69 * v68
    local v74 = v69 * v69
    local v75 = v70 * v69
    local v76 = -0.5 * v65 + 1

    for _, v77 in {
            { v66, 1026206379 },
            { v67, 3132492641 },
            { v68, 936381697 },
            { v69, 3029594750 },
            { v70, 823097032 },
            { v71, 2907294629 },
            { v72, 693583775 },
            { v73, 2771653571 },
            { v74, 552771933 },
            { v75, 2626056651 }
        } do
        local v78 = v77[1]

        buffer.writeu32(v1, 0, v77[2])
        v76 = buffer.readf32(v1, 0) * v78 + v76
    end

    return v76
end

return t1
