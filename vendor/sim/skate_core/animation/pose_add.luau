-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/animation/pose_trajectory")
local multiply, rotate = v1.multiply, v1.rotate

return {
    add = function(p1, p2, p3) -- add | line: 17
        -- upvalues: multiply (copy), rotate (copy)
        local v2 = rotate(p2.rotation, {
            p1.translation[1],
            p1.translation[2],
            p1.translation[3]
        })

        return {
            scale = {
                p2.scale[1] * p1.scale[1],
                p2.scale[2] * p1.scale[2],
                p2.scale[3] * p1.scale[3],
                p2.scale[4] * p1.scale[4]
            },
            rotation = multiply(p2.rotation, p1.rotation),
            translation = {
                v2[1] + p2.translation[1],
                v2[2] + p2.translation[2],
                v2[3] + p2.translation[3],
                if p3 then p1.translation[4] else p2.translation[4]
            }
        }
    end,
    add_into = function(p4, p5, p6, p7) -- add_into | line: 45
        local rotation = p5.rotation
        local v7 = rotation[1]
        local v8 = rotation[2]
        local v9 = rotation[3]
        local v10 = rotation[4]
        local translation = p4.translation
        local v11 = translation[1]
        local v12 = translation[2]
        local v13 = translation[3]
        local v14 = -v9 * v12 + v8 * v13
        local v15 = -v7 * v13 + v9 * v11
        local v16 = -v8 * v11 + v7 * v12
        local v17 = v10 * v11 + v14
        local v18 = v10 * v12 + v15
        local v19 = v10 * v13 + v16
        local v20 = -v9 * v18 + v8 * v19
        local v21 = -v7 * v19 + v9 * v17
        local v22 = -v8 * v17 + v7 * v18
        local v23 = 2 * v20 + v11
        local v24 = 2 * v21 + v12
        local v25 = 2 * v22 + v13
        local scale = p4.scale
        local scale2 = p5.scale
        local v26 = scale2[1] * scale[1]
        local v27 = scale2[2] * scale[2]
        local v28 = scale2[3] * scale[3]
        local v29 = scale2[4] * scale[4]
        local rotation2 = p4.rotation
        local v30 = rotation2[1]
        local v31 = rotation2[2]
        local v32 = rotation2[3]
        local v33 = rotation2[4]
        local v34 = -v9 * v31 + v8 * v32
        local v35 = -v7 * v32 + v9 * v30
        local v36 = -v8 * v30 + v7 * v31
        local v37 = v7 * v33 + (v30 * v10 + v34)
        local v38 = v8 * v33 + (v31 * v10 + v35)
        local v39 = v9 * v33 + (v32 * v10 + v36)
        local v40 = v10 * v33 - (v7 * v30 + v8 * v31 + v9 * v32)
        local translation2 = p5.translation
        local v41 = v23 + translation2[1]
        local v42 = v24 + translation2[2]
        local v43 = v25 + translation2[3]
        local v44 = if p6 then translation[4] else translation2[4]
        local scale3, rotation3, translation3 = p7.scale, p7.rotation, p7.translation

        scale3[1] = v26
        scale3[2] = v27
        scale3[3] = v28
        scale3[4] = v29
        rotation3[1] = v37
        rotation3[2] = v38
        rotation3[3] = v39
        rotation3[4] = v40
        translation3[1] = v41
        translation3[2] = v42
        translation3[3] = v43
        translation3[4] = v44
    end
}
