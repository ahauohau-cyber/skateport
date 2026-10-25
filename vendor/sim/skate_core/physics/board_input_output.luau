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

local import = require(sim.import)
local BodyId = import("skate_core/physics/board").BodyId
local v8 = import("skate_core/physics/board_motion_output")
local dot, scale, subtract = v8.dot, v8.scale, v8.subtract
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local t1 = {
    BoardInputFrame = {}
}

function t1.publish_board_input(p3, p4, p5, p6) -- line: 49
    -- upvalues: rt (copy), v1 (copy), BodyId (copy), t1 (copy)
    local v9 = rt.copy(p4.effective_basis.columns[1])
    local v10 = if bit32.band(p6.processed_flags_2476, 4) == 0 then 1 else -1
    local v11 = v9[1] * v10
    local v12

    if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
        local v13 = math.abs(v11) * 7.1362384635298E+44
        local v14 = math.floor(v13)
        local v15 = v13 - v14

        v12 = if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14

        if v11 < 0 then
            v12 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v11)
        v12 = buffer.readu32(v1, 0)
    end

    local v16 = v9[2] * v10
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    local v21 = v9[3] * v10
    local v22

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v21 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)
    p3.board_reckoning_side_176 = {
        v12,
        v17,
        v22,
        (buffer.readu32(v1, 0))
    }
    p3.skateboard.vector_64 = t1.bits(p4.angular_velocity)
    p3.skateboard.vector_80 = t1.bits(p4.linear_velocity)
    p3.skateboard.vector_96 = t1.bits(p4.ground_velocity)
    p3.skateboard.scalar_160 = p4.speed
    p3.skateboard.scalar_164 = p4.ground_speed
    p3.skateboard.scalar_168 = p4.forward_speed
    p3.skateboard.scalar_172 = t1.travel_angle(p6.processed_forward, p4.ground_velocity, p6.reckoning_normal_1216, p6.reckoning_ground_up)
    p3.ground.vector_64 = t1.bits(p6.retained_ground_normal_112)
    p3.ground.vector_96 = t1.bits(p5.wheel_normal)
    p3.collision.wheel_contact_3296_3299 = {
        if p5.parts[1].in_contact then 1 else 0,
        if p5.parts[2].in_contact then 1 else 0,
        if p5.parts[3].in_contact then 1 else 0,
        if p5.parts[4].in_contact then 1 else 0
    }
    p3.collision.wheel_count_0 = p5.wheel_contact_count
    p3.collision.flag_3472 = (p5.parts[BodyId.index(BodyId.FrontTruck) + 1].in_contact or p5.parts[BodyId.index(BodyId.BackTruck) + 1].in_contact) and 1 or 0
    p3.collision.flag_3475 = p5.parts[BodyId.index(BodyId.Deck) + 1].in_contact and 1 or 0
    p3.collision.flag_3477 = not (p3.collision.wheel_count_0 > 0) and p3.collision.flag_3472 == 0 and p3.collision.flag_3475 == 0 and 0 or 1
end

function t1.travel_angle(p7, p8, p9, p10) -- line: 94
    -- upvalues: dot (copy), scale (copy), signed_angle (copy), t1 (copy)
    local v31 = t1.reject(p7, p9)

    if not (dot(v31, p8) > 0) then
        v31 = scale(v31, -1)
    end

    local v32 = (if dot(v31, v31) * dot(p8, p8) > 1.52587890625E-05 then signed_angle(t1.reject(v31, p10), t1.reject(p8, p10), p10) else 0) * 0.15915493667125702
    local v33 = v32 - math.floor(v32)

    return (v33 - (if v33 > 0.5 then 1 else 0)) * 6.2831854820251465
end

function t1.reject(p11, p12) -- line: 110
    -- upvalues: dot (copy), scale (copy), subtract (copy)
    return subtract(p11, scale(p12, dot(p11, p12)))
end

function t1.bits(p13) -- line: 115
    -- upvalues: v1 (copy)
    local x = p13.x
    local v34

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v35 = math.abs(x) * 7.1362384635298E+44
        local v36 = math.floor(v35)
        local v37 = v35 - v36

        v34 = if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36

        if x < 0 then
            v34 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v34 = buffer.readu32(v1, 0)
    end

    local y = p13.y
    local v38

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v39 = math.abs(y) * 7.1362384635298E+44
        local v40 = math.floor(v39)
        local v41 = v39 - v40

        v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

        if y < 0 then
            v38 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v38 = buffer.readu32(v1, 0)
    end

    local z = p13.z
    local v42

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v43 = math.abs(z) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if z < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v42 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)

    return {
        v34,
        v38,
        v42,
        (buffer.readu32(v1, 0))
    }
end

return t1
