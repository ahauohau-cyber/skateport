-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/grab_scene/qualify/math")
local v2 = import("skate_core/player/offboard/grab_scene/qualify/polyline")
local v3 = import("skate_core/player/offboard/grab_scene/qualify/selection")

local function grab_scene() -- line: 13
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/grab_scene")
end

local t1 = {
    best_spline = v3.best_spline,
    closest_point = v1.closest_point
}
local dot, sub, flatten, cross = v1.dot, v1.sub, v1.flatten, v1.cross
local normalize, angle, inverse_point = v1.normalize, v1.angle, v1.inverse_point

function t1.qualify(p1, p2, p3, p4) -- line: 38
    -- upvalues: rt (copy), import (copy), v2 (copy), dot (copy), sub (copy), flatten (copy), cross (copy), normalize (copy), angle (copy), inverse_point (copy)
    local Record = import("skate_core/player/offboard/grab_scene").Record
    local v4 = Record.scalar(p1, 176)
    local margin = p4.margin

    if v4 * 0.5 < margin then
        margin = v4 * 0.5
    end

    local v5 = rt.fmin(rt.fmax(v2.nearest_distance(p1, p2), margin), v4 - margin)
    local v6 = v2.at_distance(p1, v5)
    local v7 = Record.endpoints(p1)
    local v8 = sub(v7[1], v7[2])
    local v9 = rt.copy(p3.frame[3])
    local v11 = math.abs((dot(normalize(flatten(rt.copy(v9))), normalize(flatten(rt.copy(v8))))))
    local v12 = normalize(cross({ 0, 1, 0, 0 }, v8))
    local v13 = Record.vector(p1, 96)
    local v14 = dot(v12, v13)

    if math.abs(v14) <= 0.1 or dot(v9, v12) * v14 >= 0 or not (v11 < 0.8) then
        return false
    end

    local v15 = flatten(sub(v6, p2))

    if not (dot(v15, v15) > 0) or not (p4.angle_a > angle(v15, {
        -v13[1],
        -v13[2],
        -v13[3],
        -v13[4]
    })) then
        return false
    end

    local v16 = v4 * 0.5

    if v16 > 0.009999999776482582 then
        v16 = 0.009999999776482582
    end

    local v17 = if v4 < v5 + v16 then v5 - v16 else v5 + v16
    local v18 = sub(v2.at_distance(p1, v17), v6)
    local v19 = flatten(rt.copy(v18))

    if not (dot(v19, v19) > 1.52587890625E-05) then
        return false
    end

    local v20 = angle(v18, v19) * 0.15915493667125702
    local v21 = v20 - math.floor(v20)
    local v23 = math.abs((v21 - (if v21 > 0.5 then 1 else 0)) * 6.2831854820251465)

    if v23 > 1.5707963705062866 then
        v23 = 3.1415927410125732 - v23
    end

    if v23 < p4.angle_b then
        local v24 = inverse_point(p3.frame, v6)

        for i = 0, 2 do
            if not (v24[i + 1] >= -p3.extents[i + 1] and v24[i + 1] <= p3.extents[i + 1]) then
                return false
            end
        end

        return true
    end

    return false
end

return t1
