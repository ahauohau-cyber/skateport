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
local v9 = import("skate_core/player/offboard/air_launch/jump")
local v10 = import("skate_core/player/offboard/air_launch/math")
local v11 = import("skate_core/player/offboard/air_launch/packet")
local add, clamp, cross, dot = v10.add, v10.clamp, v10.cross, v10.dot
local length, madd, normalize_or, scale = v10.length, v10.madd, v10.normalize_or, v10.scale
local sub, ZERO, UP, DT = v10.sub, v10.ZERO, v10.UP, v10.DT
local select, flatten = v10.select, v10.flatten
local t1 = {
    Packet = v11.Packet,
    Settings = {},
    DepartureGeometry = {}
}

function t1.DepartureGeometry.eq(p3, p4) -- line: 61
    for i = 1, 4 do
        if p3.point_1120[i] ~= p4.point_1120[i] or p3.axis_1136[i] ~= p4.axis_1136[i] then
            return false
        end
    end

    return true
end

t1.Processed = {}

function t1.mode(p5, p6) -- line: 91
    local v13 = if p6 then p5.current_state_2508 else p5.previous_state_2504
    local v12 = if p6 then p5.current_category_2512 else p5.previous_category_2516

    if v12 == 100 then
        return 0
    end

    if v12 == 400 then
        return 1
    end

    if v12 == 200 then
        return 2
    end

    if v12 == 500 and (bit32.band(p5.flags_2480, 128) ~= 0 or v13 == 503) then
        return 3
    end

    local v14 = v12 == 500
    local v15 = if v14 then bit32.band(p5.flags_2476, 524288) == 0 else nil

    if v14 and not v15 then
        return 4
    end

    if v12 == 500 then
        return 5
    end

    return 6
end

function t1.produce(p7, p8, p9, p10, p11, p12) -- line: 119
    -- upvalues: rt (copy), v1 (copy), v9 (copy), add (copy), clamp (copy), cross (copy), dot (copy), length (copy), madd (copy), normalize_or (copy), scale (copy), sub (copy), ZERO (copy), UP (copy), DT (copy), select (copy), flatten (copy), t1 (copy)
    local v16 = t1.mode(p11, p12)
    local v17

    if v16 == 1 then
        if p11.departure_geometry == nil then
            error("Offboard launch mode1 requires source-backed departure geometry1120/1136", 0)
        end

        v17 = rt.copy(p11.departure_geometry)
    end

    local v18 = normalize_or(flatten(p11.forward_224), ZERO)

    p7.up_48 = rt.copy(p11.up_544)
    p7.forward_64 = rt.copy(v18)
    p7.scalar_96 = 0.0872664600610733
    p7.scalar_100 = 0.8726646304130554
    p7.scalar_104 = 0.6981316804885864
    p7.kind_108 = 1
    p7.kind_112 = 0
    p7.position_32 = rt.copy(p11.position_592)

    local v19 = rt.copy(p11.velocity_608)
    local v20 = rt.copy(v19)
    local v21 = v19
    local v22 = v20

    if v16 == 0 then
        local v23 = select(v19[2] - 3, v19[2], 3)

        v19[2] = select(v19[2] + 3 - v23, v23, v19[2] + 3)
        p7.board_position_80 = rt.copy(p11.board_position_112)
        p7.has_board_position_116 = true
        p7.position_32 = madd(v19, DT, p7.position_32)
    elseif v16 == 1 then
        if v17 == nil then
            error("Mode1 geometry validated before packet writes", 0)
        end

        local v24 = sub(p11.position_592, v17.point_1120)

        v21 = add(madd(normalize_or(flatten((sub(v24, scale(v17.axis_1136, dot(v24, v17.axis_1136))))), ZERO), 2, v19), UP)
        p7.position_32 = madd(v21, DT, p7.position_32)
        p7.kind_108 = 6
    elseif v16 == 3 then
        local v27 = cross(UP, v19)
        local v28 = length(v27)

        if not (v28 <= 0.0010000000474974513) then
            v21 = madd(v27, (if bit32.band(p11.flags_2476, 4) == 0 then -0.75 else 0.75) / v28, v19)
        end
    elseif v16 == 4 then
        v21, v22 = v9.calculate(p8, p9, p10, p11, v18)
        p7.kind_108 = 6
        p7.kind_112 = 3
    elseif v16 == 5 then
        local v30 = flatten(v19)
        local v31 = length(v30)
        local v32

        if v31 == 0 then
            buffer.writef32(v1, 0, v31)
            v32 = buffer.readf32(v1, 0)
        elseif v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
            local v33 = math.abs(v31) * 7.1362384635298E+44
            local v34 = math.floor(v33)
            local v35 = v33 - v34

            if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then
                v34 += 1
            end

            v32 = v34 * 1.401298464324817E-45

            if v31 < 0 then
                v32 = -v32
            end
        else
            buffer.writef32(v1, 0, v31)
            v32 = buffer.readf32(v1, 0)
        end

        if v32 >= 1.875 then
            v21 = scale(p11.velocity_912, 0.75)
            v21[2] = clamp(v21[2], -10, 5)
        else
            v21 = scale(normalize_or(v30, v18), 2.5)
            v21[2] = select(1 - v21[2], 1, v21[2])
            p7.scalar_96 = 0.5235987901687622
        end

        p7.kind_108 = 6
    elseif v16 ~= 2 and v16 ~= 6 then
        error("mode returns only the seven native cases", 0)
    end

    p7.velocity_0 = rt.copy(v21)
    p7.secondary_velocity_16 = rt.copy(v22)
end

return t1
