-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local Trajectory = import("skate_core/air/trajectory").Trajectory

local function air_selector() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector")
end

local t1 = {
    add = v1.add,
    cross = v1.cross,
    dot = v1.dot,
    length = v1.length,
    madd = v1.madd,
    normalize = v1.normalize,
    normalize_or = v1.normalize_or,
    reciprocal = v1.reciprocal,
    scale = v1.scale,
    sub = v1.sub,
    wrap_angle = v1.wrap_angle
}
local dot, length, madd, reciprocal = t1.dot, t1.length, t1.madd, t1.reciprocal
local scale = t1.scale

t1.UP = { 0, 1, 0, 0 }

function t1.flatten(p1) -- line: 38
    -- upvalues: rt (copy)
    local v2 = rt.copy(p1)

    v2[2] = 0

    return v2
end

function t1.shift(p2, p3) -- line: 44
    -- upvalues: Trajectory (copy)
    local v3 = Trajectory.position_at(p2, p3)

    p2.velocity = Trajectory.velocity_at(p2, p3)
    p2.position = v3
end

function t1.adjust(p4, p5, p6, p7) -- line: 51
    -- upvalues: import (copy), dot (copy), length (copy), madd (copy), reciprocal (copy), scale (copy)
    if p5 <= 0 then
        return
    end

    local v4 = scale(p6, reciprocal(p5 * import("skate_core/player/offboard/air_selector").DT))

    p4.velocity = madd(v4, if dot(v4, v4) > p7 * p7 then p7 / length(v4) else 1, p4.velocity)
end

return t1
