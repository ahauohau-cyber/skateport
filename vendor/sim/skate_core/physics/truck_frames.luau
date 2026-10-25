-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/drive_frames")
local v2 = import("skate_core/trigonometry")
local RetailAffineTransform = v1.RetailAffineTransform
local IDENTITY = RetailAffineTransform.IDENTITY
local t1 = {}

function t1.steering_drive_frames(p1, p2) -- line: 23
    -- upvalues: v1 (copy), t1 (copy), IDENTITY (copy)
    local v3 = t1.rotate_truck(p1[1], -p2[1])
    local v4 = t1.rotate_truck(p1[2], p2[2])

    return {
        v1.set_drive_frames_2(IDENTITY, v4),
        (v1.set_drive_frames_2(IDENTITY, v3))
    }
end

function t1.steering_drive_frames_reference(p3, p4) -- line: 34
    -- upvalues: rt (copy), v1 (copy), RetailAffineTransform (copy), t1 (copy)
    local v5 = t1.steering_truck_transforms_reference(p3, p4)
    local v6 = v5[1]
    local t2 = {
        v5[2],
        v6
    }
    local v7 = table.create(2)

    v7[1] = v1.set_drive_frames_2_reference(rt.copy(RetailAffineTransform.IDENTITY), t2[1])
    v7[2] = v1.set_drive_frames_2_reference(rt.copy(RetailAffineTransform.IDENTITY), t2[2])

    return v7
end

function t1.steering_truck_transforms(p5, p6) -- line: 47
    -- upvalues: t1 (copy)
    return {
        t1.rotate_truck(p5[1], -p6[1]),
        t1.rotate_truck(p5[2], p6[2])
    }
end

function t1.steering_truck_transforms_reference(p7, p8) -- line: 54
    -- upvalues: t1 (copy)
    return {
        t1.rotate_truck_reference(p7[1], -p8[1]),
        t1.rotate_truck_reference(p7[2], p8[2])
    }
end

function t1.rotate_truck(p9, p10) -- line: 66
    -- upvalues: v2 (copy)
    local v8, v9 = v2.sin_cos(p10)
    local v10 = -v8
    local columns = p9.basis.columns
    local v11 = columns[1]
    local v12 = columns[2]
    local v13 = columns[3]
    local v14 = v11[1]
    local v15 = v11[2]
    local v16 = v11[3]
    local v17 = v12[1]
    local v18 = v12[2]
    local v19 = v12[3]
    local v20 = v13[1]
    local v21 = v13[2]
    local v22 = v13[3]

    return {
        basis = {
            columns = {
                {
                    0 * v20 + (0 * v17 + 1 * v14),
                    0 * v21 + (0 * v18 + 1 * v15),
                    0 * v22 + (0 * v19 + 1 * v16)
                },
                {
                    v8 * v20 + (v9 * v17 + 0 * v14),
                    v8 * v21 + (v9 * v18 + 0 * v15),
                    v8 * v22 + (v9 * v19 + 0 * v16)
                },
                {
                    v9 * v20 + (v10 * v17 + 0 * v14),
                    v9 * v21 + (v10 * v18 + 0 * v15),
                    v9 * v22 + (v10 * v19 + 0 * v16)
                }
            }
        },
        translation = table.clone(p9.translation)
    }
end

function t1.rotate_truck_reference(p11, p12) -- line: 102
    -- upvalues: rt (copy), v2 (copy)
    local v23, v24 = v2.sin_cos(p12)
    local t3 = {
        { 1, 0, 0 },
        { 0, v24, v23 },
        { 0, -v23, v24 }
    }
    local v25 = table.create(3)

    for i = 1, 3 do
        local v26 = t3[i]

        v25[i] = rt.from_fn(3, function(p13) -- line: 108
            -- upvalues: p11 (copy), v26 (copy)
            local v27 = v26[1] * p11.basis.columns[1][p13 + 1]
            local v28 = v26[2] * p11.basis.columns[2][p13 + 1] + v27

            return v26[3] * p11.basis.columns[3][p13 + 1] + v28
        end)
    end

    return {
        basis = {
            columns = v25
        },
        translation = rt.copy(p11.translation)
    }
end

return t1
