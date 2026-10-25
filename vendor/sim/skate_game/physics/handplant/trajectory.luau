-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_core/air/trajectory")
local v2 = import("skate_core/trigonometry")
local PointGraph = import("skate_core/point_graph").PointGraph
local v3 = import("skate_game/physics/footplant/math")
local v4 = import("skate_game/physics/handplant/rotation")
local Trajectory = v1.Trajectory
local STEP, dot, cross, add = v3.STEP, v3.dot, v3.cross, v3.add
local sub, scale, madd, reciprocal = v3.sub, v3.scale, v3.madd, v3.reciprocal
local length, normalize, clamp_length, clamp01 = v3.length, v3.normalize, v3.clamp_length, v3.clamp01
local t1 = {}

local function handplant() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function air_trajectory() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local apex_position, to_apex, from_apex, arc_between, bezier

t1.Handplant = {}

function t1.Handplant.launch(p2, p3, p4, p5, p6, p7, p8) -- line: 56
    -- upvalues: rt (copy), import (copy), v4 (copy), dot (copy), cross (copy), sub (copy), scale (copy), length (copy), normalize (copy), apex_position (ref), to_apex (ref)
    local v5 = import("skate_game/physics/handplant")
    local UP = v5.UP
    local v6 = normalize(cross(sub(p3.edge["end"], p3.edge.start), UP))

    if dot(v6, p6) > 0 then
        v6 = scale(v6, -1)
    end

    p2.direction = scale(v6, -1)

    local v7 = apex_position(p3.point, v6, p2.settings.apex_radius, p2.settings.apex_angle)

    p2.initial = to_apex(p4, v7)
    p2.apex = v5.apex_time(p2.initial)
    p2.warped = 0
    p2.outgoing = {
        rt.copy(p2.initial),
        rt.copy(p2.initial)
    }
    p2.travel_sign = dot(p8, p5) > 0 and 1 or -1
    p2.rotations[1] = v4.frame(rt.copy(p8), p6)
    p2.rotations[1][4] = rt.copy(p4)

    local v8 = normalize(sub(p3.edge.start, p3.edge["end"]))
    local v10 = scale(v8, (if dot({
        v8[1],
        0,
        v8[3],
        0
    }, sub(v7, p4)) > 0 then 1 else -1) * p2.travel_sign)

    p2.rotations[2] = v4.frame(v10, normalize(sub(p3.point, v7)))
    p2.rotations[2][4] = rt.copy(v7)
    p2.rotations[3] = v4.frame(scale(UP, -p2.travel_sign), p6)
    p2.rotations[4] = rt.copy(p2.rotations[3])
    v5.Handplant.estimate_apex(p2)

    local v11 = length(sub(p2.previous_candidate_point, p3.point)) > 0.15
    local v12 = dot(sub(p3.point, p4), p7) < 0

    p2.flags = bit32.bor(bit32.band(p2.flags, 268435455), 2147483648, if v11 then 1073741824 else 0, if v12 then 536870912 else 0, p2.phase < p2.settings.committed_time and 268435456 or 0)
    p2.anchor = rt.copy(p3.point)
    p2.candidate = rt.copy(p3)
end

function t1.Handplant.select_outgoing(p9, p10) -- line: 95
    -- upvalues: rt (copy), import (copy), v2 (copy), v4 (copy), Trajectory (copy), dot (copy), cross (copy), add (copy), sub (copy), scale (copy), madd (copy), length (copy), normalize (copy), clamp_length (copy), t1 (copy), from_apex (ref)
    local v17 = import("skate_game/physics/handplant")
    local UP, GRAVITY = v17.UP, v17.GRAVITY
    local candidate = p9.candidate

    if candidate == nil then
        error("Handplant entry requires the selected coping", 0)
    end

    local v18 = Trajectory.position_at(p9.initial, p9.apex)
    local v19 = Trajectory.velocity_at(p9.initial, p9.apex)
    local v20 = scale(p9.direction, dot(v19, p9.direction))
    local v21 = sub(v19, v20)
    local v22 = normalize(v21)
    local v23 = length(add(v20, clamp_length(v21, 2)))

    if candidate.side ~= 0 then
        p9.continuation = dot(scale(cross(UP, p9.direction), if candidate.side == 1 then 1 else -1), v22) >= 0
    end

    local v27 = madd(p9.direction, 0.1, p9.anchor)

    v27[2] = v18[2]

    local v28 = rt.copy(v17.EMPTY)
    local n1 = 1.1
    local t3
    local t2

    for _, v29 in { 0, 0.24, 0.48, 0.7199999690055847, 0.96, 1.1999999284744263 } do
        local v30, v31 = v2.sin_cos(v29)
        local v32 = scale(madd(p9.direction, v30, scale(v22, v31)), v23)
        local t4 = {
            duration = 3,
            position = rt.copy(v27),
            velocity = v32,
            acceleration = rt.copy(GRAVITY)
        }

        v28 = rt.copy(t4)

        local v33 = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.query(p10, {
            radius = 0.2,
            start_error = 1,
            end_error = 1,
            trajectory = rt.copy(t4)
        })

        if not (v33.contact_time < 0) then
            local contact_position = v33.contact_position

            if not (p9.anchor[2] - contact_position[2] <= 0.5) then
                local v34 = rt.copy(v33.landing_normal)
                local v35 = Trajectory.position_at(t4, v33.contact_time)
                local v36 = madd(v34, 0.56, v35)
                local v37 = true

                for _, v38 in v36 do
                    if v38 ~= v38 or v38 == 1e999 or v38 == (-1e999) then
                        v37 = false
                        break
                    end
                end

                if v37 and v36[2] < v18[2] then
                    if v34[2] < 0.71 then
                        t3 = { v35, v34 }
                        break
                    end

                    if v34[2] < n1 then
                        n1 = v34[2]
                        t2 = { v35, v34 }
                    end
                end
            end
        end

        t3 = t2
    end

    local v39 = Trajectory.position_at(v28, 3)
    local v40

    if t3 ~= nil then
        v39 = t3[1]
        v40 = t3[2]
    else
        v40 = rt.copy(UP)
    end

    local v41 = madd(v40, 0.56, v39)
    local v42 = from_apex(v18, v41)
    local duration = v42.duration

    v42.position = Trajectory.position_at(v42, -p9.apex)
    v42.velocity = Trajectory.velocity_at(v42, -p9.apex)
    v42.duration = -1
    p9.outgoing = {
        rt.copy(v42),
        rt.copy(v42)
    }

    local v43 = dot(p9.direction, p9.outgoing[2].velocity)

    if v43 < p9.settings.minimum_out_speed then
        p9.outgoing[2].velocity = madd(p9.direction, p9.settings.minimum_out_speed - v43, p9.outgoing[2].velocity)
    end

    p9.rotations[3][4] = Trajectory.position_at(v42, 2 * p9.apex)

    local v44 = p9.apex + duration

    p9.rotations[4] = v4.frame(scale(normalize(Trajectory.velocity_at(v42, v44)), p9.travel_sign), v40)
    p9.rotations[4][4] = Trajectory.position_at(v42, v44)
    p9.out_duration = rt.fmax(v44 - p9.phase, 0.5)
    t1.Handplant.build_curve(p9)
end

function t1.Handplant.build_curve(p11) -- line: 208
    -- upvalues: Trajectory (copy), STEP (copy), sub (copy), madd (copy)
    local v45 = p11.apex - p11.settings.curve_half_time
    local v46 = p11.apex + p11.settings.curve_half_time

    p11.curve[1] = Trajectory.position_at(p11.initial, v45)
    p11.curve[2] = madd(sub(Trajectory.position_at(p11.initial, v45 + STEP), p11.curve[1]), 6, p11.curve[1])
    p11.curve[4] = Trajectory.position_at(p11.outgoing[2], v46)
    p11.curve[3] = madd(sub(Trajectory.position_at(p11.outgoing[2], v46 - STEP), p11.curve[4]), 6, p11.curve[4])
end

function t1.Handplant.values(p12, p13, p14) -- line: 221
    -- upvalues: rt (copy), PointGraph (copy), v4 (copy), Trajectory (copy), dot (copy), sub (copy), scale (copy), madd (copy), reciprocal (copy), length (copy), normalize (copy), clamp01 (copy), bezier (ref)
    local v47 = p12.warped - p12.apex
    local v48 = (1 + v47 * reciprocal(p12.settings.curve_half_time)) * 0.5
    local v49

    if v48 < 0 then
        v49 = Trajectory.position_at(p12.initial, p12.warped)
    elseif v48 > 1 then
        local v50 = clamp01((v47 - p12.settings.curve_half_time) * reciprocal(p12.out_duration))

        v49 = madd(Trajectory.position_at(p12.outgoing[1], p12.warped), v50, scale(Trajectory.position_at(p12.outgoing[2], p12.warped), 1 - v50))
    else
        v49 = bezier(p12.curve, v48)
    end

    local v51 = rt.fmax(p13[16][4][2], p13[20][4][2])
    local flags = p12.flags
    local v52, v53

    if bit32.band(flags, 536870912) == 0 then
        v52 = 3.2
        v53 = -0.05
    else
        v52 = 5
        v53 = 0
    end

    v49[2] += rt.fmax((v51 - p14[2]) / v52 + v53, 0)

    local v54 = rt.fmax(1 - p12.elapsed * reciprocal(p12.settings.entry_blend), 0)
    local v55 = madd(v49, 1 - v54, scale(Trajectory.position_at(p12.entry, p12.elapsed), v54))

    if v54 > 0 and v48 < 0 then
        local v56 = Trajectory.velocity_at(p12.initial, p12.warped)
        local v57 = dot(sub(v55, v49), normalize(v56)) * reciprocal(length(v56))

        p12.warped += rt.clamp(v57, -0.008333333767950535, 0.008333333767950535)
    end

    local v58

    if p12.warped < p12.apex then
        local v59 = rt.fmax(1 - (p12.apex - p12.warped) * reciprocal(rt.fmin(p12.apex, p12.settings.rotation_time)), 0)

        v58 = v4.blend(p12.rotations[1], p12.rotations[2], PointGraph.evaluate(p12.settings.into_rotation, v59))
    else
        local v60 = p12.warped - p12.apex
        local v61 = PointGraph.evaluate(p12.settings.out_heading, clamp01(v60 * reciprocal(p12.out_duration)))
        local v62 = PointGraph.evaluate(p12.settings.out_rotation, clamp01(v60 * reciprocal(p12.settings.rotation_time)))

        v58 = v4.blend(p12.rotations[2], v4.blend(p12.rotations[3], p12.rotations[4], v61), v62)
    end

    return v55, v58[2], v58[3]
end

function apex_position(p15, p16, p17, p18) -- line: 279
    -- upvalues: import (copy), v2 (copy), madd (copy)
    local v63 = v2.sin(p18)
    local v64 = v2.cos(p18)

    return madd(p16, p17 * v63, madd(import("skate_game/physics/handplant").UP, p17 * v64, p15))
end

t1.apex_position = apex_position

function to_apex(p19, p20) -- line: 287
    -- upvalues: import (copy), reciprocal (copy), arc_between (ref)
    local GRAVITY = import("skate_game/physics/handplant").GRAVITY
    local v66 = math.sqrt(-2 * GRAVITY[2] * (p20[2] - p19[2])) * reciprocal(-GRAVITY[2])

    return arc_between(p19, p20, v66)
end

t1.to_apex = to_apex

function from_apex(p21, p22) -- line: 297
    -- upvalues: import (copy), reciprocal (copy), arc_between (ref)
    local GRAVITY = import("skate_game/physics/handplant").GRAVITY
    local v68 = math.sqrt(-2 * GRAVITY[2] * (p21[2] - p22[2])) * reciprocal(-GRAVITY[2])

    return arc_between(p21, p22, v68)
end

t1.from_apex = from_apex

function arc_between(p23, p24, p25) -- line: 305
    -- upvalues: rt (copy), import (copy), sub (copy), scale (copy), reciprocal (copy)
    local GRAVITY = import("skate_game/physics/handplant").GRAVITY
    local v69 = scale(sub(sub(p24, p23), scale(GRAVITY, p25 * 0.5 * p25)), reciprocal(p25))

    return {
        position = rt.copy(p23),
        velocity = v69,
        acceleration = rt.copy(GRAVITY),
        duration = p25
    }
end

t1.arc_between = arc_between

function bezier(p26, p27) -- line: 318
    -- upvalues: scale (copy), madd (copy)
    local v70 = 1 - p27

    return madd(p26[4], p27 * p27 * p27, madd(p26[3], p27 * 3 * p27 * v70, madd(p26[1], v70 * v70 * v70, scale(p26[2], p27 * 3 * v70 * v70))))
end

t1.bezier = bezier

return t1
