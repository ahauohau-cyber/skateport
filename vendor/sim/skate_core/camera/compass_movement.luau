-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/direction")
local v2 = import("skate_core/camera/manager_state")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/camera/orientation_math")
local v5 = import("skate_core/physics/reciprocal_sqrt")

local function compass() -- line: 14
    -- upvalues: import (copy)
    return import("skate_core/camera/compass")
end

local direction_to_angles = v1.direction_to_angles
local clamp = v2.clamp
local length, refined_reciprocal = v3.length, v3.refined_reciprocal
local t1 = {
    Compass = {}
}

function t1.Compass.update_movement_reference(p1, p2, p3, p4) -- line: 30
    -- upvalues: rt (copy), import (copy), v4 (copy), direction_to_angles (copy), clamp (copy), length (copy), refined_reciprocal (copy), t1 (copy)
    if p3.no_trajectory then
        local v6 = import("skate_core/camera/compass")
        local horizontal = v6.horizontal
        local v7 = p2 == 0 or p1.previous_reset

        if v7 then
            p1.velocity = { 0, 0, 0, 0 }
            p1.damped_velocity = { 0, 0, 0, 0 }
        else
            local v8 = refined_reciprocal(p2)
            local v9 = v6.sub(p3.transform[4], p1.previous_position)

            p1.velocity = {
                v9[1] * v8,
                v9[2] * v8,
                v9[3] * v8,
                v9[4] * v8
            }
            p1.deadzone_size = (clamp((length(horizontal(p1.velocity)) - p4.maximum_deadzone_speed) / (p4.minimum_deadzone_speed - p4.maximum_deadzone_speed), 0, 1) * p4.maximum_deadzone_size + -p1.deadzone_size) * (1 - p4.deadzone_smoothing) + p1.deadzone_size
            t1.Compass.update_deadzone(p1, p2, {
                p3.transform[4][1],
                p3.transform[4][3]
            })
            p1.damped_velocity = {
                p1.deadzone_velocity[1],
                0,
                p1.deadzone_velocity[2],
                p1.deadzone_velocity[1]
            }
            p1.previous_position = rt.copy(p3.transform[4])
        end

        local v11 = length(horizontal(p1.velocity))

        if v7 then
            p1.movement_heading = -direction_to_angles(p3.skeleton_direction)[2]
        elseif p3.grinding then
            p1.movement_heading = -direction_to_angles(p3.grind_direction)[2]
        else
            local movement_heading = p1.movement_heading

            if p3.wiping_out or v11 > 0.5 then
                p1.stopped_time = 0
            else
                p1.stopped_time += p2
            end

            local n1 = 1

            if v11 > 0.5 then
                n1 = clamp(p4.heading_response, 0, 1)
                movement_heading = -direction_to_angles(v4.normalize(p1.damped_velocity))[2]
            elseif p3.state_103 then
            elseif p1.stopped_time >= p4.time_before_lineup then
                n1 = p4.lineup_speed
                movement_heading = -direction_to_angles(p3.transform[3])[2]
            end

            p1.movement_heading = v6.blend(p1.movement_heading, movement_heading, n1)
        end
    end
end

function t1.Compass.update_deadzone_reference(p5, p6, p7) -- line: 90
    -- upvalues: rt (copy), v5 (copy)
    local v12 = rt.copy(p5.deadzone_position)
    local t2 = {
        p7[1] - v12[1],
        p7[2] - v12[2]
    }
    local v13 = t2[1] * t2[1] + t2[2] * t2[2]
    local v14 = v5.estimate(v13)
    local v15 = v14 * 0.5 * (-v13 * (v14 * v14) + 1) + v14
    local v16 = v15 * 0.5 * (-v13 * (v15 * v15) + 1) + v15
    local v17 = if v13 == 0 then 0 else v13 * v16

    if p5.deadzone_size < v17 then
        p5.deadzone_position = {
            t2[1] * v16 * (v17 - p5.deadzone_size) + v12[1],
            t2[2] * v16 * (v17 - p5.deadzone_size) + v12[2]
        }
    end

    if p6 == 0 then
        p5.deadzone_velocity = { 0, 0 }
    else
        p5.deadzone_velocity = {
            (p5.deadzone_position[1] - v12[1]) * (1 / p6),
            (p5.deadzone_position[2] - v12[2]) * (1 / p6)
        }
    end
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v3.length3
local direction_heading = v1.direction_heading

local function update_deadzone_lanes(p8, p9, p10, p11) -- line: 130
    local deadzone_position = p8.deadzone_position
    local v18 = deadzone_position[1]
    local v19 = deadzone_position[2]
    local v20 = p10 - v18
    local v21 = p11 - v19
    local v22 = v20 * v20 + v21 * v21
    local v23 = 1 / math.sqrt(v22)
    local v24 = v23 * 0.5 * (-v22 * (v23 * v23) + 1) + v23
    local v25 = v24 * 0.5 * (-v22 * (v24 * v24) + 1) + v24
    local v26 = if v22 == 0 then 0 else v22 * v25
    local deadzone_size = p8.deadzone_size
    local v27, v28

    if deadzone_size < v26 then
        v27 = v20 * v25 * (v26 - deadzone_size) + v18
        v28 = v21 * v25 * (v26 - deadzone_size) + v19
        deadzone_position[1] = v27
        deadzone_position[2] = v28
    else
        v28 = v19
        v27 = v18
    end

    local deadzone_velocity = p8.deadzone_velocity

    if p9 == 0 then
        deadzone_velocity[1] = 0
        deadzone_velocity[2] = 0
    else
        local v29 = (v27 - v18) * (1 / p9)
        local v30 = (v28 - v19) * (1 / p9)

        deadzone_velocity[1] = v29
        deadzone_velocity[2] = v30
    end
end

function t1.Compass.update_deadzone(p12, p13, p14) -- line: 156
    -- upvalues: t1 (copy), PERF (copy), update_deadzone_lanes (copy)
    if PERF.reference then
        return t1.Compass.update_deadzone_reference(p12, p13, p14)
    end

    return update_deadzone_lanes(p12, p13, p14[1], p14[2])
end

function t1.Compass.update_movement(p15, p16, p17, p18) -- line: 163
    -- upvalues: import (copy), clamp (copy), refined_reciprocal (copy), t1 (copy), PERF (copy), length3 (copy), direction_heading (copy), update_deadzone_lanes (copy)
    if PERF.reference then
        return t1.Compass.update_movement_reference(p15, p16, p17, p18)
    end

    if p17.no_trajectory then
        local v31 = import("skate_core/camera/compass")
        local v32 = p16 == 0 or p15.previous_reset
        local velocity = p15.velocity
        local v33, v34

        if v32 then
            local damped_velocity = p15.damped_velocity

            velocity[1] = 0
            velocity[2] = 0
            velocity[3] = 0
            velocity[4] = 0
            damped_velocity[1] = 0
            damped_velocity[2] = 0
            damped_velocity[3] = 0
            v33 = 0
            v34 = 0
            damped_velocity[4] = 0
        else
            local v35 = refined_reciprocal(p16)
            local v36 = p17.transform[4]
            local previous_position = p15.previous_position
            local v37 = v36[1]
            local v38 = v36[2]
            local v39 = v36[3]
            local v40 = v36[4]

            v33 = (v37 - previous_position[1]) * v35

            local v41 = (v38 - previous_position[2]) * v35

            v34 = (v39 - previous_position[3]) * v35

            local v42 = (v40 - previous_position[4]) * v35

            velocity[1] = v33
            velocity[2] = v41
            velocity[3] = v34
            velocity[4] = v42
            p15.deadzone_size = (clamp((length3(v33, 0, v34) - p18.maximum_deadzone_speed) / (p18.minimum_deadzone_speed - p18.maximum_deadzone_speed), 0, 1) * p18.maximum_deadzone_size + -p15.deadzone_size) * (1 - p18.deadzone_smoothing) + p15.deadzone_size
            update_deadzone_lanes(p15, p16, v37, v39)

            local deadzone_velocity, damped_velocity = p15.deadzone_velocity, p15.damped_velocity
            local v44 = deadzone_velocity[1]
            local v45 = deadzone_velocity[2]

            damped_velocity[1] = v44
            damped_velocity[2] = 0
            damped_velocity[3] = v45
            damped_velocity[4] = v44
            previous_position[1] = v37
            previous_position[2] = v38
            previous_position[3] = v39
            previous_position[4] = v40
        end

        local v46 = length3(v33, 0, v34)

        if v32 then
            local skeleton_direction = p17.skeleton_direction

            p15.movement_heading = -direction_heading(skeleton_direction[1], skeleton_direction[3])
        elseif p17.grinding then
            local grind_direction = p17.grind_direction

            p15.movement_heading = -direction_heading(grind_direction[1], grind_direction[3])
        else
            local movement_heading = p15.movement_heading

            if p17.wiping_out or v46 > 0.5 then
                p15.stopped_time = 0
            else
                p15.stopped_time += p16
            end

            local n2 = 1

            if v46 > 0.5 then
                n2 = clamp(p18.heading_response, 0, 1)

                local damped_velocity = p15.damped_velocity
                local v47 = damped_velocity[1]
                local v48 = damped_velocity[2]
                local v49 = damped_velocity[3]
                local v50 = v47 * v47 + v48 * v48 + v49 * v49
                local v51 = 1 / math.sqrt(v50)
                local v52 = v51 * 0.5 * (-v50 * (v51 * v51) + 1) + v51
                local v53 = v52 * 0.5 * (-v50 * (v52 * v52) + 1) + v52

                movement_heading = -direction_heading(v47 * v53, v49 * v53)
            elseif p17.state_103 then
            elseif p15.stopped_time >= p18.time_before_lineup then
                n2 = p18.lineup_speed

                local v54 = p17.transform[3]

                movement_heading = -direction_heading(v54[1], v54[3])
            end

            p15.movement_heading = v31.blend(p15.movement_heading, movement_heading, n2)
        end
    end
end

return t1
