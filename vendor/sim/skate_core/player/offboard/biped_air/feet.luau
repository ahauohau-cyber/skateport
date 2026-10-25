-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_launch/math")
local v2 = import("skate_core/player/wipeout_state/math")
local transform_point = import("skate_core/physics/skeleton_animation_record").transform_point
local dot, length, limit_angle, madd = v1.dot, v1.length, v1.limit_angle, v1.madd
local scale, sub = v1.scale, v1.sub
local normalize_or, reciprocal = v2.normalize_or, v2.reciprocal
local t1 = {
    Line = {},
    Input = {},
    Target = {}
}

function t1.update(p1, p2) -- line: 47
    -- upvalues: rt (copy), transform_point (copy), dot (copy), length (copy), madd (copy), scale (copy), sub (copy), t1 (copy)
    for i = 0, 1 do
        local v3 = p1.hands[i + 1]
        local v4 = p2.lines[i + 1]

        v3.vectors_0_to_64[2] = rt.copy(p2.world_foot_pairs[i + 1][1])
        v3.vectors_0_to_64[4] = rt.copy(v4.position)
        v3.vectors_0_to_64[5] = rt.copy(v4.normal)
        v3.word_80 = v4.surface
        v3.flag_84 = v4.valid

        local v6 = bit32.bxor(i, if bit32.band(p2.flags_2476, 4) == 0 then 0 else 1)

        v3.flags_104_to_107[3] = bit32.band(p2.flags_2484, (bit32.lshift(1, v6 + 6))) ~= 0
        v3.flags_104_to_107[4] = bit32.band(p2.flags_2484, (bit32.lshift(1, v6 + 2))) ~= 0
    end

    if p1.words_308_to_316[1] == 0 then
        p1.vectors_224_to_272[3] = rt.copy(p2.effective_root[4])
        p1.flags_304_to_307[4] = true
    end

    for i = 0, 1 do
        local v11 = p1.hands[i + 1]
        local v12 = p1.word_300 ~= 3

        if v12 then
            for _, v13 in p2.local_foot_pairs[i + 1] do
                if not (v13[2] < 0.09) then
                    v12 = false
                    break
                end
            end
        end

        v11.flags_104_to_107[1] = v12

        if v11.flag_84 then
            local v14 = t1.clamp_normal(v11.vectors_0_to_64[5])

            v11.vectors_0_to_64[3] = rt.copy(v14)

            local v15 = p2.world_foot_pairs[i + 1]
            local t2 = {
                dot(v14, sub(v15[1], v11.vectors_0_to_64[4])),
                dot(v14, sub(v15[2], v11.vectors_0_to_64[4]))
            }
            local v16 = rt.fmax(t2[1], t2[2])

            v12 = v16 < 0.09 or v12 and v16 < 0.2
        else
            v11.vectors_0_to_64[3] = { 0, 1, 0, 0 }
        end

        v11.flags_104_to_107[2] = v12
    end

    local v17 = bit32.band(p2.flags_2476, 4) ~= 0
    local v19 = bit32.band(p2.flags_2480, if v17 then 32 else 64) ~= 0
    local v21 = bit32.band(p2.flags_2480, if v17 then 64 else 32) ~= 0

    if v19 then
        p1.hands[1].flags_104_to_107[2] = true
        p1.hands[2].flags_104_to_107[2] = false
    elseif v21 then
        p1.hands[1].flags_104_to_107[2] = false
        p1.hands[2].flags_104_to_107[2] = true
    end

    p1.scalars_288_to_296[2] += 0.01666666753590107

    local n1 = 2

    if p2.state == 501 then
        n1 = 3
    elseif p1.flags_304_to_307[1] then
        local v22 = p1.hands[1].flags_104_to_107[2]
        local v23 = p1.hands[2].flags_104_to_107[2]

        n1 = if v22 and not v23 then 0 elseif v22 or not v23 then 2 else 1
    end

    if n1 ~= p1.word_300 then
        p1.word_300 = n1
        p1.scalars_288_to_296[2] = 0

        if n1 < 2 then
            p1.vectors_224_to_272[4] = rt.copy(p2.world_foot_pairs[n1 + 1][1])
        else
            p1.vectors_224_to_272[4] = { 0, 0, 0, 0 }
        end
    end

    for i = 0, 1 do
        local v24 = rt.copy(p1.hands[i + 1])
        local v25 = rt.copy(v24.vectors_0_to_64[2])

        if p1.word_300 == i then
            local v26 = sub(p1.vectors_224_to_272[4], v25)

            v26[2] = 0

            local v27

            if dot(v26, v26) < 0.006399999838322401 then
                v27 = rt.copy(p1.vectors_224_to_272[4])
            else
                local v28 = rt.copy(p1.vectors_224_to_272[4])

                v27 = madd(v26, 0.08 / length(v26), v25)
                v27[2] = v28[2]
                p1.vectors_224_to_272[4] = rt.copy(v27)
            end

            p1.hands[i + 1].vectors_0_to_64[1] = rt.copy(v27)
        else
            if v24.flag_84 then
                v25[2] = t1.foot_height(p1, p2, v24.vectors_0_to_64[4][2], v25[2] - rt.fmax(v24.scalars_96_100[1], 0))
            end

            local v30 = rt.fmax(v24.scalars_96_100[2] - 0.01666666753590107, 0)

            p1.hands[i + 1].scalars_96_100[2] = v30

            local v31 = 1 - v30 * 10

            p1.hands[i + 1].vectors_0_to_64[1] = madd(v25, v31, scale(v24.vectors_0_to_64[1], 1 - v31))
        end
    end

    local v32 = table.create(2)

    for i = 0, 1 do
        local v33 = p1.hands[i + 1]
        local v34 = p1.word_300 == i

        if v34 and bit32.band(p2.flags_2484, 2147483648) == 0 then
            v33.scalars_96_100[2] = 0.1
        end

        local v35 = if v33.flags_104_to_107[2] and v33.flag_84 then rt.copy(v33.vectors_0_to_64[3]) else nil

        v32[i + 1] = {
            position = if v34 then rt.copy(v33.vectors_0_to_64[1]) else transform_point(p2.inverse_root, v33.vectors_0_to_64[1]),
            world = v34,
            blend = v34 and 1 or 0.3,
            normal = v35
        }
    end

    p1.scalars_288_to_296[1] = p2.root[4][2]
    p1.scalars_288_to_296[3] = t1.height_correction(p1, p2)

    return v32
end

function t1.foot_height(p3, p4, p5, p6) -- line: 186
    -- upvalues: rt (copy)
    local v37 = p5 + 0.02
    local v38 = p6 - p3.scalars_288_to_296[1] + p5
    local v39 = rt.fmax(rt.fmin(v38, v37 + 0.08), v37)
    local v40 = rt.fmax(p6, v39)
    local v41 = p4.velocity[2] * 0.01666666753590107 + p4.position[2] - 0.46

    if v40 - p6 > 0.4 or v41 < v40 then
        return p6
    end

    return v40
end

function t1.clamp_normal(p7) -- line: 200
    -- upvalues: rt (copy), length (copy), scale (copy), reciprocal (copy)
    local v42 = rt.copy(p7)

    if v42[2] >= 0.9 then
        return v42
    end

    v42[2] = 0

    local v43 = scale(v42, reciprocal(length(v42)) * 0.43588994289762845)

    v43[2] = 0.9

    return v43
end

function t1.height_correction(p8, p9) -- line: 213
    -- upvalues: rt (copy), dot (copy), scale (copy), sub (copy), normalize_or (copy)
    local v44 = false

    for _, v45 in p8.hands do
        if v45.flag_84 then
            v44 = true
            break
        end
    end

    if not v44 then
        return 0
    end

    local n2 = 1E+10

    for _, v46 in p8.hands do
        v46.scalars_96_100[1] = 0

        if v46.flag_84 then
            if v46.flags_104_to_107[1] then
                local v47 = v46.vectors_0_to_64[5]
                local v48 = p9.effective_root[1]
                local v49 = normalize_or(sub(v47, scale(v48, dot(v48, v47))), { 0, 0, 0, 0 })

                v46.scalars_96_100[1] = dot(v49, p9.effective_root[3]) * 0.2
            end

            n2 = rt.fmin(n2, v46.vectors_0_to_64[4][2] + v46.scalars_96_100[1])
        end
    end

    return p8.scalars_288_to_296[1] - n2
end

function t1.set_normal(p10, p11) -- line: 243
    -- upvalues: rt (copy), limit_angle (copy)
    if p10.normal_blend > 0 then
        p10.normal = limit_angle(p11, p10.normal, 0.1)
    end

    p10.normal_set = true
    p10.normal_blend = rt.fmin(p10.normal_blend + 0.2, 1)
end

return t1
