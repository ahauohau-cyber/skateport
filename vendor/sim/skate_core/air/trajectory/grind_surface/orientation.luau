-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/trigonometry")
local scale, madd, cross = v1.scale, v1.madd, v1.cross
local t1 = {}

function t1.tilted_normal(p1, p2, p3) -- line: 14
    -- upvalues: rt (copy), scale (copy), t1 (copy)
    local v3 = p3[1]
    local v4 = p3[2]

    if not (v3 < v4) then
        v3 = (v4 + v3) * 0.5

        return t1.rotate(p1, scale(p2, -1), v3)
    end

    if v3 < 3.1415927410125732 and v4 > 3.1415927410125732 then
        return rt.copy(p2)
    end

    if not (math.abs(3.1415927410125732 - v3) < math.abs(3.1415927410125732 - v4)) then
        v3 = v4
    end

    return t1.rotate(p1, scale(p2, -1), v3)
end

function t1.rotate(p4, p5, p6) -- line: 31
    -- upvalues: v2 (copy), scale (copy), madd (copy), cross (copy)
    local v8, v9 = v2.sin_cos(p6 * 0.5)
    local v10 = scale(p4, v8)

    return madd(cross(v10, madd(p5, v9, cross(v10, p5))), 2, p5)
end

return t1
