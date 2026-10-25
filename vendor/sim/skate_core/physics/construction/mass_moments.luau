-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/rigid_body")
local v3 = import("skate_core/physics/construction/principal_axes")

local function mass() -- line: 16
    -- upvalues: import (copy)
    return import("skate_core/physics/mass")
end

local Vector3 = v1.Vector3
local RetailLocalMassFrame = v2.RetailLocalMassFrame
local diagonalize = v3.diagonalize
local t1 = {}

local function struct_eq(p1, p2) -- line: 26
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

t1.MassMoments = {}
t1.MassMoments.eq = struct_eq
t1.AggregateMassProperties = {}
t1.AggregateMassProperties.eq = struct_eq
t1.MassMoments.ZERO = {
    columns = rt.filled(4, table.create(4, 0))
}

function t1.MassMoments.from_primitive(p3) -- line: 59
    local moments_per_unit_mass, volume = p3.moments_per_unit_mass, p3.volume
    local v7 = (moments_per_unit_mass.z + moments_per_unit_mass.y - moments_per_unit_mass.x) * volume * 0.5
    local v8 = (moments_per_unit_mass.z + moments_per_unit_mass.x - moments_per_unit_mass.y) * volume * 0.5
    local v9 = (moments_per_unit_mass.y + moments_per_unit_mass.x - moments_per_unit_mass.z) * volume * 0.5

    return {
        columns = {
            { v7, 0, 0, 0 },
            { 0, v8, 0, 0 },
            { 0, 0, v9, 0 },
            { 0, 0, 0, volume }
        }
    }
end

function t1.MassMoments.transform(p4, p5, p6) -- line: 77
    -- upvalues: rt (copy), t1 (copy)
    local v10 = rt.filled(4, table.create(4, 0))

    for i = 1, 3 do
        local v11 = v10[i]
        local v12 = p5.columns[i]

        v11[1] = v12[1]
        v11[2] = v12[2]
        v11[3] = v12[3]
    end

    v10[4] = {
        p6.x,
        p6.y,
        p6.z,
        1
    }

    local v13 = table.create(4)

    for i = 1, 4 do
        v13[i] = t1.product(v10, p4.columns[i])
    end

    p4.columns = {
        t1.product(v13, {
            v10[1][1],
            v10[2][1],
            v10[3][1],
            v10[4][1]
        }),
        t1.product(v13, {
            v10[1][2],
            v10[2][2],
            v10[3][2],
            v10[4][2]
        }),
        t1.product(v13, {
            v10[1][3],
            v10[2][3],
            v10[3][3],
            v10[4][3]
        }),
        t1.product(v13, {
            v10[1][4],
            v10[2][4],
            v10[3][4],
            v10[4][4]
        })
    }
end

function t1.MassMoments.add(p7, p8) -- line: 101
    for i = 1, 4 do
        local v14 = p7.columns[i]
        local v15 = p8.columns[i]

        v14[1] += v15[1]
        v14[2] += v15[2]
        v14[3] += v15[3]
        v14[4] += v15[4]
    end
end

function t1.MassMoments.principal_properties(p9) -- line: 113
    -- upvalues: rt (copy), import (copy), Vector3 (copy), RetailLocalMassFrame (copy), diagonalize (copy), t1 (copy)
    local v16 = p9.columns[4][4]
    local v17 = import("skate_core/physics/mass").refined_reciprocal(v16)
    local v18 = Vector3.new(p9.columns[4][1] * v17, p9.columns[4][2] * v17, p9.columns[4][3] * v17)

    t1.MassMoments.transform(p9, rt.copy(RetailLocalMassFrame.IDENTITY.basis), Vector3.new(-v18.x, -v18.y, -v18.z))

    local v19 = rt.copy(p9.columns)
    local v20 = (v19[2][1] + v19[1][2]) * -0.5
    local v21 = (v19[3][1] + v19[1][3]) * -0.5
    local v22 = (v19[3][2] + v19[2][3]) * -0.5
    local t2 = {
        {
            v19[2][2] + v19[3][3],
            v20,
            v21
        },
        {
            v20,
            v19[1][1] + v19[3][3],
            v22
        },
        {
            v21,
            v22,
            v19[1][1] + v19[2][2]
        }
    }
    local v23 = diagonalize(t2)
    local v24 = t1.select_nonnegative(t2[2][2] - t2[3][3], t2[2][2], t2[3][3])
    local v25 = t1.select_nonnegative(t2[1][1] - v24, t2[1][1], v24) * 0.0050000004
    local t3 = {
        t1.select_nonnegative(t2[1][1] - v25, t2[1][1], v25) * v17,
        t1.select_nonnegative(t2[2][2] - v25, t2[2][2], v25) * v17,
        t1.select_nonnegative(t2[3][3] - v25, t2[3][3], v25) * v17
    }

    return {
        volume = v16,
        local_mass_frame = {
            basis = {
                columns = {
                    {
                        v23[1][1],
                        v23[2][1],
                        v23[3][1]
                    },
                    {
                        v23[1][2],
                        v23[2][2],
                        v23[3][2]
                    },
                    {
                        v23[1][3],
                        v23[2][3],
                        v23[3][3]
                    }
                }
            },
            translation = v18
        },
        moments_per_unit_mass = Vector3.new(t3[1], t3[2], t3[3])
    }
end

function t1.product(p10, p11) -- line: 160
    return {
        p10[4][1] * p11[4] + (p10[3][1] * p11[3] + (p10[2][1] * p11[2] + p10[1][1] * p11[1])),
        p10[4][2] * p11[4] + (p10[3][2] * p11[3] + (p10[2][2] * p11[2] + p10[1][2] * p11[1])),
        p10[4][3] * p11[4] + (p10[3][3] * p11[3] + (p10[2][3] * p11[2] + p10[1][3] * p11[1])),
        p10[4][4] * p11[4] + (p10[3][4] * p11[3] + (p10[2][4] * p11[2] + p10[1][4] * p11[1]))
    }
end

function t1.select_nonnegative(p12, p13, p14) -- line: 169
    if p12 >= 0 then
        return p13
    end

    return p14
end

return t1
