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
local v8 = import("skate_core/physics/board_pose")
local initialized_body = import("skate_core/physics/board_runtime").initialized_body
local body_pose_lanes = v8.body_pose_lanes
local v9 = import("skate_core/physics/native_arithmetic")
local v10 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v10.IDENTITY, v10.compose_affine
local inverse_rigid = import("skate_core/physics/skeleton_root").inverse_rigid

local function skeleton_body() -- line: 45
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local v11 = false
local t1 = {}

function t1.set_b3_twin(p4) -- line: 57
    -- upvalues: v11 (ref)
    v11 = p4
end

local v12

t1.SkeletonBody = {}

function t1.SkeletonBody.new(p5, p6, p7, p8) -- line: 70
    -- upvalues: rt (copy), import (copy), v8 (copy), initialized_body (copy), compose_affine (copy), inverse_rigid (copy), t1 (copy)
    local v13 = p6
    local v14 = import("skate_core/physics/skeleton_body")
    local PART_COUNT, ANIMATION_PART_COUNT, SkeletonPhysicalRecord = v14.PART_COUNT, v14.ANIMATION_PART_COUNT, v14.SkeletonPhysicalRecord
    local v15 = table.create(ANIMATION_PART_COUNT)

    for i = 1, ANIMATION_PART_COUNT do
        v15[i] = t1.floats(v8.orthonormalize_part_basis(t1.words(p6[i])))
    end

    v13 = v15

    local v16 = compose_affine(p7, inverse_rigid(v15[1]))
    local t2 = {
        definition = p5,
        bodies = rt.from_fn(PART_COUNT, function(p9) -- line: 84
            -- upvalues: v13 (ref), p5 (copy), p7 (copy), p8 (copy), ANIMATION_PART_COUNT (copy), v16 (copy), rt (copy), v8 (copy), initialized_body (copy), compose_affine (copy), t1 (copy)
            local v17 = if p9 < ANIMATION_PART_COUNT then compose_affine(v16, v13[p9 + 1]) else rt.copy(p7)
            local v18 = rt.copy(p5.parts[p9 + 1].animated)
            local v19 = rt.copy(v18.dynamics)

            if p9 >= 1 and p9 < ANIMATION_PART_COUNT then
                v19.inverse_mass = p5.parts[p9 + 1].inverse_mass_animated
            end

            local t3 = {
                transform = t1.words(v17),
                local_mass_frame = t1.mass_words(v18.local_mass_frame),
                body = table.create(44, 0),
                inertia = t1.inertia_words(v19)
            }

            v8.set_part_transform(t3, t1.words(v17))

            return initialized_body(t3, v19, p8, "Active")
        end),
        animation_to_world = v16,
        record = SkeletonPhysicalRecord.default()
    }
    local v20 = t1.SkeletonBody.part_transforms(t2)

    SkeletonPhysicalRecord.update(t2.record, v20, v20[1], t2.definition.animation_masses.fractional)
    SkeletonPhysicalRecord.update(t2.record, v20, v20[1], t2.definition.animation_masses.fractional)

    return t2
end

function t1.SkeletonBody.bodies(p10) -- line: 121
    return p10.bodies
end

function t1.SkeletonBody.bodies_mut(p11) -- line: 127
    return p11.bodies
end

function t1.SkeletonBody.set_part_transform(p12, p13, p14) -- line: 159
    -- upvalues: rt (copy), body_pose_lanes (copy), t1 (copy), v11 (ref)
    if v11 then
        return t1.SkeletonBody.set_part_transform_reference(p12, p13, p14)
    end

    local v21 = p12.bodies[p13 + 1]
    local local_mass_frame = p12.definition.parts[p13 + 1].animated.local_mass_frame
    local columns = local_mass_frame.basis.columns
    local v22 = p14[1]
    local v23 = p14[2]
    local v24 = p14[3]
    local v25 = p14[4]

    if #p14 ~= 4
        or #columns ~= 3
        or type(v22) ~= "table"
        or type(v23) ~= "table"
        or type(v24) ~= "table"
        or type(v25) ~= "table"
        or #v22 ~= 4
        or #v23 ~= 4
        or #v24 ~= 4
        or #v25 ~= 4 then
        return t1.SkeletonBody.set_part_transform_reference(p12, p13, p14)
    end

    local v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40, v41, v42, v43, v44, v45, v46, v47 = body_pose_lanes(p14, columns, local_mass_frame.translation, v21.inertia.inverse_tensor)
    local rates = v21.rates

    rates.orientation = {
        x = v38,
        y = v39,
        z = v40,
        w = v41
    }
    rates.position = {
        x = v35,
        y = v36,
        z = v37
    }
    rates.basis = {
        columns = {
            { v26, v27, v28 },
            { v29, v30, v31 },
            { v32, v33, v34 }
        }
    }
    rates.world_inverse_inertia = {
        columns = {
            { v42, v43, v44 },
            { v43, v46, v47 },
            { v44, v47, v45 }
        }
    }

    local pose = p12.record.pose
    local v48 = pose[p13 + 1]

    if type(v48) == "table" and v48 ~= p14 and #v48 == 4 then
        local v49 = v48[1]
        local v50 = v48[2]
        local v51 = v48[3]
        local v52 = v48[4]

        if type(v49) == "table" and type(v50) == "table" and type(v51) == "table" and type(v52) == "table" and #v49 == 4 and #v50 == 4 and #v51 == 4 and #v52 == 4 and v49 ~= v50 and v49 ~= v51 and v49 ~= v52 and v50 ~= v51 and v50 ~= v52 and v51 ~= v52 and v49 ~= v22 and v49 ~= v23 and v49 ~= v24 and v49 ~= v25 and v50 ~= v22 and v50 ~= v23 and v50 ~= v24 and v50 ~= v25 and v51 ~= v22 and v51 ~= v23 and v51 ~= v24 and v51 ~= v25 and v52 ~= v22 and v52 ~= v23 and v52 ~= v24 and v52 ~= v25 then
            local v53 = v22[1]
            local v54 = v22[2]
            local v55 = v22[3]
            local v56 = v22[4]

            v49[1] = v53
            v49[2] = v54
            v49[3] = v55
            v49[4] = v56

            local v57 = v23[1]
            local v58 = v23[2]
            local v59 = v23[3]
            local v60 = v23[4]

            v50[1] = v57
            v50[2] = v58
            v50[3] = v59
            v50[4] = v60

            local v61 = v24[1]
            local v62 = v24[2]
            local v63 = v24[3]
            local v64 = v24[4]

            v51[1] = v61
            v51[2] = v62
            v51[3] = v63
            v51[4] = v64

            local v65 = v25[1]
            local v66 = v25[2]
            local v67 = v25[3]
            local v68 = v25[4]

            v52[1] = v65
            v52[2] = v66
            v52[3] = v67
            v52[4] = v68

            return
        end
    end

    pose[p13 + 1] = rt.copy(p14)
end

function t1.SkeletonBody.set_part_transform_reference(p15, p16, p17) -- line: 246
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), v8 (copy), t1 (copy)
    local v69 = p15.bodies[p16 + 1]
    local t4 = {
        transform = t1.words(p17),
        local_mass_frame = t1.mass_words(p15.definition.parts[p16 + 1].animated.local_mass_frame),
        body = t1.body_words(v69.rates),
        inertia = t1.inertia_words(v69.inertia)
    }

    v8.set_part_transform(t4, t1.words(p17))

    local body = t4.body

    if body == nil then
        error("called `Option::unwrap()` on a `None` value", 0)
    end

    local function f(p18) -- line: 259
        -- upvalues: body (copy), v1 (copy)
        buffer.writeu32(v1, 0, body[p18 + 1])

        return (buffer.readf32(v1, 0))
    end

    local rates = v69.rates
    local t5 = {}

    buffer.writeu32(v1, 0, body[1])
    t5.x = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[2])
    t5.y = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[3])
    t5.z = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[4])
    t5.w = buffer.readf32(v1, 0)
    rates.orientation = t5

    local rates2 = v69.rates
    local new = Vector3.new

    buffer.writeu32(v1, 0, body[5])

    local v76 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[6])

    local v78 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[7])
    rates2.position = new(v76, v78, (buffer.readf32(v1, 0)))

    local rates3 = v69.rates
    local t6 = {}

    buffer.writeu32(v1, 0, body[17])

    local v81 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[18])

    local v83 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[19])

    local t7 = {
        v81,
        v83,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[21])

    local v86 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[22])

    local v88 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[23])

    local t8 = {
        v86,
        v88,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[25])

    local v91 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[26])

    local v93 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[27])
    t6.columns = {
        t7,
        t8,
        {
            v91,
            v93,
            (buffer.readf32(v1, 0))
        }
    }
    rates3.basis = t6

    local rates4 = v69.rates
    local t9 = {}

    buffer.writeu32(v1, 0, body[29])

    local v96 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[30])

    local v98 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[31])

    local t10 = {
        v96,
        v98,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[30])

    local v101 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[34])

    local v103 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[35])

    local t11 = {
        v101,
        v103,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[31])

    local v106 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[35])

    local v108 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[33])
    t9.columns = {
        t10,
        t11,
        {
            v106,
            v108,
            (buffer.readf32(v1, 0))
        }
    }
    rates4.world_inverse_inertia = t9
    p15.record.pose[p16 + 1] = rt.copy(p17)
end

function t1.SkeletonBody.part_transforms_reference(p19) -- line: 282
    -- upvalues: rt (copy), import (copy), v8 (copy), IDENTITY (copy), t1 (copy)
    local PART_COUNT = import("skate_core/physics/skeleton_body").PART_COUNT

    return rt.from_fn(PART_COUNT, function(p20) -- line: 284
        -- upvalues: p19 (copy), v8 (copy), IDENTITY (copy), t1 (copy)
        local t12 = {
            inertia = nil,
            transform = t1.words(IDENTITY),
            local_mass_frame = t1.mass_words(p19.definition.parts[p20 + 1].animated.local_mass_frame),
            body = t1.body_words(p19.bodies[p20 + 1].rates)
        }

        return t1.floats(v8.part_transform(t12))
    end)
end

local v110 = buffer.create(8)
local to_bits = rt.to_bits

local function f32r(p21) -- line: 304
    -- upvalues: v110 (copy), to_bits (copy)
    if p21 ~= 0 and p21 > -1.1754943508222875E-38 and p21 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(p21))

        return (buffer.readf32(v110, 0))
    end

    buffer.writef32(v110, 0, p21)

    return (buffer.readf32(v110, 0))
end

function t1.SkeletonBody.part_transforms(p22) -- line: 315
    -- upvalues: import (copy), t1 (copy), v110 (copy), to_bits (copy)
    local PART_COUNT = import("skate_core/physics/skeleton_body").PART_COUNT
    local v111 = table.create(PART_COUNT)
    local bodies = p22.bodies
    local parts = p22.definition.parts

    for i = 1, PART_COUNT do
        local rates = bodies[i].rates
        local local_mass_frame = parts[i].animated.local_mass_frame
        local columns = rates.basis.columns
        local columns2 = local_mass_frame.basis.columns

        if #columns ~= 3 or #columns2 ~= 3 then
            return t1.SkeletonBody.part_transforms_reference(p22)
        end

        local v112 = columns[1]
        local v113 = columns[2]
        local v114 = columns[3]
        local v115 = v112[1]

        if v115 == 0 then
            buffer.writef32(v110, 0, v115)
        elseif v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v115))
        else
            buffer.writef32(v110, 0, v115)
        end

        local v116 = buffer.readf32(v110, 0)

        v115 = v112[2]

        if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v115))
        else
            buffer.writef32(v110, 0, v115)
        end

        local v117 = buffer.readf32(v110, 0)

        v115 = v112[3]

        if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v115))
        else
            buffer.writef32(v110, 0, v115)
        end

        local v118 = buffer.readf32(v110, 0)
        local v119 = v113[1]

        if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v119))
        else
            buffer.writef32(v110, 0, v119)
        end

        v115 = buffer.readf32(v110, 0)
        v119 = v113[2]

        if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v119))
        else
            buffer.writef32(v110, 0, v119)
        end

        local v120 = buffer.readf32(v110, 0)

        v119 = v113[3]

        if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v119))
        else
            buffer.writef32(v110, 0, v119)
        end

        local v121 = buffer.readf32(v110, 0)
        local v122 = v114[1]

        if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v122))
        else
            buffer.writef32(v110, 0, v122)
        end

        v119 = buffer.readf32(v110, 0)
        v122 = v114[2]

        if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v122))
        else
            buffer.writef32(v110, 0, v122)
        end

        local v123 = buffer.readf32(v110, 0)

        v122 = v114[3]

        if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v122))
        else
            buffer.writef32(v110, 0, v122)
        end

        local v124 = buffer.readf32(v110, 0)
        local position = rates.position
        local v125 = position.x

        if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v125))
        else
            buffer.writef32(v110, 0, v125)
        end

        v122 = buffer.readf32(v110, 0)
        v125 = position.y

        if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v125))
        else
            buffer.writef32(v110, 0, v125)
        end

        local v126 = buffer.readf32(v110, 0)

        v125 = position.z

        if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v125))
        else
            buffer.writef32(v110, 0, v125)
        end

        local v127 = buffer.readf32(v110, 0)

        v125 = table.create(4)

        local v128, v129, v130, v131, v132, v133

        for j = 1, 3 do
            local v134 = columns2[j]

            v128 = v134[1]

            if v128 ~= 0 and v128 > -1.1754943508222875E-38 and v128 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v128))
            else
                buffer.writef32(v110, 0, v128)
            end

            v130 = buffer.readf32(v110, 0)
            v128 = v134[2]

            if v128 ~= 0 and v128 > -1.1754943508222875E-38 and v128 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v128))
            else
                buffer.writef32(v110, 0, v128)
            end

            v131 = buffer.readf32(v110, 0)
            v128 = v134[3]

            if v128 ~= 0 and v128 > -1.1754943508222875E-38 and v128 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v128))
            else
                buffer.writef32(v110, 0, v128)
            end

            v129 = buffer.readf32(v110, 0)
            v128 = {}
            v133 = v129 * v119 + (v131 * v115 + v130 * v116)

            if v133 ~= 0 and v133 > -1.1754943508222875E-38 and v133 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v133))
            else
                buffer.writef32(v110, 0, v133)
            end

            v132 = buffer.readf32(v110, 0)

            local v135 = v129 * v123 + (v131 * v120 + v130 * v117)

            if v135 ~= 0 and v135 > -1.1754943508222875E-38 and v135 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v135))
            else
                buffer.writef32(v110, 0, v135)
            end

            v133 = buffer.readf32(v110, 0)

            local v136 = v129 * v124 + (v131 * v121 + v130 * v118)

            if v136 ~= 0 and v136 > -1.1754943508222875E-38 and v136 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v136))
            else
                buffer.writef32(v110, 0, v136)
            end

            v135 = buffer.readf32(v110, 0)

            local v137 = v129 * 0 + (v131 * 0 + v130 * 0)

            if v137 ~= 0 and v137 > -1.1754943508222875E-38 and v137 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v137))
            else
                buffer.writef32(v110, 0, v137)
            end

            v136 = buffer.readf32(v110, 0)
            v128[1] = v132
            v128[2] = v133
            v128[3] = v135
            v128[4] = v136
            v125[j] = v128
        end

        local translation = local_mass_frame.translation

        v130 = translation.x

        if v130 ~= 0 and v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v130))
        else
            buffer.writef32(v110, 0, v130)
        end

        local v138 = buffer.readf32(v110, 0)

        v130 = translation.y

        if v130 ~= 0 and v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v130))
        else
            buffer.writef32(v110, 0, v130)
        end

        local v139 = buffer.readf32(v110, 0)

        v130 = translation.z

        if v130 ~= 0 and v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v130))
        else
            buffer.writef32(v110, 0, v130)
        end

        local v140 = buffer.readf32(v110, 0)

        v130 = {}
        v129 = v140 * v119 + (v139 * v115 + (v138 * v116 + v122))

        if v129 ~= 0 and v129 > -1.1754943508222875E-38 and v129 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v129))
        else
            buffer.writef32(v110, 0, v129)
        end

        v131 = buffer.readf32(v110, 0)
        v128 = v140 * v123 + (v139 * v120 + (v138 * v117 + v126))

        if v128 ~= 0 and v128 > -1.1754943508222875E-38 and v128 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v128))
        else
            buffer.writef32(v110, 0, v128)
        end

        v129 = buffer.readf32(v110, 0)
        v132 = v140 * v124 + (v139 * v121 + (v138 * v118 + v127))

        if v132 ~= 0 and v132 > -1.1754943508222875E-38 and v132 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v132))
        else
            buffer.writef32(v110, 0, v132)
        end

        v128 = buffer.readf32(v110, 0)
        v133 = v140 * 0 + (v139 * 0 + (v138 * 0 + 0))

        if v133 ~= 0 and v133 > -1.1754943508222875E-38 and v133 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v133))
        else
            buffer.writef32(v110, 0, v133)
        end

        v132 = buffer.readf32(v110, 0)
        v130[1] = v131
        v130[2] = v129
        v130[3] = v128
        v130[4] = v132
        v125[4] = v130
        v111[i] = v125
    end

    return v111
end

function t1.SkeletonBody.pose_scratch() -- line: 362
    -- upvalues: import (copy)
    local PART_COUNT = import("skate_core/physics/skeleton_body").PART_COUNT
    local v141 = table.create(PART_COUNT)

    for i = 1, PART_COUNT do
        v141[i] = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
    end

    return v141
end

local create = vector.create

local function tiny(p23) -- line: 396
    -- upvalues: v110 (copy), to_bits (copy)
    buffer.writeu32(v110, 0, to_bits(p23))

    return (buffer.readf32(v110, 0))
end

function t1.SkeletonBody.part_transforms_into(p24, p25) -- line: 401
    -- upvalues: import (copy), t1 (copy), v11 (ref), v12 (ref), v110 (copy), to_bits (copy), create (copy)
    if v11 then
        return t1.SkeletonBody.part_transforms_into_r3(p24, p25)
    end

    local v142 = v12

    if v142 == nil then
        v142 = import("skate_core/physics/skeleton_body").PART_COUNT
        v12 = v142
    end

    local bodies = p24.bodies
    local parts = p24.definition.parts

    for i = 1, v142 do
        local rates = bodies[i].rates
        local local_mass_frame = parts[i].animated.local_mass_frame
        local v143 = rates.basis.columns
        local columns = local_mass_frame.basis.columns

        if #v143 ~= 3 or #columns ~= 3 then
            return t1.SkeletonBody.part_transforms_reference(p24)
        end

        local v144 = v143[1]
        local v145 = v143[2]
        local v146 = v143[3]
        local position = rates.position
        local v147 = p25[i]
        local x = v144[1]
        local v148 = v144[2]
        local v149 = v144[3]
        local x2 = create(x, v148, v149)
        local x3, y, z = x2.x, x2.y, x2.z

        if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
            buffer.writeu32(v110, 0, to_bits(x))
            x3 = buffer.readf32(v110, 0)
        end

        local v150

        if not (v148 < 1.1754943508222875E-38) or not (v148 > -1.1754943508222875E-38) or v148 == 0 then
            v150 = y
        else
            buffer.writeu32(v110, 0, to_bits(v148))
            v150 = buffer.readf32(v110, 0)
        end

        local v151

        if not (v149 < 1.1754943508222875E-38) or not (v149 > -1.1754943508222875E-38) or v149 == 0 then
            v151 = z
        else
            buffer.writeu32(v110, 0, to_bits(v149))
            v151 = buffer.readf32(v110, 0)
        end

        x2 = v145[1]

        local y2 = v145[2]
        local z2 = v145[3]
        local x4 = create(x2, y2, z2)

        x = x4.x

        local y3, z3 = x4.y, x4.z

        if x2 < 1.1754943508222875E-38 and x2 > -1.1754943508222875E-38 and x2 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(x2))
            x = buffer.readf32(v110, 0)
        end

        if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(y2))
            y3 = buffer.readf32(v110, 0)
        end

        if z2 < 1.1754943508222875E-38 and z2 > -1.1754943508222875E-38 and z2 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z2))
            z3 = buffer.readf32(v110, 0)
        end

        x4 = v146[1]

        local y4 = v146[2]
        local z4 = v146[3]
        local x5 = create(x4, y4, z4)

        x2 = x5.x
        y2 = x5.y
        z2 = x5.z

        if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(x4))
            x2 = buffer.readf32(v110, 0)
        end

        if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(y4))
            y2 = buffer.readf32(v110, 0)
        end

        if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z4))
            z2 = buffer.readf32(v110, 0)
        end

        x5 = position.x

        local y5, y6 = position.y, position.z
        local z5 = create(x5, y5, y6)

        x4 = z5.x
        y4 = z5.y
        z4 = z5.z

        if x5 < 1.1754943508222875E-38 and x5 > -1.1754943508222875E-38 and x5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(x5))
            x4 = buffer.readf32(v110, 0)
        end

        if y5 < 1.1754943508222875E-38 and y5 > -1.1754943508222875E-38 and y5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(y5))
            y4 = buffer.readf32(v110, 0)
        end

        if y6 < 1.1754943508222875E-38 and y6 > -1.1754943508222875E-38 and y6 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(y6))
            z4 = buffer.readf32(v110, 0)
        end

        v143 = columns[1]
        z5 = v143[1]

        local v152 = v143[2]
        local v153 = v143[3]
        local v154 = create(z5, v152, v153)

        x5 = v154.x
        y5 = v154.y
        y6 = v154.z

        if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z5))
            x5 = buffer.readf32(v110, 0)
        end

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y5 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y6 = buffer.readf32(v110, 0)
        end

        v143 = v147[1]
        z5 = y6 * x2 + (y5 * x + x5 * x3)
        v152 = y6 * y2 + (y5 * y3 + x5 * v150)
        v153 = y6 * z2 + (y5 * z3 + x5 * v151)
        v154 = create(z5, v152, v153)

        local x6, y7, y8 = v154.x, v154.y, v154.z

        if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z5))
            x6 = buffer.readf32(v110, 0)
        end

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y7 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y8 = buffer.readf32(v110, 0)
        end

        v143[1] = x6
        v143[2] = y7
        v143[3] = y8
        v143[4] = y6 * 0 + (y5 * 0 + x5 * 0)
        x5 = columns[2]
        v152 = x5[1]
        v153 = x5[2]
        v154 = x5[3]
        x6 = create(v152, v153, v154)
        y5 = x6.x
        y6 = x6.y
        z5 = x6.z

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y5 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y6 = buffer.readf32(v110, 0)
        end

        if v154 < 1.1754943508222875E-38 and v154 > -1.1754943508222875E-38 and v154 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v154))
            z5 = buffer.readf32(v110, 0)
        end

        x5 = v147[2]
        v152 = z5 * x2 + (y6 * x + y5 * x3)
        v153 = z5 * y2 + (y6 * y3 + y5 * v150)
        v154 = z5 * z2 + (y6 * z3 + y5 * v151)
        x6 = create(v152, v153, v154)
        y7 = x6.x
        y8 = x6.y

        local z6 = x6.z

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y7 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y8 = buffer.readf32(v110, 0)
        end

        if v154 < 1.1754943508222875E-38 and v154 > -1.1754943508222875E-38 and v154 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v154))
            z6 = buffer.readf32(v110, 0)
        end

        x5[1] = y7
        x5[2] = y8
        x5[3] = z6
        x5[4] = z5 * 0 + (y6 * 0 + y5 * 0)
        x5 = columns[3]
        v152 = x5[1]
        v153 = x5[2]
        v154 = x5[3]
        x6 = create(v152, v153, v154)
        y5 = x6.x
        y6 = x6.y
        z5 = x6.z

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y5 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y6 = buffer.readf32(v110, 0)
        end

        if v154 < 1.1754943508222875E-38 and v154 > -1.1754943508222875E-38 and v154 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v154))
            z5 = buffer.readf32(v110, 0)
        end

        x5 = v147[3]
        v152 = z5 * x2 + (y6 * x + y5 * x3)
        v153 = z5 * y2 + (y6 * y3 + y5 * v150)
        v154 = z5 * z2 + (y6 * z3 + y5 * v151)
        x6 = create(v152, v153, v154)
        y7 = x6.x
        y8 = x6.y
        z6 = x6.z

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y7 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y8 = buffer.readf32(v110, 0)
        end

        if v154 < 1.1754943508222875E-38 and v154 > -1.1754943508222875E-38 and v154 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v154))
            z6 = buffer.readf32(v110, 0)
        end

        x5[1] = y7
        x5[2] = y8
        x5[3] = z6
        x5[4] = z5 * 0 + (y6 * 0 + y5 * 0)
        columns = local_mass_frame.translation
        z5 = columns.x
        v152 = columns.y
        v153 = columns.z
        v154 = create(z5, v152, v153)
        x5 = v154.x
        y5 = v154.y
        y6 = v154.z

        if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z5))
            x5 = buffer.readf32(v110, 0)
        end

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y5 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y6 = buffer.readf32(v110, 0)
        end

        columns = v147[4]
        z5 = y6 * x2 + (y5 * x + (x5 * x3 + x4))
        v152 = y6 * y2 + (y5 * y3 + (x5 * v150 + y4))
        v153 = y6 * z2 + (y5 * z3 + (x5 * v151 + z4))
        v154 = create(z5, v152, v153)
        x6 = v154.x
        y7 = v154.y
        y8 = v154.z

        if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(z5))
            x6 = buffer.readf32(v110, 0)
        end

        if v152 < 1.1754943508222875E-38 and v152 > -1.1754943508222875E-38 and v152 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v152))
            y7 = buffer.readf32(v110, 0)
        end

        if v153 < 1.1754943508222875E-38 and v153 > -1.1754943508222875E-38 and v153 ~= 0 then
            buffer.writeu32(v110, 0, to_bits(v153))
            y8 = buffer.readf32(v110, 0)
        end

        columns[1] = x6
        columns[2] = y7
        columns[3] = y8
        columns[4] = y6 * 0 + (y5 * 0 + (x5 * 0 + 0))
    end

    return p25
end

function t1.SkeletonBody.part_transforms_into_r3(p26, p27) -- line: 629
    -- upvalues: import (copy), t1 (copy), v110 (copy), to_bits (copy)
    local PART_COUNT = import("skate_core/physics/skeleton_body").PART_COUNT
    local bodies = p26.bodies
    local parts = p26.definition.parts

    for i = 1, PART_COUNT do
        local rates = bodies[i].rates
        local local_mass_frame = parts[i].animated.local_mass_frame
        local columns = rates.basis.columns
        local columns2 = local_mass_frame.basis.columns

        if #columns ~= 3 or #columns2 ~= 3 then
            return t1.SkeletonBody.part_transforms_reference(p26)
        end

        local v155 = columns[1]
        local v156 = columns[2]
        local v157 = columns[3]
        local v158 = v155[1]

        if v158 == 0 then
            buffer.writef32(v110, 0, v158)
        elseif v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v158))
        else
            buffer.writef32(v110, 0, v158)
        end

        local v159 = buffer.readf32(v110, 0)

        v158 = v155[2]

        if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v158))
        else
            buffer.writef32(v110, 0, v158)
        end

        local v160 = buffer.readf32(v110, 0)

        v158 = v155[3]

        if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v158))
        else
            buffer.writef32(v110, 0, v158)
        end

        local v161 = buffer.readf32(v110, 0)
        local v162 = v156[1]

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v162))
        else
            buffer.writef32(v110, 0, v162)
        end

        v158 = buffer.readf32(v110, 0)
        v162 = v156[2]

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v162))
        else
            buffer.writef32(v110, 0, v162)
        end

        local v163 = buffer.readf32(v110, 0)

        v162 = v156[3]

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v162))
        else
            buffer.writef32(v110, 0, v162)
        end

        local v164 = buffer.readf32(v110, 0)
        local v165 = v157[1]

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v165))
        else
            buffer.writef32(v110, 0, v165)
        end

        v162 = buffer.readf32(v110, 0)
        v165 = v157[2]

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v165))
        else
            buffer.writef32(v110, 0, v165)
        end

        local v166 = buffer.readf32(v110, 0)

        v165 = v157[3]

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v165))
        else
            buffer.writef32(v110, 0, v165)
        end

        local v167 = buffer.readf32(v110, 0)
        local v168 = rates.position
        local v169 = v168.x

        if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v169))
        else
            buffer.writef32(v110, 0, v169)
        end

        v165 = buffer.readf32(v110, 0)
        v169 = v168.y

        if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v169))
        else
            buffer.writef32(v110, 0, v169)
        end

        local v170 = buffer.readf32(v110, 0)

        v169 = v168.z

        if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v169))
        else
            buffer.writef32(v110, 0, v169)
        end

        local v171 = buffer.readf32(v110, 0)

        v168 = p27[i]

        local v172, v173

        for j = 1, 3 do
            local v174 = columns2[j]
            local v175 = v174[1]

            if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v175))
            else
                buffer.writef32(v110, 0, v175)
            end

            v172 = buffer.readf32(v110, 0)
            v175 = v174[2]

            if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v175))
            else
                buffer.writef32(v110, 0, v175)
            end

            v173 = buffer.readf32(v110, 0)
            v175 = v174[3]

            if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v175))
            else
                buffer.writef32(v110, 0, v175)
            end

            local v176 = buffer.readf32(v110, 0)

            v174 = v168[j]

            local v177 = v176 * v162 + (v173 * v158 + v172 * v159)

            if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v177))
            else
                buffer.writef32(v110, 0, v177)
            end

            v174[1] = buffer.readf32(v110, 0)
            v177 = v176 * v166 + (v173 * v163 + v172 * v160)

            if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v177))
            else
                buffer.writef32(v110, 0, v177)
            end

            v174[2] = buffer.readf32(v110, 0)
            v177 = v176 * v167 + (v173 * v164 + v172 * v161)

            if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v177))
            else
                buffer.writef32(v110, 0, v177)
            end

            v174[3] = buffer.readf32(v110, 0)
            v177 = v176 * 0 + (v173 * 0 + v172 * 0)

            if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
                buffer.writeu32(v110, 0, to_bits(v177))
            else
                buffer.writef32(v110, 0, v177)
            end

            v174[4] = buffer.readf32(v110, 0)
        end

        local v178 = local_mass_frame.translation

        v172 = v178.x

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v172))
        else
            buffer.writef32(v110, 0, v172)
        end

        v169 = buffer.readf32(v110, 0)
        v172 = v178.y

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v172))
        else
            buffer.writef32(v110, 0, v172)
        end

        local v179 = buffer.readf32(v110, 0)

        v172 = v178.z

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v172))
        else
            buffer.writef32(v110, 0, v172)
        end

        local v180 = buffer.readf32(v110, 0)

        v178 = v168[4]
        v173 = v180 * v162 + (v179 * v158 + (v169 * v159 + v165))

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v173))
        else
            buffer.writef32(v110, 0, v173)
        end

        v178[1] = buffer.readf32(v110, 0)
        v173 = v180 * v166 + (v179 * v163 + (v169 * v160 + v170))

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v173))
        else
            buffer.writef32(v110, 0, v173)
        end

        v178[2] = buffer.readf32(v110, 0)
        v173 = v180 * v167 + (v179 * v164 + (v169 * v161 + v171))

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v173))
        else
            buffer.writef32(v110, 0, v173)
        end

        v178[3] = buffer.readf32(v110, 0)
        v173 = v180 * 0 + (v179 * 0 + (v169 * 0 + 0))

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v110, 0, to_bits(v173))
        else
            buffer.writef32(v110, 0, v173)
        end

        v178[4] = buffer.readf32(v110, 0)
    end

    return p27
end

function t1.SkeletonBody.part_translation_reference(p28, p29) -- line: 675
    -- upvalues: rt (copy), t1 (copy)
    return rt.copy(t1.SkeletonBody.part_transforms_reference(p28)[p29 + 1][4])
end

function t1.SkeletonBody.part_translation(p30, p31) -- line: 687
    -- upvalues: t1 (copy), v11 (ref), v110 (copy), to_bits (copy), create (copy)
    if v11 then
        return t1.SkeletonBody.part_translation_r3(p30, p31)
    end

    local rates = p30.bodies[p31 + 1].rates
    local local_mass_frame = p30.definition.parts[p31 + 1].animated.local_mass_frame
    local columns = rates.basis.columns

    if #columns ~= 3 or #local_mass_frame.basis.columns ~= 3 then
        return t1.SkeletonBody.part_translation_reference(p30, p31)
    end

    local v181 = columns[1]
    local v182 = columns[2]
    local v183 = columns[3]
    local position = rates.position
    local translation = local_mass_frame.translation
    local v184 = v181[1]
    local v185 = v181[2]
    local v186 = v181[3]
    local v187 = create(v184, v185, v186)
    local x, y, z = v187.x, v187.y, v187.z

    if v184 < 1.1754943508222875E-38 and v184 > -1.1754943508222875E-38 and v184 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v184))
        x = buffer.readf32(v110, 0)
    end

    if v185 < 1.1754943508222875E-38 and v185 > -1.1754943508222875E-38 and v185 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v185))
        y = buffer.readf32(v110, 0)
    end

    if v186 < 1.1754943508222875E-38 and v186 > -1.1754943508222875E-38 and v186 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v186))
        z = buffer.readf32(v110, 0)
    end

    local v188 = v182[1]
    local v189 = v182[2]
    local v190 = v182[3]
    local v191 = create(v188, v189, v190)
    local x2, y2, z2 = v191.x, v191.y, v191.z

    if v188 < 1.1754943508222875E-38 and v188 > -1.1754943508222875E-38 and v188 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v188))
        x2 = buffer.readf32(v110, 0)
    end

    if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v189))
        y2 = buffer.readf32(v110, 0)
    end

    if v190 < 1.1754943508222875E-38 and v190 > -1.1754943508222875E-38 and v190 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v190))
        z2 = buffer.readf32(v110, 0)
    end

    local v192 = v183[1]
    local v193 = v183[2]
    local v194 = v183[3]
    local v195 = create(v192, v193, v194)
    local x3, y3, z3 = v195.x, v195.y, v195.z

    if v192 < 1.1754943508222875E-38 and v192 > -1.1754943508222875E-38 and v192 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v192))
        x3 = buffer.readf32(v110, 0)
    end

    if v193 < 1.1754943508222875E-38 and v193 > -1.1754943508222875E-38 and v193 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v193))
        y3 = buffer.readf32(v110, 0)
    end

    if v194 < 1.1754943508222875E-38 and v194 > -1.1754943508222875E-38 and v194 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v194))
        z3 = buffer.readf32(v110, 0)
    end

    local x4, y4, z4 = position.x, position.y, position.z
    local v196 = create(x4, y4, z4)
    local x5, y5, z5 = v196.x, v196.y, v196.z

    if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(x4))
        x5 = buffer.readf32(v110, 0)
    end

    if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(y4))
        y5 = buffer.readf32(v110, 0)
    end

    if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(z4))
        z5 = buffer.readf32(v110, 0)
    end

    local x6, y6, z6 = translation.x, translation.y, translation.z
    local v197 = create(x6, y6, z6)
    local x7, y7, z7 = v197.x, v197.y, v197.z

    if x6 < 1.1754943508222875E-38 and x6 > -1.1754943508222875E-38 and x6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(x6))
        x7 = buffer.readf32(v110, 0)
    end

    if y6 < 1.1754943508222875E-38 and y6 > -1.1754943508222875E-38 and y6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(y6))
        y7 = buffer.readf32(v110, 0)
    end

    if z6 < 1.1754943508222875E-38 and z6 > -1.1754943508222875E-38 and z6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(z6))
        z7 = buffer.readf32(v110, 0)
    end

    local v198 = z7 * x3 + (y7 * x2 + (x7 * x + x5))
    local v199 = z7 * y3 + (y7 * y2 + (x7 * y + y5))
    local v200 = z7 * z3 + (y7 * z2 + (x7 * z + z5))
    local v201 = create(v198, v199, v200)
    local x8, y8, z8 = v201.x, v201.y, v201.z

    if v198 < 1.1754943508222875E-38 and v198 > -1.1754943508222875E-38 and v198 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v198))
        x8 = buffer.readf32(v110, 0)
    end

    if v199 < 1.1754943508222875E-38 and v199 > -1.1754943508222875E-38 and v199 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v199))
        y8 = buffer.readf32(v110, 0)
    end

    if v200 < 1.1754943508222875E-38 and v200 > -1.1754943508222875E-38 and v200 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v200))
        z8 = buffer.readf32(v110, 0)
    end

    return {
        x8,
        y8,
        z8,
        z7 * 0 + (y7 * 0 + (x7 * 0 + 0))
    }
end

function t1.SkeletonBody.part_translation_into(p32, p33, p34) -- line: 799
    -- upvalues: v110 (copy), to_bits (copy), create (copy)
    local rates = p32.bodies[p33 + 1].rates
    local local_mass_frame = p32.definition.parts[p33 + 1].animated.local_mass_frame
    local columns = rates.basis.columns

    if #columns ~= 3 or #local_mass_frame.basis.columns ~= 3 then
        return false
    end

    local v202 = columns[1]
    local v203 = columns[2]
    local v204 = columns[3]
    local position = rates.position
    local translation = local_mass_frame.translation
    local v205 = v202[1]
    local v206 = v202[2]
    local v207 = v202[3]
    local v208 = create(v205, v206, v207)
    local x, y, z = v208.x, v208.y, v208.z

    if v205 < 1.1754943508222875E-38 and v205 > -1.1754943508222875E-38 and v205 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v205))
        x = buffer.readf32(v110, 0)
    end

    if v206 < 1.1754943508222875E-38 and v206 > -1.1754943508222875E-38 and v206 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v206))
        y = buffer.readf32(v110, 0)
    end

    if v207 < 1.1754943508222875E-38 and v207 > -1.1754943508222875E-38 and v207 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v207))
        z = buffer.readf32(v110, 0)
    end

    local v209 = v203[1]
    local v210 = v203[2]
    local v211 = v203[3]
    local v212 = create(v209, v210, v211)
    local x2, y2, z2 = v212.x, v212.y, v212.z

    if v209 < 1.1754943508222875E-38 and v209 > -1.1754943508222875E-38 and v209 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v209))
        x2 = buffer.readf32(v110, 0)
    end

    if v210 < 1.1754943508222875E-38 and v210 > -1.1754943508222875E-38 and v210 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v210))
        y2 = buffer.readf32(v110, 0)
    end

    if v211 < 1.1754943508222875E-38 and v211 > -1.1754943508222875E-38 and v211 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v211))
        z2 = buffer.readf32(v110, 0)
    end

    local v213 = v204[1]
    local v214 = v204[2]
    local v215 = v204[3]
    local v216 = create(v213, v214, v215)
    local x3, y3, z3 = v216.x, v216.y, v216.z

    if v213 < 1.1754943508222875E-38 and v213 > -1.1754943508222875E-38 and v213 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v213))
        x3 = buffer.readf32(v110, 0)
    end

    if v214 < 1.1754943508222875E-38 and v214 > -1.1754943508222875E-38 and v214 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v214))
        y3 = buffer.readf32(v110, 0)
    end

    if v215 < 1.1754943508222875E-38 and v215 > -1.1754943508222875E-38 and v215 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v215))
        z3 = buffer.readf32(v110, 0)
    end

    local x4, y4, z4 = position.x, position.y, position.z
    local v217 = create(x4, y4, z4)
    local x5, y5, z5 = v217.x, v217.y, v217.z

    if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(x4))
        x5 = buffer.readf32(v110, 0)
    end

    if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(y4))
        y5 = buffer.readf32(v110, 0)
    end

    if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(z4))
        z5 = buffer.readf32(v110, 0)
    end

    local x6, y6, z6 = translation.x, translation.y, translation.z
    local v218 = create(x6, y6, z6)
    local x7, y7, z7 = v218.x, v218.y, v218.z

    if x6 < 1.1754943508222875E-38 and x6 > -1.1754943508222875E-38 and x6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(x6))
        x7 = buffer.readf32(v110, 0)
    end

    if y6 < 1.1754943508222875E-38 and y6 > -1.1754943508222875E-38 and y6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(y6))
        y7 = buffer.readf32(v110, 0)
    end

    if z6 < 1.1754943508222875E-38 and z6 > -1.1754943508222875E-38 and z6 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(z6))
        z7 = buffer.readf32(v110, 0)
    end

    local v219 = z7 * x3 + (y7 * x2 + (x7 * x + x5))
    local v220 = z7 * y3 + (y7 * y2 + (x7 * y + y5))
    local v221 = z7 * z3 + (y7 * z2 + (x7 * z + z5))
    local v222 = create(v219, v220, v221)
    local x8, y8, z8 = v222.x, v222.y, v222.z

    if v219 < 1.1754943508222875E-38 and v219 > -1.1754943508222875E-38 and v219 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v219))
        x8 = buffer.readf32(v110, 0)
    end

    if v220 < 1.1754943508222875E-38 and v220 > -1.1754943508222875E-38 and v220 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v220))
        y8 = buffer.readf32(v110, 0)
    end

    if v221 < 1.1754943508222875E-38 and v221 > -1.1754943508222875E-38 and v221 ~= 0 then
        buffer.writeu32(v110, 0, to_bits(v221))
        z8 = buffer.readf32(v110, 0)
    end

    local v223 = z7 * 0 + (y7 * 0 + (x7 * 0 + 0))

    p34[1] = x8
    p34[2] = y8
    p34[3] = z8
    p34[4] = v223

    return true
end

function t1.SkeletonBody.part_translation_r3(p35, p36) -- line: 903
    -- upvalues: import (copy), t1 (copy), v110 (copy), to_bits (copy)
    local local_mass_frame = p35.bodies
    local parts = p35.definition.parts

    for i = 1, import("skate_core/physics/skeleton_body").PART_COUNT do
        if #local_mass_frame[i].rates.basis.columns ~= 3 or #parts[i].animated.local_mass_frame.basis.columns ~= 3 then
            return t1.SkeletonBody.part_translation_reference(p35, p36)
        end
    end

    local rates = local_mass_frame[p36 + 1].rates

    local_mass_frame = parts[p36 + 1].animated.local_mass_frame
    parts = rates.basis.columns

    local v224 = parts[1]
    local v225 = parts[2]
    local v226 = parts[3]
    local v227 = v224[1]

    if v227 == 0 then
        buffer.writef32(v110, 0, v227)
    elseif v227 > -1.1754943508222875E-38 and v227 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v227))
    else
        buffer.writef32(v110, 0, v227)
    end

    local v228 = buffer.readf32(v110, 0)

    v227 = v224[2]

    if v227 == 0 then
        buffer.writef32(v110, 0, v227)
    elseif v227 > -1.1754943508222875E-38 and v227 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v227))
    else
        buffer.writef32(v110, 0, v227)
    end

    local v229 = buffer.readf32(v110, 0)

    v227 = v224[3]

    if v227 == 0 then
        buffer.writef32(v110, 0, v227)
    elseif v227 > -1.1754943508222875E-38 and v227 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v227))
    else
        buffer.writef32(v110, 0, v227)
    end

    local v230 = buffer.readf32(v110, 0)
    local v231 = v225[1]

    if v231 == 0 then
        buffer.writef32(v110, 0, v231)
    elseif v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v231))
    else
        buffer.writef32(v110, 0, v231)
    end

    local v232 = buffer.readf32(v110, 0)

    v231 = v225[2]

    if v231 == 0 then
        buffer.writef32(v110, 0, v231)
    elseif v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v231))
    else
        buffer.writef32(v110, 0, v231)
    end

    local v233 = buffer.readf32(v110, 0)

    v231 = v225[3]

    if v231 == 0 then
        buffer.writef32(v110, 0, v231)
    elseif v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v231))
    else
        buffer.writef32(v110, 0, v231)
    end

    local v234 = buffer.readf32(v110, 0)
    local v235 = v226[1]

    if v235 == 0 then
        buffer.writef32(v110, 0, v235)
    elseif v235 > -1.1754943508222875E-38 and v235 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v235))
    else
        buffer.writef32(v110, 0, v235)
    end

    local v236 = buffer.readf32(v110, 0)

    v235 = v226[2]

    if v235 == 0 then
        buffer.writef32(v110, 0, v235)
    elseif v235 > -1.1754943508222875E-38 and v235 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v235))
    else
        buffer.writef32(v110, 0, v235)
    end

    local v237 = buffer.readf32(v110, 0)

    v235 = v226[3]

    if v235 == 0 then
        buffer.writef32(v110, 0, v235)
    elseif v235 > -1.1754943508222875E-38 and v235 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v235))
    else
        buffer.writef32(v110, 0, v235)
    end

    local v238 = buffer.readf32(v110, 0)

    v226 = rates.position

    local y = v226.x

    if y == 0 then
        buffer.writef32(v110, 0, y)
    elseif y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(y))
    else
        buffer.writef32(v110, 0, y)
    end

    local v239 = buffer.readf32(v110, 0)

    y = v226.y

    if y == 0 then
        buffer.writef32(v110, 0, y)
    elseif y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(y))
    else
        buffer.writef32(v110, 0, y)
    end

    local v240 = buffer.readf32(v110, 0)

    y = v226.z

    if y == 0 then
        buffer.writef32(v110, 0, y)
    elseif y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(y))
    else
        buffer.writef32(v110, 0, y)
    end

    local v241 = buffer.readf32(v110, 0)

    v226 = local_mass_frame.translation

    local v242 = v226.x

    if v242 == 0 then
        buffer.writef32(v110, 0, v242)
    elseif v242 > -1.1754943508222875E-38 and v242 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v242))
    else
        buffer.writef32(v110, 0, v242)
    end

    local v243 = buffer.readf32(v110, 0)

    v242 = v226.y

    if v242 == 0 then
        buffer.writef32(v110, 0, v242)
    elseif v242 > -1.1754943508222875E-38 and v242 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v242))
    else
        buffer.writef32(v110, 0, v242)
    end

    local v244 = buffer.readf32(v110, 0)

    v242 = v226.z

    if v242 == 0 then
        buffer.writef32(v110, 0, v242)
    elseif v242 > -1.1754943508222875E-38 and v242 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v242))
    else
        buffer.writef32(v110, 0, v242)
    end

    local v245 = buffer.readf32(v110, 0)

    v242 = {}

    local v246 = v245 * v236 + (v244 * v232 + (v243 * v228 + v239))

    if v246 == 0 then
        buffer.writef32(v110, 0, v246)
    elseif v246 > -1.1754943508222875E-38 and v246 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v246))
    else
        buffer.writef32(v110, 0, v246)
    end

    local v247 = buffer.readf32(v110, 0)
    local v248 = v245 * v237 + (v244 * v233 + (v243 * v229 + v240))

    if v248 == 0 then
        buffer.writef32(v110, 0, v248)
    elseif v248 > -1.1754943508222875E-38 and v248 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v248))
    else
        buffer.writef32(v110, 0, v248)
    end

    local v249 = buffer.readf32(v110, 0)
    local v250 = v245 * v238 + (v244 * v234 + (v243 * v230 + v241))

    if v250 == 0 then
        buffer.writef32(v110, 0, v250)
    elseif v250 > -1.1754943508222875E-38 and v250 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v250))
    else
        buffer.writef32(v110, 0, v250)
    end

    local v251 = buffer.readf32(v110, 0)
    local v252 = v245 * 0 + (v244 * 0 + (v243 * 0 + 0))

    if v252 == 0 then
        buffer.writef32(v110, 0, v252)
    elseif v252 > -1.1754943508222875E-38 and v252 < 1.1754943508222875E-38 then
        buffer.writeu32(v110, 0, to_bits(v252))
    else
        buffer.writef32(v110, 0, v252)
    end

    local v253 = buffer.readf32(v110, 0)

    v242[1] = v247
    v242[2] = v249
    v242[3] = v251
    v242[4] = v253

    return v242
end

function t1.SkeletonBody.publish_physical_record_reference(p37, p38) -- line: 932
    -- upvalues: import (copy), t1 (copy)
    local v254 = t1.SkeletonBody.part_transforms_reference(p37)

    import("skate_core/physics/skeleton_body").SkeletonPhysicalRecord.update(p37.record, v254, p38, p37.definition.animation_masses.fractional)
end

local v255

function t1.SkeletonBody.publish_physical_record(p39, p40) -- line: 946
    -- upvalues: import (copy), t1 (copy), v255 (ref)
    local v256 = v255

    if v256 == nil then
        v256 = t1.SkeletonBody.pose_scratch()
        v255 = v256
    end

    local v257 = t1.SkeletonBody.part_transforms_into(p39, v256)

    import("skate_core/physics/skeleton_body").SkeletonPhysicalRecord.update(p39.record, v257, p40, p39.definition.animation_masses.fractional)
end

function t1.SkeletonBody.apply_part_displacement(p41, p42, p43) -- line: 962
    -- upvalues: v9 (copy)
    local v258 = v9.reciprocal_estimate(0.01666666753590107)
    local v259 = v258 * (-v258 * 0.01666666753590107 + 1) + v258
    local v260 = v259 * (-v259 * 0.01666666753590107 + 1) + v259
    local v261 = p41.bodies[p42 + 1]
    local v262 = table.create(4)

    v262[1] = p43[1] * v260 * v261.inertia.inverse_mass
    v262[2] = p43[2] * v260 * v261.inertia.inverse_mass
    v262[3] = p43[3] * v260 * v261.inertia.inverse_mass
    v262[4] = p43[4] * v260 * v261.inertia.inverse_mass
    v261.rates.force_acceleration.x += v262[1]
    v261.rates.force_acceleration.y += v262[2]
    v261.rates.force_acceleration.z += v262[3]
    v261.rates.cool_down = 0
end

function t1.words(p44) -- line: 980
    -- upvalues: v1 (copy)
    local v263 = table.create(16)

    for i = 0, 3 do
        local v264 = p44[i + 1]

        for j = 0, 3 do
            local v265 = i * 4 + j + 1
            local v266 = v264[j + 1]

            if v266 ~= 0 and v266 > -1.1754943508222875E-38 and v266 < 1.1754943508222875E-38 then
                local v267 = math.abs(v266) * 7.1362384635298E+44
                local v268 = math.floor(v267)
                local v269 = v267 - v268
                local v270 = if v269 > 0.5 or v269 == 0.5 and v268 % 2 == 1 then v268 + 1 else v268

                if v266 < 0 then
                    v263[v265] = v270 + 2147483648
                else
                    v263[v265] = v270
                end
            else
                buffer.writef32(v1, 0, v266)
                v263[v265] = buffer.readu32(v1, 0)
            end
        end
    end

    return v263
end

function t1.floats(p45) -- line: 992
    -- upvalues: v1 (copy)
    local v271 = table.create(4)

    for i = 0, 3 do
        local v272 = table.create(4)

        for j = 0, 3 do
            local v273 = j + 1

            buffer.writeu32(v1, 0, p45[i * 4 + j + 1])
            v272[v273] = buffer.readf32(v1, 0)
        end

        v271[i + 1] = v272
    end

    return v271
end

function t1.mass_words(p46) -- line: 1005
    -- upvalues: rt (copy), IDENTITY (copy), t1 (copy)
    local v275 = rt.copy(IDENTITY)

    for i = 0, #p46.basis.columns - 1 do
        local v276 = p46.basis.columns[i + 1]

        v275[i + 1][1] = v276[1]
        v275[i + 1][2] = v276[2]
        v275[i + 1][3] = v276[3]
    end

    v275[4] = {
        p46.translation.x,
        p46.translation.y,
        p46.translation.z,
        0
    }

    return t1.words(v275)
end

function t1.inertia_words(p47) -- line: 1018
    -- upvalues: v1 (copy)
    local x = p47.inverse_tensor.x
    local v277

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v278 = math.abs(x) * 7.1362384635298E+44
        local v279 = math.floor(v278)
        local v280 = v278 - v279

        v277 = if v280 > 0.5 or v280 == 0.5 and v279 % 2 == 1 then v279 + 1 else v279

        if x < 0 then
            v277 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v277 = buffer.readu32(v1, 0)
    end

    local y = p47.inverse_tensor.y
    local v281

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v282 = math.abs(y) * 7.1362384635298E+44
        local v283 = math.floor(v282)
        local v284 = v282 - v283

        v281 = if v284 > 0.5 or v284 == 0.5 and v283 % 2 == 1 then v283 + 1 else v283

        if y < 0 then
            v281 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v281 = buffer.readu32(v1, 0)
    end

    local z = p47.inverse_tensor.z
    local v285

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v286 = math.abs(z) * 7.1362384635298E+44
        local v287 = math.floor(v286)
        local v288 = v286 - v287

        v285 = if v288 > 0.5 or v288 == 0.5 and v287 % 2 == 1 then v287 + 1 else v287

        if z < 0 then
            v285 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v285 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)

    local v289 = buffer.readu32(v1, 0)
    local inverse_mass = p47.inverse_mass
    local v290

    if inverse_mass ~= 0 and inverse_mass > -1.1754943508222875E-38 and inverse_mass < 1.1754943508222875E-38 then
        local v291 = math.abs(inverse_mass) * 7.1362384635298E+44
        local v292 = math.floor(v291)
        local v293 = v291 - v292

        v290 = if v293 > 0.5 or v293 == 0.5 and v292 % 2 == 1 then v292 + 1 else v292

        if inverse_mass < 0 then
            v290 += 2147483648
        end
    else
        buffer.writef32(v1, 0, inverse_mass)
        v290 = buffer.readu32(v1, 0)
    end

    local spherical = p47.spherical
    local v294

    if spherical ~= 0 and spherical > -1.1754943508222875E-38 and spherical < 1.1754943508222875E-38 then
        local v295 = math.abs(spherical) * 7.1362384635298E+44
        local v296 = math.floor(v295)
        local v297 = v295 - v296

        v294 = if v297 > 0.5 or v297 == 0.5 and v296 % 2 == 1 then v296 + 1 else v296

        if spherical < 0 then
            v294 += 2147483648
        end
    else
        buffer.writef32(v1, 0, spherical)
        v294 = buffer.readu32(v1, 0)
    end

    local maximum_linear_velocity = p47.maximum_linear_velocity
    local v298

    if maximum_linear_velocity ~= 0 and maximum_linear_velocity > -1.1754943508222875E-38 and maximum_linear_velocity < 1.1754943508222875E-38 then
        local v299 = math.abs(maximum_linear_velocity) * 7.1362384635298E+44
        local v300 = math.floor(v299)
        local v301 = v299 - v300

        v298 = if v301 > 0.5 or v301 == 0.5 and v300 % 2 == 1 then v300 + 1 else v300

        if maximum_linear_velocity < 0 then
            v298 += 2147483648
        end
    else
        buffer.writef32(v1, 0, maximum_linear_velocity)
        v298 = buffer.readu32(v1, 0)
    end

    local maximum_angular_velocity = p47.maximum_angular_velocity
    local v302

    if maximum_angular_velocity ~= 0 and maximum_angular_velocity > -1.1754943508222875E-38 and maximum_angular_velocity < 1.1754943508222875E-38 then
        local v303 = math.abs(maximum_angular_velocity) * 7.1362384635298E+44
        local v304 = math.floor(v303)
        local v305 = v303 - v304

        v302 = if v305 > 0.5 or v305 == 0.5 and v304 % 2 == 1 then v304 + 1 else v304

        if maximum_angular_velocity < 0 then
            v302 += 2147483648
        end
    else
        buffer.writef32(v1, 0, maximum_angular_velocity)
        v302 = buffer.readu32(v1, 0)
    end

    local linear_drag = p47.linear_drag
    local v306

    if linear_drag ~= 0 and linear_drag > -1.1754943508222875E-38 and linear_drag < 1.1754943508222875E-38 then
        local v307 = math.abs(linear_drag) * 7.1362384635298E+44
        local v308 = math.floor(v307)
        local v309 = v307 - v308

        v306 = if v309 > 0.5 or v309 == 0.5 and v308 % 2 == 1 then v308 + 1 else v308

        if linear_drag < 0 then
            v306 += 2147483648
        end
    else
        buffer.writef32(v1, 0, linear_drag)
        v306 = buffer.readu32(v1, 0)
    end

    local angular_drag = p47.angular_drag
    local v310

    if angular_drag ~= 0 and angular_drag > -1.1754943508222875E-38 and angular_drag < 1.1754943508222875E-38 then
        local v311 = math.abs(angular_drag) * 7.1362384635298E+44
        local v312 = math.floor(v311)
        local v313 = v311 - v312

        v310 = if v313 > 0.5 or v313 == 0.5 and v312 % 2 == 1 then v312 + 1 else v312

        if angular_drag < 0 then
            v310 += 2147483648
        end
    else
        buffer.writef32(v1, 0, angular_drag)
        v310 = buffer.readu32(v1, 0)
    end

    return {
        v277,
        v281,
        v285,
        v289,
        v290,
        v294,
        v298,
        v302,
        v306,
        v310
    }
end

function t1.body_words(p48) -- line: 1034
    -- upvalues: v1 (copy)
    local v314 = table.create(44, 0)
    local orientation = p48.orientation
    local x = orientation.x
    local v315

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v316 = math.abs(x) * 7.1362384635298E+44
        local v317 = math.floor(v316)
        local v318 = v316 - v317

        v315 = if v318 > 0.5 or v318 == 0.5 and v317 % 2 == 1 then v317 + 1 else v317

        if x < 0 then
            v315 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v315 = buffer.readu32(v1, 0)
    end

    v314[1] = v315

    local y = orientation.y
    local v319

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v320 = math.abs(y) * 7.1362384635298E+44
        local v321 = math.floor(v320)
        local v322 = v320 - v321

        v319 = if v322 > 0.5 or v322 == 0.5 and v321 % 2 == 1 then v321 + 1 else v321

        if y < 0 then
            v319 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v319 = buffer.readu32(v1, 0)
    end

    v314[2] = v319

    local z = orientation.z
    local v323

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v324 = math.abs(z) * 7.1362384635298E+44
        local v325 = math.floor(v324)
        local v326 = v324 - v325

        v323 = if v326 > 0.5 or v326 == 0.5 and v325 % 2 == 1 then v325 + 1 else v325

        if z < 0 then
            v323 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v323 = buffer.readu32(v1, 0)
    end

    v314[3] = v323

    local w = orientation.w
    local v327

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        local v328 = math.abs(w) * 7.1362384635298E+44
        local v329 = math.floor(v328)
        local v330 = v328 - v329

        v327 = if v330 > 0.5 or v330 == 0.5 and v329 % 2 == 1 then v329 + 1 else v329

        if w < 0 then
            v327 += 2147483648
        end
    else
        buffer.writef32(v1, 0, w)
        v327 = buffer.readu32(v1, 0)
    end

    v314[4] = v327

    local x2 = p48.position.x
    local v331

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        local v332 = math.abs(x2) * 7.1362384635298E+44
        local v333 = math.floor(v332)
        local v334 = v332 - v333

        v331 = if v334 > 0.5 or v334 == 0.5 and v333 % 2 == 1 then v333 + 1 else v333

        if x2 < 0 then
            v331 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x2)
        v331 = buffer.readu32(v1, 0)
    end

    v314[5] = v331

    local y2 = p48.position.y
    local v335

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        local v336 = math.abs(y2) * 7.1362384635298E+44
        local v337 = math.floor(v336)
        local v338 = v336 - v337

        v335 = if v338 > 0.5 or v338 == 0.5 and v337 % 2 == 1 then v337 + 1 else v337

        if y2 < 0 then
            v335 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y2)
        v335 = buffer.readu32(v1, 0)
    end

    v314[6] = v335

    local z2 = p48.position.z
    local v339

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        local v340 = math.abs(z2) * 7.1362384635298E+44
        local v341 = math.floor(v340)
        local v342 = v340 - v341

        v339 = if v342 > 0.5 or v342 == 0.5 and v341 % 2 == 1 then v341 + 1 else v341

        if z2 < 0 then
            v339 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z2)
        v339 = buffer.readu32(v1, 0)
    end

    v314[7] = v339

    for i = 0, #p48.basis.columns - 1 do
        local v343 = p48.basis.columns[i + 1]
        local v344 = i * 4 + 16 + 0 + 1
        local v345 = v343[1]

        if v345 ~= 0 and v345 > -1.1754943508222875E-38 and v345 < 1.1754943508222875E-38 then
            local v346 = math.abs(v345) * 7.1362384635298E+44
            local v347 = math.floor(v346)
            local v348 = v346 - v347
            local v349 = if v348 > 0.5 or v348 == 0.5 and v347 % 2 == 1 then v347 + 1 else v347

            if v345 < 0 then
                v314[v344] = v349 + 2147483648
            else
                v314[v344] = v349
            end
        else
            buffer.writef32(v1, 0, v345)
            v314[v344] = buffer.readu32(v1, 0)
        end

        local v350 = i * 4 + 16 + 1 + 1
        local v351 = v343[2]

        if v351 ~= 0 and v351 > -1.1754943508222875E-38 and v351 < 1.1754943508222875E-38 then
            local v352 = math.abs(v351) * 7.1362384635298E+44
            local v353 = math.floor(v352)
            local v354 = v352 - v353
            local v355 = if v354 > 0.5 or v354 == 0.5 and v353 % 2 == 1 then v353 + 1 else v353

            if v351 < 0 then
                v314[v350] = v355 + 2147483648
            else
                v314[v350] = v355
            end
        else
            buffer.writef32(v1, 0, v351)
            v314[v350] = buffer.readu32(v1, 0)
        end

        local v356 = i * 4 + 16 + 2 + 1
        local v357 = v343[3]

        if v357 ~= 0 and v357 > -1.1754943508222875E-38 and v357 < 1.1754943508222875E-38 then
            local v358 = math.abs(v357) * 7.1362384635298E+44
            local v359 = math.floor(v358)
            local v360 = v358 - v359
            local v361 = if v360 > 0.5 or v360 == 0.5 and v359 % 2 == 1 then v359 + 1 else v359

            if v357 < 0 then
                v314[v356] = v361 + 2147483648
            else
                v314[v356] = v361
            end
        else
            buffer.writef32(v1, 0, v357)
            v314[v356] = buffer.readu32(v1, 0)
        end
    end

    return v314
end

return t1
