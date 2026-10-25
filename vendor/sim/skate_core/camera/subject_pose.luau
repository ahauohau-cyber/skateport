-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/camera/vector_tracker")
local t1 = {
    SubjectPoseInputs = {},
    PublishedSubjectPose = {},
    SubjectPosePublisher = {}
}

function t1.SubjectPosePublisher.new() -- line: 25
    return {
        previous_physical_transform = {
            { 1, 0, 0, 0 },
            { 0, 1, 0, 0 },
            { 0, 0, 1, 0 },
            { 0, 0, 0, 0 }
        }
    }
end

function t1.SubjectPosePublisher.publish(p1, p2) -- line: 38
    -- upvalues: rt (copy), v1 (copy)
    local v2 = if p2.wiping_out or p2.state_flag_75 then rt.copy(p2.skeleton_root) else rt.copy(p1.previous_physical_transform)

    p1.previous_physical_transform = rt.copy(p2.physical_transform)

    local v3 = rt.copy(p2.reckoned_center_of_mass)
    local t2 = {}

    t2[1] = v3[1] - p2.center_of_mass[1]
    t2[2] = v3[2] - p2.center_of_mass[2]
    t2[3] = v3[3] - p2.center_of_mass[3]
    t2[4] = v3[4] - p2.center_of_mass[4]

    local v4 = v1.length(t2)

    if v4 > 0.14499999582767487 then
        local v5 = v1.refined_reciprocal(v4)

        v3 = {}
        v3[1] = v5 * t2[1] * 0.14499999582767487 + p2.center_of_mass[1]
        v3[2] = v5 * t2[2] * 0.14499999582767487 + p2.center_of_mass[2]
        v3[3] = v5 * t2[3] * 0.14499999582767487 + p2.center_of_mass[3]
        v3[4] = v5 * t2[4] * 0.14499999582767487 + p2.center_of_mass[4]
    end

    return {
        transform = v2,
        damped_center_of_mass = v3
    }
end

function t1.SubjectPosePublisher.publish_into(p3, p4, p5) -- line: 72
    -- upvalues: v1 (copy)
    local previous_physical_transform = p3.previous_physical_transform
    local v6 = if p4.wiping_out or p4.state_flag_75 then p4.skeleton_root else previous_physical_transform

    for i = 1, 4 do
        local v7 = p5[i]
        local v8 = v6[i]
        local v9 = v8[1]
        local v10 = v8[2]
        local v11 = v8[3]
        local v12 = v8[4]

        v7[1] = v9
        v7[2] = v10
        v7[3] = v11
        v7[4] = v12
    end

    local physical_transform = p4.physical_transform

    for i = 1, 4 do
        local v13 = previous_physical_transform[i]
        local v14 = physical_transform[i]
        local v15 = v14[1]
        local v16 = v14[2]
        local v17 = v14[3]
        local v18 = v14[4]

        v13[1] = v15
        v13[2] = v16
        v13[3] = v17
        v13[4] = v18
    end

    local reckoned_center_of_mass, center_of_mass = p4.reckoned_center_of_mass, p4.center_of_mass
    local v19 = reckoned_center_of_mass[1]
    local v20 = reckoned_center_of_mass[2]
    local v21 = reckoned_center_of_mass[3]
    local v22 = reckoned_center_of_mass[4]
    local v23 = center_of_mass[1]
    local v24 = center_of_mass[2]
    local v25 = center_of_mass[3]
    local v26 = center_of_mass[4]
    local v27 = v19 - v23
    local v28 = v20 - v24
    local v29 = v21 - v25
    local v30 = v22 - v26
    local v31 = v1.length3(v27, v28, v29)

    if v31 > 0.14499999582767487 then
        local v32 = v1.refined_reciprocal(v31)

        v19 = v32 * v27 * 0.14499999582767487 + v23
        v20 = v32 * v28 * 0.14499999582767487 + v24
        v21 = v32 * v29 * 0.14499999582767487 + v25
        v22 = v32 * v30 * 0.14499999582767487 + v26
    end

    return v19, v20, v21, v22
end

return t1
