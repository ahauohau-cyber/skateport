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

local Clip = require(sim.import)("skate_game/physics/climbing/clip").Clip
local t1 = {}

local function glam_add(p2, p3) -- line: 23
    return {
        p2[1] + p3[1],
        p2[2] + p3[2],
        p2[3] + p3[3]
    }
end

local function glam_sub(p4, p5) -- line: 26
    return {
        p4[1] - p5[1],
        p4[2] - p5[2],
        p4[3] - p5[3]
    }
end

local function glam_scale(p6, p7) -- line: 29
    return {
        p6[1] * p7,
        p6[2] * p7,
        p6[3] * p7
    }
end

local function glam_neg(p8) -- line: 32
    return {
        -p8[1],
        -p8[2],
        -p8[3]
    }
end

local function glam_dot(p9, p10) -- line: 35
    return p9[1] * p10[1] + p9[2] * p10[2] + p9[3] * p10[3]
end

local function glam_cross(p11, p12) -- line: 38
    return {
        p11[2] * p12[3] - p12[2] * p11[3],
        p11[3] * p12[1] - p12[3] * p11[1],
        p11[1] * p12[2] - p12[1] * p11[2]
    }
end

local function glam_length(p13) -- line: 45
    return (math.sqrt(p13[1] * p13[1] + p13[2] * p13[2] + p13[3] * p13[3]))
end

local function glam_distance(p14, p15) -- line: 48
    local t2 = {
        p14[1] - p15[1],
        p14[2] - p15[2],
        p14[3] - p15[3]
    }

    return (math.sqrt(t2[1] * t2[1] + t2[2] * t2[2] + t2[3] * t2[3]))
end

local function glam_lerp(p16, p17, p18) -- line: 52
    local v3 = 1 - p18

    return {
        p16[1] * v3 + p17[1] * p18,
        p16[2] * v3 + p17[2] * p18,
        p16[3] * v3 + p17[3] * p18
    }
end

local function glam_normalize(p19) -- line: 57
    local v5 = 1 / math.sqrt(p19[1] * p19[1] + p19[2] * p19[2] + p19[3] * p19[3])

    return {
        p19[1] * v5,
        p19[2] * v5,
        p19[3] * v5
    }
end

local function glam_try_normalize(p20) -- line: 61
    local v7 = 1 / math.sqrt(p20[1] * p20[1] + p20[2] * p20[2] + p20[3] * p20[3])

    return if v7 == v7 and v7 ~= 1e999 and v7 ~= (-1e999) and v7 > 0 then {
        p20[1] * v7,
        p20[2] * v7,
        p20[3] * v7
    } else nil
end

local function glam_any_orthonormal_vector(p21) -- line: 69
    -- upvalues: rt (copy)
    local v8 = rt.signum(p21[3])
    local v9 = -1 / (v8 + p21[3])

    return {
        p21[1] * p21[2] * v9,
        v8 + p21[2] * p21[2] * v9,
        -p21[2]
    }
end

local function glam_quat_mul(p22, p23) -- line: 77
    local v10 = p22[1]
    local v11 = p22[2]
    local v12 = p22[3]
    local v13 = p22[4]
    local v14 = p23[1]
    local v15 = p23[2]
    local v16 = p23[3]
    local v17 = p23[4]

    return {
        v13 * v14 + v10 * v17 + v11 * v16 - v12 * v15,
        v13 * v15 - v10 * v16 + v11 * v17 + v12 * v14,
        v13 * v16 + v10 * v15 - v11 * v14 + v12 * v17,
        v13 * v17 - v10 * v14 - v11 * v15 - v12 * v16
    }
end

local function glam_quat_mul_vec3(p24, p25) -- line: 88
    -- upvalues: glam_cross (copy)
    local v18 = p24[4]
    local t3 = {
        p24[1],
        p24[2],
        p24[3]
    }
    local v19 = t3[1] * t3[1] + t3[2] * t3[2] + t3[3] * t3[3]
    local v20 = v18 * v18 - v19
    local t4 = {
        p25[1] * v20,
        p25[2] * v20,
        p25[3] * v20
    }
    local v21 = (p25[1] * t3[1] + p25[2] * t3[2] + p25[3] * t3[3]) * 2
    local t5 = {
        t3[1] * v21,
        t3[2] * v21,
        t3[3] * v21
    }
    local t6 = {
        t4[1] + t5[1],
        t4[2] + t5[2],
        t4[3] + t5[3]
    }
    local v22 = glam_cross(t3, p25)
    local v23 = v18 * 2
    local t7 = {
        v22[1] * v23,
        v22[2] * v23,
        v22[3] * v23
    }

    return {
        t6[1] + t7[1],
        t6[2] + t7[2],
        t6[3] + t7[3]
    }
end

local function glam_quat_inverse(p26) -- line: 98
    return {
        -p26[1],
        -p26[2],
        -p26[3],
        p26[4]
    }
end

local function glam_quat_normalize(p27) -- line: 102
    local v25 = 1 / math.sqrt(p27[1] * p27[1] + p27[2] * p27[2] + p27[3] * p27[3] + p27[4] * p27[4])

    return {
        p27[1] * v25,
        p27[2] * v25,
        p27[3] * v25,
        p27[4] * v25
    }
end

local function glam_quat_from_axis_angle(p28, p29) -- line: 107
    local v27 = math.sin(p29 * 0.5)
    local v29 = math.cos(p29 * 0.5)

    return {
        p28[1] * v27,
        p28[2] * v27,
        p28[3] * v27,
        v29
    }
end

local function glam_quat_from_rotation_arc(p30, p31) -- line: 112
    -- upvalues: rt (copy), glam_cross (copy), glam_any_orthonormal_vector (copy), glam_quat_normalize (copy)
    local v30 = 1 - 2 * rt.F32_EPSILON
    local v31 = p30[1] * p31[1] + p30[2] * p31[2] + p30[3] * p31[3]

    if v30 < v31 then
        return { 0, 0, 0, 1 }
    end

    if v31 < -v30 then
        local v32 = glam_any_orthonormal_vector(p30)

        return {
            v32[1] * 1,
            v32[2] * 1,
            v32[3] * 1,
            6.123233995736766E-17
        }
    end

    local v33 = glam_cross(p30, p31)

    return (glam_quat_normalize({
        v33[1],
        v33[2],
        v33[3],
        v31 + 1
    }))
end

local function glam_acos_approx(p32) -- line: 127
    local v34 = p32 >= 0
    local v35 = math.abs(p32)
    local v36 = 1 - v35

    if v36 < 0 then
        v36 = 0
    end

    local v37 = math.sqrt(v36)
    local v38 = (((((((v35 * -0.0012624911 + 0.00667009) * v35 - 0.017088126) * v35 + 0.03089188) * v35 - 0.050174303) * v35 + 0.08897899) * v35 - 0.2145988) * v35 + 1.5707963) * v37

    if v34 then
        return v38
    end

    return 3.141592653589793 - v38
end

local function glam_quat_slerp(p33, p34, p35) -- line: 150
    -- upvalues: rt (copy), glam_quat_normalize (copy)
    local v39 = p33[1] * p34[1] + p33[2] * p34[2] + p33[3] * p34[3] + p33[4] * p34[4]
    local v40 = p34[1]
    local v41 = p34[2]
    local v42 = p34[3]
    local v43 = p34[4]

    if v39 < 0 then
        v40 = -v40
        v41 = -v41
        v42 = -v42
        v43 = -v43
        v39 = -v39
    end

    if 1 - rt.F32_EPSILON < v39 then
        local v44 = 1 - p35

        return (glam_quat_normalize({
            p33[1] * v44 + v40 * p35,
            p33[2] * v44 + v41 * p35,
            p33[3] * v44 + v42 * p35,
            p33[4] * v44 + v43 * p35
        }))
    end

    local v45 = v39 >= 0
    local v46 = math.abs(v39)
    local v47 = 1 - v46

    if v47 < 0 then
        v47 = 0
    end

    local v48 = math.sqrt(v47)
    local v49 = (((((((v46 * -0.0012624911 + 0.00667009) * v46 - 0.017088126) * v46 + 0.03089188) * v46 - 0.050174303) * v46 + 0.08897899) * v46 - 0.2145988) * v46 + 1.5707963) * v48

    if not v45 then
        v49 = 3.141592653589793 - v49
    end

    local v51 = math.sin(v49 * (1 - p35))
    local v53 = math.sin(v49 * p35)
    local v54 = 1 / math.sin(v49)

    return {
        (p33[1] * v51 + v40 * v53) * v54,
        (p33[2] * v51 + v41 * v53) * v54,
        (p33[3] * v51 + v42 * v53) * v54,
        (p33[4] * v51 + v43 * v53) * v54
    }
end

local function glam_quat_from_rotation_axes(p36, p37, p38) -- line: 176
    local v55 = p36[1]
    local v56 = p36[2]
    local v57 = p36[3]
    local v58 = p37[1]
    local v59 = p37[2]
    local v60 = p37[3]
    local v61 = p38[1]
    local v62 = p38[2]
    local v63 = p38[3]

    if v63 <= 0 then
        local v64 = v59 - v55
        local v65 = 1 - v63

        if v64 <= 0 then
            local v66 = v65 - v64
            local v67 = 0.5 / math.sqrt(v66)

            return {
                v66 * v67,
                (v56 + v58) * v67,
                (v57 + v61) * v67,
                (v60 - v62) * v67
            }
        end

        local v68 = v65 + v64
        local v69 = 0.5 / math.sqrt(v68)

        return {
            (v56 + v58) * v69,
            v68 * v69,
            (v60 + v62) * v69,
            (v61 - v57) * v69
        }
    end

    local v70 = v59 + v55
    local v71 = 1 + v63

    if v70 <= 0 then
        local v72 = v71 - v70
        local v73 = 0.5 / math.sqrt(v72)

        return {
            (v57 + v61) * v73,
            (v60 + v62) * v73,
            v72 * v73,
            (v56 - v58) * v73
        }
    end

    local v74 = v71 + v70
    local v75 = 0.5 / math.sqrt(v74)

    return {
        (v60 - v62) * v75,
        (v61 - v57) * v75,
        (v56 - v58) * v75,
        v74 * v75
    }
end

local function glam_mat4_inverse(p39) -- line: 215
    local v76 = p39[1][1]
    local v77 = p39[1][2]
    local v78 = p39[1][3]
    local v79 = p39[1][4]
    local v80 = p39[2][1]
    local v81 = p39[2][2]
    local v82 = p39[2][3]
    local v83 = p39[2][4]
    local v84 = p39[3][1]
    local v85 = p39[3][2]
    local v86 = p39[3][3]
    local v87 = p39[3][4]
    local v88 = p39[4][1]
    local v89 = p39[4][2]
    local v90 = p39[4][3]
    local v91 = p39[4][4]
    local v92 = v76 * v81 - v80 * v77
    local v93 = v76 * v82 - v80 * v78
    local v94 = v76 * v83 - v80 * v79
    local v95 = v77 * v82 - v81 * v78
    local v96 = v77 * v83 - v81 * v79
    local v97 = v78 * v83 - v82 * v79
    local v98 = v86 * v91 - v90 * v87
    local v99 = v85 * v91 - v89 * v87
    local v100 = v85 * v90 - v89 * v86
    local v101 = v84 * v91 - v88 * v87
    local v102 = v84 * v90 - v88 * v86
    local v103 = v84 * v89 - v88 * v85
    local v104 = v92 * v98 - v93 * v99 + v94 * v100 + v95 * v101 - v96 * v102 + v97 * v103
    local v105 = 1 / v104

    return {
        {
            (v81 * v98 - v82 * v99 + v83 * v100) * v105,
            (-v77 * v98 + v78 * v99 - v79 * v100) * v105,
            (v89 * v97 - v90 * v96 + v91 * v95) * v105,
            (-v85 * v97 + v86 * v96 - v87 * v95) * v105
        },
        {
            (-v80 * v98 + v82 * v101 - v83 * v102) * v105,
            (v76 * v98 - v78 * v101 + v79 * v102) * v105,
            (-v88 * v97 + v90 * v94 - v91 * v93) * v105,
            (v84 * v97 - v86 * v94 + v87 * v93) * v105
        },
        {
            (v80 * v99 - v81 * v101 + v83 * v103) * v105,
            (-v76 * v99 + v77 * v101 - v79 * v103) * v105,
            (v88 * v96 - v89 * v94 + v91 * v92) * v105,
            (-v84 * v96 + v85 * v94 - v87 * v92) * v105
        },
        {
            (-v80 * v100 + v81 * v102 - v82 * v103) * v105,
            (v76 * v100 - v77 * v102 + v78 * v103) * v105,
            (-v88 * v95 + v89 * v93 - v90 * v92) * v105,
            (v84 * v95 - v85 * v93 + v86 * v92) * v105
        }
    }, v104
end

local function glam_mat4_transform_point3(p40, p41) -- line: 263
    return {
        p40[1][1] * p41[1] + p40[2][1] * p41[2] + p40[3][1] * p41[3] + p40[4][1],
        p40[1][2] * p41[1] + p40[2][2] * p41[2] + p40[3][2] * p41[3] + p40[4][2],
        p40[1][3] * p41[1] + p40[2][3] * p41[2] + p40[3][3] * p41[3] + p40[4][3]
    }
end

local function glam_mat4_rotation(p42) -- line: 271
    -- upvalues: rt (copy), glam_quat_from_rotation_axes (copy), glam_mat4_inverse (copy)
    local _, v106 = glam_mat4_inverse(p42)
    local v107 = p42[1]
    local v108 = p42[2]
    local v109 = p42[3]
    local v111 = math.sqrt(v107[1] * v107[1] + v107[2] * v107[2] + v107[3] * v107[3] + v107[4] * v107[4]) * rt.signum(v106)
    local v113 = math.sqrt(v108[1] * v108[1] + v108[2] * v108[2] + v108[3] * v108[3] + v108[4] * v108[4])
    local v115 = math.sqrt(v109[1] * v109[1] + v109[2] * v109[2] + v109[3] * v109[3] + v109[4] * v109[4])
    local v116 = 1 / v111
    local v117 = 1 / v113
    local v118 = 1 / v115

    return (glam_quat_from_rotation_axes({
        v107[1] * v116,
        v107[2] * v116,
        v107[3] * v116
    }, {
        v108[1] * v117,
        v108[2] * v117,
        v108[3] * v117
    }, {
        v109[1] * v118,
        v109[2] * v118,
        v109[3] * v118
    }))
end

local function glam_w_axis(p43) -- line: 285
    return {
        p43[4][1],
        p43[4][2],
        p43[4][3]
    }
end

local solve, rotate

function t1.clearance(p44, p45) -- line: 292
    -- upvalues: rt (copy), Clip (copy)
    local v119 = Clip.hands(p44, p45)
    local v120 = p45[Clip.index(p44, "HIPS") + 1]
    local t8 = {
        v120[4][1],
        v120[4][2],
        v120[4][3]
    }
    local v121 = rt.fmax(t8[3] - v119[3] + 0.24, 0)

    return {
        0,
        v121 * 0.53,
        -v121
    }
end

t1.PALM = { 0.075, 0.052, 0 }

function t1.wrist(p46, p47) -- line: 306
    -- upvalues: t1 (copy), glam_cross (copy), glam_quat_mul_vec3 (copy), glam_quat_from_rotation_axes (copy)
    local v122 = p46.normals[p47 + 1]
    local forward, forward2 = p46.forward, p46.forward
    local v123 = forward2[1] * v122[1] + forward2[2] * v122[2] + forward2[3] * v122[3]
    local t9 = {
        v122[1] * v123,
        v122[2] * v123,
        v122[3] * v123
    }
    local t10 = {
        forward[1] - t9[1],
        forward[2] - t9[2],
        forward[3] - t9[3]
    }
    local v125 = 1 / math.sqrt(t10[1] * t10[1] + t10[2] * t10[2] + t10[3] * t10[3])
    local t11 = {
        t10[1] * v125,
        t10[2] * v125,
        t10[3] * v125
    }
    local v126 = glam_quat_from_rotation_axes(t11, {
        -v122[1],
        -v122[2],
        -v122[3]
    }, (glam_cross(t11, {
        -v122[1],
        -v122[2],
        -v122[3]
    })))
    local v127 = p46.palms[p47 + 1]
    local v128 = glam_quat_mul_vec3(v126, t1.PALM)

    return {
        v127[1] - v128[1],
        v127[2] - v128[2],
        v127[3] - v128[3]
    }, v126
end

function t1.hands(p48, p49, p50, p51, p52) -- line: 315
    -- upvalues: Clip (copy), t1 (copy), glam_lerp (copy), glam_quat_mul (copy), glam_quat_slerp (copy), glam_mat4_inverse (copy), glam_mat4_transform_point3 (copy), glam_mat4_rotation (copy), solve (ref)
    local v129 = Clip.globals(p48, p49)
    local v130 = glam_mat4_inverse(p50)
    local v131 = glam_mat4_rotation(p50)

    for v132, v133 in ipairs({ "LEFT", "RIGHT" }) do
        local v134 = v132 - 1
        local v135 = Clip.index(p48, v133 .. "ARM")
        local v136 = Clip.index(p48, v133 .. "FOREARM")
        local v137 = Clip.index(p48, v133 .. "HAND")
        local v138, v139 = t1.wrist(p51, v134)
        local v140 = v129[v137 + 1]
        local v141 = glam_lerp({
            v140[4][1],
            v140[4][2],
            v140[4][3]
        }, glam_mat4_transform_point3(v130, v138), p52)
        local v142 = glam_quat_slerp(glam_mat4_rotation(v129[v137 + 1]), glam_quat_mul({
            -v131[1],
            -v131[2],
            -v131[3],
            v131[4]
        }, v139), p52)

        solve(p48, p49, v135, v136, v137, v141, v142)
    end
end

function t1.solve(p53, p54, p55, p56, p57, p58, p59) -- line: 337
    -- upvalues: rt (copy), Clip (copy), glam_any_orthonormal_vector (copy), glam_quat_mul (copy), glam_quat_normalize (copy), glam_mat4_rotation (copy), rotate (ref)
    local v143 = Clip.globals(p53, p54)
    local v144 = v143[p55 + 1]
    local t12 = {
        v144[4][1],
        v144[4][2],
        v144[4][3]
    }
    local v145 = v143[p56 + 1]
    local t13 = {
        v145[4][1],
        v145[4][2],
        v145[4][3]
    }
    local v146 = v143[p57 + 1]
    local t14 = {
        v146[4][1],
        v146[4][2],
        v146[4][3]
    }
    local t15 = {
        t12[1] - t13[1],
        t12[2] - t13[2],
        t12[3] - t13[3]
    }
    local v148 = math.sqrt(t15[1] * t15[1] + t15[2] * t15[2] + t15[3] * t15[3])
    local t16 = {
        t13[1] - t14[1],
        t13[2] - t14[2],
        t13[3] - t14[3]
    }
    local v150 = math.sqrt(t16[1] * t16[1] + t16[2] * t16[2] + t16[3] * t16[3])
    local t17 = {
        p58[1] - t12[1],
        p58[2] - t12[2],
        p58[3] - t12[3]
    }
    local v152 = 1 / math.sqrt(t17[1] * t17[1] + t17[2] * t17[2] + t17[3] * t17[3])
    local t18 = if not (v152 == v152 and v152 ~= 1e999 and v152 ~= (-1e999) and v152 > 0) then nil else {
        t17[1] * v152,
        t17[2] * v152,
        t17[3] * v152
    }

    if t18 == nil then
        return
    end

    local v154 = math.abs(v148 - v150) + 1E-04
    local v155 = v148 + v150 - 1E-04

    if not (v154 <= v155) then
        error(("min > max, or either was NaN. min = %*, max = %*"):format(v154, v155), 0)
    end

    local clamp = rt.clamp
    local t19 = {
        t12[1] - p58[1],
        t12[2] - p58[2],
        t12[3] - p58[3]
    }
    local v157 = clamp(math.sqrt(t19[1] * t19[1] + t19[2] * t19[2] + t19[3] * t19[3]), v154, v155)
    local v158 = (v148 * v148 - v150 * v150 + v157 * v157) / (2 * v157)
    local t20 = {
        t13[1] - t12[1],
        t13[2] - t12[2],
        t13[3] - t12[3]
    }
    local t21 = {
        t13[1] - t12[1],
        t13[2] - t12[2],
        t13[3] - t12[3]
    }
    local v159 = t21[1] * t18[1] + t21[2] * t18[2] + t21[3] * t18[3]
    local t22 = {
        t18[1] * v159,
        t18[2] * v159,
        t18[3] * v159
    }
    local t23 = {
        t20[1] - t22[1],
        t20[2] - t22[2],
        t20[3] - t22[3]
    }
    local v161 = 1 / math.sqrt(t23[1] * t23[1] + t23[2] * t23[2] + t23[3] * t23[3])
    local v162 = if not (v161 == v161 and v161 ~= 1e999 and v161 ~= (-1e999) and v161 > 0) then nil else {
        t23[1] * v161,
        t23[2] * v161,
        t23[3] * v161
    }

    if v162 == nil then
        v162 = glam_any_orthonormal_vector(t18)
    end

    local t24 = {
        t18[1] * v158,
        t18[2] * v158,
        t18[3] * v158
    }
    local t25 = {
        t12[1] + t24[1],
        t12[2] + t24[2],
        t12[3] + t24[3]
    }
    local v164 = math.sqrt((rt.fmax(v148 * v148 - v158 * v158, 0)))
    local t26 = {
        v162[1] * v164,
        v162[2] * v164,
        v162[3] * v164
    }
    local t27 = {
        t25[1] + t26[1],
        t25[2] + t26[2],
        t25[3] + t26[3]
    }

    rotate(p53, p54, v143, p55, {
        t13[1] - t12[1],
        t13[2] - t12[2],
        t13[3] - t12[3]
    }, {
        t27[1] - t12[1],
        t27[2] - t12[2],
        t27[3] - t12[3]
    })

    local v165 = Clip.globals(p53, p54)
    local v166 = v165[p56 + 1]
    local t28 = {
        v166[4][1],
        v166[4][2],
        v166[4][3]
    }
    local rotate2 = rotate
    local v167 = v165[p57 + 1]
    local t29 = {
        v167[4][1],
        v167[4][2],
        v167[4][3]
    }
    local t30 = {
        t29[1] - t28[1],
        t29[2] - t28[2],
        t29[3] - t28[3]
    }
    local t31 = {
        t18[1] * v157,
        t18[2] * v157,
        t18[3] * v157
    }
    local t32 = {
        t12[1] + t31[1],
        t12[2] + t31[2],
        t12[3] + t31[3]
    }

    rotate2(p53, p54, v165, p56, t30, {
        t32[1] - t28[1],
        t32[2] - t28[2],
        t32[3] - t28[3]
    })

    local v169 = glam_mat4_rotation(Clip.globals(p53, p54)[p56 + 1])
    local v170 = glam_quat_mul({
        -v169[1],
        -v169[2],
        -v169[3],
        v169[4]
    }, p59)
    local translation = p54[p57 + 1].translation
    local v172 = 1 / math.sqrt(translation[1] * translation[1] + translation[2] * translation[2] + translation[3] * translation[3])
    local t33 = {
        translation[1] * v172,
        translation[2] * v172,
        translation[3] * v172
    }
    local t34 = {
        v170[1],
        v170[2],
        v170[3]
    }
    local v173 = t34[1] * t33[1] + t34[2] * t33[2] + t34[3] * t33[3]
    local t35 = {
        t33[1] * v173,
        t33[2] * v173,
        t33[3] * v173
    }
    local t36 = {
        t35[1],
        t35[2],
        t35[3],
        v170[4]
    }
    local v174 = if t36[1] * t36[1] + t36[2] * t36[2] + t36[3] * t36[3] + t36[4] * t36[4] > 1E-08 then glam_quat_normalize(t36) else { 0, 0, 0, 1 }

    p54[p56 + 1].rotation = glam_quat_normalize((glam_quat_mul(p54[p56 + 1].rotation, v174)))
    p54[p57 + 1].rotation = glam_quat_normalize((glam_quat_mul({
        -v174[1],
        -v174[2],
        -v174[3],
        v174[4]
    }, v170)))
end

solve = t1.solve

function t1.rotate(p60, p61, p62, p63, p64, p65) -- line: 401
    -- upvalues: glam_quat_mul (copy), glam_quat_normalize (copy), glam_quat_from_rotation_arc (copy), glam_mat4_rotation (copy)
    local v176 = 1 / math.sqrt(p64[1] * p64[1] + p64[2] * p64[2] + p64[3] * p64[3])
    local t37 = {
        p64[1] * v176,
        p64[2] * v176,
        p64[3] * v176
    }
    local v178 = 1 / math.sqrt(p65[1] * p65[1] + p65[2] * p65[2] + p65[3] * p65[3])
    local v179 = glam_quat_from_rotation_arc(t37, {
        p65[1] * v178,
        p65[2] * v178,
        p65[3] * v178
    })
    local v180 = p60.parents[p63 + 1]

    if v180 < 0 or p62[v180 + 1] == nil then
        error("index out of bounds", 0)
    end

    local v181 = p61[p63 + 1]
    local v182 = glam_mat4_rotation(p62[v180 + 1])

    v181.rotation = glam_quat_normalize((glam_quat_mul(glam_quat_mul({
        -v182[1],
        -v182[2],
        -v182[3],
        v182[4]
    }, v179), (glam_mat4_rotation(p62[p63 + 1])))))
end

rotate = t1.rotate

return t1
