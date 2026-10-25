-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/board_motion_output")
local v2 = import("skate_core/physics/native_arithmetic")
local v3 = import("skate_core/physics/skeleton_animation_record")
local inverse_length_squared = v1.inverse_length_squared
local dot3 = v2.dot3
local IDENTITY, compose_affine = v3.IDENTITY, v3.compose_affine
local t1 = {
    SkateboardOffset = {}
}

function t1.SkateboardOffset.default() -- line: 25
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        orientation_frames = 0,
        height_frames = 0,
        orientation_refreshed = false,
        height_refreshed = false,
        transform = rt.copy(IDENTITY)
    }
end

function t1.SkateboardOffset.refresh_transform(p1, p2) -- line: 38
    -- upvalues: rt (copy)
    p1.transform = rt.copy(p2)
    p1.orientation_frames = 15
    p1.height_frames = 15
    p1.orientation_refreshed = true
    p1.height_refreshed = true
end

function t1.SkateboardOffset.refresh_height(p3, p4, p5) -- line: 47
    p3.transform[4][2] = p4
    p3.height_frames = p5
    p3.height_refreshed = true
end

function t1.SkateboardOffset.update(p6, p7, p8) -- line: 56
    -- upvalues: rt (copy), inverse_length_squared (copy), dot3 (copy), IDENTITY (copy), compose_affine (copy)
    local v4 = false

    if p6.orientation_frames > 0 then
        if not p6.orientation_refreshed then
            local v5 = (p6.orientation_frames - 1) / p6.orientation_frames
            local v6 = v5 * v5
            local v7 = 1 - v6

            for i = 0, 2 do
                local v8 = IDENTITY[i + 1]
                local v9 = p6.transform[i + 1]

                v9[1] = v9[1] * v6 + v8[1] * v7
                v9[2] = v9[2] * v6 + v8[2] * v7
                v9[3] = v9[3] * v6 + v8[3] * v7
                v9[4] = v9[4] * v6 + v8[4] * v7
            end

            for _, v10 in { 0, 2, 3 } do
                p6.transform[4][v10 + 1] *= v6
            end

            local v11 = rt.copy(p6.transform)

            for i = 2, 0, -1 do
                local v12 = rt.copy(v11[i + 1])

                for j = 2, i + 1, -1 do
                    local v13 = dot3(p6.transform[j + 1], v11[i + 1])

                    v12[1] -= p6.transform[j + 1][1] * v13
                    v12[2] -= p6.transform[j + 1][2] * v13
                    v12[3] -= p6.transform[j + 1][3] * v13
                    v12[4] -= p6.transform[j + 1][4] * v13
                end

                local v14 = inverse_length_squared(dot3(v12, v12), 2)

                p6.transform[i + 1] = {
                    v12[1] * v14,
                    v12[2] * v14,
                    v12[3] * v14,
                    v12[4] * v14
                }
            end

            p6.orientation_frames -= 1
        end

        v4 = true
    end

    if p6.height_frames > 0 then
        if not p6.height_refreshed then
            local v15 = (p6.height_frames - 1) / p6.height_frames

            p6.transform[4][2] *= v15 * v15
            p6.height_frames -= 1
        end

        v4 = true
    end

    if v4 then
        rt.assign(p7, compose_affine(p6.transform, p7))

        for i = 1, #p8 do
            local v16 = p8[i]

            rt.assign(v16, compose_affine(p6.transform, v16))
        end
    end

    p6.orientation_refreshed = false
    p6.height_refreshed = false
end

return t1
