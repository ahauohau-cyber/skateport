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
local dot, inverse_length_squared = v9.dot, v9.inverse_length_squared
local Vector3 = import("skate_core/math").Vector3
local t1 = {
    BoardProbeHit = {},
    BoardProbeState = {}
}

function t1.BoardProbeState.default() -- line: 45
    -- upvalues: rt (copy), Vector3 (copy)
    return {
        surface_tag = 0,
        hit = false,
        start = rt.copy(Vector3.ZERO),
        point = rt.copy(Vector3.ZERO),
        normal = rt.copy(Vector3.ZERO)
    }
end

function t1.BoardProbeState.eq(p3, p4) -- line: 57
    -- upvalues: Vector3 (copy)
    return Vector3.eq(p3.start, p4.start) and Vector3.eq(p3.point, p4.point) and Vector3.eq(p3.normal, p4.normal) and p3.surface_tag == p4.surface_tag and p3.hit == p4.hit
end

function t1.BoardProbeState.start(p5, p6) -- line: 65
    -- upvalues: rt (copy)
    p5.start = rt.copy(p6)
    p5.hit = false
end

function t1.BoardProbeState.publish(p7, p8) -- line: 72
    -- upvalues: rt (copy)
    p7.hit = p8 ~= nil

    if p8 == nil then
        return
    end

    p7.point = rt.copy(p8.point)
    p7.normal = rt.copy(p8.normal)
    p7.surface_tag = p8.surface_tag
end

function t1.BoardProbeState.disable(p9) -- line: 86
    -- upvalues: Vector3 (copy)
    for v11 in p9 do
        if v11 ~= "start" and v11 ~= "point" and v11 ~= "normal" and v11 ~= "surface_tag" and v11 ~= "hit" then
            p9[v11] = nil
        end
    end

    p9.start = Vector3.new(0, 0, 0)
    p9.point = Vector3.new(0, 0, 0)
    p9.normal = Vector3.new(0, 0, 0)
    p9.surface_tag = 0
    p9.hit = false
end

function t1.BoardProbeState.disable_reference(p10) -- line: 103
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p10, t1.BoardProbeState.default())
end

t1.DECK_PROBE_RADIUS = 0.15000000596046448

function t1.deck_probe(p11) -- line: 111
    -- upvalues: rt (copy), Vector3 (copy)
    return {
        start = rt.copy(p11),
        ["end"] = Vector3.new(p11.x, p11.y + -100, p11.z)
    }
end

t1.WallLineInput = {}

function t1.wall_probe(p12) -- line: 128
    -- upvalues: rt (copy), v1 (copy), dot (copy), inverse_length_squared (copy), Vector3 (copy), t1 (copy)
    if p12.state ~= 100 and p12.state ~= 101 then
        return nil
    end

    if math.abs(p12.contact_normal.y) < 0.5 and dot(p12.skater_up, p12.contact_normal) > 0.7099999785423279 and p12.time > 0.009999999776482582 then
        local v12 = rt.copy(p12.contact_normal)
        local v13 = Vector3.new(v12.x * 0.05 + p12.deck_position.x, v12.y * 0.05 + p12.deck_position.y, v12.z * 0.05 + p12.deck_position.z)
        local v14 = t1.cross(Vector3.new(0, 1, 0), v12)
        local v15 = t1.cross(v14, v12)
        local v16 = dot(v15, v15)
        local v17

        if v16 == 0 then
            buffer.writef32(v1, 0, v16)
            v17 = buffer.readf32(v1, 0)
        elseif v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
            local v18 = math.abs(v16) * 7.1362384635298E+44
            local v19 = math.floor(v18)
            local v20 = v18 - v19

            if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then
                v19 += 1
            end

            v17 = v19 * 1.401298464324817E-45

            if v16 < 0 then
                v17 = -v17
            end
        else
            buffer.writef32(v1, 0, v16)
            v17 = buffer.readf32(v1, 0)
        end

        local v21 = inverse_length_squared(v17, 2)
        local v22 = if (if v17 == 0 then 0 else v17 * v21) > 9.999999974752427E-07 then Vector3.new(v15.x * v21, v15.y * v21, v15.z * v21) else rt.copy(Vector3.ZERO)

        return {
            start = v13,
            ["end"] = Vector3.new(v22.x * 4 + v13.x, v22.y * 4 + v13.y, v22.z * 4 + v13.z)
        }
    end

    return nil
end

function t1.cross(p13, p14) -- line: 157
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p13.z * p14.y + p13.y * p14.z, -p13.x * p14.z + p13.z * p14.x, -p13.y * p14.x + p13.x * p14.y)
end

return t1
