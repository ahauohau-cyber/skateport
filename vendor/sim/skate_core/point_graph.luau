-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    PointGraph = {}
}

function t1.PointGraph.eq(p1, p2) -- line: 15
    if #p1.x ~= #p2.x or #p1.y ~= #p2.y then
        return false
    end

    for i = 1, #p1.x do
        if p1.x[i] ~= p2.x[i] then
            return false
        end
    end

    for i = 1, #p1.y do
        if p1.y[i] ~= p2.y[i] then
            return false
        end
    end

    return true
end

function t1.PointGraph.evaluate(p3, p4) -- line: 33
    local v1 = #p3.x

    if not (v1 > 0) then
        error("assertion failed: N > 0", 0)
    end

    if not (p4 < p3.x[1]) then
        if not (p4 < p3.x[v1]) then
            return p3.y[v1]
        end

        for i = 1, v1 - 1 do
            if p4 < p3.x[i + 1] then
                local v2 = i - 1
                local v3 = p3.x[i + 1] - p3.x[v2 + 1]

                if v3 <= 0 then
                    return p3.y[i + 1]
                end

                return (p3.y[i + 1] - p3.y[v2 + 1]) / v3 * (p4 - p3.x[v2 + 1]) + p3.y[v2 + 1]
            end
        end
    end

    return p3.y[1]
end

return t1
