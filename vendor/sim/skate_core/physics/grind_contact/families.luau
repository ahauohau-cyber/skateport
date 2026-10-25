-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/physics/grind_contact/arithmetic")
local v3 = import("skate_core/physics/grind_contact/admission")
local dot3, scale, add, sub = v1.dot3, v1.scale, v1.add, v1.sub
local segment_triangle, deck_contact, upright_normal = v1.segment_triangle, v1.deck_contact, v1.upright_normal
local Admission, EntryKind = v3.Admission, v3.EntryKind
local t1 = {}

t1.Contact = {}

function t1.rectangle(p1, p2, p3, p4, p5, p6) -- line: 31
    -- upvalues: dot3 (copy), sub (copy), segment_triangle (copy)
    local n1 = 1E+06
    local t2

    for i = 1, #p6 do
        local v5 = i - 1
        local v6 = p6[i]
        local v7 = segment_triangle(v6.start, v6["end"], { p1, p2, p3 }) or segment_triangle(v6.start, v6["end"], { p4, p1, p3 })

        if v7 ~= nil then
            local v8 = sub(v7, p5)
            local v9 = dot3(v8, v8)

            if v9 < n1 then
                n1 = v9
                t2 = {
                    position = v7,
                    primitive = v5
                }
            end
        end
    end

    return t2
end

local rectangle = t1.rectangle

function t1.inverted_contact(p7, p8, p9, p10, p11) -- line: 56
    -- upvalues: rt (copy), scale (copy), deck_contact (copy)
    if bit32.band(p8, 2097152) == 0 then
        return nil
    end

    local v10 = rt.copy(p7)

    v10[2] = scale(p7[2], -1)

    return deck_contact(v10, 0, p9, p10, 0.3, p11)
end

local function tip_contacts_reference(p12, p13, p14, p15, p16, p17) -- line: 70
    -- upvalues: scale (copy), add (copy), rectangle (copy)
    if bit32.band(p13, 2097152) ~= 0 then
        return { nil, nil }
    end

    local t3 = {
        nil,
        nil
    }

    for i = 0, 1 do
        if (p14 == 402 or p14 == 404) and bit32.band(p15, 512) ~= 0 ~= (i == 0) then
            t3[i + 1] = nil
        else
            local v11 = if i == 0 then 1 else -1
            local v12 = add(p12[4], scale(p12[2], 0.02))
            local v13 = add(v12, scale(p12[3], v11 * p16))
            local v14 = add(add(v12, scale(p12[3], v11 * (p16 + 0.215))), scale(p12[2], 0.03))
            local v15 = add(v14, scale(p12[2], -0.2))
            local v16 = add(v13, scale(p12[2], -0.2))

            t3[i + 1] = rectangle(v13, v14, v15, v16, scale(add(v13, v14), 0.5), p17)
        end
    end

    return t3
end

t1.tip_contacts_reference = tip_contacts_reference

local v17 = false

function t1.set_reference(p18) -- line: 112
    -- upvalues: v17 (ref)
    local v18 = v17

    v17 = p18

    return v18
end

local segment_triangle_xyz = v1.segment_triangle_xyz

function t1.tip_contacts(p19, p20, p21, p22, p23, p24) -- line: 118
    -- upvalues: tip_contacts_reference (copy), v17 (ref), segment_triangle_xyz (copy)
    if v17 then
        return (tip_contacts_reference(p19, p20, p21, p22, p23, p24))
    end

    if bit32.band(p20, 2097152) ~= 0 then
        return { nil, nil }
    end

    local t4 = {
        nil,
        nil
    }
    local v19 = p19[2]
    local v20 = p19[3]
    local v21 = p19[4]
    local v22 = v19[1]
    local v23 = v19[2]
    local v24 = v19[3]
    local v25 = v20[1]
    local v26 = v20[2]
    local v27 = v20[3]
    local v28 = v21[1] + v22 * 0.02
    local v29 = v21[2] + v23 * 0.02
    local v30 = v21[3] + v24 * 0.02

    for i = 0, 1 do
        if (p21 == 402 or p21 == 404) and bit32.band(p22, 512) ~= 0 ~= (i == 0) then
            t4[i + 1] = nil
        else
            local v31 = if i == 0 then 1 else -1
            local v32 = v31 * p23
            local v33 = v28 + v25 * v32
            local v34 = v29 + v26 * v32
            local v35 = v30 + v27 * v32
            local v36 = v31 * (p23 + 0.215)
            local v37 = v28 + v25 * v36 + v22 * 0.03
            local v38 = v29 + v26 * v36 + v23 * 0.03
            local v39 = v30 + v27 * v36 + v24 * 0.03
            local v40 = v37 + v22 * -0.2
            local v41 = v38 + v23 * -0.2
            local v42 = v39 + v24 * -0.2
            local v43 = v33 + v22 * -0.2
            local v44 = v34 + v23 * -0.2
            local v45 = v35 + v24 * -0.2
            local v46 = (v33 + v37) * 0.5
            local v47 = (v34 + v38) * 0.5
            local v48 = (v35 + v39) * 0.5
            local n2 = 1E+06
            local t5

            for j = 1, #p24 do
                local v50 = p24[j]
                local start, v51 = v50.start, v50["end"]
                local v52 = segment_triangle_xyz(start, v51, v33, v34, v35, v37, v38, v39, v40, v41, v42) or segment_triangle_xyz(start, v51, v43, v44, v45, v33, v34, v35, v40, v41, v42)

                if v52 ~= nil then
                    local v53 = v52[1] - v46
                    local v54 = v52[2] - v47
                    local v55 = v52[3] - v48
                    local v56 = v53 * v53 + v54 * v54 + v55 * v55

                    if v56 < n2 then
                        n2 = v56
                        t5 = {
                            position = v52,
                            primitive = j - 1
                        }
                    end
                end
            end

            t4[i + 1] = t5
        end
    end

    return t4
end

local function v57(p25, p26) -- line: 174
    -- upvalues: rt (copy), v2 (copy), dot3 (copy), scale (copy), sub (copy)
    local v58 = sub(p26["end"], p26.start)

    return {
        direction = scale(v58, v2.inverse_square_root(dot3(v58, v58))),
        centre = rt.copy(p25.position),
        front = rt.copy(p26["end"]),
        rear = rt.copy(p26.start),
        primitive = p25.primitive
    }
end

t1.geometry = v57

function t1.is_backslash(p27, p28, p29, p30, p31, p32) -- line: 188
    -- upvalues: dot3 (copy), sub (copy)
    if p32 == 402 then
        return false
    end

    local t6 = {
        sub(p29[1], p28),
        sub(p29[2], p28)
    }
    local t7 = {
        dot3(t6[1], p30),
        dot3(t6[2], p30)
    }

    if math.abs(t7[1] - t7[2]) <= p31 * 0.1 then
        return false
    end

    local v60 = if t7[1] > t7[2] then t6[1] else t6[2]

    return dot3(sub(p27, p28), v60) > 0
end

function t1.darkslide(p33, p34, p35, p36, p37, p38, p39) -- line: 214
    -- upvalues: v2 (copy), dot3 (copy), scale (copy), sub (copy), upright_normal (copy), Admission (copy), v57 (copy)
    local v61 = v57(p34, p35)
    local v62 = sub(p35["end"], p35.start)

    v61.direction = scale(v62, v2.reciprocal(v2.square_root(dot3(v62, v62))))

    if dot3(upright_normal(v61.direction), scale(p33[2], -1)) <= 0.45 then
        return nil
    end

    local v63 = Admission.test(p39, 400, v61.direction, false)

    if not v63.allowed then
        return nil
    end

    local v64 = dot3(sub(p33[4], p34.position), p33[2])

    return if not (dot3(scale(p33[2], v64), scale(p33[2], v64)) >= 0.005625) and (p37 ~= 100 or not (math.abs((dot3(p36, v61.direction))) <= 0.75) or not (p38 <= 10)) then {
        front = false,
        kind = 5,
        geometry = v61,
        entry_kind = v63.kind
    } else nil
end

function t1.five_o(p40, p41, p42, p43, p44, p45, p46, p47, p48) -- line: 244
    -- upvalues: rt (copy), dot3 (copy), scale (copy), sub (copy), Admission (copy), v57 (copy)
    if bit32.band(p44, 1073741824) ~= 0 then
        return nil
    end

    local t8 = {
        nil,
        nil
    }

    for i = 1, 2 do
        local v66 = p41[i]

        if v66 ~= nil then
            local v67 = v57(v66, p42[v66.primitive + 1])
            local v68 = dot3(sub(p40[4], v66.position), p40[2])
            local v69 = scale(p40[2], v68)

            if not (dot3(v69, v69) >= 0.016899999231100082) then
                local v70 = Admission.test(p48, 403, v67.direction, true)

                if v70.allowed and not (math.abs((dot3(p40[1], v67.direction))) >= 0.906) and not (math.abs((dot3(p40[2], v67.direction))) >= 0.46) then
                    t8[i] = {
                        v67,
                        v70.kind
                    }
                end
            end
        end
    end

    local v73 = if dot3(p40[3], p43) > 0 then 0 else 1
    local v74 = 1 - v73
    local v75 = t8[v73 + 1] ~= nil
    local v76 = t8[v74 + 1] ~= nil
    local v77, v78

    if v75 and v76 then
        v77 = if p46 > 30 then bit32.band(p45, 4096) ~= 0 else p47 > 0.68
        v78 = not v77
    elseif v75 or not v76 then
        v77 = not not (v75 and not v76) and (p46 <= 30 or bit32.band(p45, 4096) ~= 0)
        v78 = false
    else
        v77 = false
        v78 = true
    end

    if not v78 then
        if not v77 then
            return nil
        end

        v74 = v73
    end

    local v81 = t8[v74 + 1]

    return if v81 ~= nil then {
        kind = 3,
        geometry = rt.copy(v81[1]),
        front = v74 == 0,
        entry_kind = v81[2]
    } else nil
end

function t1.tipslide(p49, p50, p51, p52, p53, p54, p55, p56, p57, p58, p59) -- line: 323
    -- upvalues: dot3 (copy), scale (copy), sub (copy), Admission (copy), EntryKind (copy), v57 (copy)
    if bit32.band(p54, 1073741824) ~= 0 then
        return nil
    end

    local v82 = p50[1] ~= nil
    local v83 = if v82 then p50[1] else p50[2]

    if v83 == nil then
        return nil
    end

    local v84 = v57(v83, p51[v83.primitive + 1])
    local v85 = Admission.test(p59, 402, v84.direction, true)

    if not v85.allowed then
        return nil
    end

    local v86, v87, v88, direction, v89, t9, v90

    if v85.kind ~= EntryKind.DropIn and (not (p52[2] < 0) or p53 == 400) then
        v86 = sub(p49[4], v83.position)
        v87 = dot3(v86, p49[2])
        v88 = scale(p49[2], v87)

        if dot3(v88, v88) >= 0.003599999938160181 then
            return nil
        end

        direction = v84.direction
        v89 = sub(p52, scale(direction, dot3(v84.direction, p52)))

        if dot3(v89, v89) < 9 then
            if math.abs(p57) > 0 then
                if dot3(sub(v83.position, p49[4]), p58) >= 0 then
                    return nil
                end
            elseif p56 > 30 then
                v90 = dot3(sub(v83.position, p49[4]), p52) > 0

                if bit32.band(p55, 4096) ~= 0 ~= v90 then
                    return nil
                end
            end
        end

        t9 = {
            kind = 2,
            geometry = v84,
            front = v82
        }
        t9.entry_kind = v85.kind

        return t9
    end

    if p49[4][2] <= v83.position[2] then
        return nil
    end

    v87 = dot3(sub(p49[4], v83.position), p49[2])
    v88 = scale(p49[2], v87)

    if dot3(v88, v88) >= 0.003599999938160181 then
        return nil
    end

    v89 = sub(p52, scale(v84.direction, dot3(v84.direction, p52)))

    if dot3(v89, v89) < 9 then
        if math.abs(p57) > 0 then
            if dot3(sub(v83.position, p49[4]), p58) >= 0 then
                return nil
            end
        elseif p56 > 30 then
            v90 = dot3(sub(v83.position, p49[4]), p52) > 0

            if bit32.band(p55, 4096) ~= 0 ~= v90 then
                return nil
            end
        end
    end

    t9 = {
        kind = 2,
        geometry = v84,
        front = v82
    }
    t9.entry_kind = v85.kind

    return t9
end

return t1
