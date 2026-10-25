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

require(sim.import)

local t1 = {}

local function from_bits4(p4) -- line: 38
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4[1])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[2])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[3])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[4])

    return {
        v9,
        v11,
        v13,
        (buffer.readf32(v1, 0))
    }
end

local function to_bits4(p5) -- line: 41
    -- upvalues: v1 (copy)
    local v15 = p5[1]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if v15 < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readu32(v1, 0)
    end

    local v20 = p5[2]
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if v20 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readu32(v1, 0)
    end

    local v25 = p5[3]
    local v26

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v27 = math.abs(v25) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if v25 < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v25)
        v26 = buffer.readu32(v1, 0)
    end

    local v30 = p5[4]
    local v31

    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
        local v32 = math.abs(v30) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if v30 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v30)
        v31 = buffer.readu32(v1, 0)
    end

    return {
        v16,
        v21,
        v26,
        v31
    }
end

function t1.storage(p6) -- line: 46
    -- upvalues: from_bits4 (copy)
    return {
        time_in_state_176 = 0,
        collision_time_180 = 0,
        time_until_collision_184 = 0,
        collision_normal_speed_188 = 0,
        time_to_apex_196 = 0,
        jump_height_200 = 0,
        trajectory_index_220 = 0,
        reached_apex_436 = false,
        known_air_valid_437 = false,
        trajectory_apex_0 = { 0, 0, 0, 0 },
        collision_position_16 = { 0, 0, 0, 0 },
        landing_normal_32 = { 0, 0, 0, 0 },
        selector_vector_48 = { 0, 0, 0, 0 },
        trajectory_position_64 = { 0, 0, 0, 0 },
        landing_heading_80 = { 0, 0, 0, 0 },
        selector_com_position_96 = { 0, 0, 0, 0 },
        landing_normal_copy_144 = { 0, 0, 0, 0 },
        locked_trajectory_velocity_160 = from_bits4(p6.vector_160),
        selected_trajectory_240 = {
            scalar_48 = 0,
            word_52 = 0,
            word_56 = 0,
            word_60 = 0,
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        },
        trajectory_plane_samples_336 = table.create(25, 0),
        locked_trajectory_velocity_valid_452 = p6.use_air_reckoning_452 ~= 0
    }
end

function t1.publish(p7, p8) -- line: 81
    -- upvalues: rt (copy), v1 (copy), to_bits4 (copy)
    p8.trajectory_apex_0 = to_bits4(p7.trajectory_apex_0)
    p8.collision_position_16 = to_bits4(p7.collision_position_16)
    p8.landing_normal_32 = to_bits4(p7.landing_normal_32)
    p8.selector_vector_48 = to_bits4(p7.selector_vector_48)
    p8.trajectory_position_64 = to_bits4(p7.trajectory_position_64)
    p8.landing_heading_80 = to_bits4(p7.landing_heading_80)
    p8.selector_com_position_96 = to_bits4(p7.selector_com_position_96)
    p8.time_in_state_176 = p7.time_in_state_176
    p8.collision_time_180 = p7.collision_time_180
    p8.collision_normal_speed_188 = p7.collision_normal_speed_188
    p8.time_to_apex_196 = p7.time_to_apex_196
    p8.trajectory_index_220 = p7.trajectory_index_220
    p8.trajectory_plane_samples_336 = rt.copy(p7.trajectory_plane_samples_336)
    p8.known_air_valid_437 = p7.known_air_valid_437 and 1 or 0

    local selected_trajectory_240 = p7.selected_trajectory_240
    local v35 = to_bits4(selected_trajectory_240.position)
    local v36 = to_bits4(selected_trajectory_240.velocity)
    local v37 = to_bits4(selected_trajectory_240.acceleration)
    local scalar_48 = selected_trajectory_240.scalar_48
    local v38

    if scalar_48 ~= 0 and scalar_48 > -1.1754943508222875E-38 and scalar_48 < 1.1754943508222875E-38 then
        local v39 = math.abs(scalar_48) * 7.1362384635298E+44
        local v40 = math.floor(v39)
        local v41 = v39 - v40

        v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

        if scalar_48 < 0 then
            v38 += 2147483648
        end
    else
        buffer.writef32(v1, 0, scalar_48)
        v38 = buffer.readu32(v1, 0)
    end

    p8.selected_trajectory_240 = {
        v35,
        v36,
        v37,
        {
            v38,
            selected_trajectory_240.word_52,
            selected_trajectory_240.word_56,
            selected_trajectory_240.word_60
        }
    }
    p8.vector_160 = to_bits4(p7.locked_trajectory_velocity_160)
    p8.use_air_reckoning_452 = p7.locked_trajectory_velocity_valid_452 and 1 or 0
    p8.scalar_184 = p7.time_until_collision_184
    p8.landing_normal_144 = to_bits4(p7.landing_normal_copy_144)
    p8.jump_height_200 = p7.jump_height_200
    p8.reached_apex_436 = p7.reached_apex_436 and 1 or 0
end

return t1
