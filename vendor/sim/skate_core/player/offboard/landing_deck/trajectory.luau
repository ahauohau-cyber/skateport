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
local Trajectory = import("skate_core/air/trajectory").Trajectory
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v9 = import("skate_core/player/wipeout_state/math")
local add, dot, length, madd = v9.add, v9.dot, v9.length, v9.madd
local reciprocal, scale, sub = v9.reciprocal, v9.scale, v9.sub

local function parent() -- line: 38
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/landing_deck")
end

local t1 = {}

function t1.frames(p3) -- line: 46
    -- upvalues: rt (copy), v1 (copy)
    local f_to_i32 = rt.f_to_i32
    local v10 = p3 * 59.999996185302734
    local v11

    if v10 == 0 or not (v10 > -1.1754943508222875E-38) or not (v10 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readf32(v1, 0)

        return f_to_i32(v11)
    end

    local v12 = math.abs(v10) * 7.1362384635298E+44
    local v13 = math.floor(v12)
    local v14 = v12 - v13

    v11 = (if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13) * 1.401298464324817E-45

    if v10 < 0 then
        v11 = -v11
    end

    return f_to_i32(v11)
end

function t1.square_root(p4) -- line: 52
    -- upvalues: v1 (copy), inverse_length_squared (copy)
    local v15 = false

    if p4 == 0 then
        v15 = true
    elseif p4 < 1E-44 and p4 > -1E-44 then
        local v16

        if p4 == 0 then
            buffer.writef32(v1, 0, p4)
            v16 = buffer.readf32(v1, 0)
        elseif p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
            local v17 = math.abs(p4) * 7.1362384635298E+44
            local v18 = math.floor(v17)
            local v19 = v17 - v18

            if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then
                v18 += 1
            end

            v16 = v18 * 1.401298464324817E-45

            if p4 < 0 then
                v16 = -v16
            end
        else
            buffer.writef32(v1, 0, p4)
            v16 = buffer.readf32(v1, 0)
        end

        v15 = v16 == 0
    end

    if not v15 then
        return p4 * inverse_length_squared(p4, 2)
    end

    return 0
end

function t1.greatest_plane_time(p5, p6, p7) -- line: 63
    -- upvalues: rt (copy), dot (copy), reciprocal (copy), scale (copy), t1 (copy)
    local v20 = dot(p7, scale(p5.acceleration, reciprocal(2)))
    local v21 = dot(p7, p5.velocity)
    local v22 = dot(p7, p5.position) - dot(p6, p7)
    local v23 = v21 * v21 - 4 * v20 * v22

    if not (v23 < 0) then
        if v23 > 0 then
            local v24 = t1.square_root(v23)
            local v25 = reciprocal(2 * v20)

            return rt.fmax(v25 * (-v21 + v24), v25 * (-v21 - v24))
        end

        local v26 = reciprocal(2 * v20) * -v21

        if v26 > 0 then
            return v26
        end
    end

    return nil
end

function t1.adjust(p8, p9, p10, p11) -- line: 85
    -- upvalues: import (copy), dot (copy), length (copy), madd (copy), reciprocal (copy), scale (copy)
    if p9 <= 0 then
        return
    end

    local v27 = scale(p10, reciprocal(p9 * import("skate_core/player/offboard/landing_deck").STEP))

    p8.velocity = madd(v27, if dot(v27, v27) > p11 * p11 then p11 / length(v27) else 1, p8.velocity)
end

function t1.shift(p12, p13) -- line: 101
    -- upvalues: import (copy), Trajectory (copy)
    local v29 = p13 * import("skate_core/player/offboard/landing_deck").STEP
    local v30 = Trajectory.position_at(p12, v29)

    p12.velocity = Trajectory.velocity_at(p12, v29)
    p12.position = v30
end

t1.Manager = {}

function t1.Manager.consider_board(p14, p15, p16, p17, p18) -- line: 112
    -- upvalues: rt (copy), import (copy), Trajectory (copy), add (copy), length (copy), madd (copy), reciprocal (copy), scale (copy), sub (copy), t1 (copy)
    local GRAVITY = import("skate_core/player/offboard/landing_deck").GRAVITY
    local v31 = p15.wheel_contacts_2556 == 0
    local v32 = rt.copy(p15.board_velocity_400)

    if v31 then
        v32[2] = 0
    end

    local t2 = {
        duration = -1,
        position = rt.copy(p17),
        velocity = sub(p18, v32),
        acceleration = if v31 then scale(GRAVITY, 0.5) else rt.copy(GRAVITY)
    }
    local v33 = madd(p15.up_544, p16.approximate_com_height, p15.board_position_112)
    local v34 = t1.greatest_plane_time(t2, v33, p15.up_544)

    if v34 ~= nil and not (v34 > 0) then
        v34 = nil
    end

    if v34 ~= nil then
        local v35 = length(sub(p17, v33))
        local v36 = t1.square_root(reciprocal(9.800000190734863) * (2 * v35))
        local v37 = rt.fmin(v34 * 1.3, rt.fmax(v34 * 0.75, v36))

        p14.proposed_96 = {
            duration = -1,
            position = rt.copy(p17),
            velocity = add(sub(scale(sub(v33, p17), reciprocal(v37)), scale(scale(GRAVITY, 0.5), v37)), p15.board_velocity_400),
            acceleration = rt.copy(GRAVITY)
        }
        p14.ik_offset_176 = sub(v33, Trajectory.position_at(t2, v34))
        p14.ik_offset_176[2] = 0
        p14.time_to_land_244 = v34
        p14.proposed_time_248 = v37
    else
        p14.can_land_256 = false
    end
end

return t1
