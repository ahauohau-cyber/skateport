-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_motion_output")
local v3 = import("skate_core/physics/native_arithmetic")
local v4 = import("skate_core/physics/skeleton_animation_record")
local v5 = import("skate_core/point_graph")
local v6 = import("skate_core/riding/collision_response")
local v7 = import("skate_core/trigonometry")
local Vector3 = v1.Vector3
local inverse_length_squared = v2.inverse_length_squared
local dot3 = v3.dot3
local IDENTITY, compose_affine = v4.IDENTITY, v4.compose_affine
local PointGraph = v5.PointGraph
local signed_angle = v6.signed_angle
local t1 = {
    ReckoningFrames = {}
}

function t1.ReckoningFrames.new() -- line: 42
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        target_lean_angle = 0,
        ground = rt.copy(IDENTITY),
        system = rt.copy(IDENTITY),
        unflipped = rt.copy(IDENTITY),
        inverse_system = rt.copy(IDENTITY),
        body_flip = rt.copy(IDENTITY),
        heading = { 1, 0, 0, 0 },
        lateral_tilt = { 0, 0, 0, 0 }
    }
end

function t1.ReckoningFrames.calculate_transform_reference(p1, p2, p3) -- line: 57
    -- upvalues: rt (copy), compose_affine (copy), t1 (copy)
    local v8 = t1.cross(p2, p1.heading)
    local v9 = t1.cross(v8, p2)

    p1.heading = t1.normalize(v9)
    p1.system[1] = t1.normalize(v8)
    p1.system[2] = rt.copy(p2)
    p1.system[3] = rt.copy(p1.heading)
    p1.unflipped = rt.copy(p1.system)
    p1.system = compose_affine(p1.body_flip, p1.system)
    p1.inverse_system = t1.inverse(p1.system)

    local v10 = t1.cross(p3, p1.heading)
    local v11 = t1.cross(v10, p3)

    p1.ground[1] = t1.normalize(v10)
    p1.ground[2] = rt.copy(p3)
    p1.ground[3] = t1.normalize(v11)
end

function t1.ReckoningFrames.calculate_dynamic_lean_reference(p4, p5, p6) -- line: 76
    -- upvalues: rt (copy), dot3 (copy), signed_angle (copy), t1 (copy)
    local v12 = rt.copy(p4.system[3])

    local function project(p7) -- line: 78
        -- upvalues: v12 (copy), dot3 (copy)
        local v13 = dot3(p7, v12)

        return {
            p7[1] - v12[1] * v13,
            p7[2] - v12[2] * v13,
            p7[3] - v12[3] * v13,
            p7[4] - v12[4] * v13
        }
    end

    local v14 = project(p5)
    local v15 = project(p6)

    if not (dot3(v14, v14) > 9.999999747378752E-06 and dot3(v15, v15) > 9.999999747378752E-06) then
        p4.target_lean_angle = 0
    else
        p4.target_lean_angle = t1.wrap_fraction(signed_angle(t1.xyz(v14), t1.xyz(v15), t1.xyz(v12)))
    end
end

function t1.ReckoningFrames.calculate_tilt_reference(p8, p9, p10, p11) -- line: 100
    -- upvalues: rt (copy), v7 (copy), dot3 (copy), PointGraph (copy), signed_angle (copy), t1 (copy)
    local v16 = rt.copy(p8.unflipped[2])
    local t2 = {
        0, 1, 0, 0
    }
    local v17 = dot3(v16, t2)
    local t3 = {
        v16[1] * v17,
        v16[2] * v17,
        v16[3] * v17,
        v16[4] * v17
    }
    local t4 = {
        t2[1] - t3[1],
        t2[2] - t3[2],
        t2[3] - t3[3],
        t2[4] - t3[4]
    }

    if dot3(t4, t4) <= 0.0005000000237487257 then
        return
    end

    local v18 = if t2[1] == t3[1] and t2[2] == t3[2] and t2[3] == t3[3] and t2[4] == t3[4] then 0 else signed_angle(t1.xyz(p8.unflipped[3]), t1.xyz(t1.normalize(t4)), t1.xyz(v16))
    local v20 = (math.abs((t1.wrap_fraction(v18 - 1.5707963705062866))) - 1.5707963705062866) * -1 * 0.6366197466850281

    if p9 then
        v20 = -v20
    end

    local v21 = (1.5707963705062866 - v7.asin(v16[2])) * 0.6366197466850281
    local v22 = PointGraph.evaluate(p10, (math.abs(v20)))
    local v23 = PointGraph.evaluate(p11, (math.abs(v21)))

    if not (v20 >= -0) then
        v22 = -v22
    end

    p8.lateral_tilt = {
        v23 * v22,
        0, 0, 0
    }
end

function t1.normalize(p12) -- line: 149
    -- upvalues: inverse_length_squared (copy), dot3 (copy)
    local v24 = inverse_length_squared(dot3(p12, p12), 2)

    return {
        p12[1] * v24,
        p12[2] * v24,
        p12[3] * v24,
        p12[4] * v24
    }
end

function t1.cross(p13, p14) -- line: 159
    return {
        -p13[3] * p14[2] + p13[2] * p14[3],
        -p13[1] * p14[3] + p13[3] * p14[1],
        -p13[2] * p14[1] + p13[1] * p14[2],
        -p13[4] * p14[4] + p13[4] * p14[4]
    }
end

function t1.inverse(p15) -- line: 168
    -- upvalues: rt (copy)
    local t5 = {
        {
            p15[1][1],
            p15[2][1],
            p15[3][1],
            0
        },
        {
            p15[1][2],
            p15[2][2],
            p15[3][2],
            0
        },
        {
            p15[1][3],
            p15[2][3],
            p15[3][3],
            0
        }
    }
    local t6 = {
        0 - p15[4][1],
        0 - p15[4][2],
        0 - p15[4][3],
        0 - p15[4][4]
    }
    local v25 = rt.from_fn(4, function(p16) -- line: 175
        -- upvalues: t5 (copy), t6 (copy)
        local v26 = t5[3][p16 + 1] * t6[3]
        local v27 = t5[2][p16 + 1] * t6[2] + v26

        return t5[1][p16 + 1] * t6[1] + v27
    end)

    return {
        t5[1],
        t5[2],
        t5[3],
        v25
    }
end

function t1.wrap_fraction(p17) -- line: 183
    local v28 = p17 * 0.15915493667125702
    local v29 = v28 - math.floor(v28)

    return (if v29 > 0.5 then v29 - 1 else v29 - 0) * 6.2831854820251465
end

function t1.xyz(p18) -- line: 194
    -- upvalues: Vector3 (copy)
    return Vector3.new(p18[1], p18[2], p18[3])
end

local signed_angle_xyz = v6.signed_angle_xyz
local asin = v7.asin

local function inverse_fast(p19) -- line: 218
    local v30 = p19[1]
    local v31 = p19[2]
    local v32 = p19[3]
    local v33 = p19[4]
    local t7 = {
        v30[1],
        v31[1],
        v32[1],
        0
    }
    local t8 = {
        v30[2],
        v31[2],
        v32[2],
        0
    }
    local t9 = {
        v30[3],
        v31[3],
        v32[3],
        0
    }
    local v34 = 0 - v33[1]
    local v35 = 0 - v33[2]
    local v36 = 0 - v33[3]

    return {
        t7,
        t8,
        t9,
        {
            t7[1] * v34 + (t8[1] * v35 + t9[1] * v36),
            t7[2] * v34 + (t8[2] * v35 + t9[2] * v36),
            t7[3] * v34 + (t8[3] * v35 + t9[3] * v36),
            t7[4] * v34 + (t8[4] * v35 + t9[4] * v36)
        }
    }
end

t1.inverse_fast = inverse_fast

function t1.ReckoningFrames.calculate_transform(p20, p21, p22) -- line: 240
    -- upvalues: rt (copy), inverse_length_squared (copy), compose_affine (copy), inverse_fast (copy)
    local v37 = p21[1]
    local v38 = p21[2]
    local v39 = p21[3]
    local v40 = p21[4]
    local heading = p20.heading
    local v41 = heading[1]
    local v42 = heading[2]
    local v43 = heading[3]
    local v44 = heading[4]
    local v45 = -v39 * v42 + v38 * v43
    local v46 = -v37 * v43 + v39 * v41
    local v47 = -v38 * v41 + v37 * v42
    local v48 = -v40 * v44 + v40 * v44
    local v49 = -v47 * v38 + v46 * v39
    local v50 = -v45 * v39 + v47 * v37
    local v51 = -v46 * v37 + v45 * v38
    local v52 = -v48 * v40 + v48 * v40
    local v53 = inverse_length_squared(v49 * v49 + v50 * v50 + v51 * v51, 2)
    local v54 = v49 * v53
    local v55 = v50 * v53
    local v56 = v51 * v53
    local v57 = v52 * v53

    p20.heading = { v54, v55, v56, v57 }

    local v58 = inverse_length_squared(v45 * v45 + v46 * v46 + v47 * v47, 2)

    p20.system[1] = {
        v45 * v58,
        v46 * v58,
        v47 * v58,
        v48 * v58
    }
    p20.system[2] = rt.copy(p21)
    p20.system[3] = rt.copy(p20.heading)
    p20.unflipped = rt.copy(p20.system)
    p20.system = compose_affine(p20.body_flip, p20.system)
    p20.inverse_system = inverse_fast(p20.system)

    local v59 = p22[1]
    local v60 = p22[2]
    local v61 = p22[3]
    local v62 = p22[4]
    local v63 = -v61 * v55 + v60 * v56
    local v64 = -v59 * v56 + v61 * v54
    local v65 = -v60 * v54 + v59 * v55
    local v66 = -v62 * v57 + v62 * v57
    local v67 = -v65 * v60 + v64 * v61
    local v68 = -v63 * v61 + v65 * v59
    local v69 = -v64 * v59 + v63 * v60
    local v70 = -v66 * v62 + v66 * v62
    local v71 = inverse_length_squared(v63 * v63 + v64 * v64 + v65 * v65, 2)

    p20.ground[1] = {
        v63 * v71,
        v64 * v71,
        v65 * v71,
        v66 * v71
    }
    p20.ground[2] = rt.copy(p22)

    local v72 = inverse_length_squared(v67 * v67 + v68 * v68 + v69 * v69, 2)

    p20.ground[3] = {
        v67 * v72,
        v68 * v72,
        v69 * v72,
        v70 * v72
    }
end

function t1.ReckoningFrames.calculate_dynamic_lean(p23, p24, p25) -- line: 287
    -- upvalues: t1 (copy), signed_angle_xyz (copy)
    local v73 = p23.system[3]
    local v74 = v73[1]
    local v75 = v73[2]
    local v76 = v73[3]
    local v77 = p24[1]
    local v78 = p24[2]
    local v79 = p24[3]
    local v80 = v77 * v74 + v78 * v75 + v79 * v76
    local v81 = v77 - v74 * v80
    local v82 = v78 - v75 * v80
    local v83 = v79 - v76 * v80
    local v84 = p25[1]
    local v85 = p25[2]
    local v86 = p25[3]
    local v87 = v84 * v74 + v85 * v75 + v86 * v76
    local v88 = v84 - v74 * v87
    local v89 = v85 - v75 * v87
    local v90 = v86 - v76 * v87

    if not (v81 * v81 + v82 * v82 + v83 * v83 > 9.999999747378752E-06 and v88 * v88 + v89 * v89 + v90 * v90 > 9.999999747378752E-06) then
        p23.target_lean_angle = 0
    else
        p23.target_lean_angle = t1.wrap_fraction(signed_angle_xyz(v81, v82, v83, v88, v89, v90, v74, v75, v76))
    end
end

function t1.ReckoningFrames.calculate_tilt(p26, p27, p28, p29) -- line: 311
    -- upvalues: inverse_length_squared (copy), PointGraph (copy), t1 (copy), signed_angle_xyz (copy), asin (copy)
    local v91 = p26.unflipped[2]
    local v92 = v91[1]
    local v93 = v91[2]
    local v94 = v91[3]
    local v95 = v91[4]
    local v96 = v92 * 0 + v93 * 1 + v94 * 0
    local v97 = v92 * v96
    local v98 = v93 * v96
    local v99 = v94 * v96
    local v100 = v95 * v96
    local v101 = 0 - v97
    local v102 = 1 - v98
    local v103 = 0 - v99
    local v104 = v101 * v101 + v102 * v102 + v103 * v103

    if v104 <= 0.0005000000237487257 then
        return
    end

    local v105

    if v97 == 0 and v98 == 1 and v99 == 0 and v100 == 0 then
        v105 = 0
    else
        local v106 = p26.unflipped[3]
        local v107 = inverse_length_squared(v104, 2)

        v105 = signed_angle_xyz(v106[1], v106[2], v106[3], v101 * v107, v102 * v107, v103 * v107, v92, v93, v94)
    end

    local v109 = (math.abs((t1.wrap_fraction(v105 - 1.5707963705062866))) - 1.5707963705062866) * -1 * 0.6366197466850281

    if p27 then
        v109 = -v109
    end

    local v110 = (1.5707963705062866 - asin(v93)) * 0.6366197466850281
    local v111 = PointGraph.evaluate(p28, (math.abs(v109)))
    local v112 = PointGraph.evaluate(p29, (math.abs(v110)))

    if not (v109 >= -0) then
        v111 = -v111
    end

    p26.lateral_tilt = {
        v112 * v111,
        0, 0, 0
    }
end

return t1
