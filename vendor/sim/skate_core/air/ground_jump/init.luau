-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/state")
local v2 = import("skate_core/trigonometry")
local v3 = import("skate_core/point_graph")
local v4 = import("skate_core/air/ground_jump/math")
local v5 = import("skate_core/air/ground_jump/types")
local AirMath = v1.AirMath
local acos = v2.acos
local PointGraph = v3.PointGraph
local UP, dot, add, sub = v4.UP, v4.dot, v4.add, v4.sub
local scale, madd, planar, maximum = v4.scale, v4.madd, v4.planar, v4.maximum
local clamp, vector_clamp, reciprocal, square_root = v4.clamp, v4.vector_clamp, v4.reciprocal, v4.square_root
local length, normalize, cross = v4.length, v4.normalize, v4.cross
local t1 = {
    GroundJump = v5.GroundJump,
    GroundJumpInput = v5.GroundJumpInput,
    GroundJumpMode = v5.GroundJumpMode,
    GroundJumpSettings = v5.GroundJumpSettings
}
local GroundJump = v5.GroundJump

function t1.calculate(p1, p2, p3) -- line: 47
    -- upvalues: rt (copy), AirMath (copy), acos (copy), PointGraph (copy), UP (copy), dot (copy), add (copy), sub (copy), scale (copy), madd (copy), planar (copy), maximum (copy), clamp (copy), vector_clamp (copy), reciprocal (copy), square_root (copy), length (copy), normalize (copy), cross (copy), GroundJump (copy)
    local v6 = bit32.band(p1.flags_2480, 4096) ~= 0

    if bit32.band(p1.flags_2468, 4194304) == 0 and not v6 then
        return GroundJump.default()
    end

    local v7 = rt.copy(p1.filtered_ground_normal)
    local v8 = PointGraph.evaluate(p3.y_scalar_vs_normal_y, v7[2])
    local v9 = planar(p1.current_velocity, v7)
    local v10 = planar(p1.prepared_velocity, v7)

    if dot(sub(v9, v10), sub(v9, v10)) > 7 then
        local v12 = acos((vector_clamp(dot(normalize(v9), normalize(v10)), 0, 1))) * reciprocal(3.1415927410125732)
        local v13 = length(v10) * PointGraph.evaluate(p3.speed_scalar_vs_angle, v12)

        v10 = rt.copy(AirMath.clamp_vector_within_max_length({}, v9, v13))
    end

    local flags_2488 = p1.flags_2488
    local v14

    if bit32.band(flags_2488, 268435456) == 0 then
        local v15 = if v6 then p3.hippy_minimum_height elseif bit32.band(p1.flags_2484, 2048) == 0 then p2.minimum_height_68 else p2.minimum_height_64
        local v16 = clamp(p1.surface_speed / p3.speed_response_max_speed, 0, 1)
        local v17 = PointGraph.evaluate(p3.minimum_height_vs_speed, v16) * (v15 - p3.absolute_minimum_height) + p3.absolute_minimum_height
        local v18 = PointGraph.evaluate(p3.maximum_height_vs_speed, v16) * ((if v6 then p3.hippy_maximum_height else p2.maximum_height) - p3.absolute_minimum_height) + p3.absolute_minimum_height
        local v22 = square_root(maximum(v17 * (1 - p1.jump_strength) + v18 * p1.jump_strength - dot(sub(p1.animation_com_position, p1.ground_reference_position), p1.reference_up), 0) * p1.gravity_y * -2)
        local v24 = clamp(acos(vector_clamp(v7[2], -1, 1)) * 0.6366197466850281, 0, 1)

        v14 = madd(v7, v22 * maximum(PointGraph.evaluate(p3.vertical_response, v24), p3.minimum_scalar), v10)
    else
        v14 = madd(p1.effective_forward, 2.3, v10)
        v14[2] += 1
    end

    local v26 = clamp((v8 - 1) * v14[2], 0, p3.maximum_y_bonus)

    v14[2] += v26

    local v27 = dot(v14, v7)
    local v28 = normalize(cross(UP, p1.forward))
    local v29 = -(p1.jump_controls[1] * p3.adjust_x_factor * v27)
    local v30 = p1.jump_controls[2] * p3.adjust_z_factor * v27

    return {
        scalar_16 = 0,
        active = true,
        velocity = add(v14, (madd(v28, v29, scale(cross(v28, UP), v30))))
    }
end

return t1
