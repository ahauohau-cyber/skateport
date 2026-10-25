-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local v1 = import("skate_core/riding/braking")
local v2 = import("skate_core/riding/push")
local t1 = {
    GroundPropulsionInput = {},
    GroundPropulsionSettings = {},
    GroundPropulsion = {},
    PropulsionSubmission = {},
    calculate = function(p1, p2, _) -- calculate | line: 57
        -- upvalues: rt (copy), v1 (copy), v2 (copy)
        local v3 = v1.calculate_braking({
            flags_2468 = p1.flags_2468,
            input_2728 = p1.brake_input,
            signed_speed = p1.signed_speed,
            absolute_body_speed = p1.absolute_body_speed,
            surface_factor = p1.surface_braking_factor,
            direction = rt.copy(p1.brake_direction)
        }, p2.braking)
        local v4 = v2.calculate_acceleration({
            flags_2468 = p1.flags_2468,
            flags_2472 = p1.flags_2472,
            target_speed = p1.target_speed,
            current_speed = p1.signed_speed,
            absolute_body_speed = p1.absolute_body_speed,
            scale = p1.scalar_2660,
            delta_seconds = p1.timestep,
            direction = rt.copy(p1.push_direction)
        }, {
            maximum_pushable_speed = p2.maximum_pushable_speed,
            low_speed_change = p2.mode_speed_changes[1],
            high_speed_change = p2.mode_speed_changes[2]
        })
        local v5 = if v4.suppressed then 1 else 0

        return {
            braking = v3,
            push = v4
        }, v5
    end
}

function t1.GroundPropulsion.submit(p4, p5, p6) -- line: 91
    -- upvalues: rt (copy), Vector3 (copy), BoardForceQueue (copy)
    if not p5.correction_active then
        return {
            tag = "BrakingAndPush",
            {
                BoardForceQueue.append(p6, rt.copy(p4.braking)),
                (BoardForceQueue.append(p6, {
                    tag = 3,
                    force_world = rt.copy(p4.push.vector),
                    point_body = rt.copy(p4.push.local_point)
                }))
            }
        }
    end

    local v6 = rt.copy(p5.corrective_force_world)
    local v7 = rt.copy(p5.corrective_point_body)

    return {
        tag = "ManualCorrection",
        (BoardForceQueue.append(p6, {
            tag = 7,
            force_world = Vector3.new(v6[1], v6[2], v6[3]),
            point_body = Vector3.new(v7[1], v7[2], v7[3])
        }))
    }
end

return t1
