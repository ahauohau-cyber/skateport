-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local TriangleFeature = import("skate_core/physics/collision").TriangleFeature
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local triangle_from_volume = import("skate_core/physics/world_contact").triangle_from_volume
local v1 = import("skate_game/grind_world")
local t1 = {
    HEIGHT = -0.035,
    Terrain = {}
}

function t1.Terrain.surfaces(p1) -- line: 32
    -- upvalues: t1 (copy)
    if p1 == "Flat" then
        return t1.flat_surfaces()
    end

    if p1 == "Course" then
        return t1.surfaces()
    end

    error("unreachable Terrain variant " .. tostring(p1), 0)
end

function t1.Terrain.world(p2, p3) -- line: 41
    -- upvalues: t1 (copy)
    if p2 == "Flat" then
        return t1.flat_world(p3)
    end

    if p2 == "Course" then
        return t1.world(p3)
    end

    error("unreachable Terrain variant " .. tostring(p2), 0)
end

t1.FLOOR_HEIGHT = t1.HEIGHT - 1.5

local HEIGHT, FLOOR_HEIGHT = t1.HEIGHT, t1.FLOOR_HEIGHT

function t1.surfaces() -- line: 61
    -- upvalues: rt (copy), Vector3 (copy), v1 (copy), HEIGHT (copy), FLOOR_HEIGHT (copy)
    local new = Vector3.new
    local t2 = {
        {
            new(-50, FLOOR_HEIGHT, -50),
            new(50, FLOOR_HEIGHT, -50),
            new(50, FLOOR_HEIGHT, 50),
            new(-50, FLOOR_HEIGHT, 50)
        }
    }
    local t3 = {
        new(-3, HEIGHT, -4),
        new(3, HEIGHT, -4),
        new(3, HEIGHT, 4),
        new(-3, HEIGHT, 4)
    }
    local t4 = { rt.copy(t3) }

    for _, v2 in { 0, 1, 3 } do
        local v3 = t3[v2 + 1]
        local v4 = t3[(v2 + 1) % 4 + 1]

        table.insert(t4, {
            rt.copy(v4),
            rt.copy(v3),
            new(v3.x, FLOOR_HEIGHT, v3.z),
            new(v4.x, FLOOR_HEIGHT, v4.z)
        })
    end

    local function ramp_point(p4) -- line: 90
        -- upvalues: HEIGHT (copy), FLOOR_HEIGHT (copy)
        local v5 = p4 / 48
        local v6 = v5 * v5 * (3 - v5 * 2)

        return v5 * 12 + 4, HEIGHT + (FLOOR_HEIGHT - HEIGHT) * v6
    end

    for i = 0, 47 do
        local v7 = i / 48
        local v8 = v7 * v7 * (3 - v7 * 2)
        local v9 = v7 * 12 + 4
        local v10 = HEIGHT + (FLOOR_HEIGHT - HEIGHT) * v8
        local v11 = (i + 1) / 48
        local v12 = v11 * v11 * (3 - v11 * 2)
        local v13 = v11 * 12 + 4
        local v14 = HEIGHT + (FLOOR_HEIGHT - HEIGHT) * v12

        table.insert(t4, {
            new(-3, v10, v9),
            new(3, v10, v9),
            new(3, v14, v13),
            new(-3, v14, v13)
        })
    end

    for _, v15 in v1.surfaces() do
        table.insert(t4, v15)
    end

    local t7 = {}

    for i = 32, 0, -1 do
        local v16 = 1.5707963267948966 * i / 32

        table.insert(t7, {
            10 - math.sin(v16) * 2.5,
            FLOOR_HEIGHT + (1 - math.cos(v16)) * 2.5
        })
    end

    for i = 0, 32 do
        local v17 = 1.5707963267948966 * i / 32

        table.insert(t7, {
            math.sin(v17) * 2.5 + 14,
            FLOOR_HEIGHT + (1 - math.cos(v17)) * 2.5
        })
    end

    local t10 = {}

    for i = 1, #t7 - 1 do
        local v18 = t7[i][1]
        local v19 = t7[i][2]
        local v20 = t7[i + 1][1]
        local v21 = t7[i + 1][2]

        if v19 ~= FLOOR_HEIGHT or v21 ~= FLOOR_HEIGHT then
            table.insert(t10, {
                new(v18, v19, -6),
                new(v20, v21, -6),
                new(v20, v21, 6),
                new(v18, v19, 6)
            })
        end
    end

    for _, v22 in {
            { 6.5, 7.5 },
            { 16.5, 17.5 }
        } do
        local v23 = v22[1]
        local v24 = v22[2]
        local v25 = FLOOR_HEIGHT + 2.5

        table.insert(t10, {
            new(v23, v25, -6),
            new(v24, v25, -6),
            new(v24, v25, 6),
            new(v23, v25, 6)
        })
    end

    local t13 = {
        new(-9, FLOOR_HEIGHT + 2.2, -2),
        new(-5, FLOOR_HEIGHT + 2.2, -2),
        new(-5, FLOOR_HEIGHT + 2.2, 2),
        new(-9, FLOOR_HEIGHT + 2.2, 2)
    }
    local t14 = { rt.copy(t13) }

    for i = 0, 3 do
        local v26 = t13[i + 1]
        local v27 = t13[(i + 1) % 4 + 1]

        table.insert(t14, {
            rt.copy(v27),
            rt.copy(v26),
            new(v26.x, FLOOR_HEIGHT, v26.z),
            new(v27.x, FLOOR_HEIGHT, v27.z)
        })
    end

    return { t2, t4, t10, t14 }
end

function t1.world(p5) -- line: 165
    -- upvalues: t1 (copy)
    return t1.build_world(p5, t1.surfaces(), t1.query_edges())
end

function t1.flat_surfaces() -- line: 173
    -- upvalues: Vector3 (copy), HEIGHT (copy)
    local new = Vector3.new

    return {
        {
            {
                new(-50, HEIGHT, -50),
                new(50, HEIGHT, -50),
                new(50, HEIGHT, 50),
                new(-50, HEIGHT, 50)
            }
        },
        {},
        {},
        {}
    }
end

function t1.flat_world(p6) -- line: 191
    -- upvalues: t1 (copy)
    return t1.build_world(p6, t1.flat_surfaces(), {})
end

local function quad_eq(p7, p8) -- line: 196
    -- upvalues: Vector3 (copy)
    for i = 1, 4 do
        if not Vector3.eq(p7[i], p8[i]) then
            return false
        end
    end

    return true
end

function t1.build_world(p9, p10, p11) -- line: 206
    -- upvalues: rt (copy), BoardWorld (copy), Bounds (copy), TriangleFeature (copy), RetailAffineTransform (copy), triangle_from_volume (copy), v1 (copy), quad_eq (copy)
    local t16 = {}
    local v28 = v1.surfaces()
    local t17 = {
        { 0, 2, 1 },
        { 0, 3, 2 }
    }

    for i = 0, #p10 - 1 do
        for _, v29 in p10[i + 1] do
            local v30 = false

            for _, v31 in v28 do
                if quad_eq(v31, v29) then
                    v30 = true
                    break
                end
            end

            for j = 0, 1 do
                local v32 = t17[j + 1]
                local v33 = if not v30 then 0 elseif j == 0 then 96 else 192

                table.insert(t16, {
                    triangle = triangle_from_volume({
                        rt.copy(v29[v32[1] + 1]),
                        rt.copy(v29[v32[2] + 1]),
                        rt.copy(v29[v32[3] + 1])
                    }, 0, {
                        1, 1, 1
                    }, (bit32.bor(TriangleFeature.ONE_SIDED, v33))),
                    material = rt.copy(p9),
                    tag = i
                })
            end
        end
    end

    local t21 = {}

    for _, v34 in t16 do
        for _, v35 in v34.triangle.vertices do
            table.insert(t21, v35)
        end
    end

    local v36 = Bounds.from_points(t21)

    if v36 == nil then
        error("Authored level contains collision triangles", 0)
    end

    local t22 = {
        island_flags = 0,
        packed_surfaces = rt.filled(#t16, 0),
        meshes = {
            {
                matching_group = -1,
                rejection_flags = 0,
                geometry = 1,
                pool = "Ground",
                triangle_range = {
                    start = 0,
                    ["end"] = #t16
                },
                local_to_world = rt.copy(RetailAffineTransform.IDENTITY),
                world_to_local = rt.copy(RetailAffineTransform.IDENTITY),
                local_bounds = v36
            }
        },
        static_edges = p11
    }
    local with_query_metadata = BoardWorld.with_query_metadata
    local ok, result = pcall(with_query_metadata, t16, t22)

    if not ok then
        error(("Authored level query metadata matches its collision geometry: %*"):format(result), 0)
    end

    return result
end

function t1.query_edges() -- line: 291
    -- upvalues: rt (copy), Vector3 (copy), Bounds (copy), HEIGHT (copy), FLOOR_HEIGHT (copy)
    local new = Vector3.new
    local t23 = {
        new(-3, HEIGHT, -4),
        new(3, HEIGHT, -4),
        new(3, HEIGHT, 4),
        new(-3, HEIGHT, 4)
    }
    local t24 = {}

    for _, v37 in { 0, 1, 3 } do
        table.insert(t24, {
            rt.copy(t23[v37 + 1]),
            rt.copy(t23[(v37 + 1) % 4 + 1])
        })
    end

    local v38 = FLOOR_HEIGHT + 2.5

    for _, v39 in { 7.5, 16.5 } do
        table.insert(t24, {
            new(v39, v38, -6),
            new(v39, v38, 6)
        })
    end

    local t27 = {}

    for _, v40 in t24 do
        local v41 = v40[1]
        local v42 = v40[2]
        local v43 = Bounds.from_points({ v41, v42 })

        if v43 == nil then
            error("Two authored edge endpoints", 0)
        end

        table.insert(t27, {
            start = v41,
            ["end"] = v42,
            local_bounds = v43
        })
    end

    return t27
end

function t1.query_settings() -- line: 324
    return {
        volume_padding = 0.05,
        maximum_separating_distance = 0.5,
        edge_cos_bend_normal_threshold = 0.999,
        convexity_epsilon = 0.01,
        is_object = false
    }, {
        capacity = 4294967295,
        duplicate_distance_squared = -1,
        deferred_reduction = true
    }
end

return t1
