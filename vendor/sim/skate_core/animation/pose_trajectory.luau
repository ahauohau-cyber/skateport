-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local dot3 = require(sim.import)("skate_core/physics/native_arithmetic").dot3
local t1 = {
    LoopTransform = {}
}

function t1.LoopTransform.eq(p1, p2) -- line: 17
    if p1.rotation[1] == p2.rotation[1] and p1.rotation[2] == p2.rotation[2] and p1.rotation[3] == p2.rotation[3] and p1.rotation[4] == p2.rotation[4] and p1.translation[1] == p2.translation[1] and p1.translation[2] == p2.translation[2] then
        return p1.translation[3] == p2.translation[3]
    end

    return false
end

function t1.delta(p3, p4, p5) -- line: 34
    -- upvalues: rt (copy), t1 (copy)
    local v1 = if p5 == nil then {
        rotation = { 0, 0, 0, 1 },
        translation = { 0, 0, 0 }
    } else p5
    local t2 = {
        -p4.rotation[1],
        -p4.rotation[2],
        -p4.rotation[3],
        p4.rotation[4]
    }
    local v2 = t1.rotate(p3.rotation, v1.translation)
    local t3 = {
        v2[1] + p3.translation[1] - p4.translation[1],
        v2[2] + p3.translation[2] - p4.translation[2],
        v2[3] + p3.translation[3] - p4.translation[3]
    }
    local v3 = t1.rotate(t2, t3)
    local v4 = t1.multiply(t1.multiply(v1.rotation, p3.rotation), t2)

    return {
        scale = rt.copy(p3.scale),
        rotation = v4,
        translation = {
            v3[1],
            v3[2],
            v3[3],
            p3.translation[4]
        }
    }
end

function t1.delta_into(p6, p7, p8, p9, p10, p11, p12, p13, p14) -- line: 72
    local rotation, translation = p6.rotation, p6.translation
    local rotation2, translation2 = p7.rotation, p7.translation
    local v5 = rotation[1]
    local v6 = rotation[2]
    local v7 = rotation[3]
    local v8 = rotation[4]
    local v9 = -rotation2[1]
    local v10 = -rotation2[2]
    local v11 = -rotation2[3]
    local v12 = rotation2[4]
    local v13 = -v7 * p13 + v6 * p14
    local v14 = -v5 * p14 + v7 * p12
    local v15 = -v6 * p12 + v5 * p13
    local v16 = v8 * p12 + v13
    local v17 = v8 * p13 + v14
    local v18 = v8 * p14 + v15
    local v19 = -v7 * v17 + v6 * v18
    local v20 = -v5 * v18 + v7 * v16
    local v21 = -v6 * v16 + v5 * v17
    local v22 = 2 * v19 + p12 + translation[1] - translation2[1]
    local v23 = 2 * v20 + p13 + translation[2] - translation2[2]
    local v24 = 2 * v21 + p14 + translation[3] - translation2[3]
    local v25 = -v11 * v23 + v10 * v24
    local v26 = -v9 * v24 + v11 * v22
    local v27 = -v10 * v22 + v9 * v23
    local v28 = v12 * v22 + v25
    local v29 = v12 * v23 + v26
    local v30 = v12 * v24 + v27
    local v31 = -v11 * v29 + v10 * v30
    local v32 = -v9 * v30 + v11 * v28
    local v33 = -v10 * v28 + v9 * v29
    local v34 = 2 * v31 + v22
    local v35 = 2 * v32 + v23
    local v36 = 2 * v33 + v24
    local v37 = p8 * v8 + (v5 * p11 + (-p10 * v6 + p9 * v7))
    local v38 = p9 * v8 + (v6 * p11 + (-p8 * v7 + p10 * v5))
    local v39 = p10 * v8 + (v7 * p11 + (-p9 * v5 + p8 * v6))
    local v40 = p11 * v8 - (p8 * v5 + p9 * v6 + p10 * v7)
    local v41 = v37 * v12 + (v9 * v40 + (-v39 * v10 + v38 * v11))
    local v42 = v38 * v12 + (v10 * v40 + (-v37 * v11 + v39 * v9))
    local v43 = v39 * v12 + (v11 * v40 + (-v38 * v9 + v37 * v10))
    local v44 = v40 * v12 - (v37 * v9 + v38 * v10 + v39 * v11)

    rotation[1] = v41
    rotation[2] = v42
    rotation[3] = v43
    rotation[4] = v44
    translation[1] = v34
    translation[2] = v35
    translation[3] = v36

    return p6
end

function t1.cross(p15, p16) -- line: 122
    return {
        -p15[3] * p16[2] + p15[2] * p16[3],
        -p15[1] * p16[3] + p15[3] * p16[1],
        -p15[2] * p16[1] + p15[1] * p16[2]
    }
end

function t1.rotate(p17, p18) -- line: 131
    -- upvalues: t1 (copy)
    local t4 = {
        p18[1],
        p18[2],
        p18[3],
        0
    }
    local v45 = t1.cross(p17, t4)
    local t5 = {
        p17[4] * p18[1] + v45[1],
        p17[4] * p18[2] + v45[2],
        p17[4] * p18[3] + v45[3],
        0
    }
    local v46 = t1.cross(p17, t5)

    return {
        2 * v46[1] + p18[1],
        2 * v46[2] + p18[2],
        2 * v46[3] + p18[3]
    }
end

function t1.multiply(p19, p20) -- line: 149
    -- upvalues: dot3 (copy), t1 (copy)
    local v47 = t1.cross(p19, p20)

    return {
        p19[1] * p20[4] + (p20[1] * p19[4] + v47[1]),
        p19[2] * p20[4] + (p20[2] * p19[4] + v47[2]),
        p19[3] * p20[4] + (p20[3] * p19[4] + v47[3]),
        p19[4] * p20[4] - dot3(p19, p20)
    }
end

return t1
