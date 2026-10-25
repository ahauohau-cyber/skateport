-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_game/grind_world/spline")
local v2 = import("skate_game/grind_world/provider")

local function ground() -- line: 16
    -- upvalues: import (copy)
    return import("skate_game/physics/ground")
end

local t1 = {
    GrindGeometry = {},
    GrindGeometryPlugin = {}
}

function t1.GrindGeometry.for_world(p1) -- line: 31
    -- upvalues: t1 (copy)
    if p1 then
        return {
            rails = t1.rails(),
            native_blob = t1.spline_blob()
        }
    end

    return {
        rails = {},
        native_blob = {}
    }
end

t1.Rail = {}

function t1.rails() -- line: 44
    -- upvalues: rt (copy), import (copy), Vector3 (copy)
    local fround = rt.fround
    local v3 = fround(import("skate_game/physics/ground").FLOOR_HEIGHT)
    local v4 = fround(import("skate_game/physics/ground").HEIGHT)
    local new = Vector3.new

    return {
        {
            id = 1,
            name = "low_flat_rail",
            start = new(-7, fround(v3 + fround(0.45)), 7),
            ["end"] = new(-7, fround(v3 + fround(0.45)), 15),
            width = 0.1,
            thickness = 0.1
        },
        {
            id = 2,
            name = "high_flat_rail",
            start = new(4.5, fround(v3 + fround(0.7)), 8),
            ["end"] = new(4.5, fround(v3 + fround(0.7)), 16),
            width = 0.1,
            thickness = 0.1
        },
        {
            id = 3,
            name = "halfpipe_left_coping",
            start = new(7.5, fround(v3 + fround(2.5)), -6),
            ["end"] = new(7.5, fround(v3 + fround(2.5)), 6),
            width = 0.08,
            thickness = 0.08
        },
        {
            id = 4,
            name = "halfpipe_right_coping",
            start = new(16.5, fround(v3 + fround(2.5)), -6),
            ["end"] = new(16.5, fround(v3 + fround(2.5)), 6),
            width = 0.08,
            thickness = 0.08
        },
        {
            id = 5,
            name = "platform_back_edge",
            start = new(-3, v4, -4),
            ["end"] = new(3, v4, -4),
            width = 0,
            thickness = 0
        },
        {
            id = 6,
            name = "platform_right_edge",
            start = new(3, v4, -4),
            ["end"] = new(3, v4, 4),
            width = 0,
            thickness = 0
        },
        {
            id = 7,
            name = "platform_left_edge",
            start = new(-3, v4, 4),
            ["end"] = new(-3, v4, -4),
            width = 0,
            thickness = 0
        }
    }
end

local box_faces

function t1.surfaces() -- line: 116
    -- upvalues: import (copy), Vector3 (copy), t1 (copy), box_faces (ref)
    local t2 = {}
    local FLOOR_HEIGHT = import("skate_game/physics/ground").FLOOR_HEIGHT

    for _, v5 in t1.rails() do
        if v5.width ~= 0 then
            local x, y = v5.start.x, v5.start.y

            box_faces(t2, Vector3.new(x - v5.width * 0.5, y - v5.thickness, v5.start.z), Vector3.new(x + v5.width * 0.5, y, v5["end"].z))

            if v5.id <= 2 then
                for _, v6 in {
                        v5.start.z + 0.6,
                        v5["end"].z - 0.6
                    } do
                    box_faces(t2, Vector3.new(x - 0.04, FLOOR_HEIGHT, v6 - 0.04), Vector3.new(x + 0.04, y - v5.thickness, v6 + 0.04))
                end
            end
        end
    end

    return t2
end

function box_faces(p2, p3, p4) -- line: 145
    -- upvalues: rt (copy), Vector3 (copy)
    local new = Vector3.new
    local t3 = {
        new(p3.x, p4.y, p3.z),
        new(p4.x, p4.y, p3.z),
        new(p4.x, p4.y, p4.z),
        new(p3.x, p4.y, p4.z)
    }

    table.insert(p2, rt.copy(t3))

    for i = 0, 3 do
        local v7 = t3[i + 1]
        local v8 = t3[rt.irem(i + 1, 4) + 1]

        table.insert(p2, {
            rt.copy(v8),
            rt.copy(v7),
            new(v7.x, p3.y, v7.z),
            new(v8.x, p3.y, v8.z)
        })
    end

    table.insert(p2, {
        new(p3.x, p3.y, p4.z),
        new(p4.x, p3.y, p4.z),
        new(p4.x, p3.y, p3.z),
        new(p3.x, p3.y, p3.z)
    })
end

t1.box_faces = box_faces
t1.StaticProvider = v2.StaticProvider

function t1.spline_blob() -- line: 171
    -- upvalues: v1 (copy), t1 (copy)
    local build_rails = v1.build_rails
    local test_rails = t1.test_rails
    local ok, result = pcall(build_rails, test_rails())

    if not ok then
        error(("authored course splines: %*"):format(result), 0)
    end

    return result
end

function t1.test_rails() -- line: 180
    -- upvalues: t1 (copy)
    local t6 = {}

    for _, v9 in t1.rails() do
        table.insert(t6, {
            closed = false,
            native = nil,
            name = v9.name,
            points = {
                {
                    v9.start.x,
                    v9.start.y,
                    v9.start.z
                },
                {
                    v9["end"].x,
                    v9["end"].y,
                    v9["end"].z
                }
            }
        })
    end

    return t6
end

return t1
