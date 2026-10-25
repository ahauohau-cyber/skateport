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

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local import = require(sim.import)
local v9 = import("skate_core/player/wipeout_state/math")
local v10 = import("skate_core/physics/board_motion_output")
local v11 = import("skate_core/trigonometry")
local t1 = {
    add = v9.add,
    clamp = v9.clamp,
    cross = v9.cross,
    dot = v9.dot,
    length = v9.length,
    madd = v9.madd,
    normalize = v9.normalize,
    normalize_or = v9.normalize_or,
    scale = v9.scale,
    sub = v9.sub,
    wrap_angle = v9.wrap_angle
}
local cross, dot, length, madd = t1.cross, t1.dot, t1.length, t1.madd
local normalize, normalize_or, scale, sub = t1.normalize, t1.normalize_or, t1.scale, t1.sub

t1.ZERO = { 0, 0, 0, 0 }
t1.UP = { 0, 1, 0, 0 }
t1.DT = 0.01666666753590107
t1.RADIANS = 0.01745329238474369

function t1.select(p4, p5, p6) -- line: 61
    if p4 >= 0 then
        return p5
    end

    return p6
end

function t1.flatten(p7) -- line: 70
    -- upvalues: rt (copy)
    local v12 = rt.copy(p7)

    v12[2] = 0

    return v12
end

function t1.xyz_finite(p8) -- line: 76
    local v13 = p8[1]

    if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
        return false
    end

    local v14 = p8[2]

    if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) then
        return false
    end

    local v15 = p8[3]

    return v15 == v15 and v15 ~= 1e999 and v15 ~= (-1e999)
end

function t1.sanitize_w_lane(p9) -- line: 86
    -- upvalues: rt (copy)
    local v16 = p9[4]

    if v16 == v16 and v16 ~= 1e999 and v16 ~= (-1e999) then
        return rt.copy(p9)
    end

    local v17 = rt.copy(p9)

    v17[4] = 0

    return v17
end

function t1.magnitude(p10) -- line: 98
    -- upvalues: v1 (copy), v10 (copy)
    local v18 = p10 * v10.inverse_length_squared(p10, 2)
    local v19 = false

    if p10 == 0 then
        v19 = true
    elseif p10 < 1E-44 and p10 > -1E-44 then
        local v20

        if p10 == 0 then
            buffer.writef32(v1, 0, p10)
            v20 = buffer.readf32(v1, 0)
        elseif p10 > -1.1754943508222875E-38 and p10 < 1.1754943508222875E-38 then
            local v21 = math.abs(p10) * 7.1362384635298E+44
            local v22 = math.floor(v21)
            local v23 = v21 - v22

            if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then
                v22 += 1
            end

            v20 = v22 * 1.401298464324817E-45

            if p10 < 0 then
                v20 = -v20
            end
        else
            buffer.writef32(v1, 0, p10)
            v20 = buffer.readf32(v1, 0)
        end

        v19 = v20 == 0
    end

    if not v19 then
        return v18
    end

    return 0
end

function t1.reject(p11, p12) -- line: 108
    -- upvalues: t1 (copy), dot (copy), normalize_or (copy), scale (copy), sub (copy)
    local v24 = normalize_or(p12, t1.ZERO)

    return sub(p11, scale(v24, dot(p11, v24)))
end

function t1.limit_angle(p13, p14, p15) -- line: 114
    -- upvalues: rt (copy), v11 (copy), t1 (copy), cross (copy), dot (copy), length (copy), madd (copy), normalize (copy), normalize_or (copy), scale (copy)
    local v25 = normalize_or(p13, t1.ZERO)
    local v26 = normalize_or(p14, t1.ZERO)
    local v27 = cross(v25, v26)
    local v28 = v11.acos(rt.fmin(rt.fmax(dot(v25, v26), -1), 1))

    if math.abs(-math.floor(v28 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + v28) < p15 or dot(v27, v27) < 1.52587890625E-05 then
        return rt.copy(p13)
    end

    local v31, v32 = v11.sin_cos(-p15 * 0.5)
    local v33 = scale(normalize(v27), v31)

    v33[4] = v32

    return scale(madd(cross(v33, (madd(p14, v32, (cross(v33, p14))))), 2, p14), length(p13))
end

function t1.rotate(p16, p17, p18) -- line: 135
    -- upvalues: v11 (copy), madd (copy), scale (copy)
    local v36 = p17[1]
    local v37 = p17[2]
    local v38 = p17[3]
    local v39, v40 = v11.sin_cos(p18)
    local v41 = 1 - v40
    local v42 = v41 * v36
    local v43 = v41 * v37
    local v44 = v41 * v38
    local v45 = v39 * v36
    local v46 = v39 * v37
    local v47 = v39 * v38
    local v48 = v42 * v36 + v40
    local v49 = v43 * v36 - v47
    local v50 = v44 * v36 + v46
    local t2 = {
        v48,
        v42 * v37 + v47,
        v42 * v38 - v46,
        0
    }
    local t3 = {
        v49,
        v43 * v37 + v40,
        v43 * v38 + v45,
        0
    }

    return madd({
        v50,
        v44 * v37 - v45,
        v44 * v38 + v40,
        0
    }, p16[3], madd(t3, p16[2], scale(t2, p16[1])))
end

return t1
