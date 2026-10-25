-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_body/collision_vector")
local dot, sub, length, transform = v1.dot, v1.sub, v1.length, v1.transform

local function skeleton_body() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {
    SkeletonPoseErrors = {}
}

function t1.SkeletonPoseErrors.default() -- line: 30
    -- upvalues: rt (copy)
    return {
        parts = rt.filled(24, table.create(4, 0)),
        extra = rt.filled(2, table.create(4, 0)),
        targets = rt.filled(3, table.create(4, 0))
    }
end

t1.SkeletonNormalError = {}

function t1.SkeletonPoseErrors.reset_history(p1) -- line: 45
    -- upvalues: rt (copy)
    p1.targets = rt.filled(3, table.create(4, 0))
end

function t1.SkeletonPoseErrors.set_targets(p2, p3) -- line: 49
    -- upvalues: rt (copy)
    p2.targets = {
        rt.copy(p3.com),
        rt.copy(p3.lifted_com),
        rt.copy(p3.following_com)
    }
end

function t1.SkeletonPoseErrors.update(p4, p5, p6, p7) -- line: 54
    -- upvalues: sub (copy), transform (copy)
    p4.parts[1] = table.create(4, 0)

    for i = 1, 23 do
        p4.parts[i + 1] = sub(p5.pose[i + 1][4], transform(p6, p7[i + 1][4]))
    end

    p4.extra[1] = sub(p5.pose[25][4], p4.targets[2])
    p4.extra[2] = sub(p5.pose[26][4], p4.targets[3])
end

local t2 = {
    23, 17, 18, 16, 21, 22, 20, 1
}

function t1.SkeletonPoseErrors.normal_response(p8, p9, p10) -- line: 68
    -- upvalues: rt (copy), import (copy), dot (copy), t1 (copy), t2 (copy)
    local SkeletonCollisionFeedback = import("skate_core/physics/skeleton_body").SkeletonCollisionFeedback
    local v2 = table.create(8)

    for i = 1, 8 do
        v2[i] = rt.copy(p8.parts[t2[i] + 1])
    end

    local v3 = table.create(8)

    for i = 1, 8 do
        v3[i] = SkeletonCollisionFeedback.filter_error(p9, v2[i], p10)
    end

    local v4 = v3[1]

    for i = 2, 8 do
        local v5 = v3[i]

        if dot(v5, v5) > dot(v4, v4) then
            v4 = v5
        end
    end

    return {
        impulse = rt.copy(v4),
        extra = rt.filled(2, table.create(4, 0)),
        maximum_error = t1.SkeletonPoseErrors.maximum_error(p8)
    }
end

function t1.SkeletonPoseErrors.partial_response(p11) -- line: 94
    -- upvalues: rt (copy), t1 (copy)
    return {
        impulse = rt.copy(p11.extra[1]),
        extra = rt.copy(p11.extra),
        maximum_error = t1.SkeletonPoseErrors.maximum_error(p11)
    }
end

function t1.SkeletonPoseErrors.maximum_error(p12) -- line: 102
    -- upvalues: rt (copy), dot (copy), length (copy), t2 (copy)
    local v6 = table.create(8)

    for i = 1, 8 do
        v6[i] = rt.copy(p12.parts[t2[i] + 1])
    end

    local v7 = if dot(v6[1], v6[1]) > dot(v6[2], v6[2]) then v6[1] else v6[2]

    for i = 3, 8 do
        local v8 = v6[i]

        if dot(v8, v8) > dot(v7, v7) then
            v7 = v8
        end
    end

    return length(v7)
end

return t1
