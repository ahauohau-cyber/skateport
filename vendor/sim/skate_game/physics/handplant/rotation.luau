-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/transforms")
local v2 = import("skate_core/physics/drive_frames")
local v3 = import("skate_core/physics/skeleton_animation_record")
local v4 = import("skate_core/trigonometry")
local v5 = import("skate_game/physics/footplant/math")
local inverse_rigid = v1.inverse_rigid
local retail_quaternion_from_basis = v2.retail_quaternion_from_basis
local compose_affine = v3.compose_affine
local dot, cross, sub, scale = v5.dot, v5.cross, v5.sub, v5.scale
local madd, normalize = v5.madd, v5.normalize

return {
    frame = function(p1, p2) -- frame | line: 28
        -- upvalues: dot (copy), cross (copy), normalize (copy)
        local v6 = dot(p1, p2)
        local v7 = p1

        if math.abs(v6) > 0.9999899864196777 then
            v7 = {
                1, 0, 0, 0
            }

            if math.abs((dot(v7, p2))) > 0.9999899864196777 then
                v7 = { 0, 0, 1, 0 }
            end
        end

        local v9 = normalize(cross(p2, v7))
        local v10 = normalize(cross(v9, p2))

        return {
            v9,
            normalize(cross(v10, v9)),
            v10,
            { 0, 0, 0, 0 }
        }
    end,
    blend = function(p3, p4, p5) -- blend | line: 42
        -- upvalues: rt (copy), v4 (copy), inverse_rigid (copy), retail_quaternion_from_basis (copy), compose_affine (copy), dot (copy), cross (copy), sub (copy), scale (copy), madd (copy), normalize (copy)
        if p5 >= 1 then
            return rt.copy(p4)
        end

        if p5 <= 0 then
            return rt.copy(p3)
        end

        local v11 = compose_affine(p4, inverse_rigid(p3))
        local v12 = retail_quaternion_from_basis({
            columns = {
                rt.slice(v11[1], 0, 3),
                rt.slice(v11[2], 0, 3),
                rt.slice(v11[3], 0, 3)
            }
        })
        local v13 = if v12.w < 0 then -1 else 1
        local v14 = 2 * v4.acos(rt.clamp(v12.w * v13, -1, 1))
        local v15 = rt.copy(p3)

        if v14 < 0.03490658476948738 then
            for i = 0, 2 do
                v15[i + 1] = normalize(madd(sub(p4[i + 1], p3[i + 1]), p5, p3[i + 1]))
            end
        else
            local v16 = normalize({
                v12.x * v13,
                v12.y * v13,
                v12.z * v13,
                0
            })
            local v17, v18 = v4.sin_cos(v14 * p5)

            for i = 0, 2 do
                v15[i + 1] = madd(v16, dot(v16, p3[i + 1]) * (1 - v18), madd(cross(v16, p3[i + 1]), v17, scale(p3[i + 1], v18)))
            end
        end

        v15[4] = madd(sub(p4[4], p3[4]), p5, p3[4])

        return v15
    end
}
