-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/transforms")
local v2 = import("skate_core/air/trajectory")
local v3 = import("skate_core/physics/skeleton_animation_record")
local v4 = import("skate_core/trigonometry")
local PointGraph = import("skate_core/point_graph").PointGraph
local v5 = import("skate_game/physics/footplant/math")
local inverse_rigid = v1.inverse_rigid
local Trajectory = v2.Trajectory
local IDENTITY = v3.IDENTITY
local dot, cross, add, sub = v5.dot, v5.cross, v5.add, v5.sub
local scale, madd, reciprocal, length = v5.scale, v5.madd, v5.reciprocal, v5.length
local normalize, point, rotate, clamp01 = v5.normalize, v5.point, v5.rotate, v5.clamp01
local t1 = {}

local function handplant() -- line: 36
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local clip_depth, clip

t1.Candidate = {}

function t1.select(p1, p2, p3, p4, p5, p6) -- line: 49
    -- upvalues: rt (copy), import (copy), v4 (copy), PointGraph (copy), inverse_rigid (copy), Trajectory (copy), IDENTITY (copy), dot (copy), cross (copy), add (copy), sub (copy), scale (copy), madd (copy), reciprocal (copy), length (copy), normalize (copy), point (copy), rotate (copy), clamp01 (copy), clip_depth (ref), clip (ref)
    local v6 = import("skate_game/physics/handplant")
    local UP, GRAVITY, apex_time = v6.UP, v6.GRAVITY, v6.apex_time
    local v7, v8

    if length(p3) > p1.minimum_speed and p3[2] > 0 then
        if math.abs(p4[2]) <= 0.95 and v4.acos(rt.clamp(p4[2], -1, 1)) * 57.295780181884766 > p1.minimum_slope then
            v7 = rt.copy(IDENTITY)

            if math.abs(p4[2]) <= 0.99 then
                v7[1] = normalize(cross(UP, p4))
                v7[2] = rt.copy(UP)
                v7[3] = cross(v7[1], UP)
            end

            v8 = false
        else
            v8 = true
        end
    else
        v8 = true
    end

    if v8 then
        return nil
    end

    v7[4] = rt.copy(p2)

    local v11 = inverse_rigid(v7)
    local v12 = rotate(v11, p3)
    local t2 = {
        v12[1],
        math.sqrt(v12[1] * v12[1] + v12[2] * v12[2]),
        0, 0
    }

    if p5 ~= 0 and p5 ~= (if t2[1] > 0 then 1 else 2) then
        t2[1] = (p5 == 1 and 1 or -1) * 1.52587890625E-05
    end

    local v15 = table.create(7)

    for i = 1, 7 do
        v15[i] = PointGraph.evaluate(p1.window[i], t2[2])
    end

    local v16 = rt.fmax(v15[2], math.abs(t2[1]) - v15[6])
    local v17 = rt.fmin(v15[7], math.abs(t2[1]) + v15[5])

    if v17 <= v16 then
        return nil
    end

    local v18 = rt.fmax(v15[1], t2[2] - v15[4])
    local v19 = t2[2] + v15[3]
    local v20 = if t2[1] > 0 then 1 else -1

    local function apex(p7, p8) -- line: 97
        -- upvalues: p1 (copy), p2 (copy), GRAVITY (copy), apex_time (copy), v11 (copy), v20 (copy), rt (copy), Trajectory (copy), point (copy)
        local t3 = {
            duration = -1,
            position = point(v11, p2),
            velocity = {
                p7 * v20,
                p8,
                0, 0
            },
            acceleration = rt.copy(GRAVITY)
        }
        local v21 = Trajectory.position_at(t3, apex_time(t3))

        v21[2] -= p1.window_drop

        return v21
    end

    local v22 = apex(v16, v18)
    local v23 = apex(v17, v18)
    local v24 = apex(v16, v19)
    local v25 = apex(v17, v19)
    local t4 = if v25[1] > v24[1] then { v24, v25, v23, v22 } else { v25, v24, v22, v23 }
    local t5 = {}
    local t6 = {
        2, 4, 2
    }
    local n1 = 0

    for _, v26 in p6 do
        local v27 = true

        for j = 0, 2 do
            local v28 = t6[j + 1]

            if not (rt.fmin(v26.start[j + 1], v26["end"][j + 1]) <= p2[j + 1] + v28 and rt.fmax(v26.start[j + 1], v26["end"][j + 1]) >= p2[j + 1] - v28) then
                v27 = false
                break
            end
        end

        if v27 then
            if n1 >= 40 then
                break
            end

            n1 += 1

            local v29 = point(v11, v26.start)
            local v30 = point(v11, v26["end"])

            if not (math.abs(normalize(sub(v30, v29))[1]) <= 0.71) then
                local t7 = {
                    v29,
                    v30
                }

                if clip_depth(t7, -p1.depth, true) and clip_depth(t7, 0, false) then
                    local v32 = true

                    for k = 0, 3 do
                        local v33 = sub(t4[(k + 1) % 4 + 1], t4[k + 1])
                        local v34 = normalize({
                            v33[2],
                            -v33[1],
                            0, 0
                        })
                        local v35 = dot(sub(t7[1], t4[k + 1]), v34)
                        local v36 = dot(sub(t7[2], t4[k + 1]), v34)

                        if not clip(t7, v35, v36) then
                            v32 = false
                            break
                        end
                    end

                    if v32 then
                        table.insert(t5, {
                            rt.copy(v26),
                            t7
                        })
                    end
                end
            end
        end
    end

    local v37 = -rt.F32_MAX
    local v38 = -rt.F32_MAX
    local v39 = #t5 - 1
    local v40

    for i = 0, v39 do
        local v41 = t5[i + 1][2]
        local v42 = if v41[1][2] > v41[2][2] then v41[1] else v41[2]
        local v43, v44, v45

        if v42[2] > v37 + 0.1 or v42[2] > v37 - 0.1 and v42[2] <= v37 + 0.1 and v38 < v42[3] then
            v43 = v42[2]
            v45 = i
            v44 = v42[3]
        else
            v44 = v38
            v43 = v37
            v45 = v40
        end

        v38 = v44
        v37 = v43
        v40 = v45
    end

    if v40 == nil then
        return nil
    end

    local v46 = rt.filled(#t5, false)

    v46[v40 + 1] = true

    for _, v47 in { false, true } do
        local v48 = rt.copy(t5[v40 + 1][2])

        if v47 then
            local v49 = v48[2]
            local v50 = v48[1]

            v48[1] = v49
            v48[2] = v50
        end

        while true do
            local v51 = #t5 - 1
            local v52, t9

            for j = 0, v51 do
                local v53 = t5[j + 1][2]

                if not v46[j + 1] then
                    local v54 = false

                    for k = 0, 1 do
                        if dot(sub(v48[2], v53[k + 1]), sub(v48[2], v53[k + 1])) < 0.0024999999441206455 and math.abs((v4.acos(rt.clamp(dot(normalize(sub(v48[2], v48[1])), normalize(sub(v53[2 - k], v53[k + 1]))), -1, 1)))) < 0.5235987901687622 then
                            v52 = j
                            t9 = {
                                rt.copy(v53[k + 1]),
                                rt.copy(v53[2 - k])
                            }
                            v54 = true
                            break
                        end
                    end

                    if v54 then
                        break
                    end
                end
            end

            if v52 == nil then
                break
            end

            v48 = t9
            v46[v52 + 1] = true
        end
    end

    local v56 = scale(add(t4[3], t4[4]), 0.5)
    local v58 = sub(scale(add(t4[1], t4[2]), 0.5), v56)
    local v59 = madd(v58, clamp01((v37 - v56[2]) * reciprocal(v58[2])), v56)
    local t10 = {
        v59[1],
        v59[2],
        0, 0
    }
    local v60 = {
        0, 0, 0, 0
    }
    local v61 = rt.F32_MAX

    for i = 0, #t5 - 1 do
        local v62 = t5[i + 1][2]
        local v63 = v61
        local v64 = v60

        if v46[i + 1] then
            local v65 = sub(v62[2], v62[1])
            local v66 = dot(v65, v65)
            local v67 = if v66 > 1.52587890625E-05 then madd(v65, clamp01(dot(sub(t10, v62[1]), v65) * reciprocal(v66)), v62[1]) else rt.copy(v62[1])

            v63 = dot(sub(v67, t10), sub(v67, t10))

            if v63 < v61 then
                v64 = v67
            else
                v63 = v61
            end
        end

        v60 = v64
        v61 = v63
    end

    return {
        point = point(v7, v60),
        edge = rt.copy(t5[v40 + 1][1]),
        side = t2[1] > 0 and 1 or 2
    }
end

function clip_depth(p9, p10, p11) -- line: 280
    -- upvalues: sub (copy), madd (copy), reciprocal (copy)
    local v68 = if p11 then 1 else -1
    local v69 = (p9[1][3] - p10) * v68
    local v70 = (p9[2][3] - p10) * v68

    if v69 <= 0 and v70 <= 0 then
        return false
    end

    local v71 = p9[2][3] - p9[1][3]
    local v72, v73

    if math.abs(v71) >= 1.52587890625E-05 then
        local v74 = (p10 - p9[1][3]) * reciprocal(v71)

        if v74 > 0 and v74 < 1 then
            v72 = madd(sub(p9[2], p9[1]), v74, p9[1])
            v73 = if v70 <= 0 then 1 else 0
            p9[v73 + 1] = v72
        end
    end

    return true
end

t1.clip_depth = clip_depth

function clip(p12, p13, p14) -- line: 300
    -- upvalues: sub (copy), madd (copy), reciprocal (copy)
    if p13 < 0 and p14 < 0 then
        return false
    end

    if p13 < 0 ~= (p14 < 0) then
        local v75 = madd(sub(p12[2], p12[1]), p13 * reciprocal(p13 - p14), p12[1])

        p12[(p13 >= 0 and 1 or 0) + 1] = v75
    end

    return true
end

t1.clip = clip

return t1
