-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/input/graph_intents")
local t1 = {
    State = {}
}

function t1.State.default() -- line: 16
    return {
        wrap = 0,
        previous_angle = 0
    }
end

function t1.State.begin(p1) -- line: 20
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p1, t1.State.default())
end

function t1.State.update(p2, p3, p4, p5, p6, p7) -- line: 25
    -- upvalues: v1 (copy), t1 (copy)
    if p3 ~= nil and p4 ~= nil then
        local v2 = if p5 <= 7 then v1.apply_filter(p4, p5) else p4

        if p6 and p7 then
            v2 *= -1
        end

        local v3 = p2.previous_angle * v2 < 0 and math.abs(p2.previous_angle) > 1.5707963705062866

        if p2.wrap == 0 and v3 and p2.previous_angle < 0 then
            p2.wrap = 1
        elseif p2.wrap == 0 and v3 and p2.previous_angle > 0 then
            p2.wrap = 2
        elseif p2.wrap == 1 and v3 and p2.previous_angle > 0 or p2.wrap == 2 and v3 and p2.previous_angle < 0 then
            p2.wrap = 0
        end

        p2.previous_angle = v2

        if p2.wrap == 1 then
            v2 = -3.1415927410125732
        elseif p2.wrap == 2 then
            v2 = 3.1415927410125732
        end

        return { p3, v2 }
    end

    t1.State.begin(p2)

    return nil
end

return t1
