-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/math")
local interpolate, interpolate_affine = v1.interpolate, v1.interpolate_affine
local v2 = import("skate_core/physics/skeleton_animation_record")
local compose_affine, transform_point = v2.compose_affine, v2.transform_point
local orthonormalize = import("skate_core/physics/skeleton_root").orthonormalize
local t1 = {}

local function board_blend(p1, p2, p3) -- line: 29
    -- upvalues: interpolate (copy), orthonormalize (copy)
    local v3 = p1[4]
    local v4 = p2[4]
    local t2 = {
        v4[1] * p3 + v3[1] * (1 - p3),
        v4[2] * p3 + v3[2] * (1 - p3),
        v4[3] * p3 + v3[3] * (1 - p3),
        v4[4] * p3 + v3[4] * (1 - p3)
    }
    local v5 = orthonormalize(p1)
    local v6 = orthonormalize(p2)

    v5[4] = { 0, 0, 0, 0 }
    v6[4] = { 0, 0, 0, 0 }

    local v7 = interpolate(v5, v6, p3)

    v7[4] = t2

    return v7
end

local function v8(p4, p5, p6) -- line: 49
    -- upvalues: rt (copy), interpolate (copy), orthonormalize (copy)
    local v9 = table.create(4)

    v9[1] = p5[4][1] * p6 + p4[4][1] * (1 - p6)
    v9[2] = p5[4][2] * p6 + p4[4][2] * (1 - p6)
    v9[3] = p5[4][3] * p6 + p4[4][3] * (1 - p6)
    v9[4] = p5[4][4] * p6 + p4[4][4] * (1 - p6)

    local v10 = orthonormalize(rt.copy(p4))
    local v11 = orthonormalize(rt.copy(p5))

    v10[4] = { 0, 0, 0, 0 }
    v11[4] = { 0, 0, 0, 0 }

    local v12 = interpolate(v10, v11, p6)

    v12[4] = v9

    return v12
end

function t1.update(p7, p8, p9, p10, p11, p12) -- line: 65
    -- upvalues: rt (copy), interpolate_affine (copy), compose_affine (copy), transform_point (copy), board_blend (copy)
    local v13 = rt.copy(p10)

    v13[4] = transform_point(p11, p12[4])

    for i = 0, 3 do
        local v14 = p7[i + 1]
        local v15 = p8[i + 1]
        local v16 = p9[i + 1]

        if v14.mode ~= "Disabled" then
            if v14.board_blend > 0 then
                local v17 = compose_affine(v13, v15.board)

                v15.world = board_blend(v15.world, v17, v14.board_blend)

                if v16.parent_part ~= nil then
                    local v18 = compose_affine(v13, v15.parent_board)

                    v15.parent_world = board_blend(v15.parent_world, v18, v14.board_blend)
                end
            end

            if v14.mode == "External" or v14.mode == "Local" then
                if v14.external_blend >= 1 then
                    v15.world = rt.copy(v15.external_world)
                    v15.parent_world = rt.copy(v15.external_parent_world)
                else
                    v15.world = interpolate_affine(v15.world, v15.external_world, v14.external_blend)
                    v15.parent_world = interpolate_affine(v15.parent_world, v15.external_parent_world, v14.external_blend)
                end
            end
        end
    end
end

t1.board_blend = board_blend
t1.board_blend_reference = v8

return t1
