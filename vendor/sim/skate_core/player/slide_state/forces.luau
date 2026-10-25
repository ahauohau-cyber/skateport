-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local PointGraph = import("skate_core/point_graph").PointGraph
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/trigonometry")
local t1 = {
    SlideSettings = {},
    SlideSurface = {},
    SlideInput = {}
}

function t1.angular_correction(p1, p2, p3) -- line: 39
    -- upvalues: rt (copy), PointGraph (copy), v2 (copy), t1 (copy)
    local v3 = PointGraph.evaluate(p1.input_remap, (math.abs(p3.slide)))
    local v4 = p3.elapsed - 0.5
    local v5 = t1.fsel(-v4, 0, v4)
    local v6 = t1.fsel(1 - v5, v5, 1)
    local v7 = PointGraph.evaluate(p1.remap_vs_speed, p3.surface_speed) * v6
    local v8 = t1.fsel(p3.slide, v3, -v3)
    local v9 = p3.slide * 3.1415927410125732 * (1 - v7) + v8 * 3.1415927410125732 * v7
    local v10 = t1.normalize(p3.velocity)
    local v11 = t1.normalize(t1.cross(p3.normal, v10))
    local v12 = t1.madd(v10, v2.cos(v9), t1.scale(v11, v2.sin(v9)))
    local v13 = t1.cross(p3.reference_forward, v12)

    if t1.dot(p3.reference_forward, v12) < 0 then
        if v13[2] < 0 then
            v13 = {
                -p3.normal[1],
                -p3.normal[2],
                -p3.normal[3],
                -p3.normal[4]
            }
        else
            v13 = rt.copy(p3.normal)
        end
    end

    local v14 = ((1 - p1.softest_wheel_spin) * p3.wheel_hardness + p1.softest_wheel_spin) * p2.yaw_strength
    local v15 = t1.scale(t1.madd(v13, v14, t1.scale(p3.angular_velocity, p2.yaw_damping)), p1.angular_force)

    return t1.scale(p3.normal, t1.dot(v15, p3.normal))
end

function t1.sliding_force(p4, p5, p6) -- line: 70
    -- upvalues: Vector3 (copy), PointGraph (copy), signed_angle (copy), t1 (copy)
    local v16 = t1.reject(p6.velocity, p6.normal)
    local v17 = t1.scale(p6.side, t1.dot(v16, p6.side))
    local v18 = PointGraph.evaluate(p5.speed_to_force, p6.absolute_speed)
    local v19 = if v18 > 0 then p6.wheel_hardness else 1
    local v20 = ((1 - p4.softest_wheel_force) * v19 + p4.softest_wheel_force) * v18
    local v21 = t1.normalize_safe(t1.cross(p6.normal, p6.velocity))
    local v22 = t1.reject(t1.scale(v17, v20), t1.normalize_safe(v21))
    local v23 = (if t1.dot(p6.velocity, p6.velocity) * t1.dot(p6.effective_forward, p6.effective_forward) > 1.52587890625E-05 then signed_angle(t1.xyz(t1.reject(p6.velocity, p6.normal)), t1.xyz(t1.reject(p6.effective_forward, p6.normal)), t1.xyz(p6.normal)) else 0) * 0.15915493667125702
    local v24 = v23 - math.floor(v23)
    local v25 = (v24 - (if v24 > 0.5 then 1 else 0)) * 6.2831854820251465 * 57.295780181884766
    local v26 = if v25 > 0 then 1 else -1
    local v27 = t1.scale(t1.scale(v21, PointGraph.evaluate(p4.force_vs_angle, (math.abs(v25)))), PointGraph.evaluate(p4.force_vs_speed, p6.surface_speed))
    local v28 = t1.madd(v27, v26, v22)
    local v29 = if not (t1.dot(v28, p6.velocity) < 0) then p4.force_y_offset else -p4.force_y_offset

    return {
        tag = 9,
        force_world = t1.xyz(v28),
        point_body = Vector3.new(0, v29, 0)
    }
end

function t1.dot(p7, p8) -- line: 118
    -- upvalues: v1 (copy)
    return v1.dot3(p7, p8)
end

function t1.scale(p9, p10) -- line: 122
    return {
        p9[1] * p10,
        p9[2] * p10,
        p9[3] * p10,
        p9[4] * p10
    }
end

function t1.madd(p11, p12, p13) -- line: 126
    return {
        p11[1] * p12 + p13[1],
        p11[2] * p12 + p13[2],
        p11[3] * p12 + p13[3],
        p11[4] * p12 + p13[4]
    }
end

function t1.reject(p14, p15) -- line: 135
    -- upvalues: t1 (copy)
    local v30 = t1.dot(p14, p15)

    return {
        p14[1] - p15[1] * v30,
        p14[2] - p15[2] * v30,
        p14[3] - p15[3] * v30,
        p14[4] - p15[4] * v30
    }
end

function t1.cross(p16, p17) -- line: 145
    return {
        -p16[3] * p17[2] + p16[2] * p17[3],
        -p16[1] * p17[3] + p16[3] * p17[1],
        -p16[2] * p17[1] + p16[1] * p17[2],
        -p16[4] * p17[4] + p16[4] * p17[4]
    }
end

function t1.normalize(p18) -- line: 154
    -- upvalues: inverse_length_squared (copy), t1 (copy)
    return t1.scale(p18, inverse_length_squared(t1.dot(p18, p18), 2))
end

function t1.normalize_safe(p19) -- line: 158
    -- upvalues: inverse_length_squared (copy), t1 (copy)
    local v31 = t1.dot(p19, p19)
    local v32 = inverse_length_squared(v31, 2)

    if (if v31 == 0 then 0 else v31 * v32) > 9.999999974752427E-07 then
        return t1.scale(p19, v32)
    end

    return table.create(4, 0)
end

function t1.fsel(p20, p21, p22) -- line: 169
    if p20 >= -0 then
        return p21
    end

    return p22
end

function t1.xyz(p23) -- line: 177
    -- upvalues: Vector3 (copy)
    return Vector3.new(p23[1], p23[2], p23[3])
end

return t1
