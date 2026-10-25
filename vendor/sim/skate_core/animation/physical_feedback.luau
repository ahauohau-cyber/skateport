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
local v8 = import("skate_core/input/turn_conditioner")
local v9 = import("skate_core/physics/native_arithmetic")
local t1 = {
    ReckoningFeedback = {},
    ControlFeedback = {},
    PhysicalFeedback = {}
}
local vector, flush_subnormal

function t1.publish(p4, p5, p6, p7, p8, p9, p10, p11) -- line: 78
    -- upvalues: rt (copy), v1 (copy), v8 (copy), v9 (copy), vector (ref), flush_subnormal (ref)
    local v10 = if bit32.band(p10.processed_flags, 1048576) ~= 0 then p9.target_lean_angle else -p9.target_lean_angle
    local update = v8.update
    local t2 = {
        body_160 = p6.speed
    }

    buffer.writeu32(v1, 0, p8[1][6])
    t2.body_176 = buffer.readf32(v1, 0)
    t2.bundle_36_field_160 = v10
    t2.bundle_32_field_264 = p10.turn
    t2.animation_152 = bit32.band(p10.processed_flags, 2147483648) == 0 and 0 or 1
    t2.animation_156 = p10.animation_mirrored and 1 or 0

    local v12 = update(p4, t2, p5)
    local v13 = vector(p9.system_position)
    local v14 = vector(p9.board_position)
    local v15 = table.create(4)

    for i = 0, 3 do
        v15[i + 1] = flush_subnormal(flush_subnormal(v13[i + 1]) - flush_subnormal(v14[i + 1]))
    end

    local v16 = v9.dot3(v15, vector(p9.system_up))

    return {
        turning = {
            field_32 = v12[1],
            field_36 = v12[2],
            field_52 = v12[6],
            field_56 = v12[7],
            field_60 = v12[8],
            body_168 = p6.forward_speed
        },
        crouching = {
            body_84 = p6.linear_velocity.y,
            body_164 = p6.ground_speed,
            body_188 = p7.pumping,
            force_516 = p7.absorption,
            ground_force_520 = p7.ground_normal_absorption,
            minimum_crouch_528 = p7.minimum_crouch,
            deck_angle_532 = p7.deck_angle_absorption,
            animation_height_72 = v16
        },
        pumping_acceleration = p7.pump_acceleration,
        ground_acceleration = rt.copy(p11.acceleration),
        bumped = p11.bumped,
        conditioned_turn = v12
    }
end

function t1.vector(p12) -- line: 132
    return {
        p12.x,
        p12.y,
        p12.z,
        0
    }
end

vector = t1.vector

function t1.flush_subnormal(p13) -- line: 137
    -- upvalues: v1 (copy)
    local v17

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v18 = math.abs(p13) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if p13 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p13)
        v17 = buffer.readu32(v1, 0)
    end

    if bit32.band(v17, 2139095040) ~= 0 then
        return p13
    end

    local v21

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v22 = math.abs(p13) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if p13 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p13)
        v21 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.band(v21, 2147483648)))

    return (buffer.readf32(v1, 0))
end

flush_subnormal = t1.flush_subnormal

return t1
