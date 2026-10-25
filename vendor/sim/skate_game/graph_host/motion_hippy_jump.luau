-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local PointGraph = import("skate_core/point_graph").PointGraph
local Collections = import("skate_data/collections").Collections
local v2

local function motion_animation() -- line: 33
    -- upvalues: import (copy), v2 (ref)
    local v3 = v2

    if v3 == nil then
        v3 = import("skate_game/graph_host/motion_animation")
        v2 = v3
    end

    return v3
end

local t1 = {
    Settings = {}
}

function t1.Settings.load(p2) -- line: 48
    -- upvalues: v1 (copy), Collections (copy)
    local v4 = Collections.words(p2, "anim_motion", "hippy_flip", "antic_length_to_hippy_height", 20)
    local t2 = {}
    local t3 = {}

    buffer.writeu32(v1, 0, v4[5])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[6])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[7])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[8])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[9])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[10])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[11])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[12])
    t3.x = {
        v6,
        v8,
        v10,
        v12,
        v14,
        v16,
        v18,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v4[13])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[14])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[15])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[16])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[17])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[18])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[19])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[20])
    t3.y = {
        v21,
        v23,
        v25,
        v27,
        v29,
        v31,
        v33,
        (buffer.readf32(v1, 0))
    }
    t2.antic_length_to_hippy_height = t3

    return t2
end

t1.State = {}

function t1.State.default() -- line: 79
    return {
        active = false,
        elapsed = 0
    }
end

function t1.State.begin(p3) -- line: 83
    p3.active = true
    p3.elapsed = 0
end

function t1.State.update(p4, p5, p6) -- line: 89
    -- upvalues: import (copy), encode (copy), PointGraph (copy), v2 (ref)
    if not p4.active then
        error("assertion failed: self.active", 0)
    end

    p4.elapsed += 0.016666666666666666

    local v35 = v2

    if v35 == nil then
        v35 = import("skate_game/graph_host/motion_animation")
        v2 = v35
    end

    v35.MotionAnimation.set_attribute(p5, {
        normalized = false,
        sequence_id = -1,
        name = encode("TrickHeight"),
        value = PointGraph.evaluate(p6.antic_length_to_hippy_height, p4.elapsed)
    })
end

t1.State["end"] = function(p7) -- line: 102
    p7.active = false
    p7.elapsed = 0
end

return t1
