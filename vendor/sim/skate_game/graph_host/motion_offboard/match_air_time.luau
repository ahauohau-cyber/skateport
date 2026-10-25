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
local encode = import("skate_core/animation/skeleton_input/name").encode
local t1 = {}
local v9

local function motion() -- line: 41
    -- upvalues: import (copy), v9 (ref)
    local v10 = v9

    if v10 == nil then
        v10 = import("skate_game/graph_host/motion")
        v9 = v10
    end

    return v10
end

local bounded_translation

t1.State = {}

function t1.State.default() -- line: 55
    return {
        cadence_start = 0,
        duration = 0,
        first_update = false,
        translation = { 0, 0, 0, 0 }
    }
end

function t1.State.begin(p3, p4, p5, p6) -- line: 65
    -- upvalues: rt (copy)
    p3.first_update = true
    p3.cadence_start = p4
    p3.duration = p5
    p3.translation = rt.copy(p6)
end

function t1.State.update(p7, p8, p9, p10, p11) -- line: 74
    -- upvalues: import (copy), encode (copy), t1 (copy), v9 (ref), bounded_translation (ref)
    local v11 = v9

    if v11 == nil then
        v11 = import("skate_game/graph_host/motion")
        v9 = v11
    end

    local MotionAnimation = v11.MotionAnimation
    local v12 = t1.State.seek_fraction(p7, p9, p10)

    if v12 ~= nil then
        MotionAnimation.synchronize_air_time(p8, v12)
    end

    p7.translation = bounded_translation(p11)
    p7.duration = p10

    for _, v13 in {
            {
                "CadenceStartPercent",
                p7.cadence_start
            },
            {
                "AnimTime",
                p7.duration
            },
            {
                "AnimTransX",
                p7.translation[1]
            },
            {
                "AnimTransY",
                p7.translation[2]
            },
            {
                "AnimTransZ",
                p7.translation[3]
            }
        } do
        MotionAnimation.set_attribute(p8, {
            normalized = false,
            sequence_id = -1,
            name = encode(v13[1]),
            value = v13[2]
        })
    end

    p7.first_update = false
end

function t1.State.seek_fraction(p12, p13, p14) -- line: 102
    if p12.first_update or p14 <= 0 then
        return nil
    end

    local v14 = 1 - p13 / p14

    if -v14 >= 0 then
        v14 = 0
    end

    if 1 - v14 >= 0 then
        return v14
    end

    return 1
end

function bounded_translation(p15) -- line: 113
    -- upvalues: rt (copy), v1 (copy)
    local v15 = p15[1] * p15[1] + p15[2] * p15[2] + p15[3] * p15[3]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if v15 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readf32(v1, 0)
    end

    local v20 = 1 / math.sqrt(v16)
    local v21 = -v16 * (v20 * v20) + 1
    local v22 = v20 * 0.5 * v21 + v20
    local v23 = -v16 * (v22 * v22) + 1
    local v24 = v22 * 0.5 * v23 + v22
    local v25 = if v16 == 0 then 0 else v16 * v24

    if v25 > 0.01 then
        local v26 = (if v25 - 2 >= 0 then 2 else v25) / v25

        return {
            p15[1] * v26,
            p15[2] * v26,
            p15[3] * v26,
            p15[4] * v26
        }
    end

    return rt.copy(p15)
end

t1.bounded_translation = bounded_translation

return t1
