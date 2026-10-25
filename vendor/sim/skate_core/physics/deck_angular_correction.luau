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

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/board_motion_output")
local dot, inverse_length_squared = v9.dot, v9.inverse_length_squared
local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local Vector3 = import("skate_core/math").Vector3
local t1 = {
    STEP = 0.01666666753590107,
    NORMAL_MINIMUM = 9.999999974752427E-07
}

function t1.apply_axis_displacement(p4, p5) -- line: 50
    -- upvalues: rt (copy), v1 (copy), dot (copy), inverse_length_squared (copy), Vector3 (copy), t1 (copy)
    local v10 = dot(p5, p5)
    local v11

    if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
        local v12 = math.abs(v10) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = (if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13) * 1.401298464324817E-45

        if v10 < 0 then
            v11 = -v11
        end
    else
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readf32(v1, 0)
    end

    local v15 = inverse_length_squared(v11, 2)
    local v16 = if (if v11 == 0 then 0 else v11 * v15) > t1.NORMAL_MINIMUM then t1.scale(p5, v15) else rt.copy(Vector3.ZERO)
    local v17 = t1.scale(v16, dot(v16, t1.scale(p4.angular_velocity, t1.STEP)))

    t1.apply_angular_displacement(p4, t1.subtract(p5, v17))
end

local fround = rt.fround

local function apply_angular_displacement_xyz(p6, p7, p8, p9) -- line: 74
    -- upvalues: Vector3 (copy), t1 (copy)
    local columns = p6.world_inverse_inertia.columns
    local v18 = columns[1]
    local v19 = columns[2]
    local v20 = columns[3]
    local v21 = v18[1]
    local v22 = v18[2]
    local v23 = v18[3]
    local v24 = v19[1]
    local v25 = v19[2]
    local v26 = v19[3]
    local v27 = v20[1]
    local v28 = v20[2]
    local v29 = v20[3]
    local v30 = -v26 * v28 + v25 * v29
    local v31 = -v24 * v29 + v26 * v27
    local v32 = -v25 * v27 + v24 * v28
    local v33 = -v29 * v22 + v28 * v23
    local v34 = -v27 * v23 + v29 * v21
    local v35 = -v28 * v21 + v27 * v22
    local v36 = -v23 * v25 + v22 * v26
    local v37 = -v21 * v26 + v23 * v24
    local v38 = -v22 * v24 + v21 * v25
    local v39 = t1.reciprocal_refined(v21 * v30 + v22 * v31 + v23 * v32)
    local v40 = v30 * v39
    local v41 = v33 * v39
    local v42 = v36 * v39
    local v43 = v31 * v39
    local v44 = v34 * v39
    local v45 = v37 * v39
    local v46 = v32 * v39
    local v47 = v35 * v39
    local v48 = v38 * v39
    local v49 = t1.reciprocal_refined(t1.STEP)
    local v50 = p7 * v49
    local v51 = p8 * v49
    local v52 = p9 * v49
    local v53 = v46 * v52 + (v43 * v51 + v40 * v50)
    local v54 = v47 * v52 + (v44 * v51 + v41 * v50)
    local v55 = v48 * v52 + (v45 * v51 + v42 * v50)
    local v56 = t1.reciprocal_refined(t1.STEP)
    local v57 = v53 * v56
    local v58 = v54 * v56
    local v59 = v55 * v56
    local v60 = v27 * v59 + (v24 * v58 + v21 * v57)
    local v61 = v28 * v59 + (v25 * v58 + v22 * v57)
    local v62 = v29 * v59 + (v26 * v58 + v23 * v57)
    local torque_acceleration = p6.torque_acceleration

    p6.torque_acceleration = Vector3.new(torque_acceleration.x + v60, torque_acceleration.y + v61, torque_acceleration.z + v62)
    p6.cool_down = 0
end

function t1.apply_limited_displacement(p10, p11) -- line: 111
    -- upvalues: inverse_length_squared (copy), t1 (copy), fround (copy), apply_angular_displacement_xyz (copy)
    local x, y, z = p11.x, p11.y, p11.z
    local v63 = x * x + y * y + z * z
    local v64 = if v63 < 1.1754943508222875E-38 and v63 > -1.1754943508222875E-38 and v63 ~= 0 then fround(v63) else vector.create(v63, 0, 0).x
    local v65 = inverse_length_squared(v64, 2)
    local v66 = if v64 == 0 then 0 else v64 * v65
    local v67, v68, v69

    if t1.NORMAL_MINIMUM < v66 then
        v67 = x * v65
        v68 = y * v65
        v69 = z * v65
    else
        v67 = 0
        v68 = 0
        v69 = 0
    end

    local angular_velocity = p10.angular_velocity
    local STEP = t1.STEP
    local v70 = v67 * (angular_velocity.x * STEP) + v68 * (angular_velocity.y * STEP) + v69 * (angular_velocity.z * STEP)
    local v71 = v67 * v70
    local v72 = v68 * v70
    local v73 = v69 * v70
    local v74 = x - v71
    local v75 = y - v72
    local v76 = z - v73

    if v74 * x + v75 * y + v76 * z < 0 then
        v74 = 0
        v75 = 0
        v76 = 0
    end

    if not (v71 * x + v72 * y + v73 * z < 0) then
        z = v76
        x = v74
        y = v75
    end

    apply_angular_displacement_xyz(p10, x, y, z)
end

function t1.apply_angular_displacement(p12, p13) -- line: 148
    -- upvalues: apply_angular_displacement_xyz (copy)
    apply_angular_displacement_xyz(p12, p13.x, p13.y, p13.z)
end

function t1.apply_limited_displacement_reference(p14, p15) -- line: 158
    -- upvalues: rt (copy), v1 (copy), dot (copy), inverse_length_squared (copy), Vector3 (copy), t1 (copy)
    local v77 = dot(p15, p15)
    local v78

    if v77 ~= 0 and v77 > -1.1754943508222875E-38 and v77 < 1.1754943508222875E-38 then
        local v79 = math.abs(v77) * 7.1362384635298E+44
        local v80 = math.floor(v79)
        local v81 = v79 - v80

        v78 = (if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then v80 + 1 else v80) * 1.401298464324817E-45

        if v77 < 0 then
            v78 = -v78
        end
    else
        buffer.writef32(v1, 0, v77)
        v78 = buffer.readf32(v1, 0)
    end

    local v82 = inverse_length_squared(v78, 2)
    local v83 = if (if v78 == 0 then 0 else v78 * v82) > t1.NORMAL_MINIMUM then t1.scale(p15, v82) else rt.copy(Vector3.ZERO)
    local v84 = t1.scale(v83, dot(v83, t1.scale(p14.angular_velocity, t1.STEP)))
    local v85 = t1.subtract(p15, v84)

    if dot(v85, p15) < 0 then
        v85 = rt.copy(Vector3.ZERO)
    end

    if dot(v84, p15) < 0 then
        v85 = rt.copy(p15)
    end

    t1.apply_angular_displacement_reference(p14, v85)
end

function t1.apply_angular_displacement_reference(p16, p17) -- line: 174
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v86 = rt.copy(p16.world_inverse_inertia)
    local v87 = t1.invert_symmetric(v86)
    local v88 = t1.reciprocal_refined(t1.STEP)
    local v89 = t1.scale(p17, v88)
    local v90 = t1.multiply(v87, v89)
    local v91 = t1.scale(v90, t1.reciprocal_refined(t1.STEP))
    local v92 = t1.multiply(v86, v91)

    p16.torque_acceleration = Vector3.new(p16.torque_acceleration.x + v92.x, p16.torque_acceleration.y + v92.y, p16.torque_acceleration.z + v92.z)
    p16.cool_down = 0
end

function t1.invert_symmetric(p18) -- line: 191
    -- upvalues: dot (copy), Vector3 (copy), t1 (copy)
    local v93 = Vector3.new(p18.columns[1][1], p18.columns[1][2], p18.columns[1][3])
    local v94 = Vector3.new(p18.columns[2][1], p18.columns[2][2], p18.columns[2][3])
    local v95 = Vector3.new(p18.columns[3][1], p18.columns[3][2], p18.columns[3][3])
    local v96 = t1.cross(v94, v95)
    local v97 = t1.cross(v95, v93)
    local v98 = t1.cross(v93, v94)
    local v99 = t1.reciprocal_refined(dot(v93, v96))

    return {
        columns = {
            {
                v96.x * v99,
                v97.x * v99,
                v98.x * v99
            },
            {
                v96.y * v99,
                v97.y * v99,
                v98.y * v99
            },
            {
                v96.z * v99,
                v97.z * v99,
                v98.z * v99
            }
        }
    }
end

function t1.reciprocal_refined(p19) -- line: 208
    -- upvalues: reciprocal_estimate (copy)
    local v100 = reciprocal_estimate(p19)
    local v101 = v100 * (-v100 * p19 + 1) + v100

    return v101 * (-v101 * p19 + 1) + v101
end

function t1.cross(p20, p21) -- line: 214
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p20.z * p21.y + p20.y * p21.z, -p20.x * p21.z + p20.z * p21.x, -p20.y * p21.x + p20.x * p21.y)
end

function t1.multiply(p22, p23) -- line: 218
    -- upvalues: Vector3 (copy)
    local function lane(p24) -- line: 219
        -- upvalues: p22 (copy), p23 (copy)
        return p22.columns[3][p24 + 1] * p23.z + (p22.columns[2][p24 + 1] * p23.y + p22.columns[1][p24 + 1] * p23.x)
    end

    return Vector3.new(p22.columns[3][1] * p23.z + (p22.columns[2][1] * p23.y + p22.columns[1][1] * p23.x), p22.columns[3][2] * p23.z + (p22.columns[2][2] * p23.y + p22.columns[1][2] * p23.x), p22.columns[3][3] * p23.z + (p22.columns[2][3] * p23.y + p22.columns[1][3] * p23.x))
end

function t1.scale(p25, p26) -- line: 225
    -- upvalues: Vector3 (copy)
    return Vector3.new(p25.x * p26, p25.y * p26, p25.z * p26)
end

function t1.subtract(p27, p28) -- line: 229
    -- upvalues: Vector3 (copy)
    return Vector3.new(p27.x - p28.x, p27.y - p28.y, p27.z - p28.z)
end

local v102

function t1.apply_ground_body_torque(p29) -- line: 242
    -- upvalues: Vector3 (copy), t1 (copy), v102 (ref)
    local v103 = v102

    if v103 == nil then
        v103 = t1.ground_torque_scalar()
        v102 = v103
    end

    local columns = p29.basis.columns
    local v104 = columns[1]
    local v105 = columns[2]
    local v106 = columns[3]
    local v107 = v106[1] * 0 + (v105[1] * v103 + v104[1] * 0)
    local v108 = v106[2] * 0 + (v105[2] * v103 + v104[2] * 0)
    local v109 = v106[3] * 0 + (v105[3] * v103 + v104[3] * 0)
    local columns2 = p29.world_inverse_inertia.columns
    local v110 = columns2[1]
    local v111 = columns2[2]
    local v112 = columns2[3]
    local v113 = v112[1] * v109 + (v111[1] * v108 + v110[1] * v107)
    local v114 = v112[2] * v109 + (v111[2] * v108 + v110[2] * v107)
    local v115 = v112[3] * v109 + (v111[3] * v108 + v110[3] * v107)
    local torque_acceleration = p29.torque_acceleration

    p29.torque_acceleration = Vector3.new(v113 + torque_acceleration.x, v114 + torque_acceleration.y, v115 + torque_acceleration.z)
    p29.cool_down = 0
end

function t1.apply_ground_body_torque_reference(p30) -- line: 267
    -- upvalues: Vector3 (copy), t1 (copy)
    local v116 = Vector3.new(0, t1.ground_torque_scalar(), 0)
    local v117 = t1.multiply(p30.basis, v116)
    local v118 = t1.multiply(p30.world_inverse_inertia, v117)

    p30.torque_acceleration = Vector3.new(v118.x + p30.torque_acceleration.x, v118.y + p30.torque_acceleration.y, v118.z + p30.torque_acceleration.z)
    p30.cool_down = 0
end

function t1.ground_torque_scalar() -- line: 279
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v119 = rt.map({ 1069066766, 3208158802, 1056249389, 3199324676, 1048030653, 3188511995, 1028997574, 3155725067 }, rt.from_bits)
    local v120 = 0.015625 * v119[4] + (0.0625 * v119[3] + (0.25 * v119[2] + v119[1]))
    local v121 = -0.25 * (0.00390625 * (0.015625 * v119[8] + (0.0625 * v119[7] + (0.25 * v119[6] + v119[5]))) + v120) + -3
    local v122 = math.floor(v121)
    local v123 = v121 - v122
    local v124 = v123 * v123
    local v125 = v123 * v124
    local v126 = v124 * v124
    local v127 = rt.map({ 1065353216, 3207688728, 1047920109, 3177404362, 1008569428, 3131971668, 958048215, 3073786465 }, rt.from_bits)
    local v128 = v125 * v127[4] + (v124 * v127[3] + (v123 * v127[2] + v127[1]))
    local v129 = v126 * (v125 * v127[8] + (v124 * v127[7] + (v123 * v127[6] + v127[5]))) + v128

    buffer.writeu32(v1, 0, (bit32.lshift(rt.to_u32(127 + rt.f_to_i32(v122)), 23)))

    return buffer.readf32(v1, 0) * t1.reciprocal_refined(v129) * -6.050000190734863
end

return t1
