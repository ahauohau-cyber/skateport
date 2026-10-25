-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/offboard/ground_query/math")
local add, sub, scale, madd = v1.add, v1.sub, v1.scale, v1.madd
local dot, abs, length, reciprocal = v1.dot, v1.abs, v1.length, v1.reciprocal
local t1 = {}

function t1.edge_search(p1, p2, p3, p4) -- line: 24
    -- upvalues: rt (copy), add (copy), sub (copy), scale (copy), madd (copy), dot (copy), abs (copy)
    local v2 = bit32.band(p4, 134217728) ~= 0 or not (dot(p3, p3) >= 1)
    local v3 = if v2 then madd(p1.forward, 0.75, p1.position) else rt.copy(p1.position)
    local v4 = madd(abs(p1.forward), 0.75, madd(abs(p1.up), 0.2, scale(abs(p1.right), 0.5)))

    return {
        min = sub(v3, v4),
        max = add(v3, v4),
        frame = rt.copy(p1),
        context = rt.copy(p2),
        narrow_forward = v2
    }
end

function t1.closest_point(p5, p6) -- line: 45
    -- upvalues: rt (copy), sub (copy), scale (copy), madd (copy), dot (copy), length (copy), reciprocal (copy)
    local v5 = sub(p6["end"], p6.start)
    local v6 = length(v5)

    if v6 > 1.52587890625E-05 then
        v5 = scale(v5, reciprocal(v6))
    end

    return madd(v5, rt.fmax(rt.fmin(dot(v5, sub(p5, p6.start)), v6), 0), p6.start)
end

local closest_point = t1.closest_point

function t1.select_edge(p7, p8) -- line: 59
    -- upvalues: rt (copy), sub (copy), scale (copy), dot (copy), length (copy), closest_point (copy)
    local n1 = 0.2
    local n2 = 1.5
    local t2

    for i = 1, math.min(#p8, 40) do
        local v10 = p8[i]
        local v11 = closest_point(p7.frame.position, v10)
        local v12 = sub(v11, p7.frame.position)

        if not (p7.narrow_forward and dot(p7.frame.forward, v12) < 0) then
            local v13 = dot(p7.frame.up, v12)
            local v14 = length(sub(v12, scale(p7.frame.up, v13)))

            if not (n1 <= math.abs(v13) or n2 <= v14) then
                n1 = math.abs(v13)
                n2 = v14
                t2 = {
                    edge = rt.copy(v10),
                    closest = v11
                }
            end
        end
    end

    return t2
end

return t1
