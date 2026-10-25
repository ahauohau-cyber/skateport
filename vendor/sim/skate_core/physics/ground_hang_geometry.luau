-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/board_motion_output")
local dot, inverse_length_squared = v1.dot, v1.inverse_length_squared
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local Vector3 = import("skate_core/math").Vector3
local t1 = {
    HangGeometryInput = {},
    HangLine = {}
}

function t1.hang_lines(p1, p2) -- line: 28
    -- upvalues: dot (copy), Vector3 (copy), t1 (copy)
    local v2 = t1.sub(p1.edge_end, p1.edge_start)
    local v3 = t1.cross(Vector3.new(0, 1, 0), v2)
    local v4 = t1.cross(v2, v3)
    local v5, v6 = t1.normalize_or_retain(v4)
    local v7 = t1.normalize_or_retain(v2)

    if v6 < 9.999999747378752E-06 then
        return nil
    end

    local v8 = t1.madd(v7, dot(t1.sub(p1.reference_point, p1.edge_start), v7), p1.edge_start)
    local v9 = t1.sub(p1.reference_point, t1.sub(p1.reference_point, v8))
    local v10 = t1.cross(v5, v7)
    local v11 = t1.scale(v5, 0.04)
    local v12 = t1.scale(v10, 0.09)
    local v13 = t1.scale(v10, p2)
    local v14 = t1.scale(v5, p2 * 1.059999942779541)
    local v15 = t1.scale(v5, 0.09)

    local function line(p3, p4, p5) -- line: 46
        -- upvalues: t1 (copy)
        return {
            start = t1.add(p3, p4),
            ["end"] = t1.sub(p3, p4),
            radius = p5
        }
    end

    local v16 = t1.add(v9, v12)
    local t2 = {
        start = t1.add(v16, v11),
        ["end"] = t1.sub(v16, v11),
        radius = 0
    }
    local v17 = t1.sub(v9, v12)
    local t3 = {
        start = t1.add(v17, v11),
        ["end"] = t1.sub(v17, v11),
        radius = 0
    }
    local v18 = t1.add(v9, v13)
    local t4 = {
        start = t1.add(v18, v14),
        ["end"] = t1.sub(v18, v14),
        radius = 0
    }
    local v19 = t1.sub(v9, v13)
    local t5 = {
        start = t1.add(v19, v14),
        ["end"] = t1.sub(v19, v14),
        radius = 0
    }
    local t6 = {
        start = t1.add(v9, v11),
        ["end"] = t1.sub(v9, v11),
        radius = 0
    }
    local v20 = t1.add(v9, v15)

    return {
        t2,
        t3,
        t4,
        t5,
        t6,
        {
            start = t1.add(v20, v12),
            ["end"] = t1.sub(v20, v12),
            radius = 0.001
        }
    }
end

function t1.detect_hung_geometry(p6, p7, p8) -- line: 66
    -- upvalues: BoardWorld (copy), t1 (copy)
    local v21 = t1.hang_lines(p7, p8)

    if v21 == nil then
        return false
    end

    local t7 = {}

    for i = 0, 5 do
        local v22 = v21[i + 1]
        local v23 = BoardWorld.query_swept_line(p6, v22.start, v22["end"], v22.radius)
        local v24 = i + 1

        if v23 ~= nil then
            t7[v24] = v23.geometry.fraction
        else
            t7[v24] = nil
        end
    end

    return t1.hung_classification(t7)
end

function t1.hung_classification(p9) -- line: 82
    if p9[1] ~= nil and p9[2] ~= nil or p9[5] ~= nil then
        return false
    end

    return (if p9[1] == nil then if p9[2] == nil then 0
        elseif p9[4] == nil then 1
        elseif p9[4] < 0.65 then 2
        else 1
        elseif p9[3] == nil then 1
        elseif p9[3] < 0.65 then 2
        else 1) ~= 2
end

function t1.normalize_or_retain(p10) -- line: 106
    -- upvalues: rt (copy), dot (copy), inverse_length_squared (copy), t1 (copy)
    local v25 = dot(p10, p10)
    local v26 = inverse_length_squared(v25, 2)
    local v27 = if v25 == 0 then 0 else v25 * v26

    return if v27 > 9.999999974752427E-07 then t1.scale(p10, v26) else rt.copy(p10), v27
end

function t1.cross(p11, p12) -- line: 113
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p11.z * p12.y + p11.y * p12.z, -p11.x * p12.z + p11.z * p12.x, -p11.y * p12.x + p11.x * p12.y)
end

function t1.add(p13, p14) -- line: 117
    -- upvalues: Vector3 (copy)
    return Vector3.new(p13.x + p14.x, p13.y + p14.y, p13.z + p14.z)
end

function t1.sub(p15, p16) -- line: 121
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15.x - p16.x, p15.y - p16.y, p15.z - p16.z)
end

function t1.scale(p17, p18) -- line: 125
    -- upvalues: Vector3 (copy)
    return Vector3.new(p17.x * p18, p17.y * p18, p17.z * p18)
end

function t1.madd(p19, p20, p21) -- line: 129
    -- upvalues: Vector3 (copy)
    return Vector3.new(p19.x * p20 + p21.x, p19.y * p20 + p21.y, p19.z * p20 + p21.z)
end

return t1
