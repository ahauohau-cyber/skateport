-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local t1 = {
    AnchorInputs = {},
    AnchorState = {},
    Anchors = {}
}

function t1.Anchors.new() -- line: 36
    -- upvalues: rt (copy)
    return {
        entries = rt.filled(7, {
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        }),
        grind_position = { 0, 0, 0, 0 }
    }
end

function t1.Anchors.update_reference(p1, p2) -- line: 47
    -- upvalues: rt (copy), v1 (copy)
    local v2 = v1.refined_reciprocal(0.01666666753590107)
    local t2 = {}

    t2[1] = p2.board_offset_direction[1] * 0.30000001192092896 + p2.board_position[1]
    t2[2] = p2.board_offset_direction[2] * 0.30000001192092896 + p2.board_position[2]
    t2[3] = p2.board_offset_direction[3] * 0.30000001192092896 + p2.board_position[3]
    t2[4] = p2.board_offset_direction[4] * 0.30000001192092896 + p2.board_position[4]

    local t3 = {}

    t3[1] = p2.center_of_mass[1] - p2.skeleton_root_up[1] * 0.33000001311302185
    t3[2] = p2.center_of_mass[2] - p2.skeleton_root_up[2] * 0.33000001311302185
    t3[3] = p2.center_of_mass[3] - p2.skeleton_root_up[3] * 0.33000001311302185
    t3[4] = p2.center_of_mass[4] - p2.skeleton_root_up[4] * 0.33000001311302185

    if p2.reset or p2.grinding then
        local v3 = if p2.reset then p2.board_position else p2.grind_point
        local t4 = {}

        t4[1] = p2.board_offset_direction[1] * 0.5 + v3[1]
        t4[2] = p2.board_offset_direction[2] * 0.5 + v3[2]
        t4[3] = p2.board_offset_direction[3] * 0.5 + v3[3]
        t4[4] = p2.board_offset_direction[4] * 0.5 + v3[4]
        p1.grind_position = t4
    else
        local t5 = {}

        t5[1] = p2.board_velocity[1] * 0.01666666753590107 + p1.grind_position[1]
        t5[2] = p2.board_velocity[2] * 0.01666666753590107 + p1.grind_position[2]
        t5[3] = p2.board_velocity[3] * 0.01666666753590107 + p1.grind_position[3]
        t5[4] = p2.board_velocity[4] * 0.01666666753590107 + p1.grind_position[4]
        p1.grind_position = t5
    end

    local t6 = {
        t2,
        p2.center_of_mass,
        t3,
        p1.grind_position,
        { 0, 0, 0, 0 },
        p2.damped_center_of_mass,
        { 0, 0, 0, 0 }
    }

    for i = 0, 6 do
        local v4 = p1.entries[i + 1]
        local v5 = t6[i + 1]
        local v6 = rt.copy(v4.position)

        v4.position = rt.copy(v5)

        if p2.reset then
            v4.velocity = { 0, 0, 0, 0 }
        else
            local t7 = {}

            t7[1] = v2 * (v5[1] - v6[1])
            t7[2] = v2 * (v5[2] - v6[2])
            t7[3] = v2 * (v5[3] - v6[3])
            t7[4] = v2 * (v5[4] - v6[4])
            v4.velocity = t7
        end

        if i ~= 0 and i ~= 2 and i ~= 3 then
            v4.acceleration = { 0, 0, 0, 0 }
        else
            v4.acceleration = rt.copy(p2.board_acceleration)
        end
    end
end

local PERF = import("skate_core/camera/tracker").PERF
local v7 = v1.refined_reciprocal(0.01666666753590107)

local function publish(p3, p4, p5, p6, p7, p8, p9) -- line: 134
    -- upvalues: v7 (copy)
    local position, velocity, acceleration = p3.position, p3.velocity, p3.acceleration
    local v8 = position[1]
    local v9 = position[2]
    local v10 = position[3]
    local v11 = position[4]

    position[1] = p4
    position[2] = p5
    position[3] = p6
    position[4] = p7

    if p8 then
        velocity[1] = 0
        velocity[2] = 0
        velocity[3] = 0
        velocity[4] = 0
    else
        velocity[1] = v7 * (p4 - v8)
        velocity[2] = v7 * (p5 - v9)
        velocity[3] = v7 * (p6 - v10)
        velocity[4] = v7 * (p7 - v11)
    end

    if p9 ~= nil then
        local v12 = p9[1]
        local v13 = p9[2]
        local v14 = p9[3]
        local v15 = p9[4]

        acceleration[1] = v12
        acceleration[2] = v13
        acceleration[3] = v14
        acceleration[4] = v15
    else
        acceleration[1] = 0
        acceleration[2] = 0
        acceleration[3] = 0
        acceleration[4] = 0
    end
end

function t1.Anchors.update_damped(p10, p11, p12, p13, p14, p15) -- line: 153
    -- upvalues: v7 (copy), publish (copy)
    local board_offset_direction, board_position, center_of_mass, skeleton_root_up = p11.board_offset_direction, p11.board_position, p11.center_of_mass, p11.skeleton_root_up
    local board_acceleration, reset = p11.board_acceleration, p11.reset
    local v16 = board_offset_direction[1]
    local v17 = board_offset_direction[2]
    local v18 = board_offset_direction[3]
    local v19 = board_offset_direction[4]
    local v20 = board_position[1]
    local v21 = board_position[2]
    local v22 = board_position[3]
    local v23 = board_position[4]
    local v24 = center_of_mass[1]
    local v25 = center_of_mass[2]
    local v26 = center_of_mass[3]
    local v27 = center_of_mass[4]
    local grind_position = p10.grind_position
    local v28, v29

    if reset then
        v28 = board_position
        v29 = false
    elseif p11.grinding then
        v28 = p11.grind_point
        v29 = false
    else
        v29 = true
    end

    local v30, v31, v32, v33

    if v29 then
        local board_velocity = p11.board_velocity

        v30 = board_velocity[1] * 0.01666666753590107 + grind_position[1]
        v31 = board_velocity[2] * 0.01666666753590107 + grind_position[2]
        v32 = board_velocity[3] * 0.01666666753590107 + grind_position[3]
        v33 = board_velocity[4] * 0.01666666753590107 + grind_position[4]
    else
        v30 = v16 * 0.5 + v28[1]
        v31 = v17 * 0.5 + v28[2]
        v32 = v18 * 0.5 + v28[3]
        v33 = v19 * 0.5 + v28[4]
    end

    grind_position[1] = v30
    grind_position[2] = v31
    grind_position[3] = v32
    grind_position[4] = v33

    local entries = p10.entries

    publish(entries[1], v16 * 0.30000001192092896 + v20, v17 * 0.30000001192092896 + v21, v18 * 0.30000001192092896 + v22, v19 * 0.30000001192092896 + v23, reset, board_acceleration)

    local v34 = entries[2]
    local position, velocity, acceleration = v34.position, v34.velocity, v34.acceleration
    local v35 = position[1]
    local v36 = position[2]
    local v37 = position[3]
    local v38 = position[4]

    position[1] = v24
    position[2] = v25
    position[3] = v26
    position[4] = v27

    if reset then
        velocity[1] = 0
        velocity[2] = 0
        velocity[3] = 0
        velocity[4] = 0
    else
        velocity[1] = v7 * (v24 - v35)
        velocity[2] = v7 * (v25 - v36)
        velocity[3] = v7 * (v26 - v37)
        velocity[4] = v7 * (v27 - v38)
    end

    acceleration[1] = 0
    acceleration[2] = 0
    acceleration[3] = 0
    acceleration[4] = 0
    publish(entries[3], v24 - skeleton_root_up[1] * 0.33000001311302185, v25 - skeleton_root_up[2] * 0.33000001311302185, v26 - skeleton_root_up[3] * 0.33000001311302185, v27 - skeleton_root_up[4] * 0.33000001311302185, reset, board_acceleration)
    publish(entries[4], v30, v31, v32, v33, reset, board_acceleration)

    local v39 = entries[5]
    local position2, velocity2, acceleration2 = v39.position, v39.velocity, v39.acceleration
    local v40 = position2[1]
    local v41 = position2[2]
    local v42 = position2[3]
    local v43 = position2[4]

    position2[1] = 0
    position2[2] = 0
    position2[3] = 0
    position2[4] = 0

    if reset then
        velocity2[1] = 0
        velocity2[2] = 0
        velocity2[3] = 0
        velocity2[4] = 0
    else
        velocity2[1] = v7 * (0 - v40)
        velocity2[2] = v7 * (0 - v41)
        velocity2[3] = v7 * (0 - v42)
        velocity2[4] = v7 * (0 - v43)
    end

    acceleration2[1] = 0
    acceleration2[2] = 0
    acceleration2[3] = 0
    acceleration2[4] = 0

    local v44 = entries[6]
    local position3, velocity3, acceleration3 = v44.position, v44.velocity, v44.acceleration
    local v45 = position3[1]
    local v46 = position3[2]
    local v47 = position3[3]
    local v48 = position3[4]

    position3[1] = p12
    position3[2] = p13
    position3[3] = p14
    position3[4] = p15

    if reset then
        velocity3[1] = 0
        velocity3[2] = 0
        velocity3[3] = 0
        velocity3[4] = 0
    else
        velocity3[1] = v7 * (p12 - v45)
        velocity3[2] = v7 * (p13 - v46)
        velocity3[3] = v7 * (p14 - v47)
        velocity3[4] = v7 * (p15 - v48)
    end

    acceleration3[1] = 0
    acceleration3[2] = 0
    acceleration3[3] = 0
    acceleration3[4] = 0

    local v49 = entries[7]
    local position4, velocity4, acceleration4 = v49.position, v49.velocity, v49.acceleration
    local v50 = position4[1]
    local v51 = position4[2]
    local v52 = position4[3]
    local v53 = position4[4]

    position4[1] = 0
    position4[2] = 0
    position4[3] = 0
    position4[4] = 0

    if reset then
        velocity4[1] = 0
        velocity4[2] = 0
        velocity4[3] = 0
        velocity4[4] = 0
    else
        velocity4[1] = v7 * (0 - v50)
        velocity4[2] = v7 * (0 - v51)
        velocity4[3] = v7 * (0 - v52)
        velocity4[4] = v7 * (0 - v53)
    end

    acceleration4[1] = 0
    acceleration4[2] = 0
    acceleration4[3] = 0
    acceleration4[4] = 0
end

function t1.Anchors.update(p16, p17) -- line: 202
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.Anchors.update_reference(p16, p17)
    end

    local damped_center_of_mass = p17.damped_center_of_mass

    return t1.Anchors.update_damped(p16, p17, damped_center_of_mass[1], damped_center_of_mass[2], damped_center_of_mass[3], damped_center_of_mass[4])
end

return t1
