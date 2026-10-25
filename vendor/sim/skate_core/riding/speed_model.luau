-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/riding/vector")
local v2 = import("skate_core/point_graph")
local clamp, dot3, normalize = v1.clamp, v1.dot3, v1.normalize
local PointGraph = v2.PointGraph

return {
    SpeedModelSettings = {},
    SpeedModelState = {},
    SpeedModelInput = {},
    update = function(p1, p2, p3) -- update | line: 77
        -- upvalues: clamp (copy), dot3 (copy), normalize (copy), PointGraph (copy)
        local v3 = math.abs(p3.signed_speed)
        local timestep = p3.timestep
        local speed_error_bound = p2.speed_error_bound
        local v4 = v3 - speed_error_bound

        if -v4 >= 0 then
            v4 = 0
        end

        local flags_1360 = p1.flags_1360
        local v5

        if bit32.band(flags_1360, 2147483648) == 0 then
            v5 = clamp(p1.target_speed, v4, speed_error_bound + v3)
        else
            v5 = v3
            p1.flags_1360 = bit32.band(p1.flags_1360, 2147483647)
        end

        local v6 = if bit32.band(p3.flags_2476, 1073741824) == 0 then 0 else p2.coffin_acceleration * timestep
        local v7 = dot3(p3.velocity_416, p3.effective_forward)
        local t2 = {
            p3.effective_forward[1] * v7,
            p3.effective_forward[2] * v7,
            p3.effective_forward[3] * v7,
            p3.effective_forward[4] * v7
        }
        local v8 = dot3(t2, p3.normal_464)
        local v9 = normalize({
            t2[1] - p3.normal_464[1] * v8,
            t2[2] - p3.normal_464[2] * v8,
            t2[3] - p3.normal_464[3] * v8,
            t2[4] - p3.normal_464[4] * v8
        }, p2.normal_threshold)
        local v10 = clamp(-v9[2] * p2.gravity, -p2.maximum_gravity_acceleration, p2.maximum_gravity_acceleration) * timestep

        if p3.frames_2580 < 30 then
            local v11 = if p3.manual_state_276 == 0 then 0 else 1
            local v12 = if p3.balance > 0 then 1 else -1

            if dot3(p3.vector_352, v9) < 0 then
                v12 *= -1
            end

            local v13 = math.abs(p3.angle_2652)
            local v14 = if p2.manual_angle_limit < v13 then 0 else 1
            local v15 = if p2.negative_manual_angle_limit < v13 then 0 else 1
            local v16 = p3.turn_2672 * p3.turn_2672 * p2.manual_acceleration * v14 * v12 * v11

            if v16 < 0 then
                v16 *= v15
            end

            v5 = v16 + v5
        end

        local v17 = -PointGraph.evaluate(p2.surface_friction, p3.surface_speed) * timestep

        if v10 > 0 then
            v10 = v17 + v10
        elseif not (v17 - v10 >= 0) then
            v10 = v17
        end

        local v18 = v10 + v6 + v5

        if p3.elapsed_without_input > p2.no_input_delay then
            v18 = -(PointGraph.evaluate(p2.no_input_friction, p3.surface_speed) * timestep + -v18)
        end

        if p3.balance ~= 0 then
            v18 = -(PointGraph.evaluate(p2.manual_friction, p3.surface_speed) * timestep + -v18)
        end

        if v18 >= 0 then
            p1.target_speed = v18
        else
            p1.target_speed = 0
        end

        local v19 = clamp(p1.target_speed - v3, -speed_error_bound, speed_error_bound)

        if p2.override_enabled and bit32.band(p3.flags_2476, 4194304) ~= 0 and p3.normal_464[2] > 0.65 then
            local v20 = p2.override_speed * 0.2777777910232544
            local v21 = dot3(p3.velocity_416, p3.vector_160)
            local v22 = true

            for _, v23 in p2.override_direction_threshold do
                if not (v21 < v23) then
                    v22 = false
                    break
                end
            end

            if v22 and p3.surface_speed < 1 then
                v20 *= -1
            end

            v19 = clamp(v20 - v3, -0.4, 0.4)
        end

        local flags_2468 = p3.flags_2468
        local v24 = false

        if bit32.band(flags_2468, 1644232704) == 0 and bit32.band(p3.flags_2476, 134217728) == 0 then
            v24 = p3.wheel_contact_count >= 2
        end

        local v25 = if not v24 then 0 elseif v19 < 0 then p2.negative_gain else p2.positive_gain
        local v26 = p3.mass * v25 * v19 / timestep
        local v27 = dot3(p3.effective_forward, v9) > 0
        local v28 = table.create(8, 0)

        v28[1] = (if v27 then p3.effective_forward[1] else -p3.effective_forward[1]) * v26
        v28[2] = (if v27 then p3.effective_forward[2] else -p3.effective_forward[2]) * v26
        v28[3] = (if v27 then p3.effective_forward[3] else -p3.effective_forward[3]) * v26
        v28[4] = (if v27 then p3.effective_forward[4] else -p3.effective_forward[4]) * v26

        return v28
    end
}
