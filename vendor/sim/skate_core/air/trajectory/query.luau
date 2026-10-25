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
local v9 = import("skate_core/air/trajectory/math")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/air/trajectory/prediction")
local Trajectory, QueryResult = v11.Trajectory, v11.QueryResult
local ZERO, UP, STEP, dot = v9.ZERO, v9.UP, v9.STEP, v9.dot
local add, sub, scale, cross = v9.add, v9.sub, v9.scale, v9.cross
local inverse_length, length, normalize = v9.inverse_length, v9.length, v9.normalize
local t1 = {
    SurfaceHit = {}
}

function t1.query_trajectory(p3, p4, p5) -- line: 50
    -- upvalues: rt (copy), Trajectory (copy), QueryResult (copy), STEP (copy), dot (copy), sub (copy), t1 (copy)
    local v12 = rt.copy(p3.trajectory)
    local duration, duration2 = v12.duration, v12.duration

    if v12.acceleration[2] < 0 then
        duration = t1.step_size(v12.acceleration[2], p3.start_error * p3.radius)
        duration2 = t1.step_size(v12.acceleration[2], p3.end_error * p3.radius)
    end

    local v13 = p3.start_error * p3.radius * p3.start_error * p3.radius
    local v14 = 0
    local v15 = Trajectory.position_at(v12, 0)
    local v16 = Trajectory.position_at(v12, 0 + duration)
    local v17

    while true do
        if not (v14 < v12.duration) then
            return QueryResult.miss()
        end

        local v18 = sub(v16, v15)
        local v19, v20

        if not (v13 < dot(v18, v18)) then
            v19 = t1.reciprocal(v12.duration) * v14
            v20 = duration2 * v19 + (1 - v19) * duration
            v14 += v20
            v16 = Trajectory.position_at(v12, v14 + v20)
            continue
        end

        local v21 = v18[1]
        local v22 = math.abs(v21) > 1.52587890625E-05 or math.abs(v18[2]) > 1.52587890625E-05 or math.abs(v18[3]) > 1.52587890625E-05
        local v25

        if v22 then
            v17 = p4(v15, v16, p3.radius)
            v25 = v17 == nil
        end

        if not v22 or v25 then
            v15 = v16
            v19 = t1.reciprocal(v12.duration) * v14
            v20 = duration2 * v19 + (1 - v19) * duration
            v14 += v20
            v16 = Trajectory.position_at(v12, v14 + v20)
            continue
        end

        break
    end

    local v26, v27 = t1.time_at_contact(p3, v17.position, v14)
    local v28 = p5(v17.position, p3.radius)
    local v29 = Trajectory.velocity_at(v12, v27 * STEP)

    return {
        contact_position = rt.copy(v17.position),
        contact_normal = rt.copy(v17.normal),
        landing_normal = t1.average_landing_normal(v28, v29),
        contact_time = v26,
        contact_frame = v27,
        contact_transform = rt.copy(v17.transform),
        surface = v17.surface,
        geometry = v17.geometry
    }
end

function t1.reciprocal(p6) -- line: 102
    -- upvalues: v10 (copy)
    local v30 = v10.reciprocal_estimate(p6)
    local v31 = v30 * (-v30 * p6 + 1) + v30

    return v31 * (-v31 * p6 + 1) + v31
end

function t1.step_size(p7, p8) -- line: 110
    -- upvalues: inverse_length (copy), t1 (copy)
    local v32 = t1.reciprocal(p7) * (p8 * -8)

    if v32 == 0 then
        return 0
    end

    return v32 * inverse_length(v32)
end

function t1.time_at_contact(p9, p10, p11) -- line: 124
    -- upvalues: rt (copy), v1 (copy), Trajectory (copy), STEP (copy), dot (copy), sub (copy), length (copy), t1 (copy)
    local v33 = rt.copy(p9.trajectory)

    if math.abs(t1.reciprocal(2) * v33.acceleration[2]) <= 9.999999747378752E-05 then
        local v35 = length(sub(p10, v33.position))

        if not (math.abs(v35) > 9.999999747378752E-05) then
            return 0, 0
        end

        local v36 = length(v33.velocity)

        if not (math.abs(v36) > 9.999999747378752E-05) then
            return 0, 0
        end

        local v37 = t1.reciprocal(v36) * v35

        return v37 * STEP, rt.f_to_i32((math.ceil(v37)))
    end

    local v38 = p11
    local v39 = rt.F32_MAX
    local v40

    while true do
        if v38 <= v33.duration then
            local v41 = sub(p10, Trajectory.position_at(v33, v38))
            local v42 = dot(v41, v41)

            if v42 <= v39 then
                v39 = v42

                local v43 = v38 + STEP

                if v43 ~= 0 and v43 > -1.1754943508222875E-38 and v43 < 1.1754943508222875E-38 then
                    local v44 = math.abs(v43) * 7.1362384635298E+44
                    local v45 = math.floor(v44)
                    local v46 = v44 - v45

                    v38 = (if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45) * 1.401298464324817E-45

                    if v43 < 0 then
                        v38 = -v38
                    end
                else
                    buffer.writef32(v1, 0, v43)
                    v38 = buffer.readf32(v1, 0)
                end
            else
                if v39 < v42 then
                    local v47 = v38 - STEP

                    if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
                        local v48 = math.abs(v47) * 7.1362384635298E+44
                        local v49 = math.floor(v48)
                        local v50 = v48 - v49

                        v38 = (if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49) * 1.401298464324817E-45

                        if v47 < 0 then
                            v38 = -v38
                        end
                    else
                        buffer.writef32(v1, 0, v47)
                        v38 = buffer.readf32(v1, 0)
                    end

                    v40 = true
                    break
                end

                local v51 = v38 + STEP

                if v51 == 0 then
                    buffer.writef32(v1, 0, v51)
                    v38 = buffer.readf32(v1, 0)
                elseif v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
                    local v52 = math.abs(v51) * 7.1362384635298E+44
                    local v53 = math.floor(v52)
                    local v54 = v52 - v53

                    v38 = (if v54 > 0.5 or v54 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53) * 1.401298464324817E-45

                    if v51 < 0 then
                        v38 = -v38
                    end
                else
                    buffer.writef32(v1, 0, v51)
                    v38 = buffer.readf32(v1, 0)
                end
            end

            continue
        end

        v40 = false
        break
    end

    if not v40 then
        v38 = v33.duration
    end

    local f_to_i32 = rt.f_to_i32
    local v55 = t1.reciprocal(STEP)
    local v56

    if v55 ~= 0 and v55 > -1.1754943508222875E-38 and v55 < 1.1754943508222875E-38 then
        local v57 = math.abs(v55) * 7.1362384635298E+44
        local v58 = math.floor(v57)
        local v59 = v57 - v58

        v56 = (if v59 > 0.5 or v59 == 0.5 and v58 % 2 == 1 then v58 + 1 else v58) * 1.401298464324817E-45

        if v55 < 0 then
            v56 = -v56
        end
    else
        buffer.writef32(v1, 0, v55)
        v56 = buffer.readf32(v1, 0)
    end

    local v60 = v56 * v38
    local v61

    if v60 == 0 or not (v60 > -1.1754943508222875E-38) or not (v60 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v60)
        v61 = buffer.readf32(v1, 0)

        return v38, f_to_i32((math.ceil(v61)))
    end

    local v62 = math.abs(v60) * 7.1362384635298E+44
    local v63 = math.floor(v62)
    local v64 = v62 - v63

    v61 = (if v64 > 0.5 or v64 == 0.5 and v63 % 2 == 1 then v63 + 1 else v63) * 1.401298464324817E-45

    if v60 < 0 then
        v61 = -v61
    end

    return v38, f_to_i32((math.ceil(v61)))
end

function t1.average_landing_normal(p12, p13) -- line: 161
    -- upvalues: rt (copy), ZERO (copy), UP (copy), dot (copy), add (copy), sub (copy), scale (copy), cross (copy), inverse_length (copy), normalize (copy)
    local t2 = {}
    local v65 = rt.copy(ZERO)
    local n1 = -1

    for i = 1, math.min(#p12, 64) do
        local v68 = p12[i]
        local v69 = cross(sub(v68[2], v68[1]), sub(v68[3], v68[1]))
        local v70 = scale(v69, inverse_length(dot(v69, v69)))
        local v71, v72

        if v70[2] > 0.7 or dot(v70, p13) <= 0 then
            local v73 = dot(v70, UP)
            local v74

            if n1 < v73 then
                v74 = v70
            else
                v73 = n1
                v74 = v65
            end

            v71 = v73
            table.insert(t2, v70)
            v72 = v74
        else
            v71 = n1
            v72 = v65
        end

        n1 = v71
        v65 = v72
    end

    if #t2 == 0 then
        return rt.copy(UP)
    end

    local v75 = rt.copy(ZERO)

    for _, v76 in t2 do
        if dot(v65, v76) > 0.5 then
            v75 = add(v75, v76)
        end
    end

    return normalize(v75)
end

return t1
