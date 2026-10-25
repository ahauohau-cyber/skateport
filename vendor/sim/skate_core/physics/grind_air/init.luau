-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/trigonometry")
local v3 = import("skate_core/physics/grind_air/angles")
local v4 = import("skate_core/physics/grind_air/pose")
local v5 = import("skate_core/physics/grind_air/prediction")
local v6 = import("skate_core/physics/grind_air/selection")
local v7 = import("skate_core/physics/grind_air/targets")
local t1 = {
    PoseInput = v4.PoseInput,
    DeckDimensions = v7.DeckDimensions,
    Settings = v7.Settings,
    ZERO = { 0, 0, 0, 0 },
    UP = { 0, 1, 0, 0 },
    DEG = 0.01745329238474369,
    RAD = 57.295780181884766,
    PI = 3.1415927410125732,
    TAU = 6.2831854820251465
}
local TAU = t1.TAU

t1.Target = {}
t1.Input = {}
t1.Adjustment = {}

for v8, v9 in v4.Adjustment do
    t1.Adjustment[v8] = v9
end

t1.GrindAir = {}

local sub, add, scale, cross, reciprocal, unit, limited

function t1.GrindAir.default() -- line: 65
    return {
        target = nil,
        selected_kind = nil,
        offset_delta = { 0, 0, 0, 0 },
        offset = { 0, 0, 0, 0 },
        angle_delta = { 0, 0, 0, 0 },
        angles = { 0, 0, 0, 0 },
        headings = table.create(12, 0)
    }
end

function t1.GrindAir.start(p1, p2) -- line: 78
    -- upvalues: rt (copy)
    p1.target = rt.copy(p2)
    p1.offset_delta = { 0, 0, 0, 0 }
    p1.offset = { 0, 0, 0, 0 }
    p1.angle_delta = { 0, 0, 0, 0 }
    p1.angles = { 0, 0, 0, 0 }
    p1.selected_kind = nil
end

function t1.GrindAir.update(p3, p4, p5) -- line: 88
    -- upvalues: rt (copy), v3 (copy), v5 (copy), v6 (copy), v7 (copy), sub (ref), add (ref), scale (ref), cross (ref), reciprocal (ref), unit (ref), limited (ref)
    if not p4.active then
        return nil
    end

    if bit32.band(p4.flags_2480, 67108864) == 0 and bit32.band(p4.flags_2472, 32768) == 0 and bit32.band(p4.flags_2468, 8) == 0 then
        if p3.target == nil then
            error("Active GrindAirAdjust has no selected primitive", 0)
        end

        local v10 = rt.copy(p3.target)

        v7.Settings.validate(p5)

        local v11 = unit(sub(v10.edge["end"], v10.edge.start))
        local v12 = unit(cross(v11, cross(p4.up, v11)))
        local v13 = v5.project(p4, p5, v11, v12, p3.headings)
        local v14 = v6.contacts(v13, p5.frames, v10.edge.start, v11, v12)
        local v15 = v6.choose(v14, p3.headings, p5, bit32.band(p4.flags_2484, 2097152) ~= 0, p3.selected_kind)

        if v15 == nil then
            return nil
        end

        p3.selected_kind = v15

        local v16 = v7.CONTACTS[v15 + 1]
        local v17 = v14.times[v16 + 1]

        p3.offset_delta = limited(add(p3.offset_delta, scale(v14.corrections[v16 + 1], reciprocal(v17))), p5.max_delta)
        p3.offset = limited(add(p3.offset, p3.offset_delta), p5.max_offset)
        v3.update(p3, p4, p5, v10, v13, v11, v12, v15, v17)

        return {
            axis = rt.copy(v11),
            offset = rt.copy(p3.offset),
            angles = rt.copy(p3.angles)
        }
    end

    p3.offset = { 0, 0, 0, 0 }
    p3.angles = { 0, 0, 0, 0 }

    return nil
end

function t1.dot(p6, p7) -- line: 137
    -- upvalues: v1 (copy)
    return v1.dot3(p6, p7)
end

local dot = t1.dot

function t1.sub(p8, p9) -- line: 142
    return {
        p8[1] - p9[1],
        p8[2] - p9[2],
        p8[3] - p9[3],
        p8[4] - p9[4]
    }
end

sub = t1.sub

function t1.add(p10, p11) -- line: 147
    return {
        p10[1] + p11[1],
        p10[2] + p11[2],
        p10[3] + p11[3],
        p10[4] + p11[4]
    }
end

add = t1.add

function t1.scale(p12, p13) -- line: 152
    return {
        p12[1] * p13,
        p12[2] * p13,
        p12[3] * p13,
        p12[4] * p13
    }
end

scale = t1.scale

function t1.madd(p14, p15, p16) -- line: 157
    return {
        p14[1] * p15 + p16[1],
        p14[2] * p15 + p16[2],
        p14[3] * p15 + p16[3],
        p14[4] * p15 + p16[4]
    }
end

local _ = t1.madd

function t1.cross(p17, p18) -- line: 162
    return {
        -p17[3] * p18[2] + p17[2] * p18[3],
        -p17[1] * p18[3] + p17[3] * p18[1],
        -p17[2] * p18[1] + p17[1] * p18[2],
        0
    }
end

cross = t1.cross

function t1.inverse_length(p19) -- line: 172
    -- upvalues: v1 (copy)
    local v18 = v1.reciprocal_square_root_estimate(p19)
    local v19 = v18 * 0.5 * (-p19 * (v18 * v18) + 1) + v18

    return v19 * 0.5 * (-p19 * (v19 * v19) + 1) + v19
end

local inverse_length = t1.inverse_length

function t1.reciprocal(p20) -- line: 181
    -- upvalues: v1 (copy)
    local v20 = v1.reciprocal_estimate(p20)
    local v21 = v20 * (-v20 * p20 + 1) + v20

    return v21 * (-v21 * p20 + 1) + v21
end

reciprocal = t1.reciprocal

function t1.length(p21) -- line: 190
    -- upvalues: dot (copy), inverse_length (copy)
    local v22 = dot(p21, p21)

    if v22 == 0 then
        return 0
    end

    return v22 * inverse_length(v22)
end

local length = t1.length

function t1.unit(p22) -- line: 200
    -- upvalues: scale (ref), dot (copy), inverse_length (copy)
    local v23 = dot(p22, p22)
    local v24 = inverse_length(v23)

    if (if v23 == 0 then 0 else v23 * v24) > 9.999999974752427E-07 then
        return scale(p22, v24)
    end

    return { 0, 0, 0, 0 }
end

unit = t1.unit

function t1.limited(p23, p24) -- line: 212
    -- upvalues: rt (copy), scale (ref), reciprocal (ref), length (copy)
    local v25 = length(p23)

    if p24 < v25 then
        return scale(p23, p24 * reciprocal(v25))
    end

    return rt.copy(p23)
end

limited = t1.limited

function t1.wrap(p25) -- line: 222
    -- upvalues: TAU (copy)
    local v26 = p25 * 0.15915493667125702
    local v27 = v26 - math.floor(v26)

    return (v27 - (if v27 > 0.5 then 1 else 0)) * TAU
end

local wrap = t1.wrap

function t1.signed_angle(p26, p27, p28) -- line: 230
    -- upvalues: rt (copy), v1 (copy), v2 (copy), TAU (copy), scale (ref), cross (ref), dot (copy), wrap (copy)
    local v28 = dot(p26, p26)
    local v29 = dot(p27, p27)

    if not (v28 > 9.999999747378752E-05 and v29 > 9.999999747378752E-05) then
        return 0
    end

    local function normalize(p29, p30) -- line: 236
        -- upvalues: v1 (copy), scale (ref)
        local v30 = v1.reciprocal_square_root_estimate(p30)

        return scale(p29, v30 * 0.5 * (-p30 * (v30 * v30) + 1) + v30)
    end

    local v31 = v1.reciprocal_square_root_estimate(v28)
    local v32 = scale(p26, v31 * 0.5 * (-v28 * (v31 * v31) + 1) + v31)
    local v33 = v1.reciprocal_square_root_estimate(v29)
    local v34 = scale(p27, v33 * 0.5 * (-v29 * (v33 * v33) + 1) + v33)
    local v35 = v2.acos(rt.fmin(rt.fmax(dot(v32, v34), -1), 1))

    if dot(cross(v32, v34), p28) < 0 then
        v35 = TAU - v35
    end

    return wrap(v35)
end

local _ = t1.signed_angle

return t1
