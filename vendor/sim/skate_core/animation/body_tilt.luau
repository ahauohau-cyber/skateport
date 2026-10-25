-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {},
    Physical = {},
    State = {}
}

function t1.State.default() -- line: 52
    return {
        value = 0,
        velocity = 0,
        was_enabled = false
    }
end

local bound

function t1.State.disable(p4) -- line: 58
    p4.was_enabled = false
end

function t1.State.update(p5, p6, p7, p8, p9) -- line: 63
    -- upvalues: v1 (copy), PointGraph (copy), bound (ref)
    if not p5.was_enabled and p6 then
        p5.value = 0
        p5.velocity = 0
    end

    p5.was_enabled = p6

    if not p6 then
        return nil
    end

    local v8

    if p7 then
        v8 = p8.lateral_tilt
    else
        local lateral_tilt = p8.lateral_tilt
        local v9

        if lateral_tilt == 0 then
            buffer.writef32(v1, 0, lateral_tilt)
            v9 = buffer.readu32(v1, 0)
        elseif lateral_tilt > -1.1754943508222875E-38 and lateral_tilt < 1.1754943508222875E-38 then
            local v10 = math.abs(lateral_tilt) * 7.1362384635298E+44

            v9 = math.floor(v10)

            local v11 = v10 - v9

            if v11 > 0.5 or v11 == 0.5 and v9 % 2 == 1 then
                v9 += 1
            end

            if lateral_tilt < 0 then
                v9 += 2147483648
            end
        else
            buffer.writef32(v1, 0, lateral_tilt)
            v9 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v9, 2147483648)))
        v8 = buffer.readf32(v1, 0)
    end

    local v13 = PointGraph.evaluate(p9.body_spin_factor, (math.abs(p8.body_spin_speed))) * v8
    local v14, v15

    if p8.filtered_category == 2 then
        v14 = p9.air_velocity
        v15 = p9.air_acceleration
    else
        v14 = p9.ground_velocity
        v15 = p9.ground_acceleration
    end

    local v16 = bound(v13 - p5.value, -v14, v14)
    local v17 = bound(v16 - p5.velocity, -v15, v15)

    p5.velocity += v17
    p5.value += p5.velocity

    return p5.value
end

function t1.bound(p10, p11, p12) -- line: 94
    local v18 = if p11 - p10 >= 0 then p11 else p10

    if p12 - v18 >= 0 then
        return v18
    end

    return p12
end

bound = t1.bound

return t1
