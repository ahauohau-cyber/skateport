-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {},
    State = {}
}

function t1.State.default() -- line: 21
    return {
        value = 0,
        filtered = 0,
        channel = nil,
        peak = 0
    }
end

t1.Update = {}

function t1.State.update(p1, p2, p3, p4) -- line: 32
    -- upvalues: PointGraph (copy)
    local value = p1.value
    local v1 = p2 / p4.maximum_physics_pump

    if -v1 >= 0 then
        v1 = 0
    end

    if not (1 - v1 >= 0) then
        v1 = 1
    end

    p1.filtered = v1 * p4.input_blend + (1 - p4.input_blend) * p1.filtered
    p1.value = PointGraph.evaluate(p4.amplify, p1.filtered)

    local v2

    if not (p4.new_pump_threshold < value) and p1.value > p4.new_pump_threshold then
        if p3[1] then
            if p3[2] then
                if p3[3] then
                    if p3[4] then
                        if not p3[5] then
                            v2 = 4
                        end
                    else
                        v2 = 3
                    end
                else
                    v2 = 2
                end
            else
                v2 = 1
            end
        else
            v2 = 0
        end
    end

    if v2 ~= nil then
        p1.channel = v2
        p1.peak = p1.value
    end

    local t2

    if value <= p1.value and p1.value >= p1.peak and p1.channel ~= nil then
        local channel = p1.channel

        p1.peak = p1.value
        t2 = {
            channel,
            p1.value
        }
    end

    return {
        start = v2,
        influence = t2
    }
end

return t1
