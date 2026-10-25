-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/player/offboard/grab_scene/record")
local v3 = import("skate_core/player/offboard/grab_scene/registry")
local v4 = import("skate_core/player/offboard/grab_scene/query")

import("skate_core/player/offboard/grab_scene/math")

local v5 = import("skate_core/player/offboard/grab_scene/qualify")
local t1 = {
    qualify = v5.qualify,
    closest_point = v5.closest_point,
    best_spline = v5.best_spline,
    query = v4.query,
    AssemblyData = v2.AssemblyData,
    Geometry = v2.Geometry,
    RecordInput = v2.RecordInput,
    Object = v3.Object,
    Provider = v3.Provider,
    Registry = v3.Registry,
    Spline = v3.Spline,
    Descriptor = {}
}

function t1.Descriptor.eq(p2, p3) -- line: 48
    if p2.kind == p3.kind then
        return p2.id == p3.id
    end

    return false
end

t1.Record = {}

function t1.Record.eq(p4, p5) -- line: 59
    for i = 1, 72 do
        if p4[1][i] ~= p5[1][i] then
            return false
        end
    end

    local v6 = p4[2]
    local v7 = p5[2]

    if v6 ~= v7 then
        if v6.id ~= v7.id or v6.word_60 ~= v7.word_60 or #v6.points ~= #v7.points or #v6.approach_vectors ~= #v7.approach_vectors then
            return false
        end

        for i = 1, #v6.points do
            for j = 1, 4 do
                if v6.points[i][j] ~= v7.points[i][j] then
                    return false
                end
            end
        end

        for i = 1, #v6.approach_vectors do
            for j = 1, 4 do
                if v6.approach_vectors[i][j] ~= v7.approach_vectors[i][j] then
                    return false
                end
            end
        end
    end

    return true
end

function t1.Record.descriptor(p6) -- line: 92
    return {
        kind = p6[1][48],
        id = p6[1][49]
    }
end

function t1.Record.endpoints(p7) -- line: 97
    -- upvalues: t1 (copy)
    return {
        t1.Record.vector(p7, 64),
        t1.Record.vector(p7, 80)
    }
end

function t1.Record.assembly(p8) -- line: 102
    return if p8[1][53] ~= 0 then p8[1][53] else nil
end

function t1.Record.valid(p9) -- line: 110
    return p9[1][50] ~= 0
end

function t1.Record.points(p10) -- line: 115
    return p10[2].points
end

function t1.Record.vector(p11, p12) -- line: 119
    -- upvalues: rt (copy), v1 (copy)
    local v8 = p11[1]
    local v9 = rt.idiv(p12, 4)

    buffer.writeu32(v1, 0, v8[v9 + 1])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[v9 + 2])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[v9 + 3])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[v9 + 4])

    return {
        v11,
        v13,
        v15,
        (buffer.readf32(v1, 0))
    }
end

function t1.Record.scalar(p13, p14) -- line: 130
    -- upvalues: rt (copy), v1 (copy)
    buffer.writeu32(v1, 0, p13[1][rt.idiv(p14, 4) + 1])

    return (buffer.readf32(v1, 0))
end

function t1.Record.byte(p15, p16) -- line: 134
    -- upvalues: rt (copy)
    return (bit32.band(bit32.rshift(p15[1][rt.idiv(p16, 4) + 1], (3 - rt.irem(p16, 4)) * 8), 255))
end

for v21, v22 in v2.Record do
    t1.Record[v21] = v22
end

t1.Query = {}
t1.Line = {}
t1.Hit = {}

function t1.Hit.eq(p17, p18) -- line: 164
    if p17.fraction == p18.fraction then
        return p17.assembly == p18.assembly
    end

    return false
end

return t1
