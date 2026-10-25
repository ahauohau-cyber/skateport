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

local function length(p1) -- line: 17
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.length(p1)
end

local tangent = v1.tangent
local t1 = {
    History = {}
}

function t1.History.default() -- line: 31
    return {
        accepted = 0,
        cursor = 0,
        samples = { 0, 0, 0 }
    }
end

function t1.History.eq(p2, p3) -- line: 36
    if p2.accepted == p3.accepted and p2.samples[1] == p3.samples[1] and p2.samples[2] == p3.samples[2] and p2.samples[3] == p3.samples[3] then
        return p2.cursor == p3.cursor
    end

    return false
end

function t1.History.classify(p4, p5, p6) -- line: 45
    -- upvalues: rt (copy), import (copy), v2 (ref), tangent (copy), t1 (copy)
    local t2 = {
        p6[1],
        0,
        p6[3],
        0
    }

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v3 = v2.length(t2)

    if 0.001 - v3 >= 0 then
        v3 = 0.001
    end

    local v4 = 1 / v3 * p6[2]

    p5.scalar_160 = v4

    local v5 = tangent(0.10471975803375244)
    local v6 = tangent(0.5585053563117981)
    local v7 = math.abs(v4)
    local v8 = if v7 <= v6 then if v7 <= v5 then 0 elseif v4 > 0 then 1 else 3 elseif v4 > 0 then 2 else 4

    if v8 ~= 0 and bit32.band(p5.flags_176, 64) == 0 then
        v8 += 4
    end

    p5.kind_164 = v8

    local samples = p4.samples

    if v8 == 0 then
        rt.assign(p4, t1.History.default())
    elseif samples[1] == v8 and samples[2] == v8 and samples[3] == v8 then
        p4.accepted = v8
    else
        p4.cursor = rt.irem(p4.cursor + 1, 3)
        p4.samples[p4.cursor + 1] = v8
        p5.kind_164 = p4.accepted
    end
end

return t1
