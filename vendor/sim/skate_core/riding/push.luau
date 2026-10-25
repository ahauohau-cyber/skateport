-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/force_queue")
local Vector3 = v1.Vector3
local BoardForceQueue, total_body_mass = v2.BoardForceQueue, v2.total_body_mass
local t1 = {
    PushInput = {},
    PushLimits = {},
    PushAcceleration = {}
}

function t1.PushAcceleration.default() -- line: 47
    -- upvalues: Vector3 (copy)
    return {
        suppressed = false,
        vector = Vector3.default(),
        local_point = Vector3.default()
    }
end

function t1.calculate_acceleration(p1, p2) -- line: 55
    -- upvalues: Vector3 (copy), t1 (copy)
    if bit32.band(p1.flags_2468, 33554432) == 0 then
        return t1.PushAcceleration.default()
    end

    if bit32.band(p1.flags_2472, 512) == 0 then
        local v3 = p1.target_speed - p1.current_speed

        if not (v3 > 0) then
            v3 = 0
        end

        local v4 = p1.current_speed / p2.maximum_pushable_speed

        if -v4 >= 0 then
            v4 = 0
        end

        if not (1 - v4 >= 0) then
            v4 = 1
        end

        local v5 = (1 - v4) * p2.low_speed_change + v4 * p2.high_speed_change
        local v6 = v3 < -v5

        if v5 < v3 then
            v3 = v5
        end

        if v6 then
            v3 = -v5
        end

        if p1.absolute_body_speed + v3 > p2.maximum_pushable_speed then
            v3 = p2.maximum_pushable_speed - p1.absolute_body_speed

            if not (v3 >= 0) then
                v3 = 0
            end
        end

        local v7 = p1.scale * v3 / p1.delta_seconds
        local v8 = t1.PushAcceleration.default()

        v8.vector = Vector3.new(p1.direction.x * v7, p1.direction.y * v7, p1.direction.z * v7)

        return v8
    end

    local v9 = t1.PushAcceleration.default()

    v9.suppressed = true

    return v9
end

function t1.enqueue_push(p3, p4, p5, p6) -- line: 121
    -- upvalues: rt (copy), BoardForceQueue (copy), total_body_mass (copy), t1 (copy)
    local v10 = rt.copy(p3)

    v10.scale = total_body_mass(p5)

    local v11 = t1.calculate_acceleration(v10, p4)

    BoardForceQueue.append(p6, {
        tag = 3,
        force_world = rt.copy(v11.vector),
        point_body = rt.copy(v11.local_point)
    })

    return v11
end

return t1
