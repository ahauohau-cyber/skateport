-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/drive")
local line_mapping, normalize_safe = v1.line_mapping, v1.normalize_safe
local cross = import("skate_core/animation/foot_ik/math").cross
local v2 = import("skate_core/animation/foot_ik/two_bone")
local v3 = import("skate_core/physics/skeleton_animation_record")
local compose_affine, transform_point = v3.compose_affine, v3.transform_point
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {}

local function sub(p1, p2) -- line: 21
    return {
        p1[1] - p2[1],
        p1[2] - p2[2],
        p1[3] - p2[3],
        p1[4] - p2[4]
    }
end

function t1.solve(p3, p4, p5, p6) -- line: 25
    -- upvalues: line_mapping (copy), normalize_safe (copy), cross (copy), v2 (copy), compose_affine (copy), transform_point (copy), SkeletonBody (copy)
    local v4 = p4.parents[p5 + 1]

    if v4 == nil then
        return false
    end

    local v5 = p4.parents[v4 + 1]

    if v5 == nil then
        return false
    end

    local function point(p7) -- line: 34
        -- upvalues: p3 (copy), p4 (copy), transform_point (copy)
        return transform_point(p3.record.pose[p7 + 1], p4.inverse_part_frames[p7 + 1][4])
    end

    local v6 = transform_point(p3.record.pose[v5 + 1], p4.inverse_part_frames[v5 + 1][4])
    local v7 = transform_point(p3.record.pose[v4 + 1], p4.inverse_part_frames[v4 + 1][4])
    local v8 = transform_point(p3.record.pose[p5 + 1], p4.inverse_part_frames[p5 + 1][4])
    local t2 = {
        v8[1] + p6[1],
        v8[2] + p6[2],
        v8[3] + p6[3],
        v8[4] + p6[4]
    }
    local t3 = {
        0, 0, 0, 0
    }

    if v2.solve(v6, v7, v8, t3, t2, {
        minimum_degrees = 0,
        maximum_degrees = 180
    }, false, 1) ~= "Solved" then
        return false
    end

    local v9 = cross({
        v6[1] - v7[1],
        v6[2] - v7[2],
        v6[3] - v7[3],
        v6[4] - v7[4]
    }, {
        v8[1] - v7[1],
        v8[2] - v7[2],
        v8[3] - v7[3],
        v8[4] - v7[4]
    })
    local v10 = cross({
        v6[1] - t3[1],
        v6[2] - t3[2],
        v6[3] - t3[3],
        v6[4] - t3[4]
    }, {
        t2[1] - t3[1],
        t2[2] - t3[2],
        t2[3] - t3[3],
        t2[4] - t3[4]
    })
    local v11 = normalize_safe({
        v9[1] + v10[1],
        v9[2] + v10[2],
        v9[3] + v10[3],
        v9[4] + v10[4]
    })
    local v12 = line_mapping(v7, v8, v11, t3, t2, v11)

    if v12 == nil then
        return false
    end

    local v13 = line_mapping(v6, v7, v11, v6, t3, v11)

    if v13 == nil then
        return false
    end

    local v14 = compose_affine(v12, p3.record.pose[v4 + 1])
    local v15 = compose_affine(v13, p3.record.pose[v5 + 1])

    SkeletonBody.set_part_transform(p3, v4, v14)
    SkeletonBody.set_part_transform(p3, v5, v15)

    return true
end

t1.sub = sub

return t1
