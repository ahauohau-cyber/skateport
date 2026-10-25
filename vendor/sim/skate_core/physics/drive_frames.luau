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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/physics/board")
local v9 = import("skate_core/physics/drive_parameters")
local v10 = import("skate_core/physics/mass")
local v11 = import("skate_core/physics/native_arithmetic")
local v12 = import("skate_core/physics/rigid_body")
local v13 = import("skate_core/math")
local v14 = import("skate_core/trigonometry")
local v15 = import("skate_core/physics/construction/authored_transforms")
local BodyId = v8.BodyId
local RetailQuaternion = v12.RetailQuaternion
local Vector3 = v13.Vector3
local t1 = {}

local function struct_eq(p3, p4) -- line: 51
    -- upvalues: struct_eq (copy)
    if type(p3) ~= "table" or type(p4) ~= "table" then
        return p3 == p4
    end

    for v16, v17 in p3 do
        if not struct_eq(v17, p4[v16]) then
            return false
        end
    end

    for v18 in p4 do
        if p3[v18] == nil then
            return false
        end
    end

    return true
end

t1.AuthoredTransformInputs = v15.AuthoredTransformInputs
t1.authored_body_pose_records = v15.authored_body_pose_records
t1.authored_body_transforms = v15.authored_body_transforms
t1.tu3 = {
    CALCULATE_TRUCK_TRANSFORMS = 2193669264,
    SET_DRIVE_FRAMES_2 = 2193670280,
    MATRIX_TO_FRAME_A = 2193439248,
    MATRIX_TO_FRAME_B = 2193439696,
    PART_SET_TRANSFORM = 2193441560
}
t1.RetailAffineTransform = {}
t1.RetailAffineTransform.eq = struct_eq
t1.RetailAffineTransform.IDENTITY = {
    basis = {
        columns = {
            { 1, 0, 0 },
            { 0, 1, 0 },
            { 0, 0, 1 }
        }
    },
    translation = rt.copy(Vector3.ZERO)
}
t1.RetailDriveFrame = {}
t1.RetailDriveFrame.eq = struct_eq
t1.RetailDriveFrames = {}
t1.RetailDriveFrames.eq = struct_eq
t1.RetailTruckTransformInputs = {}
t1.RetailTruckTransformInputs.eq = struct_eq
t1.RETAIL_DEFAULT_TRUCK_TRANSFORM_INPUTS = {
    deck_mid_length = v8.RETAIL_DECK_MID_LENGTH,
    truck_z_position_front = v8.RETAIL_TRUCK_Z_POSITION_FRONT,
    truck_z_position_back = v8.RETAIL_TRUCK_Z_POSITION_BACK,
    truck_y_position = v8.RETAIL_TRUCK_Y_POSITION,
    truck_rotation_axis_angle_degrees = v8.RETAIL_TRUCK_ROTATION_AXIS_ANGLE_DEGREES
}

function t1.default_truck_transforms() -- line: 119
    -- upvalues: rt (copy), t1 (copy)
    return t1.calculate_truck_transforms(rt.copy(t1.RETAIL_DEFAULT_TRUCK_TRANSFORM_INPUTS))
end

function t1.default_body_transforms() -- line: 125
    -- upvalues: rt (copy), t1 (copy)
    return t1.authored_body_transforms(rt.copy(t1.AuthoredTransformInputs.STOCK))
end

function t1.default_live_body_transforms() -- line: 131
    -- upvalues: rt (copy), v10 (copy), BodyId (copy), t1 (copy)
    local v19 = t1.default_body_transforms()
    local local_mass_frame = v10.retail_deck_mass_properties().local_mass_frame

    v19[BodyId.index(BodyId.Deck) + 1] = t1.compose_affine(rt.copy(v19[BodyId.index(BodyId.Deck) + 1]), t1.inverse_affine({
        basis = rt.copy(local_mass_frame.basis),
        translation = rt.copy(local_mass_frame.translation)
    }))

    return v19
end

function t1.default_live_body_orientations() -- line: 145
    -- upvalues: t1 (copy)
    local v20 = t1.default_live_body_transforms()
    local v21 = table.create(#v20)

    for i = 1, #v20 do
        v21[i] = t1.retail_quaternion_from_basis(v20[i].basis)
    end

    return v21
end

t1.RETAIL_LEVEL_GROUND_DECK_CENTER_HEIGHT = v8.RETAIL_WHEEL_RADIUS - v8.RETAIL_TRUCK_Y_POSITION

function t1.default_truck_drive_frames() -- line: 160
    -- upvalues: rt (copy), t1 (copy)
    local v22 = t1.default_truck_transforms()

    return {
        t1.set_drive_frames_2(rt.copy(t1.RetailAffineTransform.IDENTITY), rt.copy(v22[2])),
        t1.set_drive_frames_2(rt.copy(t1.RetailAffineTransform.IDENTITY), rt.copy(v22[1]))
    }
end

function t1.default_wheel_drive_frames() -- line: 169
    -- upvalues: rt (copy), t1 (copy)
    local v23 = t1.wheel_drive_frame(t1.AuthoredTransformInputs.STOCK.wheel_x_distance)
    local v24 = t1.wheel_drive_frame(-t1.AuthoredTransformInputs.STOCK.wheel_x_distance)

    return {
        rt.copy(v23),
        rt.copy(v24),
        rt.copy(v23),
        rt.copy(v24)
    }
end

function t1.set_drive_frames_2(p5, p6) -- line: 189
    -- upvalues: rt (copy), RetailQuaternion (copy), Vector3 (copy), t1 (copy)
    local columns = p5.basis.columns
    local v25 = columns[1]
    local v26 = columns[2]
    local v27 = columns[3]
    local v28 = v25[1]
    local v29 = v25[2]
    local v30 = v25[3]
    local v31 = v26[1]
    local v32 = v26[2]
    local v33 = v26[3]
    local v34 = v27[1]
    local v35 = v27[2]
    local v36 = v27[3]
    local columns2 = p6.basis.columns
    local v37 = columns2[1]
    local v38 = columns2[2]
    local v39 = columns2[3]
    local v40 = v37[1]
    local v41 = v37[2]
    local v42 = v37[3]
    local v43 = v42 * v30 + (v41 * v29 + v40 * v28)
    local v44 = v42 * v33 + (v41 * v32 + v40 * v31)
    local v45 = v42 * v36 + (v41 * v35 + v40 * v34)
    local v46 = v38[1]
    local v47 = v38[2]
    local v48 = v38[3]
    local v49 = v48 * v30 + (v47 * v29 + v46 * v28)
    local v50 = v48 * v33 + (v47 * v32 + v46 * v31)
    local v51 = v48 * v36 + (v47 * v35 + v46 * v34)
    local v52 = v39[1]
    local v53 = v39[2]
    local v54 = v39[3]
    local v55 = v54 * v30 + (v53 * v29 + v52 * v28)
    local v56 = v54 * v33 + (v53 * v32 + v52 * v31)
    local v57 = v54 * v36 + (v53 * v35 + v52 * v34)
    local translation = p5.translation
    local translation2 = p6.translation
    local v58 = 0 - translation.x
    local v59 = 0 - translation.y
    local v60 = 0 - translation.z
    local x, y, z = translation2.x, translation2.y, translation2.z
    local v61, v62, v63, v64 = t1.retail_quaternion_from_basis_scalar(v43, v49, v55, v44, v50, v56, v45, v51, v57)

    return {
        body_a = {
            orientation = rt.copy(RetailQuaternion.IDENTITY),
            translation = rt.copy(Vector3.ZERO)
        },
        body_b = {
            orientation = {
                x = v61,
                y = v62,
                z = v63,
                w = v64
            },
            translation = Vector3.new(z * v30 + (y * v29 + (x * v28 + (v58 * v28 + (v59 * v29 + v60 * v30)))), z * v33 + (y * v32 + (x * v31 + (v58 * v31 + (v59 * v32 + v60 * v33)))), z * v36 + (y * v35 + (x * v34 + (v58 * v34 + (v59 * v35 + v60 * v36)))))
        }
    }
end

function t1.set_drive_frames_2_reference(p7, p8) -- line: 233
    -- upvalues: rt (copy), RetailQuaternion (copy), Vector3 (copy), t1 (copy)
    local v65 = t1.relative_parent_transform(p7, p8)

    return {
        body_a = {
            orientation = rt.copy(RetailQuaternion.IDENTITY),
            translation = rt.copy(Vector3.ZERO)
        },
        body_b = {
            orientation = t1.retail_quaternion_from_basis(v65.basis),
            translation = rt.copy(v65.translation)
        }
    }
end

function t1.retail_quaternion_from_basis_reference(p9) -- line: 256
    -- upvalues: t1 (copy)
    local v66 = p9.columns[1][1]
    local v67 = p9.columns[2][1]
    local v68 = p9.columns[3][1]
    local v69 = p9.columns[1][2]
    local v70 = p9.columns[2][2]
    local v71 = p9.columns[3][2]
    local v72 = p9.columns[1][3]
    local v73 = p9.columns[2][3]
    local v74 = p9.columns[3][3]

    if v66 + v70 + v74 > 0 then
        return t1.quaternion_candidate(v66 + v70 + (v74 + 1), {
            v73 - v71,
            v68 - v72,
            v69 - v67,
            0
        }, 3)
    end

    if v70 < v66 and v74 < v66 then
        return t1.quaternion_candidate(v66 - v70 + (0 - v74 + 1), {
            0,
            v67 + v69,
            v68 + v72,
            v73 - v71
        }, 0)
    end

    if v74 < v70 then
        return t1.quaternion_candidate(0 - v66 + v70 + (0 - v74 + 1), {
            v67 + v69,
            0,
            v71 + v73,
            v68 - v72
        }, 1)
    end

    return t1.quaternion_candidate(0 - v66 - v70 + (v74 + 1), {
        v68 + v72,
        v71 + v73,
        0,
        v69 - v67
    }, 2)
end

local function refined_rsqrt(p10) -- line: 295
    local v75 = 1 / math.sqrt(p10)
    local v76 = v75 * v75
    local v77 = v75 * 0.5 * (-p10 * v76 + 1) + v75
    local v78 = v77 * v77

    return v77 * 0.5 * (-p10 * v78 + 1) + v77
end

function t1.refined_reciprocal_square_root(p11) -- line: 308
    local v79 = 1 / math.sqrt(p11)
    local v80 = v79 * v79
    local v81 = v79 * 0.5 * (-p11 * v80 + 1) + v79
    local v82 = v81 * v81

    return v81 * 0.5 * (-p11 * v82 + 1) + v81
end

function t1.refined_reciprocal_square_root_reference(p12) -- line: 316
    -- upvalues: v11 (copy)
    local v83 = v11.reciprocal_square_root_estimate(p12)
    local v84 = v83 * v83
    local v85 = v83 * 0.5 * (-p12 * v84 + 1) + v83
    local v86 = v85 * v85

    return v85 * 0.5 * (-p12 * v86 + 1) + v85
end

function t1.retail_quaternion_from_basis_scalar(p13, p14, p15, p16, p17, p18, p19, p20, p21) -- line: 335
    if p13 + p17 + p21 > 0 then
        local v87 = p13 + p17 + (p21 + 1)
        local v88 = 1 / math.sqrt(v87)
        local v89 = v88 * v88
        local v90 = v88 * 0.5 * (-v87 * v89 + 1) + v88
        local v91 = v90 * v90
        local v92 = v90 * 0.5 * (-v87 * v91 + 1) + v90
        local v93 = v92 * 0.5
        local v94 = v87 * v92 * 0.5

        return (p20 - p18) * v93, (p15 - p19) * v93, (p16 - p14) * v93, v94
    end

    if not (p17 < p13 and p21 < p13) then
        if p21 < p17 then
            local v95 = 0 - p13 + p17 + (0 - p21 + 1)
            local v96 = 1 / math.sqrt(v95)
            local v97 = v96 * v96
            local v98 = v96 * 0.5 * (-v95 * v97 + 1) + v96
            local v99 = v98 * v98
            local v100 = v98 * 0.5 * (-v95 * v99 + 1) + v98
            local v101 = v100 * 0.5
            local v102 = v95 * v100 * 0.5

            return (p14 + p16) * v101, v102, (p18 + p20) * v101, (p15 - p19) * v101
        end

        local v103 = 0 - p13 - p17 + (p21 + 1)
        local v104 = 1 / math.sqrt(v103)
        local v105 = v104 * v104
        local v106 = v104 * 0.5 * (-v103 * v105 + 1) + v104
        local v107 = v106 * v106
        local v108 = v106 * 0.5 * (-v103 * v107 + 1) + v106
        local v109 = v108 * 0.5
        local v110 = v103 * v108 * 0.5

        return (p15 + p19) * v109, (p18 + p20) * v109, v110, (p16 - p14) * v109
    end

    local v111 = p13 - p17 + (0 - p21 + 1)
    local v112 = 1 / math.sqrt(v111)
    local v113 = v112 * v112
    local v114 = v112 * 0.5 * (-v111 * v113 + 1) + v112
    local v115 = v114 * v114
    local v116 = v114 * 0.5 * (-v111 * v115 + 1) + v114
    local v117 = v116 * 0.5

    return v111 * v116 * 0.5, (p14 + p16) * v117, (p15 + p19) * v117, (p20 - p18) * v117
end

function t1.retail_quaternion_from_basis_scalar_r3(p22, p23, p24, p25, p26, p27, p28, p29, p30) -- line: 379
    -- upvalues: t1 (copy)
    if p22 + p26 + p30 > 0 then
        local v118 = p22 + p26 + (p30 + 1)
        local v119 = t1.refined_reciprocal_square_root_reference(v118)
        local v120 = v119 * 0.5
        local v121 = v118 * v119 * 0.5

        return (p29 - p27) * v120, (p24 - p28) * v120, (p25 - p23) * v120, v121
    end

    if not (p26 < p22 and p30 < p22) then
        if p30 < p26 then
            local v122 = 0 - p22 + p26 + (0 - p30 + 1)
            local v123 = t1.refined_reciprocal_square_root_reference(v122)
            local v124 = v123 * 0.5
            local v125 = v122 * v123 * 0.5

            return (p23 + p25) * v124, v125, (p27 + p29) * v124, (p24 - p28) * v124
        end

        local v126 = 0 - p22 - p26 + (p30 + 1)
        local v127 = t1.refined_reciprocal_square_root_reference(v126)
        local v128 = v127 * 0.5
        local v129 = v126 * v127 * 0.5

        return (p24 + p28) * v128, (p27 + p29) * v128, v129, (p25 - p23) * v128
    end

    local v130 = p22 - p26 + (0 - p30 + 1)
    local v131 = t1.refined_reciprocal_square_root_reference(v130)
    local v132 = v131 * 0.5

    return v130 * v131 * 0.5, (p23 + p25) * v132, (p24 + p28) * v132, (p29 - p27) * v132
end

function t1.retail_quaternion_from_basis(p31) -- line: 422
    -- upvalues: t1 (copy)
    local columns = p31.columns
    local v133 = columns[1]
    local v134 = columns[2]
    local v135 = columns[3]
    local v136, v137, v138, v139 = t1.retail_quaternion_from_basis_scalar(v133[1], v134[1], v135[1], v133[2], v134[2], v135[2], v133[3], v134[3], v135[3])

    return {
        x = v136,
        y = v137,
        z = v138,
        w = v139
    }
end

function t1.wheel_drive_frame(p32) -- line: 433
    -- upvalues: rt (copy), RetailQuaternion (copy), Vector3 (copy)
    return {
        body_a = {
            orientation = rt.copy(RetailQuaternion.IDENTITY),
            translation = rt.copy(Vector3.ZERO)
        },
        body_b = {
            orientation = rt.copy(RetailQuaternion.IDENTITY),
            translation = Vector3.new(0, 0, p32)
        }
    }
end

function t1.inverse_affine(p33) -- line: 446
    -- upvalues: Vector3 (copy), t1 (copy)
    local columns = p33.basis.columns
    local t2 = {
        columns = {
            {
                columns[1][1],
                columns[2][1],
                columns[3][1]
            },
            {
                columns[1][2],
                columns[2][2],
                columns[3][2]
            },
            {
                columns[1][3],
                columns[2][3],
                columns[3][3]
            }
        }
    }
    local v140 = t1.multiply_basis_vector(t2, p33.translation)

    return {
        basis = t2,
        translation = Vector3.new(0 - v140.x, 0 - v140.y, 0 - v140.z)
    }
end

function t1.compose_affine(p34, p35) -- line: 462
    -- upvalues: Vector3 (copy), t1 (copy)
    local v141 = t1.multiply_basis_vector(p34.basis, p35.translation)

    return {
        basis = t1.multiply_basis(p34.basis, p35.basis),
        translation = Vector3.new(v141.x + p34.translation.x, v141.y + p34.translation.y, v141.z + p34.translation.z)
    }
end

function t1.multiply_basis_vector(p36, p37) -- line: 474
    -- upvalues: Vector3 (copy)
    local function component(p38) -- line: 475
        -- upvalues: p36 (copy), p37 (copy)
        local v142 = p37.x * p36.columns[1][p38 + 1]
        local v143 = p37.y * p36.columns[2][p38 + 1] + v142

        return p37.z * p36.columns[3][p38 + 1] + v143
    end

    local new = Vector3.new
    local v144 = p37.x * p36.columns[1][1]
    local v145 = p37.y * p36.columns[2][1] + v144
    local v146 = p37.z * p36.columns[3][1] + v145
    local v147 = p37.x * p36.columns[1][2]
    local v148 = p37.y * p36.columns[2][2] + v147
    local v149 = p37.z * p36.columns[3][2] + v148
    local v150 = p37.x * p36.columns[1][3]
    local v151 = p37.y * p36.columns[2][3] + v150

    return new(v146, v149, p37.z * p36.columns[3][3] + v151)
end

function t1.quaternion_candidate(p39, p40, p41) -- line: 483
    -- upvalues: t1 (copy)
    local v152 = t1.refined_reciprocal_square_root(p39)
    local v153 = v152 * 0.5
    local v154 = p39 * v152 * 0.5
    local v155 = table.create(4)

    v155[1] = p40[1] * v153
    v155[2] = p40[2] * v153
    v155[3] = p40[3] * v153
    v155[4] = p40[4] * v153
    v155[p41 + 1] = v154

    return {
        x = v155[1],
        y = v155[2],
        z = v155[3],
        w = v155[4]
    }
end

v9.RetailDriveFramesRaw.from = function(p42) -- line: 502
    -- upvalues: t1 (copy)
    return {
        body_a = t1.raw_frame(p42.body_a),
        body_b = t1.raw_frame(p42.body_b)
    }
end

function t1.raw_frame(p43) -- line: 509
    -- upvalues: v1 (copy)
    local x = p43.orientation.x
    local v156

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v157 = math.abs(x) * 7.1362384635298E+44
        local v158 = math.floor(v157)
        local v159 = v157 - v158

        v156 = if v159 > 0.5 or v159 == 0.5 and v158 % 2 == 1 then v158 + 1 else v158

        if x < 0 then
            v156 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v156 = buffer.readu32(v1, 0)
    end

    local y = p43.orientation.y
    local v160

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v161 = math.abs(y) * 7.1362384635298E+44
        local v162 = math.floor(v161)
        local v163 = v161 - v162

        v160 = if v163 > 0.5 or v163 == 0.5 and v162 % 2 == 1 then v162 + 1 else v162

        if y < 0 then
            v160 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v160 = buffer.readu32(v1, 0)
    end

    local z = p43.orientation.z
    local v164

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v165 = math.abs(z) * 7.1362384635298E+44
        local v166 = math.floor(v165)
        local v167 = v165 - v166

        v164 = if v167 > 0.5 or v167 == 0.5 and v166 % 2 == 1 then v166 + 1 else v166

        if z < 0 then
            v164 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v164 = buffer.readu32(v1, 0)
    end

    local w = p43.orientation.w
    local v168

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        local v169 = math.abs(w) * 7.1362384635298E+44
        local v170 = math.floor(v169)
        local v171 = v169 - v170

        v168 = if v171 > 0.5 or v171 == 0.5 and v170 % 2 == 1 then v170 + 1 else v170

        if w < 0 then
            v168 += 2147483648
        end
    else
        buffer.writef32(v1, 0, w)
        v168 = buffer.readu32(v1, 0)
    end

    local t3 = {}

    t3.quaternion_lanes = {
        v156,
        v160,
        v164,
        v168
    }

    local x2 = p43.translation.x
    local v172

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        local v173 = math.abs(x2) * 7.1362384635298E+44
        local v174 = math.floor(v173)
        local v175 = v173 - v174

        v172 = if v175 > 0.5 or v175 == 0.5 and v174 % 2 == 1 then v174 + 1 else v174

        if x2 < 0 then
            v172 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x2)
        v172 = buffer.readu32(v1, 0)
    end

    local y2 = p43.translation.y
    local v176

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        local v177 = math.abs(y2) * 7.1362384635298E+44
        local v178 = math.floor(v177)
        local v179 = v177 - v178

        v176 = if v179 > 0.5 or v179 == 0.5 and v178 % 2 == 1 then v178 + 1 else v178

        if y2 < 0 then
            v176 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y2)
        v176 = buffer.readu32(v1, 0)
    end

    local z2 = p43.translation.z
    local v180

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        local v181 = math.abs(z2) * 7.1362384635298E+44
        local v182 = math.floor(v181)
        local v183 = v181 - v182

        v180 = if v183 > 0.5 or v183 == 0.5 and v182 % 2 == 1 then v182 + 1 else v182

        if z2 < 0 then
            v180 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z2)
        v180 = buffer.readu32(v1, 0)
    end

    t3.translation_lanes = {
        v172,
        v176,
        v180,
        0
    }

    return t3
end

function t1.calculate_truck_transforms(p44) -- line: 526
    -- upvalues: Vector3 (copy), t1 (copy)
    local v184 = p44.truck_rotation_axis_angle_degrees * 0.01745329238474369
    local v185 = p44.deck_mid_length * 0.5 + p44.truck_z_position_front
    local v186 = -(p44.deck_mid_length * 0.5 + p44.truck_z_position_back)

    return {
        {
            basis = t1.multiply_basis(t1.rotation_x(v184), t1.rotation_y(1.5707963705062866)),
            translation = Vector3.new(0, p44.truck_y_position, v186)
        },
        {
            basis = t1.multiply_basis(t1.rotation_x(-v184), t1.rotation_y(-1.5707963705062866)),
            translation = Vector3.new(0, p44.truck_y_position, v185)
        }
    }
end

function t1.rotation_x(p45) -- line: 548
    -- upvalues: v14 (copy)
    local v187, v188 = v14.sin_cos(p45)

    return {
        columns = {
            { 1, 0, 0 },
            { 0, v188, v187 },
            { 0, -v187, v188 }
        }
    }
end

function t1.rotation_y(p46) -- line: 555
    -- upvalues: v14 (copy)
    local v189, v190 = v14.sin_cos(p46)

    return {
        columns = {
            { v190, 0, -v189 },
            { 0, 1, 0 },
            { v189, 0, v190 }
        }
    }
end

function t1.multiply_basis(p47, p48) -- line: 562
    -- upvalues: rt (copy)
    local v191 = table.create(3)

    for i = 1, 3 do
        local v192 = p48.columns[i]

        v191[i] = rt.from_fn(3, function(p49) -- line: 566
            -- upvalues: p47 (copy), v192 (copy)
            local v193 = v192[1] * p47.columns[1][p49 + 1]
            local v194 = v192[2] * p47.columns[2][p49 + 1] + v193

            return v192[3] * p47.columns[3][p49 + 1] + v194
        end)
    end

    return {
        columns = v191
    }
end

function t1.relative_parent_transform(p50, p51) -- line: 577
    -- upvalues: t1 (copy)
    return {
        basis = t1.transpose_multiply_basis(p50.basis, p51.basis),
        translation = t1.transpose_relative_translation(p50.basis, p50.translation, p51.translation)
    }
end

function t1.transpose_multiply_basis(p52, p53) -- line: 588
    -- upvalues: rt (copy)
    return {
        columns = rt.from_fn(3, function(p54) -- line: 590
            -- upvalues: p52 (copy), p53 (copy), rt (copy)
            local v195 = p53.columns[p54 + 1]

            return rt.from_fn(3, function(p55) -- line: 592
                -- upvalues: v195 (copy), p52 (copy)
                local v196 = p52.columns[p55 + 1]
                local v197 = v195[1] * v196[1]
                local v198 = v195[2] * v196[2] + v197

                return v195[3] * v196[3] + v198
            end)
        end)
    }
end

function t1.transpose_relative_translation(p56, p57, p58) -- line: 602
    -- upvalues: Vector3 (copy)
    local v199 = Vector3.new(0 - p57.x, 0 - p57.y, 0 - p57.z)

    local function component(p59) -- line: 608
        -- upvalues: p58 (copy), v199 (copy)
        local v200 = v199.z * p59[3]
        local v201 = v199.y * p59[2] + v200
        local v202 = v199.x * p59[1] + v201
        local v203 = p58.x * p59[1] + v202
        local v204 = p58.y * p59[2] + v203

        return p58.z * p59[3] + v204
    end

    local new = Vector3.new
    local v205 = p56.columns[1]
    local v206 = v199.z * v205[3]
    local v207 = v199.y * v205[2] + v206
    local v208 = v199.x * v205[1] + v207
    local v209 = p58.x * v205[1] + v208
    local v210 = p58.y * v205[2] + v209
    local v211 = p58.z * v205[3] + v210
    local v212 = p56.columns[2]
    local v213 = v199.z * v212[3]
    local v214 = v199.y * v212[2] + v213
    local v215 = v199.x * v212[1] + v214
    local v216 = p58.x * v212[1] + v215
    local v217 = p58.y * v212[2] + v216
    local v218 = p58.z * v212[3] + v217
    local v219 = p56.columns[3]
    local v220 = v199.z * v219[3]
    local v221 = v199.y * v219[2] + v220
    local v222 = v199.x * v219[1] + v221
    local v223 = p58.x * v219[1] + v222
    local v224 = p58.y * v219[2] + v223

    return new(v211, v218, p58.z * v219[3] + v224)
end

return t1
