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
local v9 = import("skate_core/air/ground_normal")
local v10 = import("skate_core/math")
local v11 = import("skate_core/point_graph")
local v12 = import("skate_core/physics/board_ground")
local v13 = import("skate_core/physics/board_motion_output")
local v14 = import("skate_core/physics/native_arithmetic")
local GroundNormalFilter = v9.GroundNormalFilter
local Vector3 = v10.Vector3
local PointGraph = v11.PointGraph
local angle_between = v12.angle_between
local add, subtract, scale, dot = v13.add, v13.subtract, v13.scale, v13.dot
local inverse_length_squared, length = v13.inverse_length_squared, v13.length
local t1 = {
    UP = Vector3.new(0, 1, 0),
    EPSILON = 9.999999974752427E-07,
    GroundOrientationSettings = {},
    GroundOrientationInput = {},
    GroundOrientation = {}
}

function t1.GroundOrientation.new(p3) -- line: 97
    -- upvalues: rt (copy), GroundNormalFilter (copy), Vector3 (copy), t1 (copy)
    return {
        ground_blend = 0,
        dynamic_up = rt.copy(t1.UP),
        up = rt.copy(t1.UP),
        target = rt.copy(t1.UP),
        up_velocity = rt.copy(Vector3.ZERO),
        ground_normal = rt.copy(t1.UP),
        ground_filter = GroundNormalFilter.initialized(p3.ground_normal_smoothing, t1.lanes(t1.UP)),
        slow_filter = GroundNormalFilter.initialized(p3.up_vector_smoothing_slow, t1.lanes(t1.UP)),
        fast_filter = GroundNormalFilter.initialized(p3.up_vector_smoothing_fast, t1.lanes(t1.UP))
    }
end

function t1.GroundOrientation.reset(p4) -- line: 112
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    p4.dynamic_up = rt.copy(t1.UP)
    p4.up = rt.copy(t1.UP)
    p4.target = rt.copy(t1.UP)
    p4.up_velocity = rt.copy(Vector3.ZERO)
    p4.ground_normal = rt.copy(t1.UP)
    p4.ground_blend = 0
end

function t1.GroundOrientation.update_reference(p5, p6, p7) -- line: 124
    -- upvalues: rt (copy), GroundNormalFilter (copy), Vector3 (copy), PointGraph (copy), angle_between (copy), add (copy), subtract (copy), scale (copy), dot (copy), inverse_length_squared (copy), length (copy), t1 (copy)
    local UP = t1.UP
    local ZERO = Vector3.ZERO
    local normalize_safe, blend, cross, madd = t1.normalize_safe, t1.blend, t1.cross, t1.madd
    local fsel, lanes, vector = t1.fsel, t1.lanes, t1.vector
    local v15 = normalize_safe(p7.com_to_deck, ZERO)
    local v16 = PointGraph.evaluate(p6.dynamic_up_vs_ground_y, p7.ground_normal.y)
    local v17 = normalize_safe(blend(p5.ground_normal, add(UP, subtract(p7.dynamic_up, v15)), v16), ZERO)

    p5.dynamic_up = rt.copy(p7.dynamic_up)
    p5.ground_normal = vector(GroundNormalFilter.update(p5.ground_filter, p6.ground_normal_smoothing, lanes(p7.ground_normal)))

    local v18 = cross(UP, p5.ground_normal)

    if dot(v18, v18) > 0.0010000000474974513 then
        local v19 = scale(v18, inverse_length_squared(dot(v18, v18), 2))
        local v20 = subtract(v17, scale(v19, dot(v19, v17)))
        local v21 = angle_between(v20, p5.ground_normal)
        local v22 = angle_between(v20, UP)
        local v23 = angle_between(p5.ground_normal, UP)
        local v24 = angle_between(p5.up, UP)
        local v25 = if v21 < v22 then rt.copy(p5.ground_normal) else rt.copy(UP)

        if not (v21 < v23 and v22 < v23) then
            v20 = v25
        end

        local v26 = (p7.speed + 1) * 0.0010000000474974513

        if not (v23 < v24 or v24 < v22) then
            v20 = madd(p5.up, 1 - v26, scale(v20, v26))
        end

        local v27 = t1.unit_saturate(v23 * 0.31830987334251404)
        local v28 = PointGraph.evaluate(p6.ground_vector_blend, v27)

        if p7.wheel_contact_count <= p6.minimum_wheels_for_ground_blend then
            v28 = 0
        end

        local v29 = v28 - p5.ground_blend
        local v30 = fsel(-p6.ground_blend_max_delta - v29, -p6.ground_blend_max_delta, v29)

        p5.ground_blend += fsel(p6.ground_blend_max_delta - v30, v30, p6.ground_blend_max_delta)
        p5.target = normalize_safe(blend(v20, p5.ground_normal, p5.ground_blend), ZERO)
    else
        p5.target = rt.copy(p5.ground_normal)
    end

    if p7.wheel_contact_count >= 2 and p7.animation_balance == 0 then
        local v31 = PointGraph.evaluate(p6.deck_angle_usage_vs_speed, p7.deck_angle_curve_input)
        local v32 = normalize_safe(cross(p7.board_forward, p5.ground_normal), ZERO)
        local v33 = normalize_safe(subtract(p7.board_up, scale(v32, dot(p7.board_up, v32))), ZERO)

        p5.target = normalize_safe(blend(p5.target, v33, v31), ZERO)
    end

    local v34 = normalize_safe(vector(GroundNormalFilter.filter_raw(p5.slow_filter, p6.up_vector_smoothing_slow, lanes(p5.target))), ZERO)
    local v35 = normalize_safe(vector(GroundNormalFilter.filter_raw(p5.fast_filter, p6.up_vector_smoothing_fast, lanes(p5.target))), ZERO)
    local v36 = p7.speed * 0.10000000149011612
    local v37 = normalize_safe(blend(v34, v35, (PointGraph.evaluate(p6.up_vector_smoothing_vs_speed, v36))), ZERO)
    local v38 = PointGraph.evaluate(p6.up_vector_max_delta_vs_speed, v36) * 0.20000000298023224
    local v39 = subtract(v37, p5.up)
    local v40 = length(v39)
    local v41 = fsel(v40 - v38, v38, v40)
    local v43 = subtract(normalize_safe(madd(normalize_safe(v39, ZERO), v41, p5.up), ZERO), p5.up)
    local v44 = t1.clamp_length_reference(subtract(v43, p5.up_velocity), p6.up_vector_max_acceleration * 0.01666666753590107)

    p5.up_velocity = add(p5.up_velocity, v44)

    local v45 = scale(p7.previous_reckoning_right, dot(p5.up_velocity, p7.previous_reckoning_right))

    p5.up_velocity = madd(v45, p6.extra_side_damping, subtract(p5.up_velocity, v45))

    local v46 = add(p5.up, p5.up_velocity)

    p5.up = normalize_safe(v46, v46)

    if dot(p5.up_velocity, v43) < 0 then
        p5.up_velocity = scale(p5.up_velocity, p6.anti_wobble_damping)
    end

    if p7.prevent_up_behind_board and dot(p5.up, p7.effective_board_forward) < 0 then
        local v47 = cross(p5.up, p7.effective_board_forward)

        p5.up = normalize_safe(cross(p7.effective_board_forward, v47), p5.up)
        p5.up_velocity = scale(p5.up_velocity, 0.5)
    end

    GroundNormalFilter.publish_current(p5.slow_filter, lanes(p5.up))
    GroundNormalFilter.publish_current(p5.fast_filter, lanes(p5.up))
end

function t1.lanes(p8) -- line: 223
    return {
        p8.x,
        p8.y,
        p8.z,
        0
    }
end

function t1.vector(p9) -- line: 227
    -- upvalues: Vector3 (copy)
    return Vector3.new(p9[1], p9[2], p9[3])
end

function t1.fsel(p10, p11, p12) -- line: 231
    if p10 >= -0 then
        return p11
    end

    return p12
end

function t1.unit_saturate(p13) -- line: 239
    -- upvalues: t1 (copy)
    local v48 = t1.fsel(-p13, 0, p13)

    return t1.fsel(1 - v48, v48, 1)
end

function t1.madd(p14, p15, p16) -- line: 244
    -- upvalues: Vector3 (copy)
    return Vector3.new(p14.x * p15 + p16.x, p14.y * p15 + p16.y, p14.z * p15 + p16.z)
end

function t1.blend(p17, p18, p19) -- line: 248
    -- upvalues: scale (copy), t1 (copy)
    return t1.madd(p18, p19, scale(p17, 1 - p19))
end

function t1.cross(p20, p21) -- line: 252
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p20.z * p21.y + p20.y * p21.z, -p20.x * p21.z + p20.z * p21.x, -p20.y * p21.x + p20.x * p21.y)
end

function t1.normalize_safe(p22, p23) -- line: 257
    -- upvalues: rt (copy), v1 (copy), scale (copy), dot (copy), inverse_length_squared (copy), t1 (copy)
    local v49 = dot(p22, p22)
    local v50

    if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
        local v51 = math.abs(v49) * 7.1362384635298E+44
        local v52 = math.floor(v51)
        local v53 = v51 - v52

        v50 = (if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52) * 1.401298464324817E-45

        if v49 < 0 then
            v50 = -v50
        end
    else
        buffer.writef32(v1, 0, v49)
        v50 = buffer.readf32(v1, 0)
    end

    local v54 = inverse_length_squared(v50, 2)

    if (if v50 == 0 then 0 else v50 * v54) > t1.EPSILON then
        return scale(p22, v54)
    end

    return rt.copy(p23)
end

function t1.clamp_length_reference(p24, p25) -- line: 274
    -- upvalues: rt (copy), v14 (copy), scale (copy), length (copy), t1 (copy)
    local v55 = length(p24)

    if v55 < 1.52587890625E-05 then
        return rt.copy(p24)
    end

    local v56 = t1.fsel(p25 - v55, v55, p25)
    local v57 = v14.reciprocal_estimate(v55)
    local v58 = v57 * (-v57 * v55 + 1) + v57
    local v59 = v58 * (-v58 * v55 + 1) + v58

    return scale(scale(p24, v56), v59)
end

local acos = import("skate_core/trigonometry").acos
local fmin, fmax = rt.fmin, rt.fmax
local reciprocal_estimate = v14.reciprocal_estimate
local EPSILON = t1.EPSILON

function t1.normalize_safe_xyz(p26, p27, p28, p29, p30, p31) -- line: 319
    -- upvalues: v1 (copy), inverse_length_squared (copy), EPSILON (copy)
    local v60 = p26 * p26 + p27 * p27 + p28 * p28
    local v61

    if v60 ~= 0 and v60 > -1.1754943508222875E-38 and v60 < 1.1754943508222875E-38 then
        local v62 = math.abs(v60) * 7.1362384635298E+44
        local v63 = math.floor(v62)
        local v64 = v62 - v63

        v61 = (if v64 > 0.5 or v64 == 0.5 and v63 % 2 == 1 then v63 + 1 else v63) * 1.401298464324817E-45

        if v60 < 0 then
            v61 = -v61
        end
    else
        buffer.writef32(v1, 0, v60)
        v61 = buffer.readf32(v1, 0)
    end

    local v65 = inverse_length_squared(v61, 2)

    if (if v61 == 0 then 0 else v61 * v65) > EPSILON then
        return p26 * v65, p27 * v65, p28 * v65
    end

    return p29, p30, p31
end

local normalize_safe_xyz = t1.normalize_safe_xyz

local function angle_between_xyz(p32, p33, p34, p35, p36, p37) -- line: 337
    -- upvalues: inverse_length_squared (copy), acos (copy), fmin (copy), fmax (copy)
    local v66 = p32 * p32 + p33 * p33 + p34 * p34
    local v67 = p35 * p35 + p36 * p36 + p37 * p37

    if not (v66 > 9.999999747378752E-05 and v67 > 9.999999747378752E-05) then
        return 0
    end

    local v68 = inverse_length_squared(v66, 1)
    local v69 = inverse_length_squared(v67, 1)
    local v70 = p32 * v68
    local v71 = p33 * v68
    local v72 = p34 * v68
    local v73 = p35 * v69
    local v74 = p36 * v69
    local v75 = p37 * v69

    return acos(fmin(fmax(v70 * v73 + v71 * v74 + v72 * v75, -1), 1))
end

t1.angle_between_xyz = angle_between_xyz

local function clamp_length_xyz(p38, p39, p40, p41) -- line: 353
    -- upvalues: v1 (copy), inverse_length_squared (copy), reciprocal_estimate (copy)
    local v76 = p38 * p38 + p39 * p39 + p40 * p40
    local v77

    if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
        local v78 = math.abs(v76) * 7.1362384635298E+44
        local v79 = math.floor(v78)
        local v80 = v78 - v79

        v77 = (if v80 > 0.5 or v80 == 0.5 and v79 % 2 == 1 then v79 + 1 else v79) * 1.401298464324817E-45

        if v76 < 0 then
            v77 = -v77
        end
    else
        buffer.writef32(v1, 0, v76)
        v77 = buffer.readf32(v1, 0)
    end

    local v81 = v77 * inverse_length_squared(v77, 2)

    if v77 == 0 then
        v81 = 0
    end

    if v81 < 1.52587890625E-05 then
        return false, p38, p39, p40
    end

    local v82 = if p41 - v81 >= -0 then v81 else p41
    local v83 = reciprocal_estimate(v81)
    local v84 = v83 * (-v83 * v81 + 1) + v83
    local v85 = v84 * (-v84 * v81 + 1) + v84

    return true, p38 * v82 * v85, p39 * v82 * v85, p40 * v82 * v85
end

t1.clamp_length_xyz = clamp_length_xyz

function t1.clamp_length(p42, p43) -- line: 378
    -- upvalues: rt (copy), Vector3 (copy), clamp_length_xyz (copy)
    local v86, v87, v88, v89 = clamp_length_xyz(p42.x, p42.y, p42.z, p43)

    if v86 then
        return Vector3.new(v87, v88, v89)
    end

    return rt.copy(p42)
end

function t1.GroundOrientation.update(p44, p45, p46) -- line: 389
    -- upvalues: rt (copy), v1 (copy), GroundNormalFilter (copy), Vector3 (copy), PointGraph (copy), inverse_length_squared (copy), t1 (copy), normalize_safe_xyz (copy), angle_between_xyz (copy), clamp_length_xyz (copy)
    local UP = t1.UP
    local x, y, z = UP.x, UP.y, UP.z
    local ZERO = Vector3.ZERO
    local x2, y2, z2 = ZERO.x, ZERO.y, ZERO.z
    local com_to_deck = p46.com_to_deck
    local v90, v91, v92 = normalize_safe_xyz(com_to_deck.x, com_to_deck.y, com_to_deck.z, x2, y2, z2)
    local v93 = PointGraph.evaluate(p45.dynamic_up_vs_ground_y, p46.ground_normal.y)
    local ground_normal = p44.ground_normal
    local dynamic_up = p46.dynamic_up
    local v94 = x + (dynamic_up.x - v90)
    local v95 = y + (dynamic_up.y - v91)
    local v96 = z + (dynamic_up.z - v92)
    local v97 = 1 - v93
    local v98, v99, v100 = normalize_safe_xyz(v94 * v93 + ground_normal.x * v97, v95 * v93 + ground_normal.y * v97, v96 * v93 + ground_normal.z * v97, x2, y2, z2)

    p44.dynamic_up = rt.copy(p46.dynamic_up)

    local ground_normal2 = p46.ground_normal
    local v101 = GroundNormalFilter.update(p44.ground_filter, p45.ground_normal_smoothing, {
        ground_normal2.x,
        ground_normal2.y,
        ground_normal2.z,
        0
    })
    local v102 = v101[1]
    local v103 = v101[2]
    local v104 = v101[3]

    p44.ground_normal = Vector3.new(v102, v103, v104)

    local v105 = -z * v103 + y * v104
    local v106 = -x * v104 + z * v102
    local v107 = -y * v102 + x * v103
    local v108, v109, v110

    if v105 * v105 + v106 * v106 + v107 * v107 > 0.0010000000474974513 then
        local v111 = inverse_length_squared(v105 * v105 + v106 * v106 + v107 * v107, 2)
        local v112 = v105 * v111
        local v113 = v106 * v111
        local v114 = v107 * v111
        local v115 = v112 * v98 + v113 * v99 + v114 * v100
        local v116 = v98 - v112 * v115
        local v117 = v99 - v113 * v115
        local v118 = v100 - v114 * v115
        local v119 = angle_between_xyz(v116, v117, v118, v102, v103, v104)
        local v120 = angle_between_xyz(v116, v117, v118, x, y, z)
        local v121 = angle_between_xyz(v102, v103, v104, x, y, z)
        local up = p44.up
        local x3, y3, z3 = up.x, up.y, up.z
        local v122 = angle_between_xyz(x3, y3, z3, x, y, z)
        local v123, v124, v125

        if v119 < v120 then
            v125 = v104
            v123 = v102
            v124 = v103
        else
            v125 = z
            v123 = x
            v124 = y
        end

        if not (v119 < v121 and v120 < v121) then
            v118 = v125
            v116 = v123
            v117 = v124
        end

        local v126 = (p46.speed + 1) * 0.0010000000474974513

        if not (v121 < v122 or v122 < v120) then
            local v127 = 1 - v126

            v116 = x3 * v127 + v116 * v126
            v117 = y3 * v127 + v117 * v126
            v118 = z3 * v127 + v118 * v126
        end

        local v128 = t1.unit_saturate(v121 * 0.31830987334251404)
        local v129 = PointGraph.evaluate(p45.ground_vector_blend, v128)

        if p46.wheel_contact_count <= p45.minimum_wheels_for_ground_blend then
            v129 = 0
        end

        local v130 = v129 - p44.ground_blend

        if -p45.ground_blend_max_delta - v130 >= -0 then
            v130 = -p45.ground_blend_max_delta
        end

        if not (p45.ground_blend_max_delta - v130 >= -0) then
            v130 = p45.ground_blend_max_delta
        end

        p44.ground_blend += v130

        local ground_blend = p44.ground_blend
        local v131 = 1 - ground_blend

        v108, v109, v110 = normalize_safe_xyz(v102 * ground_blend + v116 * v131, v103 * ground_blend + v117 * v131, v104 * ground_blend + v118 * v131, x2, y2, z2)
    else
        v110 = v104
        v108 = v102
        v109 = v103
    end

    p44.target = Vector3.new(v108, v109, v110)

    if p46.wheel_contact_count >= 2 and p46.animation_balance == 0 then
        local v132 = PointGraph.evaluate(p45.deck_angle_usage_vs_speed, p46.deck_angle_curve_input)
        local board_forward = p46.board_forward
        local v133, v134, v135 = normalize_safe_xyz(-board_forward.z * v103 + board_forward.y * v104, -board_forward.x * v104 + board_forward.z * v102, -board_forward.y * v102 + board_forward.x * v103, x2, y2, z2)
        local board_up = p46.board_up
        local x, y, z = board_up.x, board_up.y, board_up.z
        local v136 = x * v133 + y * v134 + z * v135
        local v137, v138, v139 = normalize_safe_xyz(x - v133 * v136, y - v134 * v136, z - v135 * v136, x2, y2, z2)
        local v140 = 1 - v132

        v108, v109, v110 = normalize_safe_xyz(v137 * v132 + v108 * v140, v138 * v132 + v109 * v140, v139 * v132 + v110 * v140, x2, y2, z2)
        p44.target = Vector3.new(v108, v109, v110)
    end

    local v141 = GroundNormalFilter.filter_raw(p44.slow_filter, p45.up_vector_smoothing_slow, { v108, v109, v110, 0 })
    local v142, v143, v144 = normalize_safe_xyz(v141[1], v141[2], v141[3], x2, y2, z2)
    local v145 = GroundNormalFilter.filter_raw(p44.fast_filter, p45.up_vector_smoothing_fast, { v108, v109, v110, 0 })
    local v146, v147, v148 = normalize_safe_xyz(v145[1], v145[2], v145[3], x2, y2, z2)
    local v149 = p46.speed * 0.10000000149011612
    local v150 = PointGraph.evaluate(p45.up_vector_smoothing_vs_speed, v149)
    local v151 = 1 - v150
    local v152, v153, v154 = normalize_safe_xyz(v146 * v150 + v142 * v151, v147 * v150 + v143 * v151, v148 * v150 + v144 * v151, x2, y2, z2)
    local v155 = PointGraph.evaluate(p45.up_vector_max_delta_vs_speed, v149) * 0.20000000298023224
    local up = p44.up
    local x3, y3, z3 = up.x, up.y, up.z
    local v156 = v152 - x3
    local v157 = v153 - y3
    local v158 = v154 - z3
    local v159 = v156 * v156 + v157 * v157 + v158 * v158
    local v160

    if v159 ~= 0 and v159 > -1.1754943508222875E-38 and v159 < 1.1754943508222875E-38 then
        local v161 = math.abs(v159) * 7.1362384635298E+44
        local v162 = math.floor(v161)
        local v163 = v161 - v162

        v160 = (if v163 > 0.5 or v163 == 0.5 and v162 % 2 == 1 then v162 + 1 else v162) * 1.401298464324817E-45

        if v159 < 0 then
            v160 = -v160
        end
    else
        buffer.writef32(v1, 0, v159)
        v160 = buffer.readf32(v1, 0)
    end

    local v164 = v160 * inverse_length_squared(v160, 2)

    if v160 == 0 then
        v164 = 0
    end

    if not (v164 - v155 >= -0) then
        v155 = v164
    end

    local v165, v166, v167 = normalize_safe_xyz(v156, v157, v158, x2, y2, z2)
    local v168, v169, v170 = normalize_safe_xyz(v165 * v155 + x3, v166 * v155 + y3, v167 * v155 + z3, x2, y2, z2)
    local v171 = v168 - x3
    local v172 = v169 - y3
    local v173 = v170 - z3
    local up_velocity = p44.up_velocity
    local x4, y4, z4 = up_velocity.x, up_velocity.y, up_velocity.z
    local _, v174, v175, v176 = clamp_length_xyz(v171 - x4, v172 - y4, v173 - z4, p45.up_vector_max_acceleration * 0.01666666753590107)
    local v177 = x4 + v174
    local v178 = y4 + v175
    local v179 = z4 + v176

    p44.up_velocity = Vector3.new(v177, v178, v179)

    local previous_reckoning_right = p46.previous_reckoning_right
    local v180 = v177 * previous_reckoning_right.x + v178 * previous_reckoning_right.y + v179 * previous_reckoning_right.z
    local v181 = previous_reckoning_right.x * v180
    local v182 = previous_reckoning_right.y * v180
    local v183 = previous_reckoning_right.z * v180
    local extra_side_damping = p45.extra_side_damping
    local v184 = v181 * extra_side_damping + (v177 - v181)
    local v185 = v182 * extra_side_damping + (v178 - v182)
    local v186 = v183 * extra_side_damping + (v179 - v183)

    p44.up_velocity = Vector3.new(v184, v185, v186)

    local v187 = x3 + v184
    local v188 = y3 + v185
    local v189 = z3 + v186
    local v190, v191, v192 = normalize_safe_xyz(v187, v188, v189, v187, v188, v189)

    p44.up = Vector3.new(v190, v191, v192)

    if v184 * v171 + v185 * v172 + v186 * v173 < 0 then
        local anti_wobble_damping = p45.anti_wobble_damping

        v184 *= anti_wobble_damping
        v185 *= anti_wobble_damping
        v186 *= anti_wobble_damping
        p44.up_velocity = Vector3.new(v184, v185, v186)
    end

    if p46.prevent_up_behind_board then
        local effective_board_forward = p46.effective_board_forward
        local x, y, z = effective_board_forward.x, effective_board_forward.y, effective_board_forward.z

        if v190 * x + v191 * y + v192 * z < 0 then
            local v193 = -v192 * y + v191 * z
            local v194 = -v190 * z + v192 * x
            local v195 = -v191 * x + v190 * y

            v190, v191, v192 = normalize_safe_xyz(-z * v194 + y * v195, -x * v195 + z * v193, -y * v193 + x * v194, v190, v191, v192)
            p44.up = Vector3.new(v190, v191, v192)

            local v196 = v184 * 0.5
            local v197 = v185 * 0.5
            local v198 = v186 * 0.5

            p44.up_velocity = Vector3.new(v196, v197, v198)
        end
    end

    GroundNormalFilter.publish_current(p44.slow_filter, { v190, v191, v192, 0 })
    GroundNormalFilter.publish_current(p44.fast_filter, { v190, v191, v192, 0 })
end

return t1
