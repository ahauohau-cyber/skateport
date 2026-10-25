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
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local v2 = import("skate_core/physics/board_probes")
local BoardProbeState = v2.BoardProbeState
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local t1 = {}
local hit

local function map_from_bits(p2) -- line: 34
    -- upvalues: v1 (copy)
    local v3 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v3[i] = buffer.readf32(v1, 0)
    end

    return v3
end

t1.BoardProbes = {}
t1.Pending = {}

function t1.BoardProbes.default() -- line: 52
    -- upvalues: BoardProbeState (copy)
    return {
        wall_line = nil,
        pending = nil,
        deck = BoardProbeState.default(),
        wall = BoardProbeState.default()
    }
end

function t1.BoardProbes.reset_results(p3) -- line: 64
    -- upvalues: BoardProbeState (copy)
    p3.deck = BoardProbeState.default()
    p3.wall = BoardProbeState.default()
end

function t1.BoardProbes.wall_contact_frame(p4, p5, p6) -- line: 70
    local function v(p7) -- line: 71
        return {
            p7.x,
            p7.y,
            p7.z,
            0
        }
    end

    local start = p4.wall.start
    local t2 = {}

    t2.vector_8032 = {
        start.x,
        start.y,
        start.z,
        0
    }

    local point = p4.wall.point

    t2.vector_8048 = {
        point.x,
        point.y,
        point.z,
        0
    }

    local normal = p4.wall.normal

    t2.vector_8064 = {
        normal.x,
        normal.y,
        normal.z,
        0
    }
    t2.word_8080 = p4.wall.surface_tag
    t2.flag_8084 = p4.wall.hit
    t2.scalar_2752 = p5
    t2.scalar_2756 = p6

    return t2
end

function t1.BoardProbes.prepare_wall(p8, p9, p10) -- line: 90
    -- upvalues: v1 (copy), Vector3 (copy), v2 (copy)
    local function vector(p11) -- line: 91
        -- upvalues: Vector3 (copy)
        return Vector3.new(p11[1], p11[2], p11[3])
    end

    local wall_probe = v2.wall_probe
    local t3 = {
        state = p9.state_2508
    }
    local v5 = p9.vectors_464_480_496_512_528[1]
    local v6 = table.create(#v5)

    for i = 1, #v5 do
        buffer.writeu32(v1, 0, v5[i])
        v6[i] = buffer.readf32(v1, 0)
    end

    t3.contact_normal = Vector3.new(v6[1], v6[2], v6[3])

    local v8 = p9.vectors_544_560_592_608[1]
    local v9 = table.create(#v8)

    for i = 1, #v8 do
        buffer.writeu32(v1, 0, v8[i])
        v9[i] = buffer.readf32(v1, 0)
    end

    t3.skater_up = Vector3.new(v9[1], v9[2], v9[3])

    local v11 = p10.deck[4]

    t3.deck_position = Vector3.new(v11[1], v11[2], v11[3])
    t3.time = p9.time_on_ground_2752
    p8.wall_line = wall_probe(t3)
end

function t1.BoardProbes.start(p12, p13, p14) -- line: 104
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy), v2 (copy), BoardProbeState (copy), BoardRuntime (copy), BoardWorld (copy), hit (ref)
    if p12.pending ~= nil then
        error("Board probes submitted twice without publication", 0)
    end

    local v12 = v2.deck_probe(Vector3.new(BoardRuntime.part_translation(p13, BodyId.index(BodyId.Deck))))

    BoardProbeState.start(p12.deck, v12.start)

    local query_swept_line = BoardWorld.query_swept_line
    local start, v13 = v12.start, v12["end"]
    local DECK_PROBE_RADIUS = v2.DECK_PROBE_RADIUS
    local ok, result = pcall(query_swept_line, p14, start, v13, DECK_PROBE_RADIUS)

    if not ok then
        error(string.format("Stock deck ground probe: %s", (tostring(result))), 0)
    end

    if result ~= nil then
        result = hit(result)
    end

    local v14 = rt.copy(p12.wall_line)
    local t4

    if v14 ~= nil then
        BoardProbeState.start(p12.wall, v14.start)

        local query_thin_line = BoardWorld.query_thin_line
        local start, v15 = v14.start, v14["end"]
        local ok, result = pcall(query_thin_line, p14, start, v15)

        if not ok then
            error(string.format("Stock wall floor probe: %s", (tostring(result))), 0)
        end

        if result ~= nil then
            result = hit(result)
        end

        t4 = {
            tag = "Some",
            result
        }
    else
        BoardProbeState.disable(p12.wall)
    end

    p12.pending = {
        deck = result,
        wall = t4
    }
end

function t1.BoardProbes.publish(p15) -- line: 153
    -- upvalues: BoardProbeState (copy)
    local pending = p15.pending

    p15.pending = nil

    if pending == nil then
        error("Board probe publication requires a submitted batch", 0)
    end

    BoardProbeState.publish(p15.deck, pending.deck)

    if pending.wall ~= nil then
        BoardProbeState.publish(p15.wall, pending.wall[1])
    else
        BoardProbeState.disable(p15.wall)
    end
end

function hit(p16) -- line: 168
    -- upvalues: rt (copy)
    return {
        point = rt.copy(p16.geometry.position),
        normal = rt.copy(p16.geometry.normal),
        surface_tag = p16.tag
    }
end

t1.hit = hit

return t1
