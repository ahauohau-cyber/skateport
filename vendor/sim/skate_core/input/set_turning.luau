-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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
local v8 = import("skate_core/input/turn_remap")
local v9 = import("skate_core/point_graph")
local t1 = {}
local TurnRemap = v8.TurnRemap
local PointGraph = v9.PointGraph

local function bool_u32(p4) -- line: 42
    if p4 then
        return 1
    end

    return 0
end

t1.SlideLatch = {}

function t1.SlideLatch.default() -- line: 52
    return {
        words = { 0, 0, 0, 0, 0 }
    }
end

function t1.SlideLatch.eq(p5, p6) -- line: 57
    for i = 1, 5 do
        if p5.words[i] ~= p6.words[i] then
            return false
        end
    end

    return true
end

function t1.SlideLatch.captured_fakie(p7) -- line: 66
    return bit32.band(p7.words[5], 2147483648) ~= 0
end

function t1.SlideLatch.candidate_enabled(p8) -- line: 70
    return bit32.band(p8.words[5], 1073741824) ~= 0
end

function t1.SlideLatch.set_candidate_enabled(p9, p10) -- line: 74
    p9.words[5] = bit32.bor(bit32.band(p9.words[5], 3221225471), (bit32.lshift(if p10 then 1 else 0, 30)))
end

function t1.SlideLatch.elapsed(p11, p12) -- line: 81
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p11.words[(if p12 then 2 else 0) + 1])

    return (buffer.readf32(v1, 0))
end

function t1.SlideLatch.start(p13, p14) -- line: 85
    return bit32.band(p13.words[(if p14 then 3 else 1) + 1], 2147483648) ~= 0
end

t1.SlideLatch["end"] = function(p15, p16) -- line: 90
    return bit32.band(p15.words[(if p16 then 3 else 1) + 1], 1073741824) ~= 0
end

function t1.SlideLatch.set_start(p17, p18, p19) -- line: 94
    local v19 = (if p18 then 3 else 1) + 1

    p17.words[v19] = bit32.bor(bit32.band(p17.words[v19], 2147483647), (bit32.lshift(if p19 then 1 else 0, 31)))
end

function t1.SlideLatch.set_end(p20, p21, p22) -- line: 102
    local v24 = (if p21 then 3 else 1) + 1

    p20.words[v24] = bit32.bor(bit32.band(p20.words[v24], 3221225471), (bit32.lshift(if p22 then 1 else 0, 30)))
end

function t1.SlideLatch.advance_elapsed(p23, p24, p25) -- line: 110
    -- upvalues: v1 (copy)
    local v29 = (if p24 then 2 else 0) + 1
    local words = p23.words

    buffer.writeu32(v1, 0, p23.words[v29])

    local v31 = p25 + buffer.readf32(v1, 0)
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    words[v29] = v32
end

function t1.SlideLatch.begin_slide(p26, p27) -- line: 116
    p26.words[1] = 0
    p26.words[3] = 0
    p26.words[5] = bit32.bor(bit32.band(p26.words[5], 2147483647), (bit32.lshift(if p27 then 1 else 0, 31)))
end

function t1.SlideLatch.grab(p28, p29) -- line: 126
    -- upvalues: t1 (copy)
    local v40 = (if p29 ~= t1.SlideLatch.captured_fakie(p28) then 3 else 1) + 1

    p28.words[v40] = bit32.bor(p28.words[v40], 536870912)
end

function t1.SlideLatch.should_leave(p30, p31) -- line: 133
    -- upvalues: t1 (copy)
    return t1.SlideLatch["end"](p30, p31 ~= t1.SlideLatch.captured_fakie(p30))
end

function t1.SlideLatch.reset(p32) -- line: 137
    p32.words[1] = 0
    p32.words[3] = 0
    p32.words[2] = bit32.band(p32.words[2], 536870911)
    p32.words[4] = bit32.band(p32.words[4], 536870911)
    p32.words[5] = bit32.band(p32.words[5], 1073741823)
end

t1.State = {}

function t1.State.enter(p33) -- line: 149
    p33.elapsed = 0
    p33.smoothed = 0
    p33.mode = 2
end

t1.Settings = {}
t1.Physical = {}
t1.Intents = {}
t1.Attribute = {}

function t1.update(p34, p35, p36, p37, p38, p39, p40, p41) -- line: 182
    -- upvalues: TurnRemap (copy), PointGraph (copy)
    local words = p35.words
    local v45 = TurnRemap.apply(p39.remaps[1], {
        p36.field_32,
        p36.field_56
    })

    TurnRemap.apply(p39.remaps[1], {
        p36.field_36,
        p36.field_56
    })

    local v46 = TurnRemap.apply(p39.remaps[2], {
        p36.field_32,
        p36.field_56
    })

    TurnRemap.apply(p39.remaps[2], {
        p36.field_36,
        p36.field_56
    })

    local v47 = 1 - p36.field_52
    local v48 = -(v45[1] * p36.field_52 + v46[1] * v47)
    local v49 = -(v45[2] * p36.field_52 + v46[2] * v47)
    local v50 = words[2]
    local v51 = words[4]

    words[2] = bit32.band(words[2], 3758096383)
    words[4] = bit32.band(words[4], 3758096383)

    local v54 = bit32.band(v50, 536870912) ~= 0
    local v55 = bit32.band(v51, 536870912) ~= 0
    local v57 = bit32.band(words[5], 1073741824) ~= 0
    local mode = p34.mode
    local v58

    if mode == 2 then
        local v59 = v57 and (bit32.band(words[4], 2147483648) ~= 0 or v55)

        if v57 then
            v57 = bit32.band(words[2], 2147483648) ~= 0 or v54
        end

        if v59 or v57 then
            if not v54 and not v55 then
                words[1] = 0
                words[3] = 0
                words[5] = bit32.bor(bit32.band(words[5], 2147483647), (bit32.lshift(if p37[1] then 1 else 0, 31)))
            end

            v58 = if v59 then 1 else 0
        else
            v58 = mode
        end
    else
        local v66 = true

        if mode == 1 then
            if v57 then
                if bit32.band(words[4], 1073741824) == 0 then
                    if mode ~= 0 or bit32.band(words[2], 1073741824) == 0 then
                        v58 = mode
                    else
                        v66 = false
                    end
                else
                    v66 = false
                end
            else
                v66 = false
            end
        elseif mode == 0 then
            if v57 then
                if bit32.band(words[2], 1073741824) == 0 then
                    v58 = mode
                else
                    v66 = false
                end
            else
                v66 = false
            end
        else
            v58 = mode
        end

        if not v66 then
            v58 = 2
        end
    end

    local v70

    if v58 <= 1 then
        v70 = if v58 == 1 == p37[2] then -1 else 1

        if bit32.band(words[5], 2147483648) ~= 0 then
            v70 = -v70
        end
    else
        v70 = v48
    end

    if v58 ~= p34.mode then
        p34.elapsed = 0
    end

    p34.mode = v58

    local v72 = PointGraph.evaluate(p39.blend, p34.elapsed)
    local v73 = p34.smoothed - p39.maximum_delta
    local v74 = p34.smoothed + p39.maximum_delta
    local v75 = (1 - v72) * p34.smoothed + v72 * v70

    if not (v73 - v75 >= 0) then
        v73 = v75
    end

    p34.elapsed += p38
    p34.smoothed = if not (v74 - v73 >= 0) then v74 else v73

    local v76 = math.abs(p36.body_168)
    local v77 = if p39.speed_threshold < v76 then PointGraph.evaluate(p39.speed_tuck, v76 - p39.speed_threshold) else 0

    p41("Angle", p34.smoothed)
    p41("Direction", v49)
    p41("Quickness", p36.field_52)
    p41("Speed", v77)
    p41("Holding", p36.field_60)

    if v58 <= 1 then
        local v79 = bit32.band(words[5], 2147483648) ~= 0

        p41("Turn", if v58 == 1 ~= v79 then p39.override_turn else -p39.override_turn)

        local v80 = if v58 == 0 then p40.mode_0_slide else p40.mode_1_slide

        if v80 == nil then
            v80 = 0
        end

        local v81

        if v79 then
            local v82 = -v80
            local v83 = math.abs(v82)

            if v83 > 0.5 then
                v83 = 1 - v83
            end

            v81 = if v82 >= 0 then v83 else -v83
        else
            v81 = v80
        end

        p41("Slide", v81)
    elseif p40.fakie_turn ~= nil then
        p41("Turn", p40.fakie_turn)
    end
end

return t1
