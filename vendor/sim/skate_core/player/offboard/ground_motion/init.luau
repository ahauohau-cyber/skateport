-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_motion/approach")
local v2 = import("skate_core/player/offboard/ground_motion/math")
local v3 = import("skate_core/player/offboard/ground_motion/publication")
local v4 = import("skate_core/player/offboard/ground_motion/support")
local v5 = import("skate_core/physics/skeleton_root")
local ZERO, DT, add, madd = v2.ZERO, v2.DT, v2.add, v2.madd
local cross, normalize, rotate = v2.cross, v2.normalize, v2.rotate

return {
    GroundMotionState = {},
    GroundMotionInput = {},
    update = function(p1, p2) -- update | line: 82
        -- upvalues: rt (copy), v1 (copy), v3 (copy), v4 (copy), v5 (copy), ZERO (copy), DT (copy), add (copy), madd (copy), cross (copy), normalize (copy), rotate (copy)
        local v6 = v4.update(p1, p2)
        local v7 = rt.copy(p1.frame_0[4])

        p1.frame_0[4] = rt.copy(ZERO)

        local v8, v9 = v1.calculate(p1, p2, v7, v6)
        local v12 = add(add(add(ZERO, v8), v9), p2.contact_displacement_384)
        local v13 = madd(p2.velocity_addition_528, DT, v12)
        local v14 = madd(p1.predicted_support_velocity_272, DT, v13)
        local v15 = (p1.angular_velocity_688 + p1.predicted_support_yaw_344) * DT
        local v16 = rt.copy(p1.frame_0[2])

        p1.frame_0 = {
            rotate(p1.frame_0[1], v16, v15),
            rotate(p1.frame_0[2], v16, v15),
            rotate(p1.frame_0[3], v16, v15),
            rotate(p1.frame_0[4], v16, v15)
        }
        p1.frame_0[1] = normalize(cross(p2.desired_up_544, p1.frame_0[3]))
        p1.frame_0[2] = rt.copy(p2.desired_up_544)
        p1.frame_0[3] = normalize(cross(p1.frame_0[1], p2.desired_up_544))
        p1.frame_0 = v5.orthonormalize(p1.frame_0)
        p1.frame_0[4] = add(v7, v14)
        v3.update(p1, v14)
    end
}
