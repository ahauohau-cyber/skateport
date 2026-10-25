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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)

local function solver() -- line: 33
    -- upvalues: import (copy)
    return import("skate_core/physics/solver")
end

local t1 = {
    tu3 = {
        SIMULATION_SOLVE = 2192451536,
        JOINT_SOLVE_LOOP = 2192452552,
        DRIVE_SOLVE_LOOP = 2192453240,
        JOINT_BATCH_BUILD = 2192456144,
        JOINT_JACOBIAN_BUILD = 2192456648,
        JACOBIAN_BYTES = 384,
        REACTION_BYTES = 64
    }
}

t1.JACOBIAN_VECTOR_COUNT = rt.idiv(t1.tu3.JACOBIAN_BYTES, 16)
t1.REACTION_VECTOR_COUNT = rt.idiv(t1.tu3.REACTION_BYTES, 16)
t1.RetailJointJacobian = {}
t1.RetailJointReactionBlock = {}

function t1.RetailJointReactionBlock.default() -- line: 67
    -- upvalues: t1 (copy)
    return {
        words = table.create(t1.REACTION_VECTOR_COUNT * 4, 0)
    }
end

function t1.RetailJointReactionBlock.from_reactions(p4) -- line: 75
    -- upvalues: v1 (copy), t1 (copy)
    local v8 = table.create(t1.REACTION_VECTOR_COUNT * 4, 0)
    local x = p4.linear_displacement.x
    local v9

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v10 = math.abs(x) * 7.1362384635298E+44
        local v11 = math.floor(v10)
        local v12 = v10 - v11

        v9 = if v12 > 0.5 or v12 == 0.5 and v11 % 2 == 1 then v11 + 1 else v11

        if x < 0 then
            v9 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v9 = buffer.readu32(v1, 0)
    end

    v8[1] = v9

    local y = p4.linear_displacement.y
    local v13

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v14 = math.abs(y) * 7.1362384635298E+44
        local v15 = math.floor(v14)
        local v16 = v14 - v15

        v13 = if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15

        if y < 0 then
            v13 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v13 = buffer.readu32(v1, 0)
    end

    v8[2] = v13

    local z = p4.linear_displacement.z
    local v17

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v18 = math.abs(z) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if z < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v17 = buffer.readu32(v1, 0)
    end

    v8[3] = v17

    local x2 = p4.angular_displacement.x
    local v21

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        local v22 = math.abs(x2) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if x2 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x2)
        v21 = buffer.readu32(v1, 0)
    end

    v8[9] = v21

    local y2 = p4.angular_displacement.y
    local v25

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        local v26 = math.abs(y2) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if y2 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y2)
        v25 = buffer.readu32(v1, 0)
    end

    v8[10] = v25

    local z2 = p4.angular_displacement.z
    local v29

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        local v30 = math.abs(z2) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if z2 < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z2)
        v29 = buffer.readu32(v1, 0)
    end

    v8[11] = v29

    return {
        words = v8
    }
end

function t1.RetailJointReactionBlock.write_velocity_reactions(p5, p6) -- line: 87
    -- upvalues: v1 (copy)
    local linear_displacement = p6.linear_displacement

    buffer.writeu32(v1, 0, p5.words[1])
    linear_displacement.x = buffer.readf32(v1, 0)

    local linear_displacement2 = p6.linear_displacement

    buffer.writeu32(v1, 0, p5.words[2])
    linear_displacement2.y = buffer.readf32(v1, 0)

    local linear_displacement3 = p6.linear_displacement

    buffer.writeu32(v1, 0, p5.words[3])
    linear_displacement3.z = buffer.readf32(v1, 0)

    local angular_displacement = p6.angular_displacement

    buffer.writeu32(v1, 0, p5.words[9])
    angular_displacement.x = buffer.readf32(v1, 0)

    local angular_displacement2 = p6.angular_displacement

    buffer.writeu32(v1, 0, p5.words[10])
    angular_displacement2.y = buffer.readf32(v1, 0)

    local angular_displacement3 = p6.angular_displacement

    buffer.writeu32(v1, 0, p5.words[11])
    angular_displacement3.z = buffer.readf32(v1, 0)
end

function t1.solve_joint_iteration(p7, p8, p9) -- line: 97
    -- upvalues: import (copy)
    import("skate_core/physics/solver").solve_joint_record(p7.words, p8.words, p9.words)
end

return t1
