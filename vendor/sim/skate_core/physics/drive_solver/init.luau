-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/constraint_frames")

import("skate_core/physics/native_arithmetic")

local v2 = import("skate_core/math")
local v3 = import("skate_core/physics/drive_solver/builder")

local function solver() -- line: 22
    -- upvalues: import (copy)
    return import("skate_core/physics/solver")
end

local Vector3 = v2.Vector3
local t1 = {}

local function struct_eq(p1, p2) -- line: 30
    -- upvalues: struct_eq (copy)
    if type(p1) ~= "table" or type(p2) ~= "table" then
        return p1 == p2
    end

    for v4, v5 in p1 do
        if not struct_eq(v5, p2[v4]) then
            return false
        end
    end

    for v6 in p2 do
        if p1[v6] == nil then
            return false
        end
    end

    return true
end

t1.build_drive_rows = v3.build_drive_rows
t1.tu3 = {
    DRIVE_JACOBIAN_BUILD = 2192448232,
    ITERATIVE_CONSTRAINT_SOLVER = 2192451536
}
t1.ACTIVE_BODY = 4
t1.RetailDriveBodyState = {}
t1.RetailDriveBodyState.eq = struct_eq
t1.RetailDriveRows = {}
t1.RetailDriveRows.eq = struct_eq

function t1.solve_drive_rows(p3, p4, p5) -- line: 80
    -- upvalues: import (copy)
    import("skate_core/physics/solver").solve_constraints({}, {}, p3, p4, p5)
end

function t1.solve_drive_iteration(p6, p7) -- line: 87
    -- upvalues: t1 (copy)
    t1.solve_drive_rows(p6, p7, 1)
end

function t1.is_active(p8) -- line: 91
    -- upvalues: t1 (copy)
    return bit32.band(p8.state, t1.ACTIVE_BODY) == t1.ACTIVE_BODY
end

function t1.basis_columns(p9) -- line: 95
    -- upvalues: Vector3 (copy)
    local v7 = table.create(3)

    for i = 1, 3 do
        local v8 = p9.columns[i]

        v7[i] = Vector3.new(v8[1], v8[2], v8[3])
    end

    return v7
end

function t1.project(p10, p11) -- line: 104
    -- upvalues: t1 (copy)
    local v9 = table.create(3)

    v9[1] = t1.dot(p10, p11[1])
    v9[2] = t1.dot(p10, p11[2])
    v9[3] = t1.dot(p10, p11[3])

    return v9
end

function t1.point_rate(p12, p13, p14) -- line: 112
    -- upvalues: v1 (copy)
    return v1.point_rate(p12, p13, p14)
end

function t1.add(p15, p16) -- line: 116
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15.x + p16.x, p15.y + p16.y, p15.z + p16.z)
end

function t1.sub(p17, p18) -- line: 120
    -- upvalues: Vector3 (copy)
    return Vector3.new(p17.x - p18.x, p17.y - p18.y, p17.z - p18.z)
end

function t1.scale(p19, p20) -- line: 124
    -- upvalues: Vector3 (copy)
    return Vector3.new(p19.x * p20, p19.y * p20, p19.z * p20)
end

function t1.dot(p21, p22) -- line: 128
    return p21.x * p22.x + p21.y * p22.y + p21.z * p22.z
end

function t1.cross(p23, p24) -- line: 132
    -- upvalues: v1 (copy)
    return v1.cross(p23, p24)
end

return t1
