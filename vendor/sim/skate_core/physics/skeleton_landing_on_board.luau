-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_root")
local v3 = import("skate_core/physics/board_motion_output")
local v4 = import("skate_core/animation/foot_ik")
local v5 = import("skate_core/point_graph")
local v6 = import("skate_core/player/wipeout_state/math")
local v7 = import("skate_core/trigonometry")
local compose_affine, transform_point = v1.compose_affine, v1.transform_point
local SkeletonRootFrames, orthonormalize, inverse_rigid = v2.SkeletonRootFrames, v2.orthonormalize, v2.inverse_rigid
local inverse_length_squared = v3.inverse_length_squared
local interpolate_affine = v4.interpolate_affine
local PointGraph = v5.PointGraph
local cross, dot, scale, sub = v6.cross, v6.dot, v6.scale, v6.sub
local t1 = {
    Vector = {},
    UP = { 0, 1, 0, 0 }
}
local UP = t1.UP

t1.EPSILON = 1.52587890625E-05

local EPSILON = t1.EPSILON

t1.Settings = {}

function t1.skate_root(p1, p2, p3, p4, p5) -- line: 45
    -- upvalues: rt (copy)
    local v8 = rt.copy(p2)

    v8[2] = p1[4][2] + p5.root_y_offset

    if bit32.band(p3, 1) ~= 0 then
        local v9 = p4 + p5.capsule_length + p5.capsule_radius

        v8[2] = rt.clamp(v9, v8[2], v8[2] + 0.3)
    end

    return {
        rt.copy(p1[3]),
        rt.copy(p1[1]),
        rt.copy(p1[2]),
        v8
    }
end

function t1.update_root(p6, p7, p8, p9, p10, p11) -- line: 57
    -- upvalues: rt (copy), v7 (copy), compose_affine (copy), transform_point (copy), SkeletonRootFrames (copy), orthonormalize (copy), inverse_length_squared (copy), interpolate_affine (copy), cross (copy), dot (copy), scale (copy), sub (copy), UP (copy), EPSILON (copy)
    p6.initialize_heading = true

    local v10

    if p10 ~= nil then
        v10 = 3.141592653589793 / p10

        if not p11 then
            v10 = -v10
        end
    else
        v10 = p9
    end

    local v11, v12 = v7.sin_cos(v10)
    local t2 = {
        { v12, 0, -v11, 0 },
        { 0, 1, 0, 0 },
        { v11, 0, v12, 0 },
        { 0, 0, 0, 0 }
    }
    local v13 = compose_affine(p6.animation_to_world, t2)

    if p10 ~= nil then
        v13 = orthonormalize(v13)
    end

    local v14 = cross(v13[2], UP)

    if dot(v14, v14) > EPSILON then
        local v15 = cross(UP, v13[3])
        local v16 = dot(v15, v15)

        if EPSILON < v16 then
            local v17 = scale(v15, inverse_length_squared(v16, 2))

            v13 = interpolate_affine(v13, {
                v17,
                rt.copy(UP),
                cross(v17, UP),
                rt.copy(v13[4])
            }, 0.1)
        end
    end

    local v18 = rt.copy(v13)

    v18[4] = { 0, 0, 0, 0 }
    v13[4] = sub(p7, transform_point(v18, p8))
    SkeletonRootFrames.reset_initial_alignment(p6, orthonormalize(v13))
end

function t1.pose_adjustment(p12, p13, p14, p15, p16, p17, p18, p19) -- line: 100
    -- upvalues: rt (copy), compose_affine (copy), transform_point (copy), inverse_rigid (copy), interpolate_affine (copy), PointGraph (copy)
    if not (p16 < 0) or bit32.band(p17, 2) ~= 0 then
        return nil
    end

    local v19 = compose_affine(p12, p13)
    local v20 = rt.copy(p12)

    v20[4] = { 0, 0, 0, 0 }

    local v21 = transform_point(v20, p15)

    v21[2] = 0

    if v19[4][2] > p14[4][2] then
        v21[2] = v19[4][2] - p14[4][2]
    end

    v19[4] = {
        p14[4][1] + v21[1],
        p14[4][2] + v21[2],
        p14[4][3] + v21[3],
        p14[4][4] + v21[4]
    }

    local v23 = compose_affine(interpolate_affine(p14, v19, PointGraph.evaluate(p19, p18)), inverse_rigid(p14))

    v23[4][2] = -v23[4][2]

    return v23
end

return t1
