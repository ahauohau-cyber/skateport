-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/air/trajectory/math")
local IDENTITY, STEP, UP, ZERO = v1.IDENTITY, v1.STEP, v1.UP, v1.ZERO
local reciprocal = v1.reciprocal
local t1 = {}

local function deep_eq(p1, p2) -- line: 14
    -- upvalues: deep_eq (copy)
    if type(p1) ~= "table" or type(p2) ~= "table" then
        return p1 == p2
    end

    for v2, v3 in p1 do
        if not deep_eq(v3, p2[v2]) then
            return false
        end
    end

    for v4 in p2 do
        if p1[v4] == nil then
            return false
        end
    end

    return true
end

t1.Trajectory = {}

function t1.Trajectory.eq(p3, p4) -- line: 39
    -- upvalues: deep_eq (copy)
    return (deep_eq(p3, p4))
end

function t1.Trajectory.position_at(p5, p6) -- line: 43
    local v5 = p6 * p6
    local acceleration, velocity, position = p5.acceleration, p5.velocity, p5.position

    return {
        acceleration[1] * 0.5 * v5 + (velocity[1] * p6 + position[1]),
        acceleration[2] * 0.5 * v5 + (velocity[2] * p6 + position[2]),
        acceleration[3] * 0.5 * v5 + (velocity[3] * p6 + position[3]),
        acceleration[4] * 0.5 * v5 + (velocity[4] * p6 + position[4])
    }
end

function t1.Trajectory.velocity_at(p7, p8) -- line: 54
    local acceleration, velocity = p7.acceleration, p7.velocity

    return {
        acceleration[1] * p8 + velocity[1],
        acceleration[2] * p8 + velocity[2],
        acceleration[3] * p8 + velocity[3],
        acceleration[4] * p8 + velocity[4]
    }
end

function t1.Trajectory.highest_position(p9) -- line: 65
    -- upvalues: rt (copy), reciprocal (copy), t1 (copy)
    if p9.velocity[2] < 0 or p9.acceleration[2] >= 0 then
        return rt.copy(p9.position), 0
    end

    local v6 = p9.velocity[2] * reciprocal(-p9.acceleration[2])

    return t1.Trajectory.position_at(p9, v6), v6
end

t1.QueryRequest = {}

function t1.QueryRequest.eq(p10, p11) -- line: 83
    -- upvalues: deep_eq (copy)
    return (deep_eq(p10, p11))
end

t1.QueryResult = {}

function t1.QueryResult.eq(p12, p13) -- line: 99
    -- upvalues: deep_eq (copy)
    return (deep_eq(p12, p13))
end

function t1.QueryResult.miss() -- line: 103
    -- upvalues: rt (copy), IDENTITY (copy), UP (copy), ZERO (copy)
    return {
        contact_time = -1,
        contact_frame = -1,
        surface = 0,
        geometry = 0,
        contact_position = rt.copy(ZERO),
        contact_normal = rt.copy(UP),
        landing_normal = rt.copy(UP),
        contact_transform = rt.copy(IDENTITY)
    }
end

function t1.QueryResult.valid(p14) -- line: 116
    return p14.contact_time >= 0
end

function t1.QueryResult.suggested_normal(p15) -- line: 121
    -- upvalues: rt (copy), UP (copy), t1 (copy)
    if t1.QueryResult.valid(p15) then
        return rt.copy(p15.landing_normal)
    end

    return rt.copy(UP)
end

t1.Prediction = {}

function t1.Prediction.eq(p16, p17) -- line: 132
    -- upvalues: deep_eq (copy)
    return (deep_eq(p16, p17))
end

function t1.Prediction.collision_position(p18) -- line: 136
    -- upvalues: t1 (copy)
    return t1.Trajectory.position_at(p18.request.trajectory, p18.result.contact_time)
end

function t1.Prediction.collision_velocity(p19) -- line: 140
    -- upvalues: STEP (copy), t1 (copy)
    return t1.Trajectory.velocity_at(p19.request.trajectory, p19.result.contact_frame * STEP)
end

return t1
