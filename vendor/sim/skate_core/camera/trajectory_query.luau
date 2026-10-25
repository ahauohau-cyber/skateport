-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/physics/reciprocal_sqrt")
local dot, length, length3, refined_reciprocal = v1.dot, v1.length, v1.length3, v1.refined_reciprocal
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {
    TrajectoryQuery = {}
}

function t1.TrajectoryQuery.collision_time_reference(p1, p2) -- line: 31
    -- upvalues: rt (copy), dot (copy), refined_reciprocal (copy), t1 (copy)
    local duration, duration2 = p1.duration, p1.duration

    if p1.gravity[2] < 0 then
        duration = t1.TrajectoryQuery.step_size(p1, p1.start_error * p1.radius)
        duration2 = t1.TrajectoryQuery.step_size(p1, p1.end_error * p1.radius)
    end

    local v3 = p1.start_error * p1.radius * p1.start_error * p1.radius
    local v4 = 0
    local v5 = t1.TrajectoryQuery.evaluate(p1, 0)
    local v6 = t1.TrajectoryQuery.evaluate(p1, 0 + duration)
    local v7

    while true do
        if not (v4 < p1.duration) then
            return -1
        end

        local t2 = {}

        t2[1] = v6[1] - v5[1]
        t2[2] = v6[2] - v5[2]
        t2[3] = v6[3] - v5[3]
        t2[4] = v6[4] - v5[4]

        local v8, v9

        if not (v3 < dot(t2, t2)) then
            v8 = refined_reciprocal(p1.duration) * v4
            v9 = duration2 * v8 + (1 - v8) * duration
            v4 += v9
            v6 = t1.TrajectoryQuery.evaluate(p1, v4 + v9)
            continue
        end

        local v10 = t2[1]
        local v11 = math.abs(v10) > 1.52587890625E-05 or math.abs(t2[2]) > 1.52587890625E-05 or math.abs(t2[3]) > 1.52587890625E-05
        local v14

        if v11 then
            v7 = p2(rt.copy(v5), rt.copy(v6), p1.radius)
            v14 = v7 == nil
        end

        if not v11 or v14 then
            v5 = rt.copy(v6)
            v8 = refined_reciprocal(p1.duration) * v4
            v9 = duration2 * v8 + (1 - v8) * duration
            v4 += v9
            v6 = t1.TrajectoryQuery.evaluate(p1, v4 + v9)
            continue
        end

        break
    end

    return t1.TrajectoryQuery.time_at_contact(p1, v7, v4)
end

function t1.TrajectoryQuery.evaluate(p3, p4) -- line: 76
    local v15 = p4 * p4
    local t3 = {}

    for i = 0, 3 do
        t3[i + 1] = p3.gravity[i + 1] * 0.5 * v15 + (p3.velocity[i + 1] * p4 + p3.position[i + 1])
    end

    return t3
end

function t1.TrajectoryQuery.step_size(p5, p6) -- line: 85
    -- upvalues: v2 (copy), refined_reciprocal (copy)
    local v16 = refined_reciprocal(p5.gravity[2]) * (p6 * -8)
    local v17 = v2.estimate(v16)
    local v18 = v17 * 0.5 * (-v16 * (v17 * v17) + 1) + v17
    local v19 = v18 * 0.5 * (-v16 * (v18 * v18) + 1) + v18

    if v16 == 0 then
        return 0
    end

    return v16 * v19
end

function t1.TrajectoryQuery.time_at_contact_reference(p7, p8, p9) -- line: 98
    -- upvalues: rt (copy), dot (copy), length (copy), refined_reciprocal (copy), t1 (copy)
    if math.abs(refined_reciprocal(2) * p7.gravity[2]) <= 9.999999747378752E-05 then
        local t4 = {}

        t4[1] = p8[1] - p7.position[1]
        t4[2] = p8[2] - p7.position[2]
        t4[3] = p8[3] - p7.position[3]
        t4[4] = p8[4] - p7.position[4]

        local v21 = length(t4)

        if math.abs(v21) > 9.999999747378752E-05 then
            local v22 = length(p7.velocity)

            if math.abs(v22) > 9.999999747378752E-05 then
                return refined_reciprocal(v22) * v21 * 0.01666666753590107
            end
        end

        return 0
    end

    local v23 = p9
    local v24 = rt.F32_MAX

    while true do
        if not (v23 <= p7.duration) then
            return p7.duration
        end

        local v25 = t1.TrajectoryQuery.evaluate(p7, v23)
        local t5 = {}

        t5[1] = p8[1] - v25[1]
        t5[2] = p8[2] - v25[2]
        t5[3] = p8[3] - v25[3]
        t5[4] = p8[4] - v25[4]

        local v26 = dot(t5, t5)
        local v27

        if v26 <= v24 then
            v27 = v26
        elseif v24 < v26 then
            break
        else
            v27 = v24
        end

        v24 = v27
        v23 += 0.01666666753590107
    end

    return v23 - 0.01666666753590107
end

local function time_at_contact_lanes(p10, p11, p12, p13, p14) -- line: 152
    -- upvalues: rt (copy), length3 (copy), refined_reciprocal (copy)
    local gravity, velocity, position = p10.gravity, p10.velocity, p10.position

    if math.abs(refined_reciprocal(2) * gravity[2]) <= 9.999999747378752E-05 then
        local v29 = length3(p11 - position[1], p12 - position[2], p13 - position[3])

        if math.abs(v29) > 9.999999747378752E-05 then
            local v30 = length3(velocity[1], velocity[2], velocity[3])

            if math.abs(v30) > 9.999999747378752E-05 then
                return refined_reciprocal(v30) * v29 * 0.01666666753590107
            end
        end

        return 0
    end

    local v31 = gravity[1] * 0.5
    local v32 = gravity[2] * 0.5
    local v33 = gravity[3] * 0.5
    local v34 = velocity[1]
    local v35 = velocity[2]
    local v36 = velocity[3]
    local v37 = position[1]
    local v38 = position[2]
    local v39 = position[3]
    local duration = p10.duration
    local v40 = p14
    local v41 = rt.F32_MAX

    while true do
        if not (v40 <= duration) then
            return duration
        end

        local v42 = v40 * v40
        local v43 = p11 - (v31 * v42 + (v34 * v40 + v37))
        local v44 = p12 - (v32 * v42 + (v35 * v40 + v38))
        local v45 = p13 - (v33 * v42 + (v36 * v40 + v39))
        local v46 = v43 * v43 + v44 * v44 + v45 * v45
        local v47

        if v46 <= v41 then
            v47 = v46
        elseif v41 < v46 then
            break
        else
            v47 = v41
        end

        v41 = v47
        v40 += 0.01666666753590107
    end

    return v40 - 0.01666666753590107
end

function t1.TrajectoryQuery.time_at_contact(p15, p16, p17) -- line: 188
    -- upvalues: PERF (copy), t1 (copy), time_at_contact_lanes (copy)
    if PERF.reference then
        return t1.TrajectoryQuery.time_at_contact_reference(p15, p16, p17)
    end

    return (time_at_contact_lanes(p15, p16[1], p16[2], p16[3], p17))
end

local t6 = {
    0, 0, 0, 0
}
local t7 = {
    0, 0, 0, 0
}

local function walk(p18, p19, p20) -- line: 200
    -- upvalues: refined_reciprocal (copy), t1 (copy), time_at_contact_lanes (copy), t6 (copy), t7 (copy)
    local duration, radius, gravity, velocity = p18.duration, p18.radius, p18.gravity, p18.velocity
    local position = p18.position
    local v48, v49

    if gravity[2] < 0 then
        v48 = t1.TrajectoryQuery.step_size(p18, p18.start_error * radius)
        v49 = t1.TrajectoryQuery.step_size(p18, p18.end_error * radius)
    else
        v49 = duration
        v48 = duration
    end

    local v50 = p18.start_error * radius * p18.start_error * radius
    local v51 = gravity[1] * 0.5
    local v52 = gravity[2] * 0.5
    local v53 = gravity[3] * 0.5
    local v54 = gravity[4] * 0.5
    local v55 = velocity[1]
    local v56 = velocity[2]
    local v57 = velocity[3]
    local v58 = velocity[4]
    local v59 = position[1]
    local v60 = position[2]
    local v61 = position[3]
    local v62 = position[4]
    local v63 = 0 * 0
    local v64 = v51 * v63 + (v55 * 0 + v59)
    local v65 = v52 * v63 + (v56 * 0 + v60)
    local v66 = v53 * v63 + (v57 * 0 + v61)
    local v67 = v54 * v63 + (v58 * 0 + v62)
    local v68 = 0 + v48
    local v69 = v68 * v68
    local v70 = v51 * v69 + (v55 * v68 + v59)
    local v71 = v52 * v69 + (v56 * v68 + v60)
    local v72 = v53 * v69 + (v57 * v68 + v61)
    local v73 = v54 * v69 + (v58 * v68 + v62)
    local v74 = refined_reciprocal(duration)
    local n1 = 0
    local v75

    while true do
        if not (n1 < duration) then
            return -1
        end

        local v76 = v70 - v64
        local v77 = v71 - v65
        local v78 = v72 - v66
        local v79, v80, v81, v82

        if not (v50 < v76 * v76 + v77 * v77 + v78 * v78) then
            v79 = v74 * n1
            v80 = v49 * v79 + (1 - v79) * v48
            n1 += v80
            v81 = n1 + v80
            v82 = v81 * v81
            v70 = v51 * v82 + (v55 * v81 + v59)
            v71 = v52 * v82 + (v56 * v81 + v60)
            v72 = v53 * v82 + (v57 * v81 + v61)
            v73 = v54 * v82 + (v58 * v81 + v62)
            continue
        end

        if not (math.abs(v76) > 1.52587890625E-05) and not (math.abs(v77) > 1.52587890625E-05) and not (math.abs(v78) > 1.52587890625E-05) then
            v64 = v70
            v65 = v71
            v66 = v72
            v67 = v73
            v79 = v74 * n1
            v80 = v49 * v79 + (1 - v79) * v48
            n1 += v80
            v81 = n1 + v80
            v82 = v81 * v81
            v70 = v51 * v82 + (v55 * v81 + v59)
            v71 = v52 * v82 + (v56 * v81 + v60)
            v72 = v53 * v82 + (v57 * v81 + v61)
            v73 = v54 * v82 + (v58 * v81 + v62)
            continue
        end

        if p20 then
            v75 = p19({ v64, v65, v66, v67 }, { v70, v71, v72, v73 }, radius)
        else
            t6[1] = v64
            t6[2] = v65
            t6[3] = v66
            t6[4] = v67
            t7[1] = v70
            t7[2] = v71
            t7[3] = v72
            t7[4] = v73
            v75 = p19(t6, t7, radius)
        end

        if v75 == nil then
            v64 = v70
            v65 = v71
            v66 = v72
            v67 = v73
            v79 = v74 * n1
            v80 = v49 * v79 + (1 - v79) * v48
            n1 += v80
            v81 = n1 + v80
            v82 = v81 * v81
            v70 = v51 * v82 + (v55 * v81 + v59)
            v71 = v52 * v82 + (v56 * v81 + v60)
            v72 = v53 * v82 + (v57 * v81 + v61)
            v73 = v54 * v82 + (v58 * v81 + v62)
            continue
        end

        break
    end

    return (time_at_contact_lanes(p18, v75[1], v75[2], v75[3], n1))
end

function t1.TrajectoryQuery.collision_time(p21, p22) -- line: 258
    -- upvalues: PERF (copy), t1 (copy), walk (copy)
    if PERF.reference then
        return t1.TrajectoryQuery.collision_time_reference(p21, p22)
    end

    return (walk(p21, p22, true))
end

function t1.TrajectoryQuery.collision_time_transient(p23, p24) -- line: 268
    -- upvalues: PERF (copy), t1 (copy), walk (copy)
    if PERF.reference then
        return t1.TrajectoryQuery.collision_time_reference(p23, p24)
    end

    return (walk(p23, p24, false))
end

return t1
