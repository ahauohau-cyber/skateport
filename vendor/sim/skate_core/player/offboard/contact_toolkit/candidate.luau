-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/analyzer_math")
local v2

local function toolkit() -- line: 11
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2
end

local function dot(p1, p2) -- line: 17
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.dot(p1, p2)
end

local function length(p3) -- line: 20
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.length(p3)
end

local function sub(p4, p5) -- line: 23
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.sub(p4, p5)
end

local intersection, madd, tangent = v1.intersection, v1.madd, v1.tangent
local t1 = {
    Candidate = {}
}

function t1.Candidate.default() -- line: 41
    -- upvalues: rt (copy), import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v3 = v2

    return {
        flags = 0,
        low = 0,
        high = 0,
        order = 0,
        segment = 0,
        kind = 0,
        position = rt.copy(v3.ZERO),
        normal = rt.copy(v3.UP),
        direction = rt.copy(v3.ZERO)
    }
end

t1.Builder = {}

local Builder = t1.Builder

function t1.Builder.add(p6, p7, p8, p9, p10, p11, p12) -- line: 60
    -- upvalues: rt (copy), import (copy), v2 (ref)
    local forward, position = p6.input.forward, p6.input.position

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v4 = v2.sub(p7, position)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v5 = v2.dot(forward, v4)
    local t2 = {
        position = rt.copy(p7),
        normal = rt.copy(p8),
        direction = rt.copy(p9),
        segment = p10,
        flags = p11,
        kind = p12,
        order = v5,
        low = v5,
        high = v5
    }

    if p10 < 0 then
        t2.low = 0
    else
        local v6 = p6.profile.segments[p10 + 1]

        if v6.kind ~= 0 then
            local v7 = if v6.kind == 2 then v6.start else v6["end"]
            local forward, position = p6.input.forward, p6.input.position

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v8 = v2.sub(v7, position)

            if v2 == nil then
                v2 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v9 = v2.dot(forward, v8)

            if v5 <= v9 then
                t2.high = v9
            else
                t2.low = v9
            end
        end
    end

    table.insert(p6.candidates, t2)
end

function t1.Builder.point(p13, p14, p15, p16, p17, p18) -- line: 90
    -- upvalues: import (copy), v2 (ref), Builder (copy)
    local position = p13.input.position

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v10 = v2.sub(p14, position)
    local add = Builder.add

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    if not (v2.length(v10) >= 0.02) then
        v10 = p13.input.forward
    end

    add(p13, p14, p15, v10, p16, p17, p18)
end

t1.Builder["local"] = function(p19, p20) -- line: 104
    -- upvalues: import (copy), v2 (ref), dot (copy)
    local position = p19.input.position

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v11 = v2.sub(p20, position)
    local forward = p19.input.forward

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return {
        v2.dot(forward, v11),
        dot(p19.input.up, v11)
    }
end

function t1.Builder.approach_up(p21, p22, p23, p24) -- line: 109
    -- upvalues: intersection (copy), madd (copy), Builder (copy)
    local v12 = Builder["local"](p21, p21.profile.segments[p22 + 1]["end"])
    local t3 = {
        -1,
        (-1 - v12[1]) * p24 + v12[2]
    }

    for i = p22 - 1, 0, -1 do
        local v13 = p21.profile.segments[i + 1]
        local v14 = intersection(Builder["local"](p21, v13.start), Builder["local"](p21, v13["end"]), v12, t3)

        if v14 < 0 then
            if i == 0 then
                Builder.point(p21, p21.input.position, p21.input.up, p22, p23, 1)

                return
            end
        elseif v14 <= 1 then
            local v15, v16

            if v13.kind == 0 then
                v15 = madd(v13.direction, v13.length * v14, v13.start)
                v16 = v13.normal
            else
                v15 = v13.start
                v16 = Builder.next_normal(p21, i)
            end

            if Builder["local"](p21, v15)[1] <= 0.75 then
                Builder.point(p21, v15, v16, p22, p23, 1)
            end

            return
        end
    end
end

function t1.Builder.approach_down(p25, p26, p27, p28, p29) -- line: 135
    -- upvalues: intersection (copy), madd (copy), Builder (copy)
    local v17 = if p26 >= 0 then p25.profile.segments[p26 + 1].start else p25.input.position
    local v18 = Builder["local"](p25, v17)
    local t4 = {
        2.8,
        (2.8 - v18[1]) * p28 + v18[2]
    }

    for i = p26 + 1, p25.profile.last_ground - 1 do
        local v19 = p25.profile.segments[i + 1]
        local v20 = intersection(Builder["local"](p25, v19.start), Builder["local"](p25, v19["end"]), v18, t4)

        if v20 >= 0 and v20 <= 1 then
            if v19.kind == 0 then
                Builder.point(p25, madd(v19.direction, v19.length * v20, v19.start), v19.normal, p26, p27, p29)
            elseif Builder["local"](p25, v19["end"])[1] <= p25.obstruction - 0.35 then
                Builder.point(p25, v19["end"], Builder.next_normal(p25, i), p26, p27, p29)
            end

            return
        end
    end
end

function t1.Builder.advance(p30, p31) -- line: 158
    -- upvalues: madd (copy), t1 (copy), Builder (copy)
    local v21 = p30.profile.last_ground - 1
    local v22 = p31

    for i = 0, v21 do
        local v23 = p30.profile.segments[i + 1]

        if v23.kind == 2 then
            v22 += v23.length / t1.down_slope(p30.input, v23.length)
        else
            v22 -= v23.length

            if not (v22 > 0) then
                if v23.kind == 1 then
                    Builder.point(p30, v23["end"], Builder.next_normal(p30, i), i, 0, 9)
                else
                    Builder.point(p30, madd(v23.direction, v22, v23["end"]), v23.normal, i, 0, 9)
                end

                return
            end
        end
    end
end

function t1.Builder.next_normal(p32, p33) -- line: 178
    -- upvalues: rt (copy)
    if p33 == p32.profile.last_ground - 1 then
        return rt.copy(p32.input.up)
    end

    return rt.copy(p32.profile.segments[p33 + 2].normal)
end

local slope

function t1.up_slope(p34, p35) -- line: 188
    -- upvalues: slope (ref)
    local v24, v25

    if p35 > 0.4 then
        v24 = 35
        v25 = 50
    else
        v24 = 15
        v25 = 30
    end

    return slope(p34, v24, v25)
end

function t1.down_slope(p36, p37) -- line: 198
    -- upvalues: slope (ref)
    local v26, v27

    if p37 > 0.4 then
        v26 = 30
        v27 = 50
    else
        v26 = 15
        v27 = 30
    end

    return slope(p36, v26, v27)
end

function t1.slope(p38, p39, p40) -- line: 209
    -- upvalues: rt (copy), import (copy), v2 (ref), tangent (copy)
    local fmin, fmax = rt.fmin, rt.fmax
    local velocity = p38.velocity

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return tangent(((fmin(fmax(v2.length(velocity), 2), 6) - 2) * (p39 - p40) * 0.25 + p40) * 0.017453292)
end

slope = t1.slope

function t1.between_slope(p41, p42, p43) -- line: 215
    -- upvalues: import (copy), v1 (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v29 = v2.sub(p43, p42)
    local forward = p41.forward

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v30 = v2.dot(forward, v29)

    if v30 < 0.001 then
        return 1000
    end

    local v31 = v1.reciprocal(v30)
    local up = p41.up

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v31 * v2.dot(up, v29)
end

return t1
