-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/native_arithmetic")
local dot3, reciprocal_estimate = v1.dot3, v1.reciprocal_estimate
local t1 = {
    CentreOfMassOutput = {},
    CentreOfMassFilter = {}
}

function t1.CentreOfMassFilter.default() -- line: 27
    return {
        position_valid = false,
        velocity = table.create(4, 0),
        position = table.create(4, 0),
        position_velocity = table.create(4, 0),
        accumulated_error = table.create(4, 0)
    }
end

function t1.CentreOfMassFilter.reset(p1) -- line: 38
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p1, t1.CentreOfMassFilter.default())
end

function t1.CentreOfMassFilter.update(p2, p3, p4) -- line: 42
    -- upvalues: rt (copy), dot3 (copy), reciprocal_estimate (copy)
    local v2 = rt.copy(p2.velocity)

    p2.velocity = {
        v2[1] * 0.75 + p4[1] * 0.25,
        v2[2] * 0.75 + p4[2] * 0.25,
        v2[3] * 0.75 + p4[3] * 0.25,
        v2[4] * 0.75 + p4[4] * 0.25
    }

    local v3 = reciprocal_estimate(0.01666666753590107)
    local v4 = v3 * (-0.01666666753590107 * v3 + 1) + v3
    local v5 = v4 * (-0.01666666753590107 * v4 + 1) + v4
    local t2 = {
        (p2.velocity[1] - v2[1]) * v5,
        (p2.velocity[2] - v2[2]) * v5,
        (p2.velocity[3] - v2[3]) * v5,
        (p2.velocity[4] - v2[4]) * v5
    }

    if p2.position_valid then
        local t3 = {
            0.05, 0.03, 0.05, 0
        }
        local t4 = {
            1, 1, 1, 0
        }
        local position_velocity = p2.position_velocity

        p2.position_velocity = {
            (t4[1] - t3[1]) * position_velocity[1] + t3[1] * p4[1],
            (t4[2] - t3[2]) * position_velocity[2] + t3[2] * p4[2],
            (t4[3] - t3[3]) * position_velocity[3] + t3[3] * p4[3],
            (t4[4] - t3[4]) * position_velocity[4] + t3[4] * p4[4]
        }

        local t5 = {
            p2.position_velocity[1] * 0.01666666753590107 + p2.position[1],
            p2.position_velocity[2] * 0.01666666753590107 + p2.position[2],
            p2.position_velocity[3] * 0.01666666753590107 + p2.position[3],
            p2.position_velocity[4] * 0.01666666753590107 + p2.position[4]
        }

        p2.position = {
            (t4[1] - t3[1]) * t5[1] + t3[1] * p3[1],
            (t4[2] - t3[2]) * t5[2] + t3[2] * p3[2],
            (t4[3] - t3[3]) * t5[3] + t3[3] * p3[3],
            (t4[4] - t3[4]) * t5[4] + t3[4] * p3[4]
        }

        if dot3({
            p3[1] - p2.position[1],
            p3[2] - p2.position[2],
            p3[3] - p2.position[3],
            p3[4] - p2.position[4]
        }, p2.accumulated_error) > 0 then
            local position = p2.position

            p2.position = {
                p2.accumulated_error[1] * 0.08 + position[1],
                p2.accumulated_error[2] * 0.08 + position[2],
                p2.accumulated_error[3] * 0.08 + position[3],
                p2.accumulated_error[4] * 0.08 + position[4]
            }
        end

        local accumulated_error = p2.accumulated_error

        p2.accumulated_error = {
            accumulated_error[1] * 0.95 + (p3[1] - p2.position[1]) * 0.05,
            accumulated_error[2] * 0.95 + (p3[2] - p2.position[2]) * 0.05,
            accumulated_error[3] * 0.95 + (p3[3] - p2.position[3]) * 0.05,
            accumulated_error[4] * 0.95 + (p3[4] - p2.position[4]) * 0.05
        }
    else
        p2.position = rt.copy(p3)
        p2.position_velocity = table.create(4, 0)
        p2.position_valid = true
    end

    return {
        velocity = rt.copy(p2.velocity),
        acceleration = t2,
        position = rt.copy(p2.position)
    }
end

return t1
