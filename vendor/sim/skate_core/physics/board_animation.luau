-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/constraint_frames")
local basis, reciprocal, reciprocal_sqrt = v1.basis, v1.reciprocal, v1.reciprocal_sqrt
local retail_quaternion_from_basis = import("skate_core/physics/drive_frames").retail_quaternion_from_basis
local dot4 = import("skate_core/physics/native_arithmetic").dot4
local v2 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v2.IDENTITY, v2.compose_affine
local v3 = import("skate_core/physics/skeleton_root")
local inverse_rigid, orthonormalize = v3.inverse_rigid, v3.orthonormalize
local PointGraph = import("skate_core/point_graph").PointGraph
local v4 = import("skate_core/trigonometry")
local t1 = {
    BoardAnimationSettings = {},
    BoardAnimation = {}
}

function t1.BoardAnimation.default() -- line: 37
    return {
        blending = false,
        rotation_error = { 0, 0, 0, 1 }
    }
end

function t1.BoardAnimation.reset(p1) -- line: 46
    p1.rotation_error = { 0, 0, 0, 1 }
end

function t1.BoardAnimation.capture_physics_error(p2, p3, p4) -- line: 54
    -- upvalues: retail_quaternion_from_basis (copy), compose_affine (copy), inverse_rigid (copy), orthonormalize (copy)
    local v5 = orthonormalize(compose_affine(inverse_rigid(p3), p4))
    local v6 = retail_quaternion_from_basis({
        columns = {
            {
                v5[1][1],
                v5[1][2],
                v5[1][3]
            },
            {
                v5[2][1],
                v5[2][2],
                v5[2][3]
            },
            {
                v5[3][1],
                v5[3][2],
                v5[3][3]
            }
        }
    })

    p2.rotation_error = {
        v6.x,
        v6.y,
        v6.z,
        v6.w
    }
    p2.blending = true
end

function t1.BoardAnimation.apply(p5, p6, p7, p8) -- line: 69
    -- upvalues: rt (copy), basis (copy), reciprocal (copy), reciprocal_sqrt (copy), dot4 (copy), IDENTITY (copy), compose_affine (copy), PointGraph (copy), v4 (copy)
    if not p5.blending then
        return rt.copy(p6)
    end

    local v7 = v4.acos(p5.rotation_error[4]) * 2 * 0.15915493667125702
    local v8 = v7 - math.floor(v7)
    local v10 = math.abs((v8 - (if v8 > 0.5 then 1 else 0)) * 6.2831854820251465)
    local v11 = PointGraph.evaluate(if p7 then p8.fast else p8.slow, v10)

    if v11 < 0.949999988079071 then
        local t2 = {
            0, 0, 0, 1
        }
        local v12 = dot4(p5.rotation_error, t2)
        local v13 = v12 < 0

        if v13 then
            v12 = -v12
        end

        local v14 = rt.map(p5.rotation_error, function(p9) -- line: 88
            -- upvalues: v13 (copy)
            if v13 then
                return -p9
            end

            return p9
        end)
        local v15

        if v12 > 0.9961947202682495 then
            local v16 = dot4(v14, t2) > 0
            local v17 = rt.from_fn(4, function(p10) -- line: 94
                -- upvalues: v11 (copy), t2 (copy), v14 (copy), v16 (copy)
                if v16 then
                    return v11 * (t2[p10 + 1] - v14[p10 + 1]) + v14[p10 + 1]
                end

                return -(t2[p10 + 1] + v14[p10 + 1]) * v11 + v14[p10 + 1]
            end)
            local v18 = reciprocal_sqrt(dot4(v17, v17))

            v15 = rt.map(v17, function(p11) -- line: 102
                -- upvalues: v18 (copy)
                return p11 * v18
            end)
        else
            local v19 = v4.acos(v12)
            local v20 = v4.sin((1 - v11) * v19)
            local v21 = v4.sin(v11 * v19)
            local v22 = reciprocal(v4.sin(v19))
            local v23 = v20 * v22
            local v24 = v21 * v22

            v15 = {
                t2[1] * v24 + v14[1] * v23,
                t2[2] * v24 + v14[2] * v23,
                t2[3] * v24 + v14[3] * v23,
                t2[4] * v24 + v14[4] * v23
            }
        end

        p5.rotation_error = rt.copy(v15)

        local v25 = basis({
            x = v15[1],
            y = v15[2],
            z = v15[3],
            w = v15[4]
        })
        local v26 = rt.copy(IDENTITY)

        for i = 0, 2 do
            v26[i + 1][1] = v25.columns[i + 1][1]
            v26[i + 1][2] = v25.columns[i + 1][2]
            v26[i + 1][3] = v25.columns[i + 1][3]
        end

        return compose_affine(p6, v26)
    end

    p5.blending = false

    return rt.copy(p6)
end

function t1.target_velocity(p12, p13, p14) -- line: 140
    local v27 = 1 / p14

    return {
        (p12[1] - p13[1]) * v27,
        (p12[2] - p13[2]) * v27,
        (p12[3] - p13[3]) * v27,
        (p12[4] - p13[4]) * v27
    }
end

return t1
