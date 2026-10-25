-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_air/targets")
local v2

local function parent() -- line: 10
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/physics/grind_air")
    end

    return v2
end

return {
    Contacts = {},
    contacts = function(p1, p2, p3, p4, p5) -- contacts | line: 23
        -- upvalues: rt (copy), import (copy), v2 (ref)
        if v2 == nil then
            v2 = import("skate_core/physics/grind_air")
        end

        local v3 = v2
        local dot, sub, madd, scale = v3.dot, v3.sub, v3.madd, v3.scale
        local length = v3.length
        local t2 = {
            times = table.create(5, -1),
            distances = table.create(5, 0),
            corrections = rt.filled(5, v3.ZERO),
            earliest = p2
        }

        for i = 0, 4 do
            for j = 1, p2 - 1 do
                local v4 = dot(p5, sub(p1[j][i + 1], p3))
                local v5 = dot(p5, sub(p1[j + 1][i + 1], p3))

                if v4 * v5 < 0 then
                    local v7 = math.abs(v4 / (v4 - v5))
                    local v8 = madd(p1[j][i + 1], 1 - v7, scale(p1[j + 1][i + 1], v7))
                    local v9 = madd(p4, dot(sub(v8, p3), p4), p3)

                    t2.times[i + 1] = j - 1 + v7
                    t2.corrections[i + 1] = sub(v9, v8)
                    t2.distances[i + 1] = length(t2.corrections[i + 1])
                    t2.earliest = rt.fmin(t2.earliest, t2.times[i + 1])
                    break
                end
            end
        end

        return t2
    end,
    choose = function(p6, p7, p8, p9, p10) -- choose | line: 52
        -- upvalues: rt (copy), v1 (copy)
        local function valid(p11) -- line: 53
            -- upvalues: p6 (copy), p7 (copy), p8 (copy), rt (copy), v1 (copy)
            local v10 = v1.CONTACTS[p11 + 1]
            local v11 = p6.times[v10 + 1]

            if p11 == 4 then
                if rt.fmin(p6.times[3], p6.times[4]) < 4 and math.abs(p6.times[3] - p6.times[4]) > 2 then
                    return false
                end
            elseif p6.earliest < 5 and math.abs(p6.earliest - v11) > 3 then
                return false
            end

            if not (v11 > 0 and p6.distances[v10 + 1] < p8.distances[p11 + 1]) then
                return false
            end

            return math.abs(v1.DESIRED[p11 + 1] - math.abs(p7[rt.f_to_usize(v11 + 0.5) + 1])) < p8.ranges[p11 + 1]
        end

        local v17

        for i = 0, 6 do
            local v18

            if p9 == (i == 0) and valid(i) then
                local v19 = if i == 3 and (p10 == 1 or p10 == 2) and valid(p10) then p10 else i

                v18 = if v17 == nil or p6.distances[v1.CONTACTS[v19 + 1] + 1] < p6.distances[v1.CONTACTS[v17 + 1] + 1] then v19 else v17

                if v18 ~= nil and v18 < 5 then
                    v17 = v18
                    break
                end
            else
                v18 = v17
            end

            v17 = v18
        end

        return v17
    end
}
