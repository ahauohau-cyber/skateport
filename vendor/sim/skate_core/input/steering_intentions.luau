-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/input/angle")
local v2 = import("skate_core/input/controller")
local left_stick_angle = v1.left_stick_angle
local magnitude = v2.magnitude
local t1 = {}

t1.SteeringIntentions = {}

function t1.SteeringIntentions.eq(p1, p2) -- line: 25
    if p1.turn == p2.turn and p1.hard_turn == p2.hard_turn then
        return p1.hard_turn_crouch == p2.hard_turn_crouch
    end

    return false
end

function t1.produce(p3, p4) -- line: 32
    -- upvalues: left_stick_angle (copy), magnitude (copy)
    local v3 = p3[1]
    local v4 = p3[2]
    local v5 = left_stick_angle(v3, v4)
    local v6 = math.abs(v5)
    local v7 = if v3 ~= 0 or v4 ~= 0 then magnitude(v4 * v4 + v3 * v3) else 0
    local v8 = if v3 >= 0 then v7 else -v7

    if v4 > 0 then
        if v6 > 3.049999952316284 then
            v8 = 0
        elseif v6 > 2.3499999046325684 then
            v8 = (3.049999952316284 - v6) * 1.428571343421936 * v8
        end
    else
        v8 = v3
    end

    local v9 = v7 > 0.8999999761581421 and not (v6 > 1.3899999856948853) and not (v6 < 0.9100000262260437)
    local v10 = (v6 - 1.3899999856948853) * -2.0833334922790527

    if not (v10 - 0.0010000000474974513 >= 0) then
        v10 = 0.0010000000474974513
    end

    if not (v5 >= 0) then
        v10 = -v10
    end

    local v11 = bit32.band(p4, 1) == 0
    local t2 = {}

    if v8 ~= 0 and v11 then
        t2.turn = v8
    end

    if v9 then
        if v11 then
            t2.hard_turn = v10
        end

        if v11 then
            t2.hard_turn_crouch = math.abs(v10 * 0.8500000238418579)
        end
    end

    return t2
end

return t1
