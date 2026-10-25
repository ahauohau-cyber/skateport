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
local v8 = import("skate_core/animation/foot_ik/math")
local axis_rotation, cross, length, limit_length = v8.axis_rotation, v8.cross, v8.length, v8.limit_length
local reciprocal = v8.reciprocal
local inverse_rigid = import("skate_core/animation/foot_ik/transforms").inverse_rigid
local v9 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine, transform_point = v9.IDENTITY, v9.compose_affine, v9.transform_point
local asin = import("skate_core/trigonometry").asin
local t1 = {
    ExternalTarget = {}
}

function t1.ExternalTarget.default() -- line: 56
    return {
        normal_set = false,
        normal_blend = 0,
        world_position = { 0, 0, 0, 0 },
        animation_position = { 0, 0, 0, 0 },
        normal = { 0, 0, 0, 0 }
    }
end

function t1.update(p4, p5, p6, p7, p8, p9, p10) -- line: 66
    -- upvalues: rt (copy), v1 (copy), axis_rotation (copy), cross (copy), length (copy), limit_length (copy), reciprocal (copy), inverse_rigid (copy), IDENTITY (copy), compose_affine (copy), transform_point (copy), asin (copy)
    local v10 = p8[p7.part + 1]
    local v11 = compose_affine(p9, v10)
    local v12 = rt.copy(IDENTITY)

    if p4.normal_blend > 0 then
        local v13 = cross({ 0, 1, 0, 0 }, p4.normal)
        local v14 = length(v13)

        if v14 > 0.05 then
            local v15 = reciprocal(v14, 2)
            local t2 = {
                v15 * v13[1],
                v15 * v13[2],
                v15 * v13[3],
                v15 * v13[4]
            }
            local v16 = asin(v14)

            if -0.71 - v16 >= 0 then
                v16 = -0.71
            end

            if not (0.71 - v16 >= 0) then
                v16 = 0.71
            end

            v12 = axis_rotation(t2, v16 * p4.normal_blend)
        end

        if not p4.normal_set then
            local v17 = p4.normal_blend - 0.2

            if -v17 >= 0 then
                p4.normal_blend = 0
            else
                p4.normal_blend = v17
            end
        end
    end

    if p5.mode == "Local" then
        local target_blend = p5.target_blend
        local v18 = table.create(4)

        for i = 0, 3 do
            v18[i + 1] = (p4.animation_position[i + 1] - v10[4][i + 1]) * target_blend + p5.external_target_local_delta[i + 1] * (1 - target_blend)
        end

        local v19 = table.create(4)

        v19[1] = v18[1] - p5.external_target_local_delta[1]
        v19[2] = v18[2] - p5.external_target_local_delta[2]
        v19[3] = v18[3] - p5.external_target_local_delta[3]
        v19[4] = v18[4] - p5.external_target_local_delta[4]

        local v20 = limit_length(v19, 0.025)

        for i = 0, 3 do
            p5.external_target_local_delta[i + 1] += v20[i + 1]
            p4.animation_position[i + 1] = v10[4][i + 1] + v18[i + 1]
        end

        p4.world_position = transform_point(p9, p4.animation_position)
    else
        p4.animation_position = transform_point(p10, p4.world_position)
    end

    local v21 = table.create(4)

    v21[1] = p4.world_position[1] - v11[4][1]
    v21[2] = p4.world_position[2] - v11[4][2]
    v21[3] = p4.world_position[3] - v11[4][3]
    v21[4] = p4.world_position[4] - v11[4][4]

    local v22 = limit_length(v21, 0.7)
    local v23 = rt.copy(IDENTITY)
    local v24 = v11[4][1]
    local v25

    if v24 ~= 0 and v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
        local v26 = math.abs(v24) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if v24 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v24)
        v25 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v25, 2147483648)))

    local v30 = buffer.readf32(v1, 0)
    local v31 = v11[4][2]
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v32, 2147483648)))

    local v37 = buffer.readf32(v1, 0)
    local v38 = v11[4][3]
    local v39

    if v38 ~= 0 and v38 > -1.1754943508222875E-38 and v38 < 1.1754943508222875E-38 then
        local v40 = math.abs(v38) * 7.1362384635298E+44
        local v41 = math.floor(v40)
        local v42 = v40 - v41

        v39 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

        if v38 < 0 then
            v39 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v38)
        v39 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v39, 2147483648)))

    local v44 = buffer.readf32(v1, 0)
    local v45 = v11[4][4]
    local v46

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        local v47 = math.abs(v45) * 7.1362384635298E+44
        local v48 = math.floor(v47)
        local v49 = v47 - v48

        v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

        if v45 < 0 then
            v46 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v45)
        v46 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v46, 2147483648)))
    v23[4] = {
        v30,
        v37,
        v44,
        (buffer.readf32(v1, 0))
    }

    local v52 = compose_affine(v12, v23)
    local v53 = rt.copy(IDENTITY)

    v53[4] = {
        v11[4][1] + v22[1],
        v11[4][2] + v22[2],
        v11[4][3] + v22[3],
        v11[4][4] + v22[4]
    }
    p6.external_world = compose_affine(compose_affine(v53, v52), v11)

    local parent_part = p7.parent_part

    if parent_part ~= nil then
        local v55 = compose_affine(inverse_rigid(v10), p8[parent_part + 1])

        p6.external_parent_world = compose_affine(p6.external_world, v55)
    end
end

return t1
