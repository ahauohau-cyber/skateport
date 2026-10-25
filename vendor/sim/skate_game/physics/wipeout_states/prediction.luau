-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory")
local QueryResult, Trajectory = v1.QueryResult, v1.Trajectory

local function air_trajectory() -- line: 15
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local t1 = {
    Prediction = {}
}

function t1.Prediction.new() -- line: 27
    -- upvalues: QueryResult (copy)
    return {
        pending = nil,
        result = QueryResult.miss()
    }
end

function t1.Prediction.reset(p1) -- line: 35
    -- upvalues: QueryResult (copy)
    p1.pending = nil
    p1.result = QueryResult.miss()
end

function t1.Prediction.advance(p2, p3, p4, p5, p6) -- line: 42
    -- upvalues: rt (copy), import (copy), QueryResult (copy), Trajectory (copy)
    local pending = p2.pending

    p2.pending = nil

    if pending ~= nil then
        local v2 = pending[1]
        local v3 = pending[2]
        local v4 = pending[3]

        p2.result = rt.copy(v2)

        if v4 then
            if not (QueryResult.valid(v2) and bit32.band(v2.surface, 3968) == 1536) then
                p3.below_surface = false
                p3.special_surface = false
            end
        elseif QueryResult.valid(v2) then
            p3.predicted_time = v2.contact_time

            if bit32.band(v2.surface, 3968) == 1536 then
                p3.imminent_surface_twelve = v2.contact_time < 0.1
            else
                p3.imminent_surface_twelve = false
            end

            p3.predicted_position = Trajectory.position_at(v3, v2.contact_time)
        else
            p3.predicted_position = Trajectory.position_at(v3, 3)
        end
    end

    local below_surface = p3.below_surface

    p3.surface_query = below_surface

    local t2

    if below_surface then
        local v7 = rt.copy(p5)

        v7[2] = p3.surface_height + 0.1
        t2 = {
            radius = 0.01,
            start_error = 1,
            end_error = 1,
            trajectory = {
                duration = 1,
                position = v7,
                velocity = { 0, -0.2, 0, 0 },
                acceleration = { 0, 0, 0, 0 }
            }
        }
    else
        t2 = {
            radius = 0.3,
            start_error = 1,
            end_error = 1,
            trajectory = {
                duration = 3,
                position = rt.copy(p5),
                velocity = rt.copy(p3.velocity),
                acceleration = rt.copy(p6)
            }
        }
    end

    local v8 = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.query(p4, rt.copy(t2))

    p2.result = rt.copy(v8)
    p2.pending = {
        v8,
        rt.copy(t2.trajectory),
        below_surface
    }
end

return t1
