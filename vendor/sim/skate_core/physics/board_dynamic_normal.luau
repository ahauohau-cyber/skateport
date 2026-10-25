-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/board_motion_output")
local add, dot, inverse_length_squared, scale = v9.add, v9.dot, v9.inverse_length_squared, v9.scale
local subtract = v9.subtract
local Vector3 = import("skate_core/math").Vector3
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    UP = Vector3.new(0, 1, 0),
    ZERO = rt.copy(Vector3.ZERO),
    DynamicNormalSettings = {},
    BoardDynamicNormal = {}
}

function t1.BoardDynamicNormal.new() -- line: 58
    -- upvalues: rt (copy), t1 (copy)
    return {
        normal = rt.copy(t1.UP),
        delta = rt.copy(t1.UP),
        acceleration = rt.copy(t1.ZERO),
        last_contact_normal = rt.copy(t1.ZERO)
    }
end

function t1.BoardDynamicNormal.update(p3, p4, p5, p6, p7) -- line: 67
    -- upvalues: rt (copy), add (copy), scale (copy), subtract (copy), Vector3 (copy), PointGraph (copy), t1 (copy)
    if p4.wheel_contact_count == 0 then
        p3.acceleration = rt.copy(t1.ZERO)
    else
        local v10 = rt.copy(t1.ZERO)

        for i = 0, 2 do
            if p4.parts[i + 1].in_contact then
                v10 = subtract(add(v10, p4.accelerations[i + 1]), p5)
            end
        end

        local v11 = t1.normalize(v10)

        p3.delta = scale(p3.delta, p7.speed_damping)

        local v12 = scale(subtract(v11, p3.normal), p7.up_vector_damping)
        local v13, v14 = t1.normalize_length(v12)
        local v15 = PointGraph.evaluate(p7.maximum_delta_vs_speed, math.abs(p6) / p7.speed_scale) * p7.maximum_delta

        if -v14 >= -0 then
            v14 = 0
        end

        if not (v15 - v14 >= -0) then
            v14 = v15
        end

        p3.delta = Vector3.new(v13.x * v14 + p3.delta.x, v13.y * v14 + p3.delta.y, v13.z * v14 + p3.delta.z)
        p3.normal = t1.normalize(add(p3.normal, p3.delta))
        p3.last_contact_normal = rt.copy(p4.overall_normal)
    end
end

function t1.normalize(p8) -- line: 104
    -- upvalues: t1 (copy)
    return (t1.normalize_length(p8))
end

function t1.normalize_length(p9) -- line: 110
    -- upvalues: rt (copy), v1 (copy), dot (copy), inverse_length_squared (copy), scale (copy), t1 (copy)
    local v16 = dot(p9, p9)
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = (if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19) * 1.401298464324817E-45

        if v16 < 0 then
            v17 = -v17
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readf32(v1, 0)
    end

    local v21 = inverse_length_squared(v17, 2)
    local v22 = if v17 == 0 then 0 else v17 * v21

    return if v22 > 9.999999974752427E-07 then scale(p9, v21) else rt.copy(t1.ZERO), v22
end

return t1
