-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_launch/math")
local PointGraph = import("skate_core/point_graph").PointGraph
local projected_angle = import("skate_core/player/wipeout_state/orientation").projected_angle
local v2 = import("skate_core/player/offboard/contact_correction")
local clamp, dot, madd, normalize = v1.clamp, v1.dot, v1.madd, v1.normalize
local normalize_or, scale, sub, wrap_angle = v1.normalize_or, v1.scale, v1.sub, v1.wrap_angle
local ZERO, RADIANS, select, flatten = v1.ZERO, v1.RADIANS, v1.select, v1.flatten
local magnitude, reject, limit_angle, rotate = v1.magnitude, v1.reject, v1.limit_angle, v1.rotate

return {
    calculate = function(p1, p2, p3, p4, p5) -- calculate | line: 25
        -- upvalues: rt (copy), PointGraph (copy), projected_angle (copy), v2 (copy), clamp (copy), dot (copy), madd (copy), normalize (copy), normalize_or (copy), scale (copy), sub (copy), wrap_angle (copy), ZERO (copy), RADIANS (copy), select (copy), flatten (copy), magnitude (copy), reject (copy), limit_angle (copy), rotate (copy)
        local v3 = rt.copy(p1.frame_output.frame[2])
        local v5 = normalize_or(madd(v3, 1, scale(p1.motion.frame_0[2], 0)), v3)
        local v6 = sub(p4.velocity_912, scale(v5, dot(v5, p4.velocity_912)))
        local v7 = dot(v6, p5)
        local v9 = madd(p5, select(-v7, 0, v7) - v7, v6)
        local v10 = rt.copy(v9)
        local v11 = dot(v9, v9)

        if bit32.band(p4.flags_2472, 268435456) == 0 then
            local t2 = {
                p4.raw_x_2692,
                0,
                p4.raw_z_2688,
                0
            }

            if v11 >= 1 then
                if p1.contact.active and dot(t2, t2) > 0.809999942779541 then
                    local v12 = wrap_angle(projected_angle(t2, v9, v5))

                    if v12 < 45 * RADIANS then
                        v10 = scale(normalize(reject(t2, v5)), magnitude(v11))
                    elseif v12 < 90 * RADIANS then
                        v10 = scale(limit_angle(normalize(reject(t2, v5)), v9, 45), magnitude(v11))
                    end
                end
            else
                v9 = v2.clamp_length(madd(t2, 1, v9), 1)
                v10 = rt.copy(v9)
            end
        end

        local v14 = magnitude(p3.jump_height * 19.600000381469727)
        local v15 = v5[2] * v14
        local v16 = select(-v15, 0, v15)
        local v17 = normalize_or(flatten(v10), ZERO)
        local v18 = PointGraph.evaluate(p2, p1.motion.speed_704) * p1.intent.steering * RADIANS
        local angular_velocity_688 = p1.motion.angular_velocity_688
        local v19 = clamp(clamp(v18, angular_velocity_688 - 1.7453292608261108, angular_velocity_688 + 1.7453292608261108) * 0.4, -0.2617993950843811, 0.2617993950843811)

        return rotate(madd(v9, p3.jump_speed_scalar, scale(v5, v16)), v5, v19), v17
    end
}
