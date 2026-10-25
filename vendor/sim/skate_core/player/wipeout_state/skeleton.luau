-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local inverse_rigid = import("skate_core/physics/skeleton_root").inverse_rigid
local t1 = {
    DT = 0.01666666753590107
}
local DT = t1.DT

function t1.update_roots(p1, p2, p3, p4, p5, p6, p7) -- line: 20
    -- upvalues: rt (copy), compose_affine (copy), inverse_rigid (copy), DT (copy)
    local v1 = inverse_rigid(p2)
    local v2 = rt.copy(p3)

    v2[4] = {
        p4[1] * DT + p3[4][1],
        p4[2] * DT + p3[4][2],
        p4[3] * DT + p3[4][3],
        p4[4] * DT + p3[4][4]
    }

    local v3 = compose_affine(v2, v1)
    local v4 = p7 + DT

    if -v4 >= 0 then
        v4 = 0
    end

    if not (1 - v4 >= 0) then
        v4 = 1
    end

    local v5 = rt.copy(p5)

    v5[2] += -0.800000011920929

    local v6 = v3[4]
    local v7 = table.create(4)

    for i = 0, 3 do
        local v8 = p6[i + 1] * DT + v6[i + 1]

        v7[i + 1] = v5[i + 1] * v4 + v8 * (1 - v4)
    end

    v3[4] = v7
    p1.animation_to_world = v3
    p1.world_to_animation = inverse_rigid(v3)
end

return t1
