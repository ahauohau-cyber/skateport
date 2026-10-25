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

local import = require(sim.import)
local PointGraph = import("skate_core/point_graph").PointGraph
local select = import("skate_core/air/known/trajectory").select
local t1 = {
    DEGREES_TO_RADIANS = 0.01745329238474369,
    RADIANS_TO_DEGREES = 57.295780181884766,
    DIRECTION_EPSILON = 0.0010000000474974513,
    PI = 3.1415927410125732,
    ALIGNMENT_DELAY = 0.03200000151991844,
    AUTO_SPIN_SCALE = 1.2000000476837158,
    FORTY_FIVE_DEGREES = 45,
    HALF = 0.5,
    REVERSE_SCALE = 0.004999999888241291,
    DECELERATION_SCALE = 0.75
}
local DEGREES_TO_RADIANS, RADIANS_TO_DEGREES, DIRECTION_EPSILON, PI = t1.DEGREES_TO_RADIANS, t1.RADIANS_TO_DEGREES, t1.DIRECTION_EPSILON, t1.PI
local ALIGNMENT_DELAY, AUTO_SPIN_SCALE, FORTY_FIVE_DEGREES, HALF = t1.ALIGNMENT_DELAY, t1.AUTO_SPIN_SCALE, t1.FORTY_FIVE_DEGREES, t1.HALF
local REVERSE_SCALE, DECELERATION_SCALE = t1.REVERSE_SCALE, t1.DECELERATION_SCALE

function t1.calculate_body_flip_speed(p4, p5, p6, p7, p8, p9) -- line: 61
    -- upvalues: PointGraph (copy)
    if not p4.body_flipping_211 then
        local flags_2468 = p5.flags_2468
        local v8 = bit32.band(flags_2468, 32) ~= 0 or bit32.band(flags_2468, 16) ~= 0
        local v9 = bit32.band(flags_2468, 128) ~= 0 or bit32.band(flags_2468, 64) ~= 0
        local begin_reckoning_body_flip, v10

        if v8 and v9 and bit32.band(p5.flags_2488, 33554432) == 0 and PointGraph.evaluate(p6.flip_start_collision_time_vs_normal_y, p8.landing_normal_1152[2]) < p4.collision_time_196 then
            begin_reckoning_body_flip = p9.begin_reckoning_body_flip
            v10 = bit32.band(bit32.rshift(flags_2468, 7), 1) ~= 0
            begin_reckoning_body_flip(p9, v10)
            p4.body_flipping_211 = true
        end
    end

    if not p7.perfect_body_flips_28 then
        local flags_2468 = p5.flags_2468

        if bit32.band(flags_2468, 32) == 0 and bit32.band(flags_2468, 16) == 0 and not (p4.time_in_state_180 < p6.body_flip_min_grab_time_fraction_456) then
            return 0
        end
    end

    return p4.body_flip_target_speed_204
end

function t1.calculate_body_spin_speed(p10, p11, p12, p13, p14, p15) -- line: 92
    -- upvalues: rt (copy), PointGraph (copy), select (copy), t1 (copy), DEGREES_TO_RADIANS (copy), RADIANS_TO_DEGREES (copy), DIRECTION_EPSILON (copy), PI (copy), ALIGNMENT_DELAY (copy), AUTO_SPIN_SCALE (copy), FORTY_FIVE_DEGREES (copy), HALF (copy), REVERSE_SCALE (copy), DECELERATION_SCALE (copy)
    local v12 = p11.body_spin_input_2640 * p12.max_spin_speed_428 * DEGREES_TO_RADIANS
    local v13 = if bit32.band(p11.flags_2472, 268435456) == 0 then 0 else v12
    local v14

    if v12 ~= 0 or not p10.landing_heading_valid_209 or bit32.band(p11.flags_2484, 32768) ~= 0 then
        v14 = v13

        return v14
    end

    local v15 = rt.copy(p14.heading_axis_1200)

    if bit32.band(bit32.rshift(p11.flags_2468, 20), 1) ~= 0 ~= p10.start_flipped_210 then
        v15 = t1.flip_sign_bits(v15)
    end

    local v18

    if p15.dot3(p15, p14.landing_normal_1152, p10.landing_normal_64) > DIRECTION_EPSILON then
        v18 = p15.signed_angle_about_axis(p15, v15, p10.landing_heading_80, p14.landing_normal_1152)

        if bit32.band(p11.flags_2468, 1048576) ~= 0 then
            v18 += PI
        end
    else
        v18 = 0
    end

    local v19 = p15.wrap_angle_8258db98(p15, v18)
    local v20 = v19 * RADIANS_TO_DEGREES

    if PointGraph.evaluate(p12.max_heading_adjust_vs_up_y_160, p11.skater_up_544[2]) < math.abs(v20) then
        local v21 = p15.wrap_angle_8258db98(p15, PI)

        v19 = p15.wrap_angle_8258db98(p15, v21 + v19)
    end

    local body_spin_speed_1572 = p14.body_spin_speed_1572
    local v22 = p10.collision_time_196 - p10.time_in_state_180
    local v23 = 1 / select(v22 - ALIGNMENT_DELAY, v22, ALIGNMENT_DELAY)
    local v24 = v23 * v19 * AUTO_SPIN_SCALE

    if math.abs(body_spin_speed_1572) < DIRECTION_EPSILON then
        body_spin_speed_1572 = 0
    end

    if body_spin_speed_1572 * v24 < 0 then
        local v25 = p15.wrap_angle_8258db98(p15, v18 + PI)

        if FORTY_FIVE_DEGREES * DEGREES_TO_RADIANS > math.abs(v25) and v23 * v25 * body_spin_speed_1572 > 0 then
            v24 = v23 * v25
        end
    end

    v14 = t1.native_clamp(v24, -p13.body_spin_speed_limit_56, p13.body_spin_speed_limit_56)

    if math.abs(v14) < p12.min_auto_body_speed_424 then
        v14 *= HALF
    end

    if math.abs(v18) < p12.min_auto_body_speed_424 then
        v14 = v18 / p11.delta_time_2604 * HALF
    end

    if v14 * body_spin_speed_1572 < 0 then
        return v14 * REVERSE_SCALE
    end

    if math.abs(body_spin_speed_1572) > math.abs(v14) then
        v14 *= DECELERATION_SCALE
    end

    return v14
end

function t1.flip_sign_bits(p16) -- line: 166
    -- upvalues: v1 (copy)
    local v26 = table.create(4)

    for i = 1, 4 do
        local v27 = p16[i]
        local v28

        if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
            local v29 = math.abs(v27) * 7.1362384635298E+44
            local v30 = math.floor(v29)
            local v31 = v29 - v30
            local v32 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

            v28 = if v27 < 0 then v32 + 2147483648 else v32
        else
            buffer.writef32(v1, 0, v27)
            v28 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v28, 2147483648)))
        v26[i] = buffer.readf32(v1, 0)
    end

    return v26
end

function t1.native_clamp(p17, p18, p19) -- line: 174
    -- upvalues: select (copy)
    local v34 = select(p18 - p17, p18, p17)

    return select(p19 - v34, v34, p19)
end

return t1
