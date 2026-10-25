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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v8 = import("skate_core/physics/drive_frames")
local retail_quaternion_from_basis = v8.retail_quaternion_from_basis
local normalize_drive_frames = import("skate_core/physics/drive_preparation").normalize_drive_frames
local v9 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v9.IDENTITY, v9.compose_affine
local t1 = {}
local to_bits, from_bits = rt.to_bits, rt.from_bits
local retail_quaternion_from_basis_scalar = v8.retail_quaternion_from_basis_scalar

local function relative_frame(p4, p5, p6, p7) -- line: 59
    -- upvalues: retail_quaternion_from_basis_scalar (copy)
    local v10 = p4[1]
    local v11 = p4[2]
    local v12 = p4[3]
    local v13 = p4[4]
    local v14 = v10[1]
    local v15 = v10[2]
    local v16 = v10[3]
    local v17 = v11[1]
    local v18 = v11[2]
    local v19 = v11[3]
    local v20 = v12[1]
    local v21 = v12[2]
    local v22 = v12[3]
    local v23, v24, v25, v26 = retail_quaternion_from_basis_scalar(0 * v20 + (0 * v17 + 1 * v14), 0 * v20 + (1 * v17 + 0 * v14), 1 * v20 + (0 * v17 + 0 * v14), 0 * v21 + (0 * v18 + 1 * v15), 0 * v21 + (1 * v18 + 0 * v15), 1 * v21 + (0 * v18 + 0 * v15), 0 * v22 + (0 * v19 + 1 * v16), 0 * v22 + (1 * v19 + 0 * v16), 1 * v22 + (0 * v19 + 0 * v16))

    return {
        orientation = {
            x = v23,
            y = v24,
            z = v25,
            w = v26
        },
        translation = {
            x = v20 * p7 + (v17 * p6 + (v14 * p5 + v13[1])),
            y = v21 * p7 + (v18 * p6 + (v15 * p5 + v13[2])),
            z = v22 * p7 + (v19 * p6 + (v16 * p5 + v13[3]))
        }
    }
end

function t1.bone_drive_frames(p8, p9, p10) -- line: 88
    -- upvalues: relative_frame (copy)
    local v27 = p8[4]
    local v28 = v27[1]
    local v29 = v27[2]
    local v30 = v27[3]

    return {
        body_a = relative_frame(p9, v28, v29, v30),
        body_b = relative_frame(p10, v28, v29, v30)
    }
end

local function relative_frame_into(p11, p12, p13, p14, p15) -- line: 104
    -- upvalues: retail_quaternion_from_basis_scalar (copy)
    local v31 = p12[1]
    local v32 = p12[2]
    local v33 = p12[3]
    local v34 = p12[4]
    local v35 = v31[1]
    local v36 = v31[2]
    local v37 = v31[3]
    local v38 = v32[1]
    local v39 = v32[2]
    local v40 = v32[3]
    local v41 = v33[1]
    local v42 = v33[2]
    local v43 = v33[3]
    local v44, v45, v46, v47 = retail_quaternion_from_basis_scalar(0 * v41 + (0 * v38 + 1 * v35), 0 * v41 + (1 * v38 + 0 * v35), 1 * v41 + (0 * v38 + 0 * v35), 0 * v42 + (0 * v39 + 1 * v36), 0 * v42 + (1 * v39 + 0 * v36), 1 * v42 + (0 * v39 + 0 * v36), 0 * v43 + (0 * v40 + 1 * v37), 0 * v43 + (1 * v40 + 0 * v37), 1 * v43 + (0 * v40 + 0 * v37))
    local v48 = v41 * p15 + (v38 * p14 + (v35 * p13 + v34[1]))
    local v49 = v42 * p15 + (v39 * p14 + (v36 * p13 + v34[2]))
    local v50 = v43 * p15 + (v40 * p14 + (v37 * p13 + v34[3]))
    local orientation = p11.orientation

    orientation.x = v44
    orientation.y = v45
    orientation.z = v46
    orientation.w = v47

    local translation = p11.translation

    translation.x = v48
    translation.y = v49
    translation.z = v50
end

function t1.bone_drive_frames_into(p16, p17, p18, p19) -- line: 136
    -- upvalues: t1 (copy), relative_frame_into (copy)
    local body_a, body_b = p16.body_a, p16.body_b

    if body_a ~= body_b and body_a.orientation ~= body_b.orientation and body_a.translation ~= body_b.translation and body_a.orientation ~= body_a.translation and body_b.orientation ~= body_b.translation and body_a.orientation ~= body_b.translation and body_a.translation ~= body_b.orientation then
        local v51 = p17[4]
        local v52 = v51[1]
        local v53 = v51[2]
        local v54 = v51[3]

        relative_frame_into(body_a, p18, v52, v53, v54)
        relative_frame_into(body_b, p19, v52, v53, v54)

        return p16
    end

    local v55 = t1.bone_drive_frames(p17, p18, p19)

    p16.body_a = v55.body_a
    p16.body_b = v55.body_b

    return p16
end

function t1.bone_drive_frames_reference(p20, p21, p22) -- line: 160
    -- upvalues: rt (copy), IDENTITY (copy), compose_affine (copy), t1 (copy)
    local v56 = rt.copy(IDENTITY)

    v56[4] = rt.copy(p20[4])

    local v57 = compose_affine(p21, v56)
    local v58 = compose_affine(p22, v56)

    return {
        body_a = t1.pack(v57),
        body_b = t1.pack(v58)
    }
end

local v59 = buffer.create(4)

local function f32r(p23) -- line: 186
    -- upvalues: to_bits (copy), from_bits (copy), v59 (copy)
    if p23 ~= 0 and p23 > -1.1754943508222875E-38 and p23 < 1.1754943508222875E-38 then
        return from_bits(to_bits(p23))
    end

    buffer.writef32(v59, 0, p23)

    return (buffer.readf32(v59, 0))
end

local function prepared_frame(p24) -- line: 194
    -- upvalues: to_bits (copy), from_bits (copy), v59 (copy)
    local orientation, translation = p24.orientation, p24.translation
    local x = orientation.x
    local v60

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        v60 = from_bits(to_bits(x))
    else
        buffer.writef32(v59, 0, x)
        v60 = buffer.readf32(v59, 0)
    end

    local y = orientation.y
    local v61

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        v61 = from_bits(to_bits(y))
    else
        buffer.writef32(v59, 0, y)
        v61 = buffer.readf32(v59, 0)
    end

    local z = orientation.z
    local v62

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        v62 = from_bits(to_bits(z))
    else
        buffer.writef32(v59, 0, z)
        v62 = buffer.readf32(v59, 0)
    end

    local w = orientation.w
    local v63

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        v63 = from_bits(to_bits(w))
    else
        buffer.writef32(v59, 0, w)
        v63 = buffer.readf32(v59, 0)
    end

    local v64 = v60 * v60 + v61 * v61 + v62 * v62 + v63 * v63
    local v65 = 1 / math.sqrt(v64)
    local v66 = v65 * v65
    local v67 = v65 * 0.5 * (-v64 * v66 + 1) + v65
    local v68 = v67 * v67
    local v69 = v67 * 0.5 * (-v64 * v68 + 1) + v67
    local t3 = {}
    local v70 = v60 * v69

    if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
        t3.x = from_bits(to_bits(v70))
    else
        buffer.writef32(v59, 0, v70)
        t3.x = buffer.readf32(v59, 0)
    end

    local v71 = v61 * v69

    if v71 ~= 0 and v71 > -1.1754943508222875E-38 and v71 < 1.1754943508222875E-38 then
        t3.y = from_bits(to_bits(v71))
    else
        buffer.writef32(v59, 0, v71)
        t3.y = buffer.readf32(v59, 0)
    end

    local v72 = v62 * v69

    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
        t3.z = from_bits(to_bits(v72))
    else
        buffer.writef32(v59, 0, v72)
        t3.z = buffer.readf32(v59, 0)
    end

    local v73 = v63 * v69

    if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
        t3.w = from_bits(to_bits(v73))
    else
        buffer.writef32(v59, 0, v73)
        t3.w = buffer.readf32(v59, 0)
    end

    local t2 = {}

    t2.orientation = t3

    local t4 = {}
    local x2 = translation.x

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        t4.x = from_bits(to_bits(x2))
    else
        buffer.writef32(v59, 0, x2)
        t4.x = buffer.readf32(v59, 0)
    end

    local y2 = translation.y

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        t4.y = from_bits(to_bits(y2))
    else
        buffer.writef32(v59, 0, y2)
        t4.y = buffer.readf32(v59, 0)
    end

    local z2 = translation.z

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        t4.z = from_bits(to_bits(z2))
    else
        buffer.writef32(v59, 0, z2)
        t4.z = buffer.readf32(v59, 0)
    end

    t2.translation = t4

    return t2
end

function t1.prepare_bone_drive_frames(p25) -- line: 228
    -- upvalues: prepared_frame (copy)
    return {
        body_a = prepared_frame(p25.body_a),
        body_b = prepared_frame(p25.body_b)
    }
end

local function prepare_frame_in_place(p26) -- line: 238
    -- upvalues: to_bits (copy), from_bits (copy), v59 (copy)
    local orientation, translation = p26.orientation, p26.translation
    local x = orientation.x
    local v74

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        v74 = from_bits(to_bits(x))
    else
        buffer.writef32(v59, 0, x)
        v74 = buffer.readf32(v59, 0)
    end

    local y = orientation.y
    local v75

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        v75 = from_bits(to_bits(y))
    else
        buffer.writef32(v59, 0, y)
        v75 = buffer.readf32(v59, 0)
    end

    local z = orientation.z
    local v76

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        v76 = from_bits(to_bits(z))
    else
        buffer.writef32(v59, 0, z)
        v76 = buffer.readf32(v59, 0)
    end

    local w = orientation.w
    local v77

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        v77 = from_bits(to_bits(w))
    else
        buffer.writef32(v59, 0, w)
        v77 = buffer.readf32(v59, 0)
    end

    local v78 = v74 * v74 + v75 * v75 + v76 * v76 + v77 * v77
    local v79 = 1 / math.sqrt(v78)
    local v80 = v79 * v79
    local v81 = v79 * 0.5 * (-v78 * v80 + 1) + v79
    local v82 = v81 * v81
    local v83 = v81 * 0.5 * (-v78 * v82 + 1) + v81
    local x2 = translation.x
    local v84

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        v84 = from_bits(to_bits(x2))
    else
        buffer.writef32(v59, 0, x2)
        v84 = buffer.readf32(v59, 0)
    end

    local y2 = translation.y
    local v85

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        v85 = from_bits(to_bits(y2))
    else
        buffer.writef32(v59, 0, y2)
        v85 = buffer.readf32(v59, 0)
    end

    local z2 = translation.z
    local v86

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        v86 = from_bits(to_bits(z2))
    else
        buffer.writef32(v59, 0, z2)
        v86 = buffer.readf32(v59, 0)
    end

    local v87 = v74 * v83
    local v88

    if v87 ~= 0 and v87 > -1.1754943508222875E-38 and v87 < 1.1754943508222875E-38 then
        v88 = from_bits(to_bits(v87))
    else
        buffer.writef32(v59, 0, v87)
        v88 = buffer.readf32(v59, 0)
    end

    local v89 = v75 * v83
    local v90

    if v89 ~= 0 and v89 > -1.1754943508222875E-38 and v89 < 1.1754943508222875E-38 then
        v90 = from_bits(to_bits(v89))
    else
        buffer.writef32(v59, 0, v89)
        v90 = buffer.readf32(v59, 0)
    end

    local v91 = v76 * v83
    local v92

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        v92 = from_bits(to_bits(v91))
    else
        buffer.writef32(v59, 0, v91)
        v92 = buffer.readf32(v59, 0)
    end

    local v93 = v77 * v83
    local v94

    if v93 ~= 0 and v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
        v94 = from_bits(to_bits(v93))
    else
        buffer.writef32(v59, 0, v93)
        v94 = buffer.readf32(v59, 0)
    end

    orientation.x = v88
    orientation.y = v90
    orientation.z = v92
    orientation.w = v94
    translation.x = v84
    translation.y = v85
    translation.z = v86
end

function t1.prepare_bone_drive_frames_in_place(p27) -- line: 269
    -- upvalues: t1 (copy), prepare_frame_in_place (copy)
    local body_a, body_b = p27.body_a, p27.body_b

    if body_a ~= body_b and body_a.orientation ~= body_b.orientation and body_a.translation ~= body_b.translation and body_a.orientation ~= body_a.translation and body_b.orientation ~= body_b.translation and body_a.orientation ~= body_b.translation and body_a.translation ~= body_b.orientation then
        prepare_frame_in_place(body_a)
        prepare_frame_in_place(body_b)

        return p27
    end

    local v95 = t1.prepare_bone_drive_frames(p27)

    p27.body_a = v95.body_a
    p27.body_b = v95.body_b

    return p27
end

function t1.prepare_bone_drive_frames_reference(p28) -- line: 291
    -- upvalues: v1 (copy), Vector3 (copy), normalize_drive_frames (copy)
    local v96 = table.create(16, 0)
    local t5 = {
        p28.body_a,
        p28.body_b
    }

    for i = 0, 1 do
        local v97 = t5[i + 1]
        local orientation, translation = v97.orientation, v97.translation
        local v98 = i * 8 + 1
        local x = orientation.x
        local v99

        if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            local v100 = math.abs(x) * 7.1362384635298E+44
            local v101 = math.floor(v100)
            local v102 = v100 - v101
            local v103 = if v102 > 0.5 or v102 == 0.5 and v101 % 2 == 1 then v101 + 1 else v101

            v99 = if x < 0 then v103 + 2147483648 else v103
        else
            buffer.writef32(v1, 0, x)
            v99 = buffer.readu32(v1, 0)
        end

        v96[v98] = v99

        local v104 = i * 8 + 2
        local y = orientation.y
        local v105

        if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
            local v106 = math.abs(y) * 7.1362384635298E+44
            local v107 = math.floor(v106)
            local v108 = v106 - v107
            local v109 = if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107

            v105 = if y < 0 then v109 + 2147483648 else v109
        else
            buffer.writef32(v1, 0, y)
            v105 = buffer.readu32(v1, 0)
        end

        v96[v104] = v105

        local v110 = i * 8 + 3
        local z = orientation.z
        local v111

        if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
            local v112 = math.abs(z) * 7.1362384635298E+44
            local v113 = math.floor(v112)
            local v114 = v112 - v113
            local v115 = if v114 > 0.5 or v114 == 0.5 and v113 % 2 == 1 then v113 + 1 else v113

            v111 = if z < 0 then v115 + 2147483648 else v115
        else
            buffer.writef32(v1, 0, z)
            v111 = buffer.readu32(v1, 0)
        end

        v96[v110] = v111

        local v116 = i * 8 + 4
        local w = orientation.w
        local v117

        if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
            local v118 = math.abs(w) * 7.1362384635298E+44
            local v119 = math.floor(v118)
            local v120 = v118 - v119
            local v121 = if v120 > 0.5 or v120 == 0.5 and v119 % 2 == 1 then v119 + 1 else v119

            v117 = if w < 0 then v121 + 2147483648 else v121
        else
            buffer.writef32(v1, 0, w)
            v117 = buffer.readu32(v1, 0)
        end

        v96[v116] = v117

        local v122 = i * 8 + 5
        local x2 = translation.x
        local v123

        if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
            local v124 = math.abs(x2) * 7.1362384635298E+44
            local v125 = math.floor(v124)
            local v126 = v124 - v125
            local v127 = if v126 > 0.5 or v126 == 0.5 and v125 % 2 == 1 then v125 + 1 else v125

            v123 = if x2 < 0 then v127 + 2147483648 else v127
        else
            buffer.writef32(v1, 0, x2)
            v123 = buffer.readu32(v1, 0)
        end

        v96[v122] = v123

        local v128 = i * 8 + 6
        local y2 = translation.y
        local v129

        if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
            local v130 = math.abs(y2) * 7.1362384635298E+44
            local v131 = math.floor(v130)
            local v132 = v130 - v131
            local v133 = if v132 > 0.5 or v132 == 0.5 and v131 % 2 == 1 then v131 + 1 else v131

            v129 = if y2 < 0 then v133 + 2147483648 else v133
        else
            buffer.writef32(v1, 0, y2)
            v129 = buffer.readu32(v1, 0)
        end

        v96[v128] = v129

        local v134 = i * 8 + 7
        local z2 = translation.z
        local v135

        if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
            local v136 = math.abs(z2) * 7.1362384635298E+44
            local v137 = math.floor(v136)
            local v138 = v136 - v137
            local v139 = if v138 > 0.5 or v138 == 0.5 and v137 % 2 == 1 then v137 + 1 else v137

            v135 = if z2 < 0 then v139 + 2147483648 else v139
        else
            buffer.writef32(v1, 0, z2)
            v135 = buffer.readu32(v1, 0)
        end

        v96[v134] = v135

        local v140 = i * 8 + 8

        buffer.writef32(v1, 0, 0)
        v96[v140] = buffer.readu32(v1, 0)
    end

    normalize_drive_frames(v96)

    local function frame(p29) -- line: 308
        -- upvalues: v96 (copy), v1 (copy), Vector3 (copy)
        local function f(p30) -- line: 309
            -- upvalues: p29 (copy), v96 (copy), v1 (copy)
            buffer.writeu32(v1, 0, v96[p29 + p30 + 1])

            return (buffer.readf32(v1, 0))
        end

        local t6 = {}
        local t7 = {}

        buffer.writeu32(v1, 0, v96[p29 + 0 + 1])
        t7.x = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v96[p29 + 1 + 1])
        t7.y = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v96[p29 + 2 + 1])
        t7.z = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v96[p29 + 3 + 1])
        t7.w = buffer.readf32(v1, 0)
        t6.orientation = t7

        local new = Vector3.new

        buffer.writeu32(v1, 0, v96[p29 + 4 + 1])

        local v147 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v96[p29 + 5 + 1])

        local v149 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v96[p29 + 6 + 1])
        t6.translation = new(v147, v149, (buffer.readf32(v1, 0)))

        return t6
    end

    return {
        body_a = frame(0),
        body_b = frame(8)
    }
end

function t1.pack(p31) -- line: 321
    -- upvalues: Vector3 (copy), retail_quaternion_from_basis (copy)
    return {
        orientation = retail_quaternion_from_basis({
            columns = {
                {
                    p31[1][1],
                    p31[1][2],
                    p31[1][3]
                },
                {
                    p31[2][1],
                    p31[2][2],
                    p31[2][3]
                },
                {
                    p31[3][1],
                    p31[3][2],
                    p31[3][3]
                }
            }
        }),
        translation = Vector3.new(p31[4][1], p31[4][2], p31[4][3])
    }
end

return t1
