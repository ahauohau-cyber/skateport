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
local v9 = import("skate_core/physics/native_arithmetic")
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local t1 = {}

t1.ContactCorrection = {}
t1.Input = {}

local dot, select, reject, inverse_length, magnitude, clamp_length

function t1.ContactCorrection.update(p3, p4) -- line: 53
    -- upvalues: rt (copy), dot (ref), select (ref), reject (ref), inverse_length (ref), magnitude (ref), clamp_length (ref)
    p3.displacement = { 0, 0, 0, 0 }

    local v11 = rt.copy(p4.collision_displacements[1])
    local v12 = rt.copy(p4.collision_displacements[2])
    local v13 = dot(v11, v11)
    local v14 = dot(v12, v12)

    if not (v14 < v13) then
        v11 = v12
    end

    local v15 = select(v13 - v14, v13, v14)

    p3.active = false

    if not (v15 <= 9.999999747378752E-05) then
        local v16 = inverse_length(dot(v11, v11))

        p3.direction = {
            v11[1] * v16,
            v11[2] * v16,
            v11[3] * v16,
            v11[4] * v16
        }
        p3.active = true

        local v17 = magnitude(v15) - 0.05000000074505806
        local v18 = select(v17, v17, 0)
        local direction = p3.direction
        local t2 = {
            direction[1] * v18 * 0.5,
            direction[2] * v18 * 0.5,
            direction[3] * v18 * 0.5,
            direction[4] * v18 * 0.5
        }

        p3.displacement = clamp_length(reject(t2, p4.projection_axis_416), 0.10000000149011612)
    end

    p3.displacement = reject(p3.displacement, p4.up_axis_16)
end

function t1.dot(p5, p6) -- line: 83
    -- upvalues: v9 (copy)
    return v9.dot3(p5, p6)
end

dot = t1.dot

function t1.select(p7, p8, p9) -- line: 89
    if p7 >= 0 then
        return p8
    end

    return p9
end

select = t1.select

function t1.reject(p10, p11) -- line: 98
    -- upvalues: dot (ref)
    local v19 = dot(p11, p10)

    return {
        p10[1] - p11[1] * v19,
        p10[2] - p11[2] * v19,
        p10[3] - p11[3] * v19,
        p10[4] - p11[4] * v19
    }
end

reject = t1.reject

function t1.inverse_length(p12) -- line: 109
    -- upvalues: estimate (copy)
    local v20 = estimate(p12)
    local v21 = v20 * 0.5 * (-p12 * (v20 * v20) + 1) + v20

    return v21 * 0.5 * (-p12 * (v21 * v21) + 1) + v21
end

inverse_length = t1.inverse_length

function t1.magnitude(p13) -- line: 118
    -- upvalues: v1 (copy), inverse_length (ref)
    local v22

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v23 = math.abs(p13) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = (if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24) * 1.401298464324817E-45

        if p13 < 0 then
            v22 = -v22
        end
    else
        buffer.writef32(v1, 0, p13)
        v22 = buffer.readf32(v1, 0)
    end

    local v26 = v22 * inverse_length(v22)

    if v22 == 0 then
        return 0
    end

    return v26
end

magnitude = t1.magnitude

function t1.clamp_length(p14, p15) -- line: 130
    -- upvalues: rt (copy), v9 (copy), dot (ref), select (ref), magnitude (ref)
    local v27 = magnitude(dot(p14, p14))

    if not (v27 >= 1.52587890625E-05) then
        return rt.copy(p14)
    end

    local v28 = select(p15 - v27, v27, p15)
    local v29 = v9.reciprocal_estimate(v27)
    local v30 = v29 * (-v29 * v27 + 1) + v29
    local v31 = v30 * (-v30 * v27 + 1) + v30

    return {
        p14[1] * v28 * v31,
        p14[2] * v28 * v31,
        p14[3] * v28 * v31,
        p14[4] * v28 * v31
    }
end

clamp_length = t1.clamp_length

return t1
