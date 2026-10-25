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
local v8 = import("skate_core/physics/board_pose/arithmetic")
local matrix, words, add, sub = v8.matrix, v8.words, v8.add, v8.sub
local mul, madd, perm, rsqrt = v8.mul, v8.madd, v8.perm, v8.rsqrt
local normalize, compose, inverse_rigid = v8.normalize, v8.compose, v8.inverse_rigid

local function board_pose() -- line: 45
    -- upvalues: import (copy)
    return import("skate_core/physics/board_pose")
end

local to_bits, from_bits = rt.to_bits, rt.from_bits
local t1 = {}

t1.PartPose = {}

function t1.part_transform(p4) -- line: 67
    -- upvalues: rt (copy), matrix (copy), words (copy), compose (copy), t1 (copy)
    local body = p4.body

    if body == nil then
        return rt.copy(p4.transform)
    end

    local t2 = {
        t1.load(body, 16),
        t1.load(body, 20),
        t1.load(body, 24),
        t1.load(body, 4)
    }
    local local_mass_frame = p4.local_mass_frame

    if local_mass_frame == nil then
        return words(t2)
    end

    return words(compose(t2, matrix(local_mass_frame)))
end

function t1.set_part_transform_reference(p5, p6) -- line: 88
    -- upvalues: rt (copy), v1 (copy), import (copy), matrix (copy), words (copy), mul (copy), madd (copy), perm (copy), compose (copy), inverse_rigid (copy), t1 (copy)
    local body = p5.body

    if body ~= nil then
        local local_mass_frame = p5.local_mass_frame
        local v9 = if local_mass_frame == nil then rt.copy(p6) else words(compose(matrix(p6), inverse_rigid(matrix(local_mass_frame))))
        local v10 = matrix(import("skate_core/physics/board_pose").orthonormalize_part_basis(v9))

        for _, v11 in {
                {
                    16,
                    v10[1]
                },
                {
                    20,
                    v10[2]
                },
                {
                    24,
                    v10[3]
                },
                {
                    4,
                    v10[4]
                }
            } do
            t1.store_xyz(body, v11[1], v11[2])
        end

        local v12 = t1.quaternion(v10)
        local v13 = v12[1]
        local v14

        if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
            local v15 = math.abs(v13) * 7.1362384635298E+44
            local v16 = math.floor(v15)
            local v17 = v15 - v16

            v14 = if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

            if v13 < 0 then
                v14 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v13)
            v14 = buffer.readu32(v1, 0)
        end

        body[1] = v14

        local v18 = v12[2]
        local v19

        if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
            local v20 = math.abs(v18) * 7.1362384635298E+44
            local v21 = math.floor(v20)
            local v22 = v20 - v21

            v19 = if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21

            if v18 < 0 then
                v19 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v18)
            v19 = buffer.readu32(v1, 0)
        end

        body[2] = v19

        local v23 = v12[3]
        local v24

        if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
            local v25 = math.abs(v23) * 7.1362384635298E+44
            local v26 = math.floor(v25)
            local v27 = v25 - v26

            v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

            if v23 < 0 then
                v24 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v23)
            v24 = buffer.readu32(v1, 0)
        end

        body[3] = v24

        local v28 = v12[4]
        local v29

        if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
            local v30 = math.abs(v28) * 7.1362384635298E+44
            local v31 = math.floor(v30)
            local v32 = v30 - v31

            v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

            if v28 < 0 then
                v29 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v28)
            v29 = buffer.readu32(v1, 0)
        end

        body[4] = v29

        local inertia = p5.inertia

        if inertia ~= nil then
            local v33 = v10[1]
            local v34 = v10[2]
            local v35 = v10[3]
            local filled = rt.filled

            buffer.writeu32(v1, 0, inertia[1])

            local v37 = mul(v33, filled(4, (buffer.readf32(v1, 0))))
            local filled2 = rt.filled

            buffer.writeu32(v1, 0, inertia[2])

            local v39 = mul(v34, filled2(4, (buffer.readf32(v1, 0))))
            local filled3 = rt.filled

            buffer.writeu32(v1, 0, inertia[3])

            local v41 = mul(v35, filled3(4, (buffer.readf32(v1, 0))))
            local v42 = madd(v41, rt.filled(4, v35[1]), madd(v37, rt.filled(4, v33[1]), mul(v39, rt.filled(4, v34[1]))))

            local function p(p7) -- line: 113
                -- upvalues: perm (copy)
                return perm(p7, { 2, 1, 1, 3 })
            end

            local function s(p8) -- line: 116
                -- upvalues: perm (copy)
                return perm(p8, { 2, 1, 2, 3 })
            end

            local v43 = madd(perm(v35, { 2, 1, 1, 3 }), perm(v41, { 2, 1, 2, 3 }), madd(perm(v33, { 2, 1, 1, 3 }), perm(v37, { 2, 1, 2, 3 }), mul(perm(v34, { 2, 1, 1, 3 }), s(v39))))

            t1.store_xyz(body, 28, v42)
            t1.store_xyz(body, 32, v43)
            body[32] = inertia[5]
        end
    end

    p5.transform = rt.copy(p6)
end

local function rsqrt_s(p9) -- line: 129
    local v44 = 1 / math.sqrt(p9)
    local v45 = v44 * v44
    local v46 = v44 * 0.5 * (-p9 * v45 + 1) + v44
    local v47 = v46 * v46

    return v46 * 0.5 * (-p9 * v47 + 1) + v46
end

local v48 = buffer.create(4)

local function word_f32(p10) -- line: 162
    -- upvalues: v48 (copy)
    buffer.writeu32(v48, 0, p10)

    return (buffer.readf32(v48, 0))
end

local function f32_word(p11) -- line: 166
    -- upvalues: to_bits (copy), v48 (copy)
    if p11 < 1.1754943508222875E-38 and p11 > -1.1754943508222875E-38 and p11 ~= 0 then
        return to_bits(p11)
    end

    buffer.writef32(v48, 0, p11)

    return (buffer.readu32(v48, 0))
end

local function f32r(p12) -- line: 173
    -- upvalues: to_bits (copy), v48 (copy)
    if p12 < 1.1754943508222875E-38 and p12 > -1.1754943508222875E-38 and p12 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(p12))

        return (buffer.readf32(v48, 0))
    end

    buffer.writef32(v48, 0, p12)

    return (buffer.readf32(v48, 0))
end

function t1.set_part_transform(p13, p14) -- line: 182
    -- upvalues: to_bits (copy), v48 (copy)
    local body = p13.body

    if body ~= nil then
        local local_mass_frame = p13.local_mass_frame
        local v49, v50, v51, v52, v53, v54, v55, v56, v57, v58, v59, v60, v61, v62, v63, v64, v65, v66, v67, v68, v69, v70, v71, v72, v73, inertia

        if local_mass_frame ~= nil then
            v73 = p14[1]
            buffer.writeu32(v48, 0, v73)

            local v74 = buffer.readf32(v48, 0)

            v73 = p14[2]
            buffer.writeu32(v48, 0, v73)

            local v75 = buffer.readf32(v48, 0)

            v73 = p14[3]
            buffer.writeu32(v48, 0, v73)
            v49 = buffer.readf32(v48, 0)
            v68 = p14[5]
            buffer.writeu32(v48, 0, v68)

            local v76 = buffer.readf32(v48, 0)

            v68 = p14[6]
            buffer.writeu32(v48, 0, v68)

            local v77 = buffer.readf32(v48, 0)

            v68 = p14[7]
            buffer.writeu32(v48, 0, v68)
            v50 = buffer.readf32(v48, 0)
            v69 = p14[9]
            buffer.writeu32(v48, 0, v69)
            v51 = buffer.readf32(v48, 0)
            v69 = p14[10]
            buffer.writeu32(v48, 0, v69)
            v52 = buffer.readf32(v48, 0)
            v69 = p14[11]
            buffer.writeu32(v48, 0, v69)
            v53 = buffer.readf32(v48, 0)
            v70 = p14[13]
            buffer.writeu32(v48, 0, v70)

            local v78 = buffer.readf32(v48, 0)

            v70 = p14[14]
            buffer.writeu32(v48, 0, v70)

            local v79 = buffer.readf32(v48, 0)

            v70 = p14[15]
            buffer.writeu32(v48, 0, v70)
            v54 = buffer.readf32(v48, 0)
            v72 = local_mass_frame[1]
            buffer.writeu32(v48, 0, v72)

            local v80 = buffer.readf32(v48, 0)

            v72 = local_mass_frame[2]
            buffer.writeu32(v48, 0, v72)

            local v81 = buffer.readf32(v48, 0)

            v72 = local_mass_frame[3]
            buffer.writeu32(v48, 0, v72)
            v55 = buffer.readf32(v48, 0)
            v71 = local_mass_frame[5]
            buffer.writeu32(v48, 0, v71)

            local v82 = buffer.readf32(v48, 0)

            v71 = local_mass_frame[6]
            buffer.writeu32(v48, 0, v71)

            local v83 = buffer.readf32(v48, 0)

            v71 = local_mass_frame[7]
            buffer.writeu32(v48, 0, v71)
            v56 = buffer.readf32(v48, 0)
            buffer.writeu32(v48, 0, local_mass_frame[9])

            local v85 = buffer.readf32(v48, 0)

            buffer.writeu32(v48, 0, local_mass_frame[10])

            local v86 = buffer.readf32(v48, 0)

            buffer.writeu32(v48, 0, local_mass_frame[11])

            local v87 = buffer.readf32(v48, 0)

            buffer.writeu32(v48, 0, local_mass_frame[13])

            local v84 = 0 - buffer.readf32(v48, 0)

            buffer.writeu32(v48, 0, local_mass_frame[14])

            local v90 = 0 - buffer.readf32(v48, 0)

            buffer.writeu32(v48, 0, local_mass_frame[15])

            local v88 = 0 - buffer.readf32(v48, 0)
            local v89 = v84 * v80 + (v90 * v81 + v88 * v55)
            local v91 = v84 * v82 + (v90 * v83 + v88 * v56)
            local v92 = v84 * v85 + (v90 * v86 + v88 * v87)
            local v93 = v85 * v51 + (v82 * v76 + v80 * v74)

            if not (v93 < 1.1754943508222875E-38) or not (v93 > -1.1754943508222875E-38) or v93 == 0 then
                buffer.writef32(v48, 0, v93)
            else
                buffer.writeu32(v48, 0, to_bits(v93))
            end

            v57 = buffer.readf32(v48, 0)
            v93 = v85 * v52 + (v82 * v77 + v80 * v75)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v58 = buffer.readf32(v48, 0)
            v93 = v85 * v53 + (v82 * v50 + v80 * v49)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v59 = buffer.readf32(v48, 0)
            v93 = v86 * v51 + (v83 * v76 + v81 * v74)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v60 = buffer.readf32(v48, 0)
            v93 = v86 * v52 + (v83 * v77 + v81 * v75)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v61 = buffer.readf32(v48, 0)
            v93 = v86 * v53 + (v83 * v50 + v81 * v49)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v62 = buffer.readf32(v48, 0)
            v93 = v87 * v51 + (v56 * v76 + v55 * v74)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v63 = buffer.readf32(v48, 0)
            v93 = v87 * v52 + (v56 * v77 + v55 * v75)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v64 = buffer.readf32(v48, 0)
            v93 = v87 * v53 + (v56 * v50 + v55 * v49)

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v65 = buffer.readf32(v48, 0)
            v93 = v92 * v51 + (v91 * v76 + (v89 * v74 + v78))

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v66 = buffer.readf32(v48, 0)
            v93 = v92 * v52 + (v91 * v77 + (v89 * v75 + v79))

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end

            v67 = buffer.readf32(v48, 0)
            v93 = v92 * v53 + (v91 * v50 + (v89 * v49 + v54))

            if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
                buffer.writeu32(v48, 0, to_bits(v93))
            else
                buffer.writef32(v48, 0, v93)
            end
        else
            inertia = p14[1]
            buffer.writeu32(v48, 0, inertia)
            v57 = buffer.readf32(v48, 0)
            inertia = p14[2]
            buffer.writeu32(v48, 0, inertia)
            v58 = buffer.readf32(v48, 0)
            inertia = p14[3]
            buffer.writeu32(v48, 0, inertia)
            v59 = buffer.readf32(v48, 0)
            inertia = p14[5]
            buffer.writeu32(v48, 0, inertia)
            v60 = buffer.readf32(v48, 0)
            inertia = p14[6]
            buffer.writeu32(v48, 0, inertia)
            v61 = buffer.readf32(v48, 0)
            inertia = p14[7]
            buffer.writeu32(v48, 0, inertia)
            v62 = buffer.readf32(v48, 0)
            inertia = p14[9]
            buffer.writeu32(v48, 0, inertia)
            v63 = buffer.readf32(v48, 0)
            inertia = p14[10]
            buffer.writeu32(v48, 0, inertia)
            v64 = buffer.readf32(v48, 0)
            inertia = p14[11]
            buffer.writeu32(v48, 0, inertia)
            v65 = buffer.readf32(v48, 0)
            inertia = p14[13]
            buffer.writeu32(v48, 0, inertia)
            v66 = buffer.readf32(v48, 0)
            inertia = p14[14]
            buffer.writeu32(v48, 0, inertia)
            v67 = buffer.readf32(v48, 0)
            inertia = p14[15]
            buffer.writeu32(v48, 0, inertia)
        end

        local v94 = buffer.readf32(v48, 0)

        local_mass_frame = v57 * v57 + v58 * v58 + v59 * v59
        inertia = v60 * v60 + v61 * v61 + v62 * v62

        local v95 = v63 * v63 + v64 * v64 + v65 * v65
        local v96 = 1 / math.sqrt(local_mass_frame)
        local v97 = v96 * v96

        v96 = v96 * 0.5 * (-local_mass_frame * v97 + 1) + v96
        v97 = v96 * v96
        v96 = v96 * 0.5 * (-local_mass_frame * v97 + 1) + v96
        v73 = 1 / math.sqrt(inertia)
        v97 = v73 * v73
        v73 = v73 * 0.5 * (-inertia * v97 + 1) + v73
        v97 = v73 * v73
        v73 = v73 * 0.5 * (-inertia * v97 + 1) + v73
        v49 = 1 / math.sqrt(v95)
        v97 = v49 * v49
        v49 = v49 * 0.5 * (-v95 * v97 + 1) + v49
        v97 = v49 * v49
        v49 = v49 * 0.5 * (-v95 * v97 + 1) + v49
        v97 = local_mass_frame * v96
        v68 = inertia * v73
        v50 = v95 * v49

        if local_mass_frame == 0 then
            v97 = 0
        end

        if inertia == 0 then
            v68 = 0
        end

        if v95 == 0 then
            v50 = 0
        end

        local v98 = v57 * v96
        local v99 = v58 * v96
        local v100 = v59 * v96
        local v101 = v60 * v73
        local v102 = v61 * v73
        local v103 = v62 * v73
        local v104 = v63 * v49
        local v105 = v64 * v49
        local v106 = v65 * v49
        local v107

        if v97 > 0 then
            if v68 > 0 then
                if v50 > 0 then
                    v107 = v104 * v98 + v105 * v99 + v106 * v100
                    v53 = math.abs(v107)
                    v107 = v101 * v104 + v102 * v105 + v103 * v106
                    v52 = math.abs(v107)
                    v107 = v98 * v101 + v99 * v102 + v100 * v103
                    v51 = math.abs(v107)
                    v69 = if v52 < v53 then if v52 < v51 then 1 else 0 elseif v53 < v51 then 2 else 0
                else
                    v69 = 0
                end
            else
                v69 = 2
            end
        else
            v69 = 1
        end

        local v108

        if v69 == 0 then
            v72 = v103
            v53 = v98
            v107 = v99
            v70 = v100
            v54 = v101
            v108 = v102
        elseif v69 == 1 then
            v72 = v106
            v53 = v101
            v107 = v102
            v70 = v103
            v54 = v104
            v108 = v105
        else
            v72 = v100
            v53 = v104
            v107 = v105
            v70 = v106
            v54 = v98
            v108 = v99
        end

        local v109 = -v70 * v108 + v107 * v72

        v68 = -v53 * v72 + v70 * v54
        v97 = -v107 * v54 + v53 * v108
        v55 = v109 * v109 + v68 * v68 + v97 * v97
        v96 = 1 / math.sqrt(v55)
        v58 = v96 * v96
        v96 = v96 * 0.5 * (-v55 * v58 + 1) + v96
        v58 = v96 * v96
        v96 = v96 * 0.5 * (-v55 * v58 + 1) + v96
        v55 = v109 * v96

        local v110 = v68 * v96

        v71 = v97 * v96
        v109 = -v71 * v107 + v110 * v70
        v68 = -v55 * v70 + v71 * v53
        v97 = -v110 * v53 + v55 * v107
        v56 = v109 * v109 + v68 * v68 + v97 * v97
        v96 = 1 / math.sqrt(v56)
        v70 = v96 * v96
        v96 = v96 * 0.5 * (-v56 * v70 + 1) + v96
        v70 = v96 * v96
        v96 = v96 * 0.5 * (-v56 * v70 + 1) + v96
        v54 = v109 * v96
        v108 = v68 * v96
        v72 = v97 * v96

        if v69 ~= 0 then
            if v69 == 1 then
                v98, v99, v100, v54, v108, v72, v55, v110, v71 = v55, v110, v71, v101, v102, v103, v54, v108, v72
            else
                v98 = v54
                v99 = v108
                v100 = v72
                v54 = v55
                v108 = v110
                v72 = v71
                v71 = v106
                v55 = v104
                v110 = v105
            end
        end

        if v98 < 1.1754943508222875E-38 and v98 > -1.1754943508222875E-38 and v98 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v98))
        else
            buffer.writef32(v48, 0, v98)
        end

        v98 = buffer.readf32(v48, 0)

        if v99 < 1.1754943508222875E-38 and v99 > -1.1754943508222875E-38 and v99 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v99))
        else
            buffer.writef32(v48, 0, v99)
        end

        v99 = buffer.readf32(v48, 0)

        if v100 < 1.1754943508222875E-38 and v100 > -1.1754943508222875E-38 and v100 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v100))
        else
            buffer.writef32(v48, 0, v100)
        end

        v100 = buffer.readf32(v48, 0)

        if v54 < 1.1754943508222875E-38 and v54 > -1.1754943508222875E-38 and v54 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v54))
        else
            buffer.writef32(v48, 0, v54)
        end

        v101 = buffer.readf32(v48, 0)

        if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v108))
        else
            buffer.writef32(v48, 0, v108)
        end

        v102 = buffer.readf32(v48, 0)

        if v72 < 1.1754943508222875E-38 and v72 > -1.1754943508222875E-38 and v72 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v72))
        else
            buffer.writef32(v48, 0, v72)
        end

        v103 = buffer.readf32(v48, 0)

        if v55 < 1.1754943508222875E-38 and v55 > -1.1754943508222875E-38 and v55 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v55))
        else
            buffer.writef32(v48, 0, v55)
        end

        v104 = buffer.readf32(v48, 0)

        if v110 < 1.1754943508222875E-38 and v110 > -1.1754943508222875E-38 and v110 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v110))
        else
            buffer.writef32(v48, 0, v110)
        end

        v105 = buffer.readf32(v48, 0)

        if v71 < 1.1754943508222875E-38 and v71 > -1.1754943508222875E-38 and v71 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v71))
        else
            buffer.writef32(v48, 0, v71)
        end

        v106 = buffer.readf32(v48, 0)

        if v66 < 1.1754943508222875E-38 and v66 > -1.1754943508222875E-38 and v66 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v66))
        else
            buffer.writef32(v48, 0, v66)
        end

        local v111 = buffer.readf32(v48, 0)

        if v67 < 1.1754943508222875E-38 and v67 > -1.1754943508222875E-38 and v67 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v67))
        else
            buffer.writef32(v48, 0, v67)
        end

        local v112 = buffer.readf32(v48, 0)

        if v94 < 1.1754943508222875E-38 and v94 > -1.1754943508222875E-38 and v94 ~= 0 then
            buffer.writeu32(v48, 0, to_bits(v94))
        else
            buffer.writef32(v48, 0, v94)
        end

        v94 = buffer.readf32(v48, 0)

        if v98 < 1.1754943508222875E-38 and v98 > -1.1754943508222875E-38 and v98 ~= 0 then
            inertia = to_bits(v98)
        else
            buffer.writef32(v48, 0, v98)
            inertia = buffer.readu32(v48, 0)
        end

        if v99 < 1.1754943508222875E-38 and v99 > -1.1754943508222875E-38 and v99 ~= 0 then
            v66 = to_bits(v99)
        else
            buffer.writef32(v48, 0, v99)
            v66 = buffer.readu32(v48, 0)
        end

        if v100 < 1.1754943508222875E-38 and v100 > -1.1754943508222875E-38 and v100 ~= 0 then
            v96 = to_bits(v100)
        else
            buffer.writef32(v48, 0, v100)
            v96 = buffer.readu32(v48, 0)
        end

        body[17] = inertia
        body[18] = v66
        body[19] = v96

        if v101 < 1.1754943508222875E-38 and v101 > -1.1754943508222875E-38 and v101 ~= 0 then
            inertia = to_bits(v101)
        else
            buffer.writef32(v48, 0, v101)
            inertia = buffer.readu32(v48, 0)
        end

        if v102 < 1.1754943508222875E-38 and v102 > -1.1754943508222875E-38 and v102 ~= 0 then
            v66 = to_bits(v102)
        else
            buffer.writef32(v48, 0, v102)
            v66 = buffer.readu32(v48, 0)
        end

        if v103 < 1.1754943508222875E-38 and v103 > -1.1754943508222875E-38 and v103 ~= 0 then
            v96 = to_bits(v103)
        else
            buffer.writef32(v48, 0, v103)
            v96 = buffer.readu32(v48, 0)
        end

        body[21] = inertia
        body[22] = v66
        body[23] = v96

        if v104 < 1.1754943508222875E-38 and v104 > -1.1754943508222875E-38 and v104 ~= 0 then
            inertia = to_bits(v104)
        else
            buffer.writef32(v48, 0, v104)
            inertia = buffer.readu32(v48, 0)
        end

        if v105 < 1.1754943508222875E-38 and v105 > -1.1754943508222875E-38 and v105 ~= 0 then
            v66 = to_bits(v105)
        else
            buffer.writef32(v48, 0, v105)
            v66 = buffer.readu32(v48, 0)
        end

        if v106 < 1.1754943508222875E-38 and v106 > -1.1754943508222875E-38 and v106 ~= 0 then
            v96 = to_bits(v106)
        else
            buffer.writef32(v48, 0, v106)
            v96 = buffer.readu32(v48, 0)
        end

        body[25] = inertia
        body[26] = v66
        body[27] = v96

        if v111 < 1.1754943508222875E-38 and v111 > -1.1754943508222875E-38 and v111 ~= 0 then
            inertia = to_bits(v111)
        else
            buffer.writef32(v48, 0, v111)
            inertia = buffer.readu32(v48, 0)
        end

        if v112 < 1.1754943508222875E-38 and v112 > -1.1754943508222875E-38 and v112 ~= 0 then
            v66 = to_bits(v112)
        else
            buffer.writef32(v48, 0, v112)
            v66 = buffer.readu32(v48, 0)
        end

        if v94 < 1.1754943508222875E-38 and v94 > -1.1754943508222875E-38 and v94 ~= 0 then
            v96 = to_bits(v94)
        else
            buffer.writef32(v48, 0, v94)
            v96 = buffer.readu32(v48, 0)
        end

        body[5] = inertia
        body[6] = v66
        body[7] = v96
        v94 = v98 + v102

        if v94 + v106 > 0 then
            v112 = v94 + (v106 + 1)
            v111 = 1 / math.sqrt(v112)
            v49 = v111 * v111
            v111 = v111 * 0.5 * (-v112 * v49 + 1) + v111
            v49 = v111 * v111
            v111 = v111 * 0.5 * (-v112 * v49 + 1) + v111
            v49 = v112 * v111
            v112 = v111 * 0.5
            inertia = (v103 - v105) * v112
            v66 = (v104 - v100) * v112
            v96 = (v99 - v101) * v112
            v73 = 0.5 * v49
        elseif v102 < v98 and v106 < v98 then
            v49 = v98 + -v102 + (-v106 + 1)
            v97 = 1 / math.sqrt(v49)
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v49 * v97
            v49 = v97 * 0.5
            inertia = 0.5 * v68
            v66 = (v99 + v101) * v49
            v96 = (v104 + v100) * v49
            v73 = (v103 - v105) * v49
        elseif v106 < v102 then
            v49 = -v98 + v102 + (-v106 + 1)
            v97 = 1 / math.sqrt(v49)
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v49 * v97
            v49 = v97 * 0.5
            inertia = (v99 + v101) * v49
            v66 = 0.5 * v68
            v96 = (v103 + v105) * v49
            v73 = (v104 - v100) * v49
        else
            v49 = -v98 + -v102 + (v106 + 1)
            v97 = 1 / math.sqrt(v49)
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v97 * v97
            v97 = v97 * 0.5 * (-v49 * v68 + 1) + v97
            v68 = v49 * v97
            v49 = v97 * 0.5
            inertia = (v104 + v100) * v49
            v66 = (v103 + v105) * v49
            v96 = 0.5 * v68
            v73 = (v99 - v101) * v49
        end

        v49 = inertia * inertia + v66 * v66 + v96 * v96 + v73 * v73
        v94 = 1 / math.sqrt(v49)
        v97 = v94 * v94
        v94 = v94 * 0.5 * (-v49 * v97 + 1) + v94
        v97 = v94 * v94
        v94 = v94 * 0.5 * (-v49 * v97 + 1) + v94
        v97 = inertia * v94

        if v97 < 1.1754943508222875E-38 and v97 > -1.1754943508222875E-38 and v97 ~= 0 then
            body[1] = to_bits(v97)
        else
            buffer.writef32(v48, 0, v97)
            body[1] = buffer.readu32(v48, 0)
        end

        v97 = v66 * v94

        if v97 < 1.1754943508222875E-38 and v97 > -1.1754943508222875E-38 and v97 ~= 0 then
            body[2] = to_bits(v97)
        else
            buffer.writef32(v48, 0, v97)
            body[2] = buffer.readu32(v48, 0)
        end

        v97 = v96 * v94

        if v97 < 1.1754943508222875E-38 and v97 > -1.1754943508222875E-38 and v97 ~= 0 then
            body[3] = to_bits(v97)
        else
            buffer.writef32(v48, 0, v97)
            body[3] = buffer.readu32(v48, 0)
        end

        v97 = v73 * v94

        if v97 < 1.1754943508222875E-38 and v97 > -1.1754943508222875E-38 and v97 ~= 0 then
            body[4] = to_bits(v97)
        else
            buffer.writef32(v48, 0, v97)
            body[4] = buffer.readu32(v48, 0)
        end

        inertia = p13.inertia

        if inertia ~= nil then
            v49 = inertia[1]
            buffer.writeu32(v48, 0, v49)
            v97 = buffer.readf32(v48, 0)
            v49 = inertia[2]
            buffer.writeu32(v48, 0, v49)

            local v113 = buffer.readf32(v48, 0)

            v49 = inertia[3]
            buffer.writeu32(v48, 0, v49)

            local v114 = buffer.readf32(v48, 0)

            v49 = v98 * v97

            local v115 = v99 * v97
            local v116 = v100 * v97

            v50 = v101 * v113

            local v117 = v102 * v113
            local v118 = v103 * v113

            v53 = v104 * v114

            local v119 = v105 * v114
            local v120 = v106 * v114

            v108 = v53 * v104 + (v49 * v98 + v50 * v101)

            if not (v108 < 1.1754943508222875E-38) or not (v108 > -1.1754943508222875E-38) or v108 == 0 then
                buffer.writef32(v48, 0, v108)
                body[29] = buffer.readu32(v48, 0)
            else
                body[29] = to_bits(v108)
            end

            v108 = v119 * v104 + (v115 * v98 + v117 * v101)

            if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
                body[30] = to_bits(v108)
            else
                buffer.writef32(v48, 0, v108)
                body[30] = buffer.readu32(v48, 0)
            end

            v108 = v120 * v104 + (v116 * v98 + v118 * v101)

            if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
                body[31] = to_bits(v108)
            else
                buffer.writef32(v48, 0, v108)
                body[31] = buffer.readu32(v48, 0)
            end

            v108 = v106 * v120 + (v100 * v116 + v103 * v118)

            if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
                body[33] = to_bits(v108)
            else
                buffer.writef32(v48, 0, v108)
                body[33] = buffer.readu32(v48, 0)
            end

            v108 = v105 * v119 + (v99 * v115 + v102 * v117)

            if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
                body[34] = to_bits(v108)
            else
                buffer.writef32(v48, 0, v108)
                body[34] = buffer.readu32(v48, 0)
            end

            v108 = v105 * v120 + (v99 * v116 + v102 * v118)

            if v108 < 1.1754943508222875E-38 and v108 > -1.1754943508222875E-38 and v108 ~= 0 then
                body[35] = to_bits(v108)
            else
                buffer.writef32(v48, 0, v108)
                body[35] = buffer.readu32(v48, 0)
            end

            body[32] = inertia[5]
        end
    end

    p13.transform = table.clone(p14)
end

function t1.set_part_transform_r2(p15, p16) -- line: 382
    -- upvalues: to_bits (copy), from_bits (copy)
    local body = p15.body

    if body ~= nil then
        local v121 = p15.local_mass_frame
        local v122, v123, v124, v125, v126, v127, v128, v129, v130, v131, v132, v133, v134, v135, v136, v137, v138, v139, v140, v141, v142, v143, v144, v145

        if v121 ~= nil then
            v126 = from_bits(p16[1])

            local v146 = from_bits(p16[2])

            v125 = from_bits(p16[3])
            v128 = from_bits(p16[5])

            local v147 = from_bits(p16[6])

            v127 = from_bits(p16[7])
            v138 = from_bits(p16[9])

            local v148 = from_bits(p16[10])

            v122 = from_bits(p16[11])
            v139 = from_bits(p16[13])

            local v149 = from_bits(p16[14])

            v140 = from_bits(p16[15])
            v123 = from_bits(v121[1])

            local v150 = from_bits(v121[2])

            v124 = from_bits(v121[3])
            v142 = from_bits(v121[5])

            local v151 = from_bits(v121[6])

            v141 = from_bits(v121[7])

            local v152 = from_bits(v121[9])
            local v153 = from_bits(v121[10])
            local v154 = from_bits(v121[11])
            local v155 = 0 - from_bits(v121[13])
            local v156 = 0 - from_bits(v121[14])
            local v157 = 0 - from_bits(v121[15])
            local v158 = v155 * v123 + (v156 * v150 + v157 * v124)
            local v159 = v155 * v142 + (v156 * v151 + v157 * v141)
            local v160 = v155 * v152 + (v156 * v153 + v157 * v154)

            v129 = from_bits(to_bits(v152 * v138 + (v142 * v128 + v123 * v126)))
            v130 = from_bits(to_bits(v152 * v148 + (v142 * v147 + v123 * v146)))
            v131 = from_bits(to_bits(v152 * v122 + (v142 * v127 + v123 * v125)))
            v132 = from_bits(to_bits(v153 * v138 + (v151 * v128 + v150 * v126)))
            v133 = from_bits(to_bits(v153 * v148 + (v151 * v147 + v150 * v146)))
            v134 = from_bits(to_bits(v153 * v122 + (v151 * v127 + v150 * v125)))
            v135 = from_bits(to_bits(v154 * v138 + (v141 * v128 + v124 * v126)))
            v136 = from_bits(to_bits(v154 * v148 + (v141 * v147 + v124 * v146)))
            v137 = from_bits(to_bits(v154 * v122 + (v141 * v127 + v124 * v125)))
            v143 = from_bits(to_bits(v160 * v138 + (v159 * v128 + (v158 * v126 + v139))))
            v144 = from_bits(to_bits(v160 * v148 + (v159 * v147 + (v158 * v146 + v149))))
            v145 = from_bits(to_bits(v160 * v122 + (v159 * v127 + (v158 * v125 + v140))))
        else
            v129 = from_bits(p16[1])
            v130 = from_bits(p16[2])
            v131 = from_bits(p16[3])
            v132 = from_bits(p16[5])
            v133 = from_bits(p16[6])
            v134 = from_bits(p16[7])
            v135 = from_bits(p16[9])
            v136 = from_bits(p16[10])
            v137 = from_bits(p16[11])
            v143 = from_bits(p16[13])
            v144 = from_bits(p16[14])
            v145 = from_bits(p16[15])
        end

        v121 = v129 * v129 + v130 * v130 + v131 * v131

        local v161 = v132 * v132 + v133 * v133 + v134 * v134
        local v162 = v135 * v135 + v136 * v136 + v137 * v137

        v125 = 1 / math.sqrt(v121)
        v127 = v125 * v125
        v125 = v125 * 0.5 * (-v121 * v127 + 1) + v125
        v127 = v125 * v125
        v125 = v125 * 0.5 * (-v121 * v127 + 1) + v125
        v126 = 1 / math.sqrt(v161)
        v127 = v126 * v126
        v126 = v126 * 0.5 * (-v161 * v127 + 1) + v126
        v127 = v126 * v126
        v126 = v126 * 0.5 * (-v161 * v127 + 1) + v126

        local v163 = 1 / math.sqrt(v162)

        v127 = v163 * v163
        v163 = v163 * 0.5 * (-v162 * v127 + 1) + v163
        v127 = v163 * v163
        v163 = v163 * 0.5 * (-v162 * v127 + 1) + v163
        v127 = v121 * v125
        v128 = v161 * v126

        local v164 = v162 * v163

        if v121 == 0 then
            v127 = 0
        end

        if v161 == 0 then
            v128 = 0
        end

        if v162 == 0 then
            v164 = 0
        end

        v129 *= v125
        v130 *= v125
        v131 *= v125
        v132 *= v126
        v133 *= v126
        v134 *= v126
        v135 *= v163
        v136 *= v163
        v137 *= v163

        local v165

        if v127 > 0 then
            if v128 > 0 then
                if v164 > 0 then
                    v140 = v135 * v129 + v136 * v130 + v137 * v131
                    v165 = math.abs(v140)
                    v140 = v132 * v135 + v133 * v136 + v134 * v137

                    local v166 = math.abs(v140)

                    v140 = v129 * v132 + v130 * v133 + v131 * v134

                    local v167 = math.abs(v140)

                    v138 = if v166 < v165 then if v166 < v167 then 1 else 0 elseif v165 < v167 then 2 else 0
                else
                    v138 = 0
                end
            else
                v138 = 2
            end
        else
            v138 = 1
        end

        local v168

        if v138 == 0 then
            v123 = v134
            v165 = v129
            v140 = v130
            v139 = v131
            v168 = v132
            v124 = v133
        elseif v138 == 1 then
            v123 = v137
            v165 = v132
            v140 = v133
            v139 = v134
            v168 = v135
            v124 = v136
        else
            v123 = v131
            v165 = v135
            v140 = v136
            v139 = v137
            v168 = v129
            v124 = v130
        end

        v122 = -v139 * v124 + v140 * v123
        v128 = -v165 * v123 + v139 * v168
        v127 = -v140 * v168 + v165 * v124

        local v169 = v122 * v122 + v128 * v128 + v127 * v127

        v125 = 1 / math.sqrt(v169)
        v162 = v125 * v125
        v125 = v125 * 0.5 * (-v169 * v162 + 1) + v125
        v162 = v125 * v125
        v125 = v125 * 0.5 * (-v169 * v162 + 1) + v125
        v169 = v122 * v125
        v141 = v128 * v125
        v142 = v127 * v125
        v122 = -v142 * v140 + v141 * v139
        v128 = -v169 * v139 + v142 * v165
        v127 = -v141 * v165 + v169 * v140

        local v170 = v122 * v122 + v128 * v128 + v127 * v127

        v125 = 1 / math.sqrt(v170)
        v139 = v125 * v125
        v125 = v125 * 0.5 * (-v170 * v139 + 1) + v125
        v139 = v125 * v125
        v125 = v125 * 0.5 * (-v170 * v139 + 1) + v125
        v168 = v122 * v125
        v124 = v128 * v125
        v123 = v127 * v125

        if v138 ~= 0 then
            if v138 == 1 then
                v129, v130, v131, v168, v124, v123, v169, v141, v142 = v169, v141, v142, v132, v133, v134, v168, v124, v123
            else
                v129 = v168
                v130 = v124
                v131 = v123
                v168 = v169
                v124 = v141
                v123 = v142
                v142 = v137
                v169 = v135
                v141 = v136
            end
        end

        v161 = from_bits(to_bits(v129))

        local v171 = from_bits(to_bits(v130))
        local v172 = from_bits(to_bits(v131))
        local v173 = from_bits(to_bits(v168))
        local v174 = from_bits(to_bits(v124))
        local v175 = from_bits(to_bits(v123))
        local v176 = from_bits(to_bits(v169))
        local v177 = from_bits(to_bits(v141))
        local v178 = from_bits(to_bits(v142))
        local v179 = from_bits(to_bits(v143))
        local v180 = from_bits(to_bits(v144))
        local v181 = from_bits(to_bits(v145))
        local v182 = to_bits(v161)

        v162 = to_bits(v171)
        v125 = to_bits(v172)
        body[17] = v182
        body[18] = v162
        body[19] = v125
        v182 = to_bits(v173)
        v162 = to_bits(v174)
        v125 = to_bits(v175)
        body[21] = v182
        body[22] = v162
        body[23] = v125
        v182 = to_bits(v176)
        v162 = to_bits(v177)
        v125 = to_bits(v178)
        body[25] = v182
        body[26] = v162
        body[27] = v125
        v179 = to_bits(v179)
        v162 = to_bits(v180)
        v125 = to_bits(v181)
        body[5] = v179
        body[6] = v162
        body[7] = v125
        v145 = v161 + v174

        if v145 + v178 > 0 then
            v144 = v145 + (v178 + 1)
            v143 = 1 / math.sqrt(v144)
            v163 = v143 * v143
            v143 = v143 * 0.5 * (-v144 * v163 + 1) + v143
            v163 = v143 * v143
            v143 = v143 * 0.5 * (-v144 * v163 + 1) + v143
            v163 = v144 * v143
            v144 = v143 * 0.5
            v179 = (v175 - v177) * v144
            v162 = (v176 - v172) * v144
            v125 = (v171 - v173) * v144
            v126 = 0.5 * v163
        elseif v174 < v161 and v178 < v161 then
            v163 = v161 + -v174 + (-v178 + 1)
            v127 = 1 / math.sqrt(v163)
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v163 * v127
            v163 = v127 * 0.5
            v179 = 0.5 * v128
            v162 = (v171 + v173) * v163
            v125 = (v176 + v172) * v163
            v126 = (v175 - v177) * v163
        elseif v178 < v174 then
            v163 = -v161 + v174 + (-v178 + 1)
            v127 = 1 / math.sqrt(v163)
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v163 * v127
            v163 = v127 * 0.5
            v179 = (v171 + v173) * v163
            v162 = 0.5 * v128
            v125 = (v175 + v177) * v163
            v126 = (v176 - v172) * v163
        else
            v163 = -v161 + -v174 + (v178 + 1)
            v127 = 1 / math.sqrt(v163)
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v127 * v127
            v127 = v127 * 0.5 * (-v163 * v128 + 1) + v127
            v128 = v163 * v127
            v163 = v127 * 0.5
            v179 = (v176 + v172) * v163
            v162 = (v175 + v177) * v163
            v125 = 0.5 * v128
            v126 = (v171 - v173) * v163
        end

        v163 = v179 * v179 + v162 * v162 + v125 * v125 + v126 * v126
        v145 = 1 / math.sqrt(v163)
        v127 = v145 * v145
        v145 = v145 * 0.5 * (-v163 * v127 + 1) + v145
        v127 = v145 * v145
        v145 = v145 * 0.5 * (-v163 * v127 + 1) + v145
        body[1] = to_bits(v179 * v145)
        body[2] = to_bits(v162 * v145)
        body[3] = to_bits(v125 * v145)
        body[4] = to_bits(v126 * v145)
        v179 = p15.inertia

        if v179 ~= nil then
            local v183 = from_bits(v179[1])
            local v184 = from_bits(v179[2])

            v126 = from_bits(v179[3])
            v163 = v161 * v183
            v127 = v171 * v183
            v128 = v172 * v183
            v164 = v173 * v184
            v122 = v174 * v184
            v138 = v175 * v184
            v165 = v176 * v126
            v140 = v177 * v126
            v139 = v178 * v126
            body[29] = to_bits(v165 * v176 + (v163 * v161 + v164 * v173))
            body[30] = to_bits(v140 * v176 + (v127 * v161 + v122 * v173))
            body[31] = to_bits(v139 * v176 + (v128 * v161 + v138 * v173))
            body[33] = to_bits(v178 * v139 + (v172 * v128 + v175 * v138))
            body[34] = to_bits(v177 * v140 + (v171 * v127 + v174 * v122))
            body[35] = to_bits(v177 * v139 + (v171 * v128 + v174 * v138))
            body[32] = v179[5]
        end
    end

    p15.transform = table.clone(p16)
end

local create = vector.create

local function tiny(p17) -- line: 598
    -- upvalues: to_bits (copy), v48 (copy)
    buffer.writeu32(v48, 0, to_bits(p17))

    return (buffer.readf32(v48, 0))
end

function t1.body_pose_lanes(p18, p19, p20, p21) -- line: 602
    -- upvalues: to_bits (copy), v48 (copy), create (copy)
    local v185 = p18[1]
    local v186 = p18[2]
    local v187 = p18[3]
    local v188 = p18[4]
    local x = v185[1]
    local y = v185[2]
    local z = v185[3]
    local x2 = create(x, y, z)
    local x3, y2, z2 = x2.x, x2.y, x2.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x3 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y2 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z2 = buffer.readf32(v48, 0)
    end

    x2 = v186[1]

    local y3 = v186[2]
    local z3 = v186[3]
    local x4 = create(x2, y3, z3)

    x = x4.x
    y = x4.y
    z = x4.z

    if x2 < 1.1754943508222875E-38 and x2 > -1.1754943508222875E-38 and x2 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x2))
        x = buffer.readf32(v48, 0)
    end

    if y3 < 1.1754943508222875E-38 and y3 > -1.1754943508222875E-38 and y3 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y3))
        y = buffer.readf32(v48, 0)
    end

    if z3 < 1.1754943508222875E-38 and z3 > -1.1754943508222875E-38 and z3 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z3))
        z = buffer.readf32(v48, 0)
    end

    x4 = v187[1]

    local y4 = v187[2]
    local z4 = v187[3]
    local v189 = create(x4, y4, z4)

    x2 = v189.x
    y3 = v189.y
    z3 = v189.z

    if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x4))
        x2 = buffer.readf32(v48, 0)
    end

    if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y4))
        y3 = buffer.readf32(v48, 0)
    end

    if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z4))
        z3 = buffer.readf32(v48, 0)
    end

    v189 = v188[1]

    local v190 = v188[2]
    local v191 = v188[3]
    local x5 = create(v189, v190, v191)

    x4 = x5.x
    y4 = x5.y
    z4 = x5.z

    if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v189))
        x4 = buffer.readf32(v48, 0)
    end

    if v190 < 1.1754943508222875E-38 and v190 > -1.1754943508222875E-38 and v190 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v190))
        y4 = buffer.readf32(v48, 0)
    end

    if v191 < 1.1754943508222875E-38 and v191 > -1.1754943508222875E-38 and v191 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v191))
        z4 = buffer.readf32(v48, 0)
    end

    v189 = p19[1]
    v190 = p19[2]
    v191 = p19[3]

    local x6 = v189[1]
    local y5 = v189[2]
    local z5 = v189[3]
    local x7 = create(x6, y5, z5)

    x5 = x7.x

    local y6, z6 = x7.y, x7.z

    if x6 < 1.1754943508222875E-38 and x6 > -1.1754943508222875E-38 and x6 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x6))
        x5 = buffer.readf32(v48, 0)
    end

    if y5 < 1.1754943508222875E-38 and y5 > -1.1754943508222875E-38 and y5 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y5))
        y6 = buffer.readf32(v48, 0)
    end

    if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z5))
        z6 = buffer.readf32(v48, 0)
    end

    x7 = v190[1]

    local y7 = v190[2]
    local z7 = v190[3]
    local x8 = create(x7, y7, z7)

    x6 = x8.x
    y5 = x8.y
    z5 = x8.z

    if x7 < 1.1754943508222875E-38 and x7 > -1.1754943508222875E-38 and x7 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x7))
        x6 = buffer.readf32(v48, 0)
    end

    if y7 < 1.1754943508222875E-38 and y7 > -1.1754943508222875E-38 and y7 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y7))
        y5 = buffer.readf32(v48, 0)
    end

    if z7 < 1.1754943508222875E-38 and z7 > -1.1754943508222875E-38 and z7 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z7))
        z5 = buffer.readf32(v48, 0)
    end

    x8 = v191[1]

    local y8 = v191[2]
    local v192 = v191[3]
    local x9 = create(x8, y8, v192)

    x7 = x9.x
    y7 = x9.y
    z7 = x9.z

    if x8 < 1.1754943508222875E-38 and x8 > -1.1754943508222875E-38 and x8 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x8))
        x7 = buffer.readf32(v48, 0)
    end

    if y8 < 1.1754943508222875E-38 and y8 > -1.1754943508222875E-38 and y8 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y8))
        y7 = buffer.readf32(v48, 0)
    end

    if v192 < 1.1754943508222875E-38 and v192 > -1.1754943508222875E-38 and v192 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v192))
        z7 = buffer.readf32(v48, 0)
    end

    x9 = p20.x

    local v193, v194 = p20.y, p20.z
    local x10 = create(x9, v193, v194)

    x8 = x10.x
    y8 = x10.y
    v192 = x10.z

    if x9 < 1.1754943508222875E-38 and x9 > -1.1754943508222875E-38 and x9 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x9))
        x8 = buffer.readf32(v48, 0)
    end

    if v193 < 1.1754943508222875E-38 and v193 > -1.1754943508222875E-38 and v193 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v193))
        y8 = buffer.readf32(v48, 0)
    end

    if v194 < 1.1754943508222875E-38 and v194 > -1.1754943508222875E-38 and v194 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v194))
        v192 = buffer.readf32(v48, 0)
    end

    x9 = 0 - x8
    x8 = 0 - y8
    y8 = 0 - v192
    v192 = x9 * x5 + (x8 * y6 + y8 * z6)
    v193 = x9 * x6 + (x8 * y5 + y8 * z5)
    v194 = x9 * x7 + (x8 * y7 + y8 * z7)

    local x11 = x7 * x2 + (x6 * x + x5 * x3)
    local y9 = x7 * y3 + (x6 * y + x5 * y2)
    local z8 = x7 * z3 + (x6 * z + x5 * z2)
    local x12 = create(x11, y9, z8)

    x10 = x12.x

    local y10, z9 = x12.y, x12.z

    if x11 < 1.1754943508222875E-38 and x11 > -1.1754943508222875E-38 and x11 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x11))
        x10 = buffer.readf32(v48, 0)
    end

    if y9 < 1.1754943508222875E-38 and y9 > -1.1754943508222875E-38 and y9 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y9))
        y10 = buffer.readf32(v48, 0)
    end

    if z8 < 1.1754943508222875E-38 and z8 > -1.1754943508222875E-38 and z8 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z8))
        z9 = buffer.readf32(v48, 0)
    end

    x12 = y7 * x2 + (y5 * x + y6 * x3)

    local y11 = y7 * y3 + (y5 * y + y6 * y2)
    local z10 = y7 * z3 + (y5 * z + y6 * z2)
    local x13 = create(x12, y11, z10)

    x11 = x13.x
    y9 = x13.y
    z8 = x13.z

    if x12 < 1.1754943508222875E-38 and x12 > -1.1754943508222875E-38 and x12 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x12))
        x11 = buffer.readf32(v48, 0)
    end

    if y11 < 1.1754943508222875E-38 and y11 > -1.1754943508222875E-38 and y11 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y11))
        y9 = buffer.readf32(v48, 0)
    end

    if z10 < 1.1754943508222875E-38 and z10 > -1.1754943508222875E-38 and z10 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z10))
        z8 = buffer.readf32(v48, 0)
    end

    x13 = z7 * x2 + (z5 * x + z6 * x3)

    local y12 = z7 * y3 + (z5 * y + z6 * y2)
    local z11 = z7 * z3 + (z5 * z + z6 * z2)
    local v195 = create(x13, y12, z11)

    x12 = v195.x
    y11 = v195.y
    z10 = v195.z

    if x13 < 1.1754943508222875E-38 and x13 > -1.1754943508222875E-38 and x13 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x13))
        x12 = buffer.readf32(v48, 0)
    end

    if y12 < 1.1754943508222875E-38 and y12 > -1.1754943508222875E-38 and y12 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y12))
        y11 = buffer.readf32(v48, 0)
    end

    if z11 < 1.1754943508222875E-38 and z11 > -1.1754943508222875E-38 and z11 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z11))
        z10 = buffer.readf32(v48, 0)
    end

    v195 = v194 * x2 + (v193 * x + (v192 * x3 + x4))

    local v196 = v194 * y3 + (v193 * y + (v192 * y2 + y4))
    local v197 = v194 * z3 + (v193 * z + (v192 * z2 + z4))
    local v198 = create(v195, v196, v197)

    x13 = v198.x
    y12 = v198.y
    z11 = v198.z

    if v195 < 1.1754943508222875E-38 and v195 > -1.1754943508222875E-38 and v195 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v195))
        x13 = buffer.readf32(v48, 0)
    end

    if v196 < 1.1754943508222875E-38 and v196 > -1.1754943508222875E-38 and v196 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v196))
        y12 = buffer.readf32(v48, 0)
    end

    if v197 < 1.1754943508222875E-38 and v197 > -1.1754943508222875E-38 and v197 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v197))
        z11 = buffer.readf32(v48, 0)
    end

    v194 = x10 * x10 + y10 * y10 + z9 * z9
    v193 = x11 * x11 + y9 * y9 + z8 * z8
    v192 = x12 * x12 + y11 * y11 + z10 * z10
    v195 = 1 / math.sqrt(v194)
    y7 = v195 * v195
    v195 = v195 * 0.5 * (-v194 * y7 + 1) + v195
    y7 = v195 * v195
    v195 = v195 * 0.5 * (-v194 * y7 + 1) + v195
    v196 = 1 / math.sqrt(v193)
    z5 = v196 * v196
    v196 = v196 * 0.5 * (-v193 * z5 + 1) + v196
    z5 = v196 * v196
    v196 = v196 * 0.5 * (-v193 * z5 + 1) + v196
    v197 = 1 / math.sqrt(v192)
    x6 = v197 * v197
    v197 = v197 * 0.5 * (-v192 * x6 + 1) + v197
    x6 = v197 * v197
    v197 = v197 * 0.5 * (-v192 * x6 + 1) + v197
    v198 = v194 * v195

    local x14 = v193 * v196
    local y13 = v192 * v197

    if v194 == 0 then
        v198 = 0
    end

    if v193 == 0 then
        x14 = 0
    end

    if v192 == 0 then
        y13 = 0
    end

    local v199 = x10 * v195
    local v200 = y10 * v195
    local v201 = z9 * v195

    x11 *= v196
    y9 *= v196
    z8 *= v196
    x12 *= v197
    y11 *= v197
    z10 *= v197

    local v202, v203, z12

    if v198 > 0 then
        if x14 > 0 then
            if y13 > 0 then
                v202 = x12 * v199 + y11 * v200 + z10 * v201
                v203 = math.abs(v202)
                v202 = x11 * x12 + y9 * y11 + z8 * z10

                local v204 = math.abs(v202)

                v202 = v199 * x11 + v200 * y9 + v201 * z8

                local v205 = math.abs(v202)

                z12 = if v204 < v203 then if v204 < v205 then 1 else 0 elseif v203 < v205 then 2 else 0
            else
                z12 = 0
            end
        else
            z12 = 2
        end
    else
        z12 = 1
    end

    local v206, v207, z13, v208

    if z12 == 0 then
        v207 = z8
        v203 = v199
        v202 = v200
        z13 = v201
        v206 = x11
        v208 = y9
    elseif z12 == 1 then
        v207 = z10
        v203 = x11
        v202 = y9
        z13 = z8
        v206 = x12
        v208 = y11
    else
        v207 = v201
        v203 = x12
        v202 = y11
        z13 = z10
        v206 = v199
        v208 = v200
    end

    x14 = -z13 * v208 + v202 * v207
    v198 = -v203 * v207 + z13 * v206
    v195 = -v202 * v206 + v203 * v208

    local v209 = x14 * x14 + v198 * v198 + v195 * v195

    v194 = 1 / math.sqrt(v209)
    v193 = v194 * v194
    v194 = v194 * 0.5 * (-v209 * v193 + 1) + v194
    v193 = v194 * v194
    v194 = v194 * 0.5 * (-v209 * v193 + 1) + v194
    v209 = x14 * v194

    local v210 = v198 * v194
    local v211 = v195 * v194

    x14 = -v211 * v202 + v210 * z13
    v198 = -v209 * z13 + v211 * v203
    v195 = -v210 * v203 + v209 * v202

    local v212 = x14 * x14 + v198 * v198 + v195 * v195

    v194 = 1 / math.sqrt(v212)
    z13 = v194 * v194
    v194 = v194 * 0.5 * (-v212 * z13 + 1) + v194
    z13 = v194 * v194
    v194 = v194 * 0.5 * (-v212 * z13 + 1) + v194
    v206 = x14 * v194
    v208 = v198 * v194
    v207 = v195 * v194

    if z12 ~= 0 then
        if z12 == 1 then
            v199, v200, v201, v206, v208, v207, v209, v210, v211 = v209, v210, v211, x11, y9, z8, v206, v208, v207
        else
            v199 = v206
            v200 = v208
            v201 = v207
            v206 = v209
            v208 = v210
            v207 = v211
            v211 = z10
            v209 = x12
            v210 = y11
        end
    end

    v198 = create(v199, v200, v201)
    x10 = v198.x
    y10 = v198.y
    z9 = v198.z

    if v199 < 1.1754943508222875E-38 and v199 > -1.1754943508222875E-38 and v199 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v199))
        x10 = buffer.readf32(v48, 0)
    end

    if v200 < 1.1754943508222875E-38 and v200 > -1.1754943508222875E-38 and v200 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v200))
        y10 = buffer.readf32(v48, 0)
    end

    if v201 < 1.1754943508222875E-38 and v201 > -1.1754943508222875E-38 and v201 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v201))
        z9 = buffer.readf32(v48, 0)
    end

    v198 = create(v206, v208, v207)
    x11 = v198.x
    y9 = v198.y
    z8 = v198.z

    if v206 < 1.1754943508222875E-38 and v206 > -1.1754943508222875E-38 and v206 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v206))
        x11 = buffer.readf32(v48, 0)
    end

    if v208 < 1.1754943508222875E-38 and v208 > -1.1754943508222875E-38 and v208 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v208))
        y9 = buffer.readf32(v48, 0)
    end

    if v207 < 1.1754943508222875E-38 and v207 > -1.1754943508222875E-38 and v207 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v207))
        z8 = buffer.readf32(v48, 0)
    end

    v198 = create(v209, v210, v211)
    x12 = v198.x
    y11 = v198.y
    z10 = v198.z

    if v209 < 1.1754943508222875E-38 and v209 > -1.1754943508222875E-38 and v209 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v209))
        x12 = buffer.readf32(v48, 0)
    end

    if v210 < 1.1754943508222875E-38 and v210 > -1.1754943508222875E-38 and v210 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v210))
        y11 = buffer.readf32(v48, 0)
    end

    if v211 < 1.1754943508222875E-38 and v211 > -1.1754943508222875E-38 and v211 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v211))
        z10 = buffer.readf32(v48, 0)
    end

    x4 = x10 + y9

    if x4 + z10 > 0 then
        z3 = x4 + (z10 + 1)
        y3 = 1 / math.sqrt(z3)
        x2 = y3 * y3
        y3 = y3 * 0.5 * (-z3 * x2 + 1) + y3
        x2 = y3 * y3
        y3 = y3 * 0.5 * (-z3 * x2 + 1) + y3
        y = z3 * y3
        z3 = y3 * 0.5
        v195 = (z8 - y11) * z3
        v196 = (x12 - z9) * z3
        v197 = (y10 - x11) * z3
        v198 = 0.5 * y
    elseif y9 < x10 and z10 < x10 then
        x = x10 + -y9 + (-z10 + 1)
        z2 = 1 / math.sqrt(x)
        y2 = z2 * z2
        z2 = z2 * 0.5 * (-x * y2 + 1) + z2
        y2 = z2 * z2
        z2 = z2 * 0.5 * (-x * y2 + 1) + z2
        x14 = x * z2
        x = z2 * 0.5
        v195 = 0.5 * x14
        v196 = (y10 + x11) * x
        v197 = (x12 + z9) * x
        v198 = (z8 - y11) * x
    elseif z10 < y9 then
        x14 = -x10 + y9 + (-z10 + 1)
        y13 = 1 / math.sqrt(x14)
        z12 = y13 * y13
        y13 = y13 * 0.5 * (-x14 * z12 + 1) + y13
        z12 = y13 * y13
        y13 = y13 * 0.5 * (-x14 * z12 + 1) + y13
        z12 = x14 * y13
        x14 = y13 * 0.5
        v195 = (y10 + x11) * x14
        v196 = 0.5 * z12
        v197 = (z8 + y11) * x14
        v198 = (x12 - z9) * x14
    else
        x14 = -x10 + -y9 + (z10 + 1)
        y13 = 1 / math.sqrt(x14)
        z12 = y13 * y13
        y13 = y13 * 0.5 * (-x14 * z12 + 1) + y13
        z12 = y13 * y13
        y13 = y13 * 0.5 * (-x14 * z12 + 1) + y13
        z12 = x14 * y13
        x14 = y13 * 0.5
        v195 = (x12 + z9) * x14
        v196 = (z8 + y11) * x14
        v197 = 0.5 * z12
        v198 = (y10 - x11) * x14
    end

    x14 = v195 * v195 + v196 * v196 + v197 * v197 + v198 * v198
    x4 = 1 / math.sqrt(x14)
    y13 = x4 * x4
    x4 = x4 * 0.5 * (-x14 * y13 + 1) + x4
    y13 = x4 * x4
    x4 = x4 * 0.5 * (-x14 * y13 + 1) + x4
    v203 = v195 * x4
    v202 = v196 * x4
    z13 = v197 * x4
    v206 = create(v203, v202, z13)
    x14 = v206.x
    y13 = v206.y
    z12 = v206.z

    if v203 < 1.1754943508222875E-38 and v203 > -1.1754943508222875E-38 and v203 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v203))
        x14 = buffer.readf32(v48, 0)
    end

    if v202 < 1.1754943508222875E-38 and v202 > -1.1754943508222875E-38 and v202 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v202))
        y13 = buffer.readf32(v48, 0)
    end

    if z13 < 1.1754943508222875E-38 and z13 > -1.1754943508222875E-38 and z13 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z13))
        z12 = buffer.readf32(v48, 0)
    end

    v203 = v198 * x4

    if v203 < 1.1754943508222875E-38 and v203 > -1.1754943508222875E-38 and v203 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v203))
    else
        buffer.writef32(v48, 0, v203)
    end

    v197 = buffer.readf32(v48, 0)
    v206 = p21.x
    v208 = p21.y
    v207 = p21.z
    v209 = create(v206, v208, v207)
    v203 = v209.x
    v202 = v209.y
    z13 = v209.z

    if v206 < 1.1754943508222875E-38 and v206 > -1.1754943508222875E-38 and v206 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v206))
        v203 = buffer.readf32(v48, 0)
    end

    if v208 < 1.1754943508222875E-38 and v208 > -1.1754943508222875E-38 and v208 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v208))
        v202 = buffer.readf32(v48, 0)
    end

    if v207 < 1.1754943508222875E-38 and v207 > -1.1754943508222875E-38 and v207 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v207))
        z13 = buffer.readf32(v48, 0)
    end

    v206 = x10 * v203
    v208 = y10 * v203
    v207 = z9 * v203
    v209 = x11 * v202
    v210 = y9 * v202
    v211 = z8 * v202
    v212 = x12 * z13

    local v213 = y11 * z13
    local v214 = z10 * z13
    local v215 = v212 * x12 + (v206 * x10 + v209 * x11)
    local v216 = v213 * x12 + (v208 * x10 + v210 * x11)
    local v217 = v214 * x12 + (v207 * x10 + v211 * x11)
    local v218 = create(v215, v216, v217)
    local x15, y14, z14 = v218.x, v218.y, v218.z

    if v215 < 1.1754943508222875E-38 and v215 > -1.1754943508222875E-38 and v215 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v215))
        x15 = buffer.readf32(v48, 0)
    end

    if v216 < 1.1754943508222875E-38 and v216 > -1.1754943508222875E-38 and v216 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v216))
        y14 = buffer.readf32(v48, 0)
    end

    if v217 < 1.1754943508222875E-38 and v217 > -1.1754943508222875E-38 and v217 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v217))
        z14 = buffer.readf32(v48, 0)
    end

    v218 = z10 * v214 + (z9 * v207 + z8 * v211)

    local v219 = y11 * v213 + (y10 * v208 + y9 * v210)
    local v220 = y11 * v214 + (y10 * v207 + y9 * v211)
    local v221 = create(v218, v219, v220)

    v215 = v221.x
    v216 = v221.y
    v217 = v221.z

    if v218 < 1.1754943508222875E-38 and v218 > -1.1754943508222875E-38 and v218 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v218))
        v215 = buffer.readf32(v48, 0)
    end

    if v219 < 1.1754943508222875E-38 and v219 > -1.1754943508222875E-38 and v219 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v219))
        v216 = buffer.readf32(v48, 0)
    end

    if v220 < 1.1754943508222875E-38 and v220 > -1.1754943508222875E-38 and v220 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v220))
        v217 = buffer.readf32(v48, 0)
    end

    return x10, y10, z9, x11, y9, z8, x12, y11, z10, x13, y12, z11, x14, y13, z12, v197, x15, y14, z14, v215, v216, v217
end

function t1.quaternion(p22) -- line: 1024
    -- upvalues: rt (copy), add (copy), sub (copy), mul (copy), rsqrt (copy), normalize (copy)
    local v222 = p22[1]
    local v223 = p22[2]
    local v224 = p22[3]
    local t3 = {
        v222[1],
        v222[1],
        -v222[1],
        -v222[1]
    }
    local t4 = {
        v223[2],
        -v223[2],
        v223[2],
        -v223[2]
    }
    local t5 = {
        v224[3],
        -v224[3],
        -v224[3],
        v224[3]
    }
    local v225 = add(t3, t4)
    local v226 = add(v225, add(t5, table.create(4, 1)))
    local v227 = rt.map(v226, rsqrt)
    local v228 = mul(v226, v227)
    local v229 = mul(table.create(4, 0.5), v227)
    local t6 = {
        v223[3],
        v224[1],
        v222[2],
        0.5
    }
    local t7 = {
        v224[2],
        v222[3],
        v223[1],
        0
    }
    local v230 = sub(t6, t7)
    local v231 = add(t6, t7)
    local v232 = mul({
        v231[3],
        v230[4],
        v231[1],
        v230[2]
    }, {
        v229[3],
        v228[3],
        v229[3],
        v229[3]
    })
    local v233 = mul({
        v231[2],
        v231[1],
        v230[4],
        v230[3]
    }, {
        v229[4],
        v229[4],
        v228[4],
        v229[4]
    })
    local v234 = mul({
        v230[4],
        v231[3],
        v231[2],
        v230[1]
    }, {
        v228[2],
        v229[2],
        v229[2],
        v229[2]
    })
    local v235 = mul(v230, {
        v229[1],
        v229[1],
        v229[1],
        v228[1]
    })

    if not (v223[2] > v224[3]) then
        v232 = v233
    end

    if v222[1] > v223[2] and v222[1] > v224[3] then
        v232 = v234
    end

    if not (v225[1] + v224[3] > 0) then
        v235 = v232
    end

    return normalize(v235, true)
end

function t1.load(p23, p24) -- line: 1049
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p23[p24 + 0 + 1])

    local v237 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 + 1 + 1])

    local v239 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 + 2 + 1])

    local v241 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p23[p24 + 3 + 1])

    return {
        v237,
        v239,
        v241,
        (buffer.readf32(v1, 0))
    }
end

function t1.store_xyz(p25, p26, p27) -- line: 1058
    -- upvalues: v1 (copy)
    local v243 = p26 + 0 + 1
    local v244 = p27[1]
    local v245

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        local v246 = math.abs(v244) * 7.1362384635298E+44
        local v247 = math.floor(v246)
        local v248 = v246 - v247

        v245 = if v248 > 0.5 or v248 == 0.5 and v247 % 2 == 1 then v247 + 1 else v247

        if v244 < 0 then
            v245 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v244)
        v245 = buffer.readu32(v1, 0)
    end

    p25[v243] = v245

    local v249 = p26 + 1 + 1
    local v250 = p27[2]
    local v251

    if v250 ~= 0 and v250 > -1.1754943508222875E-38 and v250 < 1.1754943508222875E-38 then
        local v252 = math.abs(v250) * 7.1362384635298E+44
        local v253 = math.floor(v252)
        local v254 = v252 - v253

        v251 = if v254 > 0.5 or v254 == 0.5 and v253 % 2 == 1 then v253 + 1 else v253

        if v250 < 0 then
            v251 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v250)
        v251 = buffer.readu32(v1, 0)
    end

    p25[v249] = v251

    local v255 = p26 + 2 + 1
    local v256 = p27[3]
    local v257

    if v256 ~= 0 and v256 > -1.1754943508222875E-38 and v256 < 1.1754943508222875E-38 then
        local v258 = math.abs(v256) * 7.1362384635298E+44
        local v259 = math.floor(v258)
        local v260 = v258 - v259

        v257 = if v260 > 0.5 or v260 == 0.5 and v259 % 2 == 1 then v259 + 1 else v259

        if v256 < 0 then
            v257 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v256)
        v257 = buffer.readu32(v1, 0)
    end

    p25[v255] = v257
end

return t1
