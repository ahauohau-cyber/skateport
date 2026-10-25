-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)

local function recovered() -- line: 8
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local t1 = {
    dot = function(p1, p2) -- dot | line: 17
        return p1[3] * p2[3] + (p1[2] * p2[2] + p1[1] * p2[1])
    end,
    sub = function(p3, p4) -- sub | line: 21
        return {
            p3[1] - p4[1],
            p3[2] - p4[2],
            p3[3] - p4[3],
            p3[4] - p4[4]
        }
    end,
    madd = function(p5, p6, p7) -- madd | line: 25
        return {
            p5[1] * p6 + p7[1],
            p5[2] * p6 + p7[2],
            p5[3] * p6 + p7[3],
            p5[4] * p6 + p7[4]
        }
    end,
    select = function(p8, p9, p10) -- select | line: 29
        if p8 >= 0 then
            return p9
        end

        return p10
    end
}
local dot, sub, madd, select = t1.dot, t1.sub, t1.madd, t1.select

function t1.projected_height(p11, p12, p13, p14) -- line: 40
    -- upvalues: dot (copy), sub (copy), select (copy)
    local v1 = dot(p14, sub(p11, p13))
    local v2 = dot(p14, sub(p12, p13))

    return select(v1 - v2, v2, v1)
end

t1.HeightInput = {}
t1.State = {}

function t1.State.correct_height(p15, p16) -- line: 58
    -- upvalues: import (copy), t1 (copy), dot (copy), sub (copy), madd (copy), select (copy)
    local DT = import("skate_core/player/offboard/biped_air/recovered").DT
    local v3 = t1.projected_height(p16.bone15, p16.bone19, p15.result.position_272, p16.up_544)
    local v5 = math.abs(dot(p16.up_544, p16.velocity_608) * DT) + 0.05
    local v6 = v3 + 0.79 - p15.height_432
    local v7 = select(-v5 - v6, -v5, v6)

    p15.height_432 += select(v5 - v7, v7, v5)
    p15.body_target_416 = madd(p16.up_544, p15.height_432, p15.result.position_272)

    local v8 = madd(p15.result.velocity_288, DT, p16.bone1)

    p15.body_offset_436 = dot(sub(madd(p16.up_544, -0.4, v8), p15.body_target_416), p16.up_544)
end

return t1
