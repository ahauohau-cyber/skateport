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

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local import = require(sim.import)
local v2 = import("skate_core/point_graph")
local v3 = import("skate_data/collections")
local PointGraph = v2.PointGraph
local Collections = v3.Collections
local t1 = {}

t1.Settings = {}

function t1.Settings.load(p3) -- line: 30
    -- upvalues: v1 (copy), Collections (copy)
    local Hash_E0C1407B688858AD = Collections.words(p3, 20, "anim_motion", "Hash_41DB0C4F82003A15", "Hash_E0C1407B688858AD")

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[1])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[3])

    local v7 = buffer.readf32(v1, 0)

    if v5 ~= v5
        or v5 == 1e999
        or v5 == (-1e999)
        or v7 ~= v7
        or v7 == 1e999
        or v7 == (-1e999)
        or v7 < v5 then
        error("FingerFlipOut has invalid stock timer bounds", 0)
    end

    local t2 = {
        minimum = v5,
        maximum = v7
    }
    local t3 = {}

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[5])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[6])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[7])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[8])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[9])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[10])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[11])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[12])
    t3.x = {
        v9,
        v11,
        v13,
        v15,
        v17,
        v19,
        v21,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[13])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[14])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[15])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[16])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[17])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[18])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[19])

    local v36 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, Hash_E0C1407B688858AD[20])
    t3.y = {
        v24,
        v26,
        v28,
        v30,
        v32,
        v34,
        v36,
        (buffer.readf32(v1, 0))
    }
    t2.curve = t3

    return t2
end

t1.State = {}

function t1.State.default() -- line: 71
    return {
        elapsed = 0
    }
end

function t1.State.begin(p4) -- line: 75
    p4.elapsed = 0
end

function t1.State.update(p5, p6, p7, p8) -- line: 79
    -- upvalues: rt (copy), PointGraph (copy)
    if p6 then
        p5.elapsed -= p7
    else
        p5.elapsed += p7
    end

    p5.elapsed = rt.clamp(p5.elapsed, p8.minimum, p8.maximum)

    return PointGraph.evaluate(p8.curve, p5.elapsed)
end

return t1
