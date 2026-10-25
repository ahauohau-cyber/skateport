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
local Vector3 = import("skate_core/math").Vector3
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local t1 = {}
local flip_sign_bit, xyz

local function wrapping_add_i32(p4, p5) -- line: 44
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p4), rt.to_u32(p5)))
end

local function wrapping_sub_i32(p6, p7) -- line: 47
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p6), rt.to_u32(p7)))
end

t1.AntiFlipNudgeInput = {}
t1.AntiFlipNudgeResult = {}

function t1.update_anti_flip_nudge(p8, p9, p10, p11) -- line: 64
    -- upvalues: rt (copy), Vector3 (copy), BoardForceQueue (copy), flip_sign_bit (ref), xyz (ref)
    if p11.dot3(p11, rt.copy(p8.anti_flip_torque_2624), rt.copy(p8.anti_flip_torque_2624)) > 0 then
        local anti_flip_nudge_frames_2752 = p8.anti_flip_nudge_frames_2752

        p8.anti_flip_nudge_frames_2752 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(anti_flip_nudge_frames_2752), rt.to_u32(1)))
    else
        p8.anti_flip_nudge_frames_2752 = 0
    end

    local v8, v9

    if p8.anti_flip_nudge_frames_2752 <= 12 then
        v9 = true
    elseif p9.deck_speed_2652 < 1.100000023841858 then
        v8 = rt.copy(p9.deck_axis_96)

        if v8[2] > 0 then
            v8 = rt.map(v8, flip_sign_bit)
        end

        v9 = false
    else
        v9 = true
    end

    if v9 then
        return {
            attempted = false,
            queued = false
        }
    end

    v8[2] = 0

    local v10 = p11.dot3(p11, rt.copy(v8), rt.copy(v8))

    if v10 > 0.0010000000474974513 then
        local v11 = p11.scale_to_magnitude(p11, rt.copy(v8), v10, 50)
        local v12 = BoardForceQueue.append(p10, {
            tag = 17,
            force_world = xyz(v11),
            point_body = rt.copy(Vector3.ZERO)
        })

        p8.anti_flip_nudge_applied_2723 = true

        return {
            attempted = true,
            queued = v12
        }
    end

    return {
        attempted = false,
        queued = false
    }
end

t1.HangUpInput = {}

function t1.manage_hang_ups(p12, p13, p14) -- line: 125
    -- upvalues: rt (copy)
    local v13 = bit32.band(p13.flags_1516, 134217728) ~= 0

    if v13 then
        if p13.deck_speed_2652 < 1.100000023841858 and p13.scalar_84 < 0.8999999761581421 and p13.scalar_84 > 0 then
            local hang_detection_frames_2740 = p12.hang_detection_frames_2740

            p12.hang_detection_frames_2740 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(hang_detection_frames_2740), rt.to_u32(1)))
        end
    else
        p12.hang_detection_frames_2740 = 0
    end

    if p12.hang_detection_frames_2740 == 20 then
        p12.hang_force_frames_2744 = 10
        p12.vector_2608 = p14.build_hang_force(p14)
    end

    if p12.hang_force_frames_2744 > 0 then
        if v13 then
            p14.apply_hang_force(p14, rt.copy(p12.vector_2608))
        end

        local hang_force_frames_2744 = p12.hang_force_frames_2744

        p12.hang_force_frames_2744 = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(hang_force_frames_2744), rt.to_u32(1)))

        if p12.hang_force_frames_2744 == 0 then
            p12.hang_detection_frames_2740 = 0
        end
    end

    local v14 = false

    if p13.deck_speed_2652 < 1.100000023841858 and bit32.band(p13.flags_1516, 201326592) == 201326592 then
        v14 = p13.geometry_axis_dot_positive
    end

    if v14 and p14.detect_hung_up_geometry(p14) then
        local hung_wipeout_frames_2748 = p12.hung_wipeout_frames_2748

        p12.hung_wipeout_frames_2748 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(hung_wipeout_frames_2748), rt.to_u32(1)))
    else
        p12.hung_wipeout_frames_2748 = 0
    end

    if p12.hung_wipeout_frames_2748 > 20 then
        p14.request_wipeout(p14)
    end
end

t1.HalfpipeWheelCatchInput = {}

function t1.manage_halfpipe_wheel_catches(p15, p16) -- line: 186
    local flags_1516 = p15.flags_1516

    if bit32.band(flags_1516, 134217728) == 0
        or not (p15.deck_speed_2652 < 3)
        or not (math.abs(p15.deck_x_axis_y) < 0.5699999928474426)
        or not (math.abs(p15.deck_y_axis_y) < 0.11999999731779099)
        or not (p15.signed_deck_distance < 0.10999999940395355)
        or not (p15.signed_deck_distance > 0) then
        return false
    end

    local v16 = p16.angular_displacement(p16)

    p16.apply_angular_displacement(p16, v16)

    return true
end

t1.PinningInput = {}

function t1.consider_pinning(p17, p18, p19) -- line: 210
    if bit32.band(p18.flags_2488, 1) ~= 0 then
        p17.pinning_2727 = false
        p17.was_pinning_2728 = false

        return
    end

    if p17.human_player_2724 and p18.frames_since_teleport_2584 < 90 then
        local v17 = p17.was_pinning_2728 or p18.frames_since_teleport_2584 < 30
        local v18 = p18.frames_since_teleport_2584 > 0 and bit32.band(p18.flags_2472, 8388608) == 0

        p17.controls_latched_2725 = p17.controls_latched_2725 or v18

        if v17 and p17.captured_position_valid_2726 and not p17.controls_latched_2725 then
            p19.pin_to_captured_position(p19, p17.captured_position_x_2656, p17.captured_position_z_2660)
            p17.pinning_2727 = true
        end
    end

    p17.was_pinning_2728 = p17.pinning_2727
end

function flip_sign_bit(p20) -- line: 232
    -- upvalues: v1 (copy)
    local v19

    if p20 ~= 0 and p20 > -1.1754943508222875E-38 and p20 < 1.1754943508222875E-38 then
        local v20 = math.abs(p20) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21

        if p20 < 0 then
            v19 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p20)
        v19 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v19, 2147483648)))

    return (buffer.readf32(v1, 0))
end

t1.flip_sign_bit = flip_sign_bit

function xyz(p21) -- line: 237
    -- upvalues: Vector3 (copy)
    return Vector3.new(p21[1], p21[2], p21[3])
end

t1.xyz = xyz

return t1
