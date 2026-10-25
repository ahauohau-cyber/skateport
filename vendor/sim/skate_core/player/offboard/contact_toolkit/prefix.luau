-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory")
local v2

local function toolkit() -- line: 12
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2
end

local function dot(p1, p2) -- line: 18
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.dot(p1, p2)
end

local function sub(p3, p4) -- line: 21
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.sub(p3, p4)
end

local QueryResult = v1.QueryResult
local t1 = {
    ContactPrefix = {}
}

function t1.ContactPrefix.reset() -- line: 44
    -- upvalues: rt (copy), import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v3 = v2

    return {
        scalar_160 = 0,
        kind_164 = 0,
        distance_168 = 1E+10,
        distance_172 = 1E+10,
        flags_176 = 0,
        support_180 = 0,
        position = rt.copy(v3.ZERO),
        normal = rt.copy(v3.UP),
        support_frame = rt.copy(v3.IDENTITY),
        target_position = rt.copy(v3.ZERO),
        target_normal = rt.copy(v3.UP),
        edge_position = rt.copy(v3.ZERO),
        edge_normal = rt.copy(v3.ZERO)
    }
end

function t1.ContactPrefix.consume_support(p5, p6, p7, p8) -- line: 64
    -- upvalues: rt (copy), import (copy), v2 (ref), QueryResult (copy)
    local v4 = rt.copy(p7[1])

    if QueryResult.valid(v4) then
        p5.position = rt.copy(v4.contact_position)
        p5.normal = rt.copy(v4.landing_normal)
        p5.support_frame = rt.copy(v4.contact_transform)
        p5.flags_176 = bit32.bor(p5.flags_176, 1)

        local up = p6.up
        local contact_position = v4.contact_position
        local position = p6.position

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v5 = v2.sub(contact_position, position)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        if v2.dot(up, v5) < -0.1 then
            p5.flags_176 = bit32.bor(p5.flags_176, 8)

            if bit32.band(p8, 64) ~= 0 then
                p5.flags_176 = bit32.bor(p5.flags_176, 64)
            end
        else
            p5.flags_176 = bit32.band(p5.flags_176, 4294967287)
        end

        p5.support_180 = v4.geometry
    end

    for i = 1, 2 do
        local v6, v7

        if i == 1 then
            v6 = p7[2]
            v7 = 16
        else
            v6 = p7[3]
            v7 = 32
        end

        local contact_position = v6.contact_position
        local position = p6.position

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v8 = v2.sub(contact_position, position)
        local up = p6.up

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v9 = v2.dot(v8, up)

        if QueryResult.valid(v6) and v9 < 0.2 and v9 > -0.2 then
            p5.flags_176 = bit32.bor(p5.flags_176, v7)

            if QueryResult.valid(v4) and v6.landing_normal[2] > p5.normal[2] then
                p5.normal = rt.copy(v6.landing_normal)
            end
        end
    end
end

function t1.ContactPrefix.default() -- line: 99
    -- upvalues: t1 (copy)
    return t1.ContactPrefix.reset()
end

return t1
