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
local Vector3 = import("skate_core/math").Vector3
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local v9 = import("skate_core/physics/skeleton_animation_record")
local compose_affine = v9.compose_affine
local v10 = import("skate_core/riding/collision_response")
local signed_angle = v10.signed_angle
local sin_cos = import("skate_core/trigonometry").sin_cos
local t1 = {
    Settings = {},
    BoneIndices = {}
}

function t1.BoneIndices.all(p3) -- line: 53
    return {
        p3.front_truck,
        p3.back_truck,
        p3.front_left_wheel,
        p3.front_right_wheel,
        p3.back_left_wheel,
        p3.back_right_wheel
    }
end

t1.Input = {}

function t1.publish(p4, p5, p6, p7) -- line: 73
    -- upvalues: rt (copy), dot3 (copy), compose_affine (copy), t1 (copy)
    local t2 = {
        0, 1, 0, 0
    }
    local t3 = {
        0, 0, 1, 0
    }
    local v11 = rt.from_fn(4, function(p8) -- line: 76
        -- upvalues: p4 (copy), t2 (copy), t3 (copy), rt (copy), t1 (copy)
        local v12 = t1.inverse_direction(p4.bodies[4 + rt.idiv(p8, 2) + 1], p4.bodies[p8 + 1][2])

        return t1.rotation_x(t1.angle(v12, t2, t3))
    end)
    local v13 = t1.inverse_direction(p4.skeleton_board, t1.normalize_safe(t1.subtract(p4.bodies[1][4], p4.bodies[2][4])))
    local v14 = t1.inverse_direction(p4.skeleton_board, t1.normalize_safe(t1.subtract(p4.bodies[4][4], p4.bodies[3][4])))

    if dot3(v13, v13) < 0.5 then
        v13 = rt.copy(p4.truck_frames[1][3])
    end

    if dot3(v14, v14) < 0.5 then
        local v15 = p4.truck_frames[2][3]

        v14 = {
            -v15[1],
            -v15[2],
            -v15[3],
            -v15[4]
        }
    end

    local t4 = {
        -1, -0, -0, -0
    }
    local v16 = t1.wrap(t1.angle(v14, t4, p4.truck_frames[2][1]))
    local v17 = t1.wrap(t1.angle(v13, t4, p4.truck_frames[1][1]))
    local v18 = p4.deck_wobble_tilt * p5.truck_tilt_wobble_scalar
    local v19 = t1.clamp(-p5.truck_tilt_scalar * v16 + -v18, -p5.truck_tilt_max_angle, p5.truck_tilt_max_angle)
    local v20 = t1.clamp(-p5.truck_tilt_scalar * v17 + v18, -p5.truck_tilt_max_angle, p5.truck_tilt_max_angle)

    for _, v21 in {
            {
                0,
                p6.front_truck,
                v20
            },
            {
                1,
                p6.back_truck,
                v19
            }
        } do
        local v22 = v21[1]
        local v23 = v21[2]
        local v24 = v21[3]
        local v25 = if p4.average_compression[v22 + 1] < 0.0010000000474974513 then 0 else p4.average_compression[v22 + 1]
        local v26 = t1.clamp(v25 - p4.deck_wobble_squish, 0, p5.truck_displacement_max)
        local v27 = compose_affine(p7[v23 + 1], t1.rotation_x(v24))
        local t5 = {
            { 1, 0, 0, 0 },
            { 0, 1, 0, 0 },
            { 0, 0, 1, 0 },
            { 0, v26, 0, 0 }
        }

        p7[v23 + 1] = compose_affine(t5, v27)
    end

    local t6 = {
        p6.front_left_wheel,
        p6.front_right_wheel,
        p6.back_left_wheel,
        p6.back_right_wheel
    }

    for i = 0, 3 do
        local v28 = t6[i + 1]

        p7[v28 + 1] = compose_affine(p7[v28 + 1], v11[i + 1])
    end
end

local signed_angle_xyz = v10.signed_angle_xyz
local compose_affine_into = v9.compose_affine_into
local t7 = {
    { 1, 0, 0, 1 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 }
}
local t8 = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}
local t9 = {
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 }
}

local function set_rotation_x(p9) -- line: 193
    -- upvalues: sin_cos (copy), t7 (copy)
    local v29, v30 = sin_cos(p9)
    local v31 = t7[2]

    v31[2] = v30
    v31[3] = v29

    local v32 = t7[3]

    v32[2] = -v29
    v32[3] = v30
end

local function wheel_angle(p10, p11) -- line: 202
    -- upvalues: signed_angle_xyz (copy)
    local v33 = p11[1]
    local v34 = p11[2]
    local v35 = p11[3]
    local v36 = p10[1]
    local v37 = p10[2]
    local v38 = p10[3]

    return signed_angle_xyz(v35 * v36[3] + (v34 * v36[2] + v33 * v36[1]), v35 * v37[3] + (v34 * v37[2] + v33 * v37[1]), v35 * v38[3] + (v34 * v38[2] + v33 * v38[1]), 0, 1, 0, 0, 0, 1)
end

local function axle_direction(p12, p13, p14) -- line: 219
    -- upvalues: v1 (copy), inverse_length_squared (copy)
    local v39 = p13[1] - p14[1]
    local v40 = p13[2] - p14[2]
    local v41 = p13[3] - p14[3]
    local v42 = v39 * v39 + v40 * v40 + v41 * v41
    local v43

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        local v44 = math.abs(v42) * 7.1362384635298E+44
        local v45 = math.floor(v44)
        local v46 = v44 - v45

        v43 = (if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45) * 1.401298464324817E-45

        if v42 < 0 then
            v43 = -v43
        end
    else
        buffer.writef32(v1, 0, v42)
        v43 = buffer.readf32(v1, 0)
    end

    local v47 = inverse_length_squared(v43, 2)
    local v48 = if v43 == 0 then 0 else v43 * v47
    local v49, v50, v51

    if v48 > 9.999999974752427E-07 then
        v51 = v39 * v47
        v50 = v40 * v47
        v49 = v41 * v47
    else
        v51 = 0
        v50 = 0
        v49 = 0
    end

    local v52 = p12[1]
    local v53 = p12[2]
    local v54 = p12[3]

    return v49 * v52[3] + (v50 * v52[2] + v51 * v52[1]), v49 * v53[3] + (v50 * v53[2] + v51 * v53[1]), v49 * v54[3] + (v50 * v54[2] + v51 * v54[1])
end

function t1.publish_owned(p15, p16, p17, p18) -- line: 240
    -- upvalues: sin_cos (copy), t1 (copy), signed_angle_xyz (copy), compose_affine_into (copy), t7 (copy), t8 (copy), t9 (copy), wheel_angle (copy), axle_direction (copy)
    local bodies = p15.bodies
    local v55 = wheel_angle(bodies[5], bodies[1][2])
    local v56 = wheel_angle(bodies[5], bodies[2][2])
    local v57 = wheel_angle(bodies[6], bodies[3][2])
    local v58 = wheel_angle(bodies[6], bodies[4][2])
    local skeleton_board, truck_frames = p15.skeleton_board, p15.truck_frames
    local v59, v60, v61 = axle_direction(skeleton_board, bodies[1][4], bodies[2][4])
    local v62, v63, v64 = axle_direction(skeleton_board, bodies[4][4], bodies[3][4])

    if v59 * v59 + v60 * v60 + v61 * v61 < 0.5 then
        local v65 = truck_frames[1][3]

        v59 = v65[1]
        v60 = v65[2]
        v61 = v65[3]
    end

    if v62 * v62 + v63 * v63 + v64 * v64 < 0.5 then
        local v66 = truck_frames[2][3]

        v62 = -v66[1]
        v63 = -v66[2]
        v64 = -v66[3]
    end

    local v67 = truck_frames[2][1]
    local v68 = t1.wrap(signed_angle_xyz(v62, v63, v64, -1, -0, -0, v67[1], v67[2], v67[3]))
    local v69 = truck_frames[1][1]
    local v70 = t1.wrap(signed_angle_xyz(v59, v60, v61, -1, -0, -0, v69[1], v69[2], v69[3]))
    local v71 = p15.deck_wobble_tilt * p16.truck_tilt_wobble_scalar
    local v72 = t1.clamp(-p16.truck_tilt_scalar * v68 + -v71, -p16.truck_tilt_max_angle, p16.truck_tilt_max_angle)
    local v73 = t1.clamp(-p16.truck_tilt_scalar * v70 + v71, -p16.truck_tilt_max_angle, p16.truck_tilt_max_angle)
    local average_compression = p15.average_compression
    local v74 = t8[4]

    for i = 0, 1 do
        local v75, v76

        if i == 0 then
            v76 = v73
            v75 = p17.front_truck
        else
            v76 = v72
            v75 = p17.back_truck
        end

        local v77 = if average_compression[i + 1] < 0.0010000000474974513 then 0 else average_compression[i + 1]
        local v78 = t1.clamp(v77 - p15.deck_wobble_squish, 0, p16.truck_displacement_max)
        local v79 = p18[v75 + 1]
        local v80, v81 = sin_cos(v76)
        local v82 = t7[2]

        v82[2] = v81
        v82[3] = v80

        local v83 = t7[3]

        v83[2] = -v80
        v83[3] = v81
        compose_affine_into(t9, v79, t7)
        v74[2] = v78
        compose_affine_into(v79, t8, t9)
    end

    local v84 = p18[p17.front_left_wheel + 1]
    local v85, v86 = sin_cos(v55)
    local v87 = t7[2]

    v87[2] = v86
    v87[3] = v85

    local v88 = t7[3]

    v88[2] = -v85
    v88[3] = v86
    compose_affine_into(v84, v84, t7)

    local v89 = p18[p17.front_right_wheel + 1]
    local v90, v91 = sin_cos(v56)
    local v92 = t7[2]

    v92[2] = v91
    v92[3] = v90

    local v93 = t7[3]

    v93[2] = -v90
    v93[3] = v91
    compose_affine_into(v89, v89, t7)

    local v94 = p18[p17.back_left_wheel + 1]
    local v95, v96 = sin_cos(v57)
    local v97 = t7[2]

    v97[2] = v96
    v97[3] = v95

    local v98 = t7[3]

    v98[2] = -v95
    v98[3] = v96
    compose_affine_into(v94, v94, t7)

    local v99 = p18[p17.back_right_wheel + 1]
    local v100, v101 = sin_cos(v58)
    local v102 = t7[2]

    v102[2] = v101
    v102[3] = v100

    local v103 = t7[3]

    v103[2] = -v100
    v103[3] = v101
    compose_affine_into(v99, v99, t7)
end

function t1.angle(p19, p20, p21) -- line: 316
    -- upvalues: Vector3 (copy), signed_angle (copy)
    local function vector(p22) -- line: 317
        -- upvalues: Vector3 (copy)
        return Vector3.new(p22[1], p22[2], p22[3])
    end

    return signed_angle(Vector3.new(p19[1], p19[2], p19[3]), Vector3.new(p20[1], p20[2], p20[3]), vector(p21))
end

function t1.inverse_direction(p23, p24) -- line: 323
    local v104 = table.create(4, 0)

    for i = 0, 2 do
        local v105 = p24[1] * p23[i + 1][1]
        local v106 = p24[2] * p23[i + 1][2] + v105

        v104[i + 1] = p24[3] * p23[i + 1][3] + v106
    end

    return v104
end

function t1.normalize_safe(p25) -- line: 333
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy)
    local v107 = dot3(p25, p25)
    local v108

    if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
        local v109 = math.abs(v107) * 7.1362384635298E+44
        local v110 = math.floor(v109)
        local v111 = v109 - v110

        v108 = (if v111 > 0.5 or v111 == 0.5 and v110 % 2 == 1 then v110 + 1 else v110) * 1.401298464324817E-45

        if v107 < 0 then
            v108 = -v108
        end
    else
        buffer.writef32(v1, 0, v107)
        v108 = buffer.readf32(v1, 0)
    end

    local v112 = inverse_length_squared(v108, 2)

    if (if v108 == 0 then 0 else v108 * v112) > 9.999999974752427E-07 then
        return {
            p25[1] * v112,
            p25[2] * v112,
            p25[3] * v112,
            p25[4] * v112
        }
    end

    return table.create(4, 0)
end

function t1.subtract(p26, p27) -- line: 349
    return {
        p26[1] - p27[1],
        p26[2] - p27[2],
        p26[3] - p27[3],
        p26[4] - p27[4]
    }
end

function t1.wrap(p28) -- line: 353
    local v113 = p28 * 0.15915493667125702
    local v114 = v113 - math.floor(v113)

    return (v114 - (if v114 > 0.5 then 1 else 0)) * 6.2831854820251465
end

function t1.clamp(p29, p30, p31) -- line: 359
    local v115 = if p30 - p29 >= 0 then p30 else p29

    if p31 - v115 >= 0 then
        return v115
    end

    return p31
end

function t1.rotation_x(p32) -- line: 369
    -- upvalues: sin_cos (copy)
    local v116, v117 = sin_cos(p32)

    return {
        { 1, 0, 0, 1 },
        { 0, v117, v116, 0 },
        { 0, -v116, v117, 0 },
        table.create(4, 0)
    }
end

return t1
