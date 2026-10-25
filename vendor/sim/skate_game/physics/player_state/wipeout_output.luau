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

local import = require(sim.import)

local function wipeout_states() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states")
end

local v8 = false
local t1 = {}

function t1.set_reference(p3) -- line: 38
    -- upvalues: v8 (ref)
    v8 = p3
end

local function map_to_bits(p4) -- line: 42
    -- upvalues: v1 (copy)
    local v9 = table.create(#p4)

    for i = 1, #p4 do
        local v10 = p4[i]

        if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
            local v11 = math.abs(v10) * 7.1362384635298E+44
            local v12 = math.floor(v11)
            local v13 = v11 - v12
            local v14 = if v13 > 0.5 or v13 == 0.5 and v12 % 2 == 1 then v12 + 1 else v12

            if v10 < 0 then
                v9[i] = v14 + 2147483648
            else
                v9[i] = v14
            end
        else
            buffer.writef32(v1, 0, v10)
            v9[i] = buffer.readu32(v1, 0)
        end
    end

    return v9
end

local function u8_from(p5) -- line: 50
    if p5 then
        return 1
    end

    return 0
end

function t1.publish(p6) -- line: 55
    -- upvalues: v1 (copy), import (copy), v8 (ref)
    local v15 = import("skate_game/physics/wipeout_states").fill(p6)
    local physical = p6.player_input.physical
    local skeleton = physical.skeleton

    skeleton.over_599 = v15.over_599 and 1 or 0
    skeleton.scalar_544 = v15.scalar_544
    skeleton.no_support_time_548 = v15.no_support_time_548
    skeleton.response_strength_580 = v15.response_strength_580
    skeleton.extra_weight_584 = v15.extra_weight_584
    skeleton.time_until_teleport_576 = v15.time_until_teleport_576
    skeleton.teleport_pending_604 = v15.teleport_pending_604 and 1 or 0
    skeleton.hips_right_angle_496 = v15.hips_right_angle_496
    skeleton.hips_up_angle_500 = v15.hips_up_angle_500

    local response_change_588 = v15.response_change_588

    if response_change_588 ~= nil then
        skeleton.response_change_588 = response_change_588
        skeleton.response_changed_605 = 1
    end

    physical.animation.collision_time_144 = v15.collision_time_144
    physical.animation.profile_148 = v15.profile_148
    physical.collision.flag_3479 = v15.material_ten_3479 and 1 or 0
    physical.collision.flag_3480 = v15.material_eleven_3480 and 1 or 0
    physical.collision.flag_3483 = v15.imminent_surface_twelve_3483 and 1 or 0

    local collision = physical.collision
    local predicted_position_64 = v15.predicted_position_64
    local v16 = table.create(#predicted_position_64)

    for i = 1, #predicted_position_64 do
        local v17 = predicted_position_64[i]

        if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
            local v18 = math.abs(v17) * 7.1362384635298E+44
            local v19 = math.floor(v18)
            local v20 = v18 - v19
            local v21 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

            if v17 < 0 then
                v16[i] = v21 + 2147483648
            else
                v16[i] = v21
            end
        else
            buffer.writef32(v1, 0, v17)
            v16[i] = buffer.readu32(v1, 0)
        end
    end

    collision.predicted_position_64 = v16

    local retained_air_velocity_160 = v15.retained_air_velocity_160

    if retained_air_velocity_160 ~= nil then
        local air = physical.air
        local v22 = table.create(#retained_air_velocity_160)

        for i = 1, #retained_air_velocity_160 do
            local v23 = retained_air_velocity_160[i]

            if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
                local v24 = math.abs(v23) * 7.1362384635298E+44
                local v25 = math.floor(v24)
                local v26 = v24 - v25
                local v27 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

                if v23 < 0 then
                    v22[i] = v27 + 2147483648
                else
                    v22[i] = v27
                end
            else
                buffer.writef32(v1, 0, v23)
                v22[i] = buffer.readu32(v1, 0)
            end
        end

        air.vector_160 = v22
        physical.air.use_air_reckoning_452 = 1
    end

    physical.state.surface_height_32 = v15.surface_height_32

    local state_flags = p6.player_state.state_flags

    if v8 then
        for _, v28 in {
                {
                    72,
                    v15.can_leave_72
                },
                {
                    81,
                    v15.special_surface_81
                },
                {
                    82,
                    v15.below_surface_82
                },
                {
                    83,
                    v15.surface_height_valid_83
                }
            } do
            local v29 = v28[1]
            local v30 = v28[2]

            state_flags[v29 - 52 + 1] = v30
        end
    else
        state_flags[21] = v15.can_leave_72
        state_flags[30] = v15.special_surface_81
        state_flags[31] = v15.below_surface_82
        state_flags[32] = v15.surface_height_valid_83
    end

    if v15.teleport_countdown_68 then
        state_flags[17] = true
    end

    if v15.request_teleport_69 then
        state_flags[18] = true
        physical.state.flag_69 = 1
    end
end

return t1
