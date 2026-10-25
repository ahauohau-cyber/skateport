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
local PointGraph = import("skate_core/point_graph").PointGraph
local Trajectory = import("skate_core/air/trajectory/prediction").Trajectory
local UP, dot, add, sub = v9.UP, v9.dot, v9.add, v9.sub
local scale, madd, cross, inverse_length = v9.scale, v9.madd, v9.cross, v9.inverse_length
local reciprocal, angle_between, length, normalize = v9.reciprocal, v9.angle_between, v9.length, v9.normalize
local t1 = {}

function t1.trajectory_box_filter(p3, p4, p5) -- line: 41
    -- upvalues: UP (copy), dot (copy), add (copy), sub (copy), scale (copy), cross (copy), inverse_length (copy), normalize (copy)
    local v11 = table.create(#p3)

    for i = 1, #p3 do
        local v12 = p3[i]
        local v13 = sub(p4[v12 + 1]["end"], p4[v12 + 1].start)

        v11[i] = scale(v13, inverse_length(dot(v13, v13)))
    end

    local v14 = table.create(#p3)

    for i = 0, #p3 - 1 do
        local v15 = p3[i + 1]
        local v16 = p4[v15 + 1]
        local v17 = #p3 - 1
        local v18 = true

        for j = 0, v17 do
            local v19 = p3[j + 1]
            local v20 = v18

            if i ~= j then
                local v21 = cross(v11[i + 1], v11[j + 1])

                if dot(v21, v21) < 9.999999747378752E-05 then
                    local v22 = p4[v19 + 1]
                    local v23 = sub(v22.start, v16.start)
                    local v24 = sub(v23, scale(v11[j + 1], dot(v11[j + 1], v23)))
                    local v25 = dot(v24, v24)

                    if v25 > 9.999999747378752E-05 and v25 < 0.010000000707805157 then
                        local v26 = scale(add(v16.start, v16["end"]), 0.5)
                        local v27 = sub(v22.start, v26)

                        if dot(v27, sub(v22["end"], v26)) < 0 then
                            local v29 = dot(v23, (normalize(cross(cross(v11[i + 1], UP), v11[i + 1]))))
                            local v30 = add(v26, sub(v27, scale(v11[j + 1], dot(v11[j + 1], v27))))
                            local v31 = sub(v26, p5)
                            local v32 = sub(v30, p5)

                            if v29 > -0.02 and dot(v31, v31) > dot(v32, v32) or v29 > 0.02 then
                                v20 = false
                            end
                        end
                    end
                end
            end

            v18 = v20
        end

        if v18 then
            table.insert(v14, v15)
        end
    end

    return v14
end

function t1.descending_plane_time(p6, p7, p8) -- line: 94
    -- upvalues: rt (copy), dot (copy), scale (copy), inverse_length (copy), reciprocal (copy)
    local v33 = dot(p8, p6.position) - dot(p7, p8)
    local v34 = dot(p8, p6.velocity)
    local v35 = dot(p8, scale(p6.acceleration, reciprocal(2)))
    local v36 = v34 * v34 - 4 * v35 * v33

    if not (v36 < 0) then
        local v37 = reciprocal(2 * v35)

        if v36 > 0 then
            local v38 = v36 * inverse_length(v36)

            return rt.fmax(v37 * (-v34 + v38), v37 * (-v34 - v38))
        end

        local v39 = v37 * -v34

        if v39 > 0 then
            return v39
        end
    end

    return nil
end

function t1.consider_grind_primitive(p9, p10, p11, p12) -- line: 117
    -- upvalues: rt (copy), v1 (copy), Trajectory (copy), UP (copy), dot (copy), add (copy), sub (copy), scale (copy), madd (copy), cross (copy), inverse_length (copy), reciprocal (copy), length (copy), normalize (copy), t1 (copy)
    local v40 = sub(p10["end"], p10.start)
    local v41 = cross(v40, cross(UP, v40))
    local v42 = scale(v41, inverse_length(dot(v41, v41)))
    local v43 = length(v40)

    if v43 > 1 then
        v40 = scale(v40, reciprocal(v43))
    end

    local v44 = madd(v42, p9.request.radius, scale(v42, p12))
    local v45 = t1.descending_plane_time(p9.request.trajectory, add(p10.start, v44), v42)

    if v45 == nil then
        return nil
    end

    local v46 = sub(Trajectory.position_at(p9.request.trajectory, v45), v44)
    local v47 = normalize(v40)
    local v48 = sub(v46, p10.start)
    local v49 = length(cross(v48, v47))
    local v50 = madd(v47, dot(v47, v48), p10.start)
    local v51 = scale(v40, 0.1)

    if not (dot(sub(v50, sub(p10.start, v51)), sub(v50, add(p10["end"], v51))) < 0) then
        return nil
    end

    local v52 = rt.copy(p9.request.trajectory.velocity)
    local v53 = normalize(sub(v52, scale(v42, dot(v42, v52))))
    local v54 = sub(v50, p9.request.trajectory.position)

    v54[2] = 0

    local t2 = {
        point = v50,
        trajectory_point = v46,
        direction = v47,
        approach = v53,
        distance = v49,
        time = v45,
        angle = t1.folded_approach_angle(v54, v47, v42)
    }
    local f_to_i32 = rt.f_to_i32
    local v55 = v45 * 59.999996185302734
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

    t2.frame = f_to_i32(v56)
    t2.primitive = p11

    return t2
end

function t1.folded_approach_angle(p13, p14, p15) -- line: 163
    -- upvalues: v10 (copy), dot (copy), scale (copy), cross (copy), angle_between (copy)
    local v60 = angle_between(p13, p14)
    local v61 = dot(p13, p13)
    local v62 = dot(p14, p14)

    if v61 > 9.999999747378752E-05 and v62 > 9.999999747378752E-05 then
        local function unit(p16, p17) -- line: 168
            -- upvalues: v10 (copy), scale (copy)
            local v63 = v10.reciprocal_square_root_estimate(p17)

            return scale(p16, v63 * 0.5 * (-p17 * (v63 * v63) + 1) + v63)
        end

        local v64 = v10.reciprocal_square_root_estimate(v61)

        if dot(cross(scale(p13, v64 * 0.5 * (-v61 * (v64 * v64) + 1) + v64), unit(p14, v62)), p15) < 0 then
            v60 = 6.2831854820251465 - v60
        end
    end

    local v65 = v60 * 0.15915493667125702
    local v66 = v65 - math.floor(v65)
    local v67 = (v66 - (if v66 > 0.5 then 1 else 0)) * 6.2831854820251465
    local v68 = if v67 > 0 then 1 else -1
    local v69 = v67 * v68

    if v69 > 1.5707963705062866 then
        v69 -= 3.141592653589793
    end

    return (math.abs(v68 * v69))
end

function t1.take_best_grind(p18, p19, p20) -- line: 188
    -- upvalues: PointGraph (copy)
    local v71 = #p18 - 1
    local n1 = 1000
    local n2 = 3.141592653589793
    local n3 = -10000
    local v72

    for i = 0, v71 do
        local v73 = p18[i + 1]

        if v73.distance < p19 then
            if n2 - v73.angle > PointGraph.evaluate(p20, v73.point[2] - n3) then
                n3 = v73.point[2]
                v72 = i
                n1 = -1
                n2 = v73.angle
            end
        elseif v73.distance < n1 then
            v72 = i
            n1 = v73.distance
        end
    end

    if v72 == nil then
        return nil
    end

    return table.remove(p18, v72 + 1)
end

return t1
