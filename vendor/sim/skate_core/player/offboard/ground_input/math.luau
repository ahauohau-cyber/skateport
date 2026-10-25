-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    HALF_PI = 1.5707963705062866
}
local HALF_PI = t1.HALF_PI

t1.PI = 3.1415927410125732

local PI = t1.PI

function t1.dot(p1, p2) -- line: 22
    return p1[1] * p2[1] + p1[2] * p2[2] + p1[3] * p2[3]
end

local dot = t1.dot

function t1.cross(p3, p4) -- line: 29
    return {
        -p3[3] * p4[2] + p3[2] * p4[3],
        -p3[1] * p4[3] + p3[3] * p4[1],
        -p3[2] * p4[1] + p3[1] * p4[2]
    }
end

local cross = t1.cross

function t1.inverse_sqrt(p5) -- line: 39
    local v1 = 1 / math.sqrt(p5)
    local v2 = v1 * v1
    local v3 = v1 * 0.5 * (-p5 * v2 + 1) + v1
    local v4 = v3 * v3

    return v3 * 0.5 * (-p5 * v4 + 1) + v3
end

local inverse_sqrt = t1.inverse_sqrt

function t1.normalize(p6) -- line: 52
    -- upvalues: dot (copy), inverse_sqrt (copy)
    local v5 = inverse_sqrt(dot(p6, p6))

    return {
        p6[1] * v5,
        p6[2] * v5,
        p6[3] * v5
    }
end

function t1.length(p7) -- line: 58
    -- upvalues: dot (copy), inverse_sqrt (copy)
    local v6 = dot(p7, p7)
    local v7 = v6 * inverse_sqrt(v6)

    if v6 == 0 then
        return 0
    end

    return v7
end

function t1.inverse_frame(p8, p9, p10, p11) -- line: 69
    -- upvalues: dot (copy), cross (copy)
    local v8 = cross(p9, p10)
    local v9 = cross(p10, p8)
    local v10 = cross(p8, p9)
    local v11 = dot(p8, v8)
    local v12 = 1 / v11
    local v13 = v12 * (-v11 * v12 + 1) + v12
    local v14 = v13 * (-v11 * v13 + 1) + v13
    local t2 = {
        v8,
        v9,
        v10
    }
    local v15 = table.create(3)

    for i = 0, 2 do
        local v16 = t2[i + 1][1] * v14
        local v17 = t2[i + 1][2] * v14
        local v18 = t2[i + 1][3] * v14

        v15[i + 1] = v18 * p11[3] + (v17 * p11[2] + v16 * p11[1])
    end

    return v15
end

function t1.reciprocal_two(p12) -- line: 91
    local v19 = 1 / p12
    local v20 = v19 * (-p12 * v19 + 1) + v19
    local v21 = v20 * (-p12 * v20 + 1) + v20

    if v20 == v20 then
        return v21
    end

    return v19
end

local reciprocal_two = t1.reciprocal_two

function t1.rational_atan(p13) -- line: 106
    -- upvalues: HALF_PI (copy), reciprocal_two (copy)
    local v22 = math.abs(p13)
    local v23 = v22 > 1
    local v24 = reciprocal_two(v22)
    local v25, v26

    if v23 then
        v26 = HALF_PI
        v25 = 1.0471975803375244
    else
        v24 = v22
        v26 = 0
        v25 = 0.5235987901687622
    end

    local v27 = v24 + 1.7320507764816284
    local v28 = (v24 * 0.7320508360862732 + v24 - 1) * reciprocal_two(v27)

    if not (v24 > 0.2679491937160492) then
        v25 = v26
        v28 = v24
    end

    local v29 = v28 * v28
    local v32 = v28 * ((v29 * (v29 * (v29 * -0.8375830054283142 + -8.494624137878418) + -20.505855560302734) + -13.688769340515137) * v29 * reciprocal_two(v29 * (v29 * (v29 * (v29 + 15.024001121520996) + 59.57843780517578) + 86.1573486328125) + 41.066307067871094)) + v28

    if not (math.abs(v28) < 0.000244140625) then
        v28 = v32
    end

    if v23 then
        v28 = -v28
    end

    local v33 = v28 + v25

    if p13 < 0 then
        v33 = -v33
    end

    if p13 > 8.507059173023462E+37 then
        v33 = HALF_PI
    end

    if p13 < -8.507059173023462E+37 then
        v33 = -HALF_PI
    end

    return v33
end

local rational_atan = t1.rational_atan

function t1.signed_angle(p14, p15) -- line: 160
    -- upvalues: rt (copy), HALF_PI (copy), PI (copy), rational_atan (copy)
    local v34 = 1 / p15
    local v36 = rational_atan(p14 * (v34 * (-p15 * v34 + 1) + v34) + 0)

    if p15 < 0 then
        v36 += rt.copysign(PI, p14)
    end

    if p15 == 0 then
        v36 = rt.copysign(HALF_PI, p14)
    end

    return v36
end

return t1
