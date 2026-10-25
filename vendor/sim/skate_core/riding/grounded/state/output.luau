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

local v8 = require(sim.import)("skate_core/physics/native_arithmetic")
local reject_axis_component, flush_subnormal
local t1 = {
    Vector4 = {},
    GroundOutputFrame = {},
    GroundOutputSettings = {},
    SkateboardMotionOutput = {},
    GroundVelocityProjectionOutput = {},
    GroundRecordOutput = {},
    StateRecordOutput = {},
    IntentRecordOutput = {},
    PhysicsGroundOutput = {},
    fill_physics_output = function(p4, p5, p6) -- fill_physics_output | line: 128
        -- upvalues: rt (copy), reject_axis_component (ref)
        local v9 = bit32.band(p5.flags_2476, 4194304) ~= 0
        local t2 = if p5.state_timer_2664 == 0 then {
            active = true,
            velocity_without_axis_component = reject_axis_component(rt.copy(p5.velocity_608), rt.copy(p5.axis_464))
        } else nil
        local v10 = if p4.manual_correction_2732 then true else nil

        return {
            skateboard_motion_4 = {
                is_push_accelerating = p4.flag_2721,
                is_at_pushable_speed = p5.absolute_body_speed_2616 < p6.pushable_speed_terms_4_8[1] + p6.pushable_speed_terms_4_8[2]
            },
            velocity_projection_36 = t2,
            ground_32 = {
                wall_ride_exit = p4.flag_2720,
                anti_flip_nudge_present = p4.anti_flip_nudge_applied_2723,
                is_pinning = p4.pinning_2727,
                anti_flip_torque = rt.copy(p4.anti_flip_torque_2624),
                time_to_skitch = p4.scalar_2664,
                skitch_spline_height = p4.scalar_2668,
                processed_scalar_2720 = p5.scalar_2720,
                processed_flag_2484_bit_13 = bit32.band(p5.flags_2484, 8192) ~= 0
            },
            state_28 = {
                grab_spline_type = p4.word_2560,
                grab_spline_object_id = p4.word_2564,
                flag_84 = p4.flag_2731,
                has_world_grab_intent_without_object = v9 and not p4.flag_2729,
                manual_correction_write_78 = v10
            },
            intents_52 = {
                has_world_grab_intent = v9,
                selected_mode_below_speed_threshold_58 = p5.selected_mode_flag_109 and p5.deck_speed_2652 < p6.mode_speed_threshold_0
            },
            is_grabbing_object_72_304 = p4.flag_2729,
            manual_opposition_56_168 = p4.manual_opposition_2733,
            push_suppressed_20_596 = p4.push_suppressed_2730
        }
    end
}

function reject_axis_component(p7, p8) -- line: 181
    -- upvalues: rt (copy), v8 (copy), flush_subnormal (ref)
    local v11 = v8.dot3(p7, p8)

    return rt.from_fn(4, function(p9) -- line: 185
        -- upvalues: p7 (copy), p8 (copy), v11 (copy), flush_subnormal (ref)
        local v12 = flush_subnormal(p8[p9 + 1] * v11)

        return flush_subnormal(p7[p9 + 1] - v12)
    end)
end

t1.reject_axis_component = reject_axis_component

function flush_subnormal(p10) -- line: 192
    -- upvalues: v1 (copy)
    local v13

    if p10 ~= 0 and p10 > -1.1754943508222875E-38 and p10 < 1.1754943508222875E-38 then
        local v14 = math.abs(p10) * 7.1362384635298E+44
        local v15 = math.floor(v14)
        local v16 = v14 - v15

        v13 = if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15

        if p10 < 0 then
            v13 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p10)
        v13 = buffer.readu32(v1, 0)
    end

    if bit32.band(v13, 2139095040) ~= 0 or bit32.band(v13, 8388607) == 0 then
        return p10
    end

    buffer.writeu32(v1, 0, (bit32.band(v13, 2147483648)))

    return (buffer.readf32(v1, 0))
end

t1.flush_subnormal = flush_subnormal

return t1
