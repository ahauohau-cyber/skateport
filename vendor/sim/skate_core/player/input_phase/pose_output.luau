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

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/physics/native_arithmetic")
local v13 = import("skate_core/physics/board_motion_output")
local v14 = import("skate_core/input/angle")
local v15 = import("skate_core/player/wipeout_state/orientation")
local t1 = {
    SkeletonOutputFields = {}
}

function t1.SkeletonOutputFields.default() -- line: 50
    -- upvalues: rt (copy)
    return {
        hips_right_angle_496 = 0,
        hips_up_angle_500 = 0,
        twist_504 = 0,
        deck_yaw_536 = 0,
        deck_pitch_540 = 0,
        scalar_544 = 0,
        no_support_time_548 = 0,
        time_until_teleport_576 = 0,
        response_strength_580 = 0,
        extra_weight_584 = 0,
        response_change_588 = 0,
        flag_597 = 0,
        over_599 = 0,
        flag_600 = 0,
        flag_601 = 0,
        teleport_pending_604 = 0,
        response_changed_605 = 0,
        anim_to_world_11920 = rt.filled(4, table.create(4, 0))
    }
end

function t1.SkeletonOutputFields.publish_deck_angles(p5, p6, p7) -- line: 77
    -- upvalues: rt (copy), v1 (copy), v12 (copy), v14 (copy)
    local dot3, reciprocal_estimate = v12.dot3, v12.reciprocal_estimate
    local v16 = if p7 then {
        -p6[1],
        -p6[2],
        -p6[3],
        -p6[4]
    } else rt.copy(p6)
    local v17 = v16[1]
    local v18 = v16[3]
    local v19 = reciprocal_estimate(v18)
    local v20 = v19 * (-v19 * v18 + 1) + v19
    local v21 = v14.atan(v17 * v20 + 0)
    local v22

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v23 = math.abs(v17) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v17 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v22 = buffer.readu32(v1, 0)
    end

    local v26 = bit32.band(v22, 2147483648)

    buffer.writeu32(v1, 0, (bit32.bor(1078530011, v26)))

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, (bit32.bor(1070141403, v26)))

    local v30 = buffer.readf32(v1, 0)

    if v18 < 0 then
        v21 = v28 + v21
    end

    if v18 == 0 then
        p5.deck_yaw_536 = v30
    else
        p5.deck_yaw_536 = v21
    end

    p5.deck_pitch_540 = dot3(v16, { 0, 1, 0, 0 })
end

function t1.SkeletonOutputFields.publish_twist(p8, p9, p10, p11) -- line: 111
    -- upvalues: rt (copy), v1 (copy), v12 (copy), v13 (copy), v15 (copy)
    local inverse_length_squared = v13.inverse_length_squared
    local dot3 = v12.dot3
    local t2 = {
        p9.pose[11][4][1] - p9.pose[7][4][1],
        p9.pose[11][4][2] - p9.pose[7][4][2],
        p9.pose[11][4][3] - p9.pose[7][4][3],
        p9.pose[11][4][4] - p9.pose[7][4][4]
    }
    local v31 = dot3(t2, t2)
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = (if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34) * 1.401298464324817E-45

        if v31 < 0 then
            v32 = -v32
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readf32(v1, 0)
    end

    local v36 = inverse_length_squared(v32, 2)
    local v37 = if (if v32 == 0 then 0 else v32 * v36) > 0 then {
        t2[1] * v36,
        t2[2] * v36,
        t2[3] * v36,
        t2[4] * v36
    } else table.create(4, 0)
    local v38 = v15.projected_angle(rt.copy(p10), v37, rt.copy(p11)) * 0.15915493667125702
    local v39 = v38 - math.floor(v38)

    p8.twist_504 = (v39 - (v39 > 0.5 and 1 or 0)) * 6.2831854820251465
end

t1.AnimationOutputFields = {}

function t1.AnimationOutputFields.default() -- line: 157
    -- upvalues: rt (copy)
    return {
        profile_148 = 0,
        tricks_blocked_on_stairs_166 = 0,
        manual_opposition_168 = 0,
        collision_time_144 = rt.F32_MAX
    }
end

t1.ScoringOutputFields = {}

function t1.ScoringOutputFields.default() -- line: 170
    return {
        capabilities_204 = 0
    }
end

return t1
