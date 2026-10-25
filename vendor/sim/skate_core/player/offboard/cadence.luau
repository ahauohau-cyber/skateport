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

require(sim.import)

local t1 = {
    DT = 0.01666666753590107,
    EPSILON = 0.0010000000474974513
}
local DT, EPSILON = t1.DT, t1.EPSILON

t1.BipedPhase = {}

local BipedPhase = t1.BipedPhase

function t1.BipedPhase.default() -- line: 45
    return {
        phase = 0,
        rate = 0,
        target = -1,
        duration = nil,
        forward_target = false
    }
end

t1.BipedCadence = {}

function t1.BipedCadence.default() -- line: 60
    -- upvalues: BipedPhase (copy)
    return {
        locomotion_index = 0,
        phase = BipedPhase.default()
    }
end

t1.CadenceThresholds = {}

function t1.CadenceThresholds.from_clip_speeds(p3, p4, p5) -- line: 71
    return {
        {
            0.009999999776482582,
            (p4 + p3) * 0.5,
            (p5 + p4) * 0.5,
            1E+10
        }
    }
end

t1.CadenceInput = {}

local select_rate, wrap, select, clamp, subtract, dot, reject, length, square_root

function t1.BipedCadence.update(p6, p7, p8) -- line: 96
    -- upvalues: rt (copy), v1 (copy), EPSILON (copy), BipedPhase (copy), subtract (ref), dot (ref), reject (ref), length (ref), square_root (ref)
    local v9 = subtract(p7.motion_512, p7.motion_reference_272)

    if p7.reject_enabled_708 then
        v9 = reject(v9, p7.reject_axis_400)
    end

    local v10 = length(reject(v9, p7.up_144))
    local v11

    if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
        local v12 = math.abs(v10) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = (if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13) * 1.401298464324817E-45

        if v10 < 0 then
            v11 = -v11
        end
    else
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readf32(v1, 0)
    end

    local v15 = p8[1]

    for i = 0, #v15 - 1 do
        if v11 <= v15[i + 1] then
            p6.locomotion_index = i
            break
        end
    end

    if p7.requested_phase_296 < 0 then
        if p6.locomotion_index == 0 then
            if not (p6.phase.target >= 0) then
                BipedPhase.stop(p6.phase)
            end
        else
            local v16 = rt.copy(p7.animation_motion_224)
            local t2 = {
                v16[1],
                0,
                v16[3]
            }
            local v17 = length(t2)

            if EPSILON < v17 then
                local frame_rows_0_16_32 = p7.frame_rows_0_16_32
                local v18 = table.create(3)

                for i = 1, 3 do
                    local v19 = frame_rows_0_16_32[i]

                    v18[i] = v19[3] * v9[3] + (v19[2] * v9[2] + v19[1] * v9[1])
                end

                local v20 = 1 / v17 * dot(v18, t2)

                v10 = square_root(v18[2] * v18[2] + v20 * v20)
            end

            local v21 = length(v16)

            if v21 < EPSILON then
                p6.phase.rate = 0
            else
                p6.phase.rate = v10 / v21
            end

            p6.phase.target = -1

            if not p7.reject_enabled_708 and not p7.suppress_adjustment_353 and bit32.band(p7.contact_flags_176, 384) ~= 0 then
                local v22 = (length(subtract(p7.contact_point_96, p7.frame_position_48)) - 0.2) / v10
                local v23 = p6.phase.rate * 0.4
                local v24 = p6.phase.rate * 2.5

                if v22 > 0.008333333767950535 then
                    if bit32.band(p7.contact_flags_176, 256) == 0 then
                        BipedPhase.adjust_contact(p6.phase, v22, v23, v24)
                    else
                        local v25 = if p6.phase.phase > 0.37 and p6.phase.phase <= 0.87 then 0.9 else 0.4

                        BipedPhase.adjust_targets(p6.phase, v25, v25, v22, v24)
                    end
                end
            end
        end
    else
        BipedPhase.request(p6.phase, p7.requested_phase_296, p7.requested_duration_288)
    end

    BipedPhase.advance(p6.phase)
end

function t1.BipedPhase.request(p9, p10, p11) -- line: 169
    local v26 = if p11 > 0.1 then p11 - 0.1 else p11

    if p9.target == p10 and p9.duration == v26 then
        return
    end

    local v27 = p10 - p9.phase

    p9.target = p10
    p9.duration = v26
    p9.forward_target = true

    if v27 < 0 then
        p9.rate = (v27 + 1) / v26
    else
        p9.rate = v27 / v26
    end
end

function t1.BipedPhase.stop(p12) -- line: 188
    -- upvalues: wrap (ref), select (ref)
    local n1 = 0
    local n2 = 1.0000000150474662E+30

    for _, v28 in { 0, 0.5 } do
        local v29 = v28 - p12.phase
        local v30 = wrap(0, v29 + 1, 1)
        local v31 = if math.abs(v29) < math.abs(v30) then math.abs(v29) else math.abs(v30)

        if v31 < n2 then
            n2 = v31
            n1 = v28
        end
    end

    p12.forward_target = false
    p12.duration = 0.2
    p12.target = n1

    local v33 = math.abs(n1 - p12.phase)

    p12.rate = select(v33 - (1 - v33), 1 - v33, v33) * 5
end

function t1.BipedPhase.advance(p13) -- line: 213
    -- upvalues: DT (copy), wrap (ref)
    if p13.target < 0 then
        local v34 = p13.rate * DT + p13.phase

        p13.phase = v34 - math.floor(v34)
    elseif p13.forward_target then
        if p13.phase ~= p13.target then
            local v35 = if p13.target < p13.phase then p13.target + 1 else p13.target
            local phase = p13.phase
            local v36 = p13.rate * DT + phase

            if not (phase < v35 and v35 <= v36) then
                p13.phase = v36 - math.floor(v36)
            else
                p13.phase = p13.target
            end
        end
    else
        local phase = p13.phase
        local v37 = phase + wrap(-0.5, p13.target - phase, 0.5)
        local v38 = p13.rate * DT

        if v37 + v38 < phase then
            v37 = phase - v38
        elseif phase < v37 - v38 then
            v37 = phase + v38
        end

        p13.phase = wrap(0, v37, 1)
    end
end

function t1.BipedPhase.adjust_targets(p14, p15, p16, p17, p18) -- line: 249
    -- upvalues: select_rate (ref), wrap (ref), select (ref), clamp (ref)
    local v39 = wrap(0, p15 - p14.phase, 1)
    local v40 = wrap(0, p16 - p14.phase, 1)

    if v39 >= 1 then
        p14.rate = clamp(v40 / p17, 0, p18)
    elseif v40 >= 1 then
        p14.rate = clamp(v39 / p17, 0, p18)
    else
        local v41 = 1 / p17
        local v42 = v39 * v41
        local v43 = v40 * v41

        p14.rate = select_rate(v42, v43, 0, p18, select(v42 - v43, v43, v42))
    end
end

function t1.BipedPhase.adjust_contact(p19, p20, p21, p22) -- line: 266
    -- upvalues: select_rate (ref), wrap (ref)
    local v44 = 1 / p20
    local v45 = wrap(0, 0.45 - p19.phase, 1) * v44
    local v46 = wrap(0, 0.95 - p19.phase, 1) * v44
    local v50 = if math.abs(p19.rate - v45) < math.abs(p19.rate - v46) then v45 else v46

    p19.rate = select_rate(v45, v46, p21, p22, v50)
end

function t1.select_rate(p23, p24, p25, p26, p27) -- line: 279
    -- upvalues: clamp (ref)
    if not (p25 <= p23 and p23 <= p26) then
        if p25 <= p24 and p24 <= p26 then
            return p24
        end

        local v51 = if p23 < p25 then p25 - p23 else p23 - p26
        local v52 = if p24 < p25 then p25 - p24 else p24 - p26

        return clamp(if v51 < v52 then p23 else p24, p25, p26)
    end

    if not (p25 <= p24 and p24 <= p26) then
        return p23
    end

    return p27
end

select_rate = t1.select_rate

function t1.wrap(p28, p29, p30) -- line: 297
    -- upvalues: rt (copy), clamp (ref)
    local n3 = 0

    if p29 < p28 then
        n3 = rt.f_to_i32((math.floor((p30 - p29) / (p30 - p28))))
    elseif p30 < p29 then
        n3 = rt.to_i32(rt.wrapping_sub_u32(0, rt.to_u32(rt.f_to_i32((math.floor((p29 - p28) / (p30 - p28)))))))
    end

    return clamp((p30 - p28) * n3 + p29, p28, p30)
end

wrap = t1.wrap

function t1.select(p31, p32, p33) -- line: 312
    if p31 >= 0 then
        return p32
    end

    return p33
end

select = t1.select

function t1.clamp(p34, p35, p36) -- line: 321
    -- upvalues: select (ref)
    local v55 = select(p35 - p34, p35, p34)

    return select(p36 - v55, v55, p36)
end

clamp = t1.clamp

function t1.subtract(p37, p38) -- line: 327
    return {
        p37[1] - p38[1],
        p37[2] - p38[2],
        p37[3] - p38[3]
    }
end

subtract = t1.subtract

function t1.dot(p39, p40) -- line: 332
    return p39[1] * p40[1] + p39[2] * p40[2] + p39[3] * p40[3]
end

dot = t1.dot

function t1.reject(p41, p42) -- line: 337
    -- upvalues: dot (ref)
    local v56 = dot(p42, p41)

    return {
        p41[1] - p42[1] * v56,
        p41[2] - p42[2] * v56,
        p41[3] - p42[3] * v56
    }
end

reject = t1.reject

function t1.length(p43) -- line: 347
    -- upvalues: dot (ref), square_root (ref)
    return square_root(dot(p43, p43))
end

length = t1.length

function t1.square_root(p44) -- line: 352
    -- upvalues: v1 (copy)
    local v57

    if p44 ~= 0 and p44 > -1.1754943508222875E-38 and p44 < 1.1754943508222875E-38 then
        local v58 = math.abs(p44) * 7.1362384635298E+44
        local v59 = math.floor(v58)
        local v60 = v58 - v59

        v57 = (if v60 > 0.5 or v60 == 0.5 and v59 % 2 == 1 then v59 + 1 else v59) * 1.401298464324817E-45

        if p44 < 0 then
            v57 = -v57
        end
    else
        buffer.writef32(v1, 0, p44)
        v57 = buffer.readf32(v1, 0)
    end

    local v61 = 1 / math.sqrt(v57)
    local v62 = v61 * 0.5 * (-v57 * (v61 * v61) + 1) + v61
    local v63 = v57 * (v62 * 0.5 * (-v57 * (v62 * v62) + 1) + v62)

    if v57 == 0 then
        return 0
    end

    return v63
end

square_root = t1.square_root

return t1
