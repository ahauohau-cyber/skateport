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
local reciprocal = import("skate_core/animation/foot_ik/math").reciprocal
local inverse_rigid = import("skate_core/animation/foot_ik/transforms").inverse_rigid
local vector_min = import("skate_core/physics/native_arithmetic").vector_min
local transform_point = import("skate_core/physics/skeleton_animation_record").transform_point
local t1 = {}

local function round_ties_even(p4) -- line: 40
    local v8 = math.floor(p4)
    local v9 = p4 - v8

    if v9 < 0.5 or not (v9 > 0.5) and v8 % 2 == 0 then
        return v8
    end

    return v8 + 1
end

t1.SettingsPost = {}

local function tangent(p5) -- line: 64
    -- upvalues: rt (copy), v1 (copy), reciprocal (copy)
    local v10 = p5 * 0.6366197466850281
    local v11 = math.floor(v10)
    local v12 = v10 - v11

    if not (v12 < 0.5) and (v12 > 0.5 or v11 % 2 ~= 0) then
        v11 += 1
    end

    local v13 = -v11 * 1.5707963705062866 + p5
    local v14 = -v11 * 6.07710062827671E-11 + v13
    local v15 = v14 * v14
    local v16 = v15 * (v15 * (v15 * (v15 * 4.981943675375078E-07 + -0.00031181532540358603) + 0.02566383220255375) + -0.46671682596206665) + 1
    local v17 = v14 * (v15 * (v15 * (v15 * -1.786170651030261E-05 + 0.003424887778237462) + -0.13338349759578705)) + v14
    local v20 = bit32.bor(if v14 > 0.000244140625 then 2147483648 else 0, if v14 < -0.000244140625 then 1073741824 else 0)
    local v21

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v22 = math.abs(v16) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if v16 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v21 = buffer.readu32(v1, 0)
    end

    local v26 = bit32.band(v21, (bit32.bnot(v20)))

    buffer.writef32(v1, 0, 1)
    buffer.writeu32(v1, 0, (bit32.bor(v26, (bit32.band(buffer.readu32(v1, 0), v20)))))

    local v30 = buffer.readf32(v1, 0)
    local v31

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v32 = math.abs(v17) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if v17 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v31 = buffer.readu32(v1, 0)
    end

    local v36 = bit32.band(v31, (bit32.bnot(v20)))
    local v37

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v38 = math.abs(v14) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v14 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v14)
        v37 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bor(v36, (bit32.band(v37, v20)))))

    local v43 = buffer.readf32(v1, 0)

    if bit32.band(rt.to_u32(rt.f_to_i32((math.abs(v11)))), 1) == 0 then
        return v43 * reciprocal(v30, 2)
    end

    return v30 * reciprocal(-v43, 2)
end

function t1.target(p6, p7, p8, p9, p10, p11, p12) -- line: 98
    -- upvalues: rt (copy), inverse_rigid (copy), vector_min (copy), transform_point (copy), tangent (copy)
    local v45 = inverse_rigid(p6)
    local v46 = transform_point(v45, p7)
    local v47 = transform_point(v45, p8)
    local v48 = table.create(4)

    v48[1] = (v46[1] + v47[1]) * 0.5
    v48[2] = (v46[2] + v47[2]) * 0.5
    v48[3] = (v46[3] + v47[3]) * 0.5
    v48[4] = (v46[4] + v47[4]) * 0.5
    v48[2] = v46[2]

    local v52 = vector_min(math.abs(v46[1]), (math.abs(v48[1])))
    local v56 = vector_min(math.abs(v46[3]), (math.abs(v48[3])))

    if p11.deck_half_width + p11.post_ik_padding[1] <= v52 or p11.deck_total_half_length + p11.post_ik_padding[3] <= v56 then
        return nil
    end

    local v57 = if p10 then p12.wipeout_height else p12.riding_height

    if p11.deck_half_length < v56 then
        local v58 = v56 - p11.deck_half_length
        local v59 = p11.deck_total_half_length - p11.deck_half_length

        if not (v59 - v58 >= 0) then
            v58 = v59
        end

        local v60 = p11.deck_front_angle_degrees * 0.01745329238474369

        if 0.01 - v60 >= 0 then
            v60 = 0.01
        end

        if not (1.5607963800430298 - v60 >= 0) then
            v60 = 1.5607963800430298
        end

        v57 = v58 * tangent(v60) + v57
    end

    if v57 <= v48[2] or v48[2] <= v57 - 0.30000001192092896 then
        return nil
    end

    local v61 = rt.copy(p9)

    v61[2] = v57

    return transform_point(p6, v61)
end

t1.tangent = tangent

return t1
