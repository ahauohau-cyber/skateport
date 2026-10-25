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

local function rtl_fround(p3) -- line: 24
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v9 = math.abs(p3) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p3 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local TrajectoryQuery = import("skate_core/camera").TrajectoryQuery
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local v12 = import("skate_core/physics/triangle_query")
local triangle_segment, triangle_segment_transient = v12.triangle_segment, v12.triangle_segment_transient
local v13 = false
local t1 = {}

function t1.set_b3_twin(p4) -- line: 53
    -- upvalues: v13 (ref)
    v13 = p4
end

local line_candidate_indices, line_vertices, line_vertices_fill = BoardWorld.line_candidate_indices, BoardWorld.line_vertices, BoardWorld.line_vertices_fill
local t2 = {}
local vector, lanes, query_trajectory_transient
local v14 = buffer.create(8)
local to_bits = rt.to_bits

local function f32r(p5) -- line: 79
    -- upvalues: v14 (copy), to_bits (copy)
    if p5 ~= 0 and p5 > -1.1754943508222875E-38 and p5 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(p5))

        return (buffer.readf32(v14, 0))
    end

    buffer.writef32(v14, 0, p5)

    return (buffer.readf32(v14, 0))
end

local function part_translation_into(p6, p7, p8, p9) -- line: 88
    -- upvalues: v14 (copy), to_bits (copy)
    local rates = p7[p9 + 1].rates
    local columns = rates.basis.columns
    local v15 = columns[1]
    local v16 = columns[2]
    local v17 = columns[3]
    local v18 = v15[1]

    if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v18))
    else
        buffer.writef32(v14, 0, v18)
    end

    local v19 = buffer.readf32(v14, 0)
    local v20 = v15[2]

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v20))
    else
        buffer.writef32(v14, 0, v20)
    end

    local v21 = buffer.readf32(v14, 0)
    local v22 = v15[3]

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v22))
    else
        buffer.writef32(v14, 0, v22)
    end

    local v23 = buffer.readf32(v14, 0)
    local v24 = v16[1]

    if v24 ~= 0 and v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v24))
    else
        buffer.writef32(v14, 0, v24)
    end

    local v25 = buffer.readf32(v14, 0)
    local v26 = v16[2]

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v26))
    else
        buffer.writef32(v14, 0, v26)
    end

    local v27 = buffer.readf32(v14, 0)
    local v28 = v16[3]

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v28))
    else
        buffer.writef32(v14, 0, v28)
    end

    local v29 = buffer.readf32(v14, 0)
    local v30 = v17[1]

    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v30))
    else
        buffer.writef32(v14, 0, v30)
    end

    local v31 = buffer.readf32(v14, 0)
    local v32 = v17[2]

    if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v32))
    else
        buffer.writef32(v14, 0, v32)
    end

    local v33 = buffer.readf32(v14, 0)
    local v34 = v17[3]

    if v34 ~= 0 and v34 > -1.1754943508222875E-38 and v34 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v34))
    else
        buffer.writef32(v14, 0, v34)
    end

    local v35 = buffer.readf32(v14, 0)
    local position = rates.position
    local x = position.x

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(x))
    else
        buffer.writef32(v14, 0, x)
    end

    local v36 = buffer.readf32(v14, 0)
    local y = position.y

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(y))
    else
        buffer.writef32(v14, 0, y)
    end

    local v37 = buffer.readf32(v14, 0)
    local z = position.z

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(z))
    else
        buffer.writef32(v14, 0, z)
    end

    local v38 = buffer.readf32(v14, 0)
    local translation = p8[p9 + 1].animated.local_mass_frame.translation
    local x2 = translation.x

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(x2))
    else
        buffer.writef32(v14, 0, x2)
    end

    local v39 = buffer.readf32(v14, 0)
    local y2 = translation.y

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(y2))
    else
        buffer.writef32(v14, 0, y2)
    end

    local v40 = buffer.readf32(v14, 0)
    local z2 = translation.z

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(z2))
    else
        buffer.writef32(v14, 0, z2)
    end

    local v41 = buffer.readf32(v14, 0)
    local v42 = v41 * v31 + (v40 * v25 + (v39 * v19 + v36))

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v42))
    else
        buffer.writef32(v14, 0, v42)
    end

    p6[1] = buffer.readf32(v14, 0)

    local v43 = v41 * v33 + (v40 * v27 + (v39 * v21 + v37))

    if v43 ~= 0 and v43 > -1.1754943508222875E-38 and v43 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v43))
    else
        buffer.writef32(v14, 0, v43)
    end

    p6[2] = buffer.readf32(v14, 0)

    local v44 = v41 * v35 + (v40 * v29 + (v39 * v23 + v38))

    if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v44))
    else
        buffer.writef32(v14, 0, v44)
    end

    p6[3] = buffer.readf32(v14, 0)

    local v45 = v41 * 0 + (v40 * 0 + (v39 * 0 + 0))

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        buffer.writeu32(v14, 0, to_bits(v45))
    else
        buffer.writef32(v14, 0, v45)
    end

    p6[4] = buffer.readf32(v14, 0)
end

local v46, part_translations_into_r3

local function part_translations_into(p10, p11, p12, p13, p14, p15, p16) -- line: 112
    -- upvalues: SkeletonBody (copy), v13 (ref), part_translations_into_r3 (ref)
    if v13 then
        return part_translations_into_r3(p10, p11, p12, p13, p14, p15, p16)
    end

    local part_translation_into = SkeletonBody.part_translation_into

    return part_translation_into(p10, p11, p12) and part_translation_into(p10, p13, p14) and part_translation_into(p10, p15, p16)
end

function part_translations_into_r3(p17, p18, p19, p20, p21, p22, p23) -- line: 120
    -- upvalues: import (copy), part_translation_into (copy), v46 (ref)
    local v47 = v46

    if v47 == nil then
        v47 = import("skate_core/physics/skeleton_body").PART_COUNT
        v46 = v47
    end

    local bodies = p17.bodies
    local parts = p17.definition.parts

    for i = 1, v47 do
        if #bodies[i].rates.basis.columns ~= 3 or #parts[i].animated.local_mass_frame.basis.columns ~= 3 then
            return false
        end
    end

    part_translation_into(p19, bodies, parts, p18)
    part_translation_into(p21, bodies, parts, p20)
    part_translation_into(p23, bodies, parts, p22)

    return true
end

t1.part_translations_into = part_translations_into

local t3 = {
    0, 0, 0, 0
}
local t4 = {
    0, 0, 0, 0
}
local t5 = {
    0, 0, 0, 0
}
local t6 = {
    0, -100, 0, 0
}
local t7 = {
    0, 0.33000001311302185, 0, 0
}
local t8 = {
    0, -1.5, 0, 0
}
local v48 = t8[1] - t7[1]
local v49

if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
    local v50 = math.abs(v48) * 7.1362384635298E+44
    local v51 = math.floor(v50)
    local v52 = v50 - v51

    v49 = (if v52 > 0.5 or v52 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51) * 1.401298464324817E-45

    if v48 < 0 then
        v49 = -v49
    end
else
    buffer.writef32(v1, 0, v48)
    v49 = buffer.readf32(v1, 0)
end

local v53 = t8[2] - t7[2]
local v54

if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
    local v55 = math.abs(v53) * 7.1362384635298E+44
    local v56 = math.floor(v55)
    local v57 = v55 - v56

    v54 = (if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56) * 1.401298464324817E-45

    if v53 < 0 then
        v54 = -v54
    end
else
    buffer.writef32(v1, 0, v53)
    v54 = buffer.readf32(v1, 0)
end

local v58 = t8[3] - t7[3]
local v59

if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
    local v60 = math.abs(v58) * 7.1362384635298E+44
    local v61 = math.floor(v60)
    local v62 = v60 - v61

    v59 = (if v62 > 0.5 or v62 == 0.5 and v61 % 2 == 1 then v61 + 1 else v61) * 1.401298464324817E-45

    if v58 < 0 then
        v59 = -v59
    end
else
    buffer.writef32(v1, 0, v58)
    v59 = buffer.readf32(v1, 0)
end

local v63 = t8[4] - t7[4]
local v64

if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
    local v65 = math.abs(v63) * 7.1362384635298E+44
    local v66 = math.floor(v65)
    local v67 = v65 - v66

    v64 = (if v67 > 0.5 or v67 == 0.5 and v66 % 2 == 1 then v66 + 1 else v66) * 1.401298464324817E-45

    if v63 < 0 then
        v64 = -v64
    end
else
    buffer.writef32(v1, 0, v63)
    v64 = buffer.readf32(v1, 0)
end

local t9 = {
    v49,
    v54,
    v59,
    v64
}
local t10 = {
    0, 0, 0, 0
}

t1.SkeletonLineHit = {}

function t1.SkeletonLineHit.pending_result() -- line: 163
    return {
        surface = 0,
        hit = false,
        collision_time = -1,
        position = { 0, 0, 0, 0 },
        normal = { 0, 1, 0, 0 }
    }
end

t1.SkeletonLineTests = {}

local function to_bits4(p24) -- line: 178
    -- upvalues: v1 (copy)
    local v68 = p24[1]
    local v69

    if v68 ~= 0 and v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
        local v70 = math.abs(v68) * 7.1362384635298E+44
        local v71 = math.floor(v70)
        local v72 = v70 - v71

        v69 = if v72 > 0.5 or v72 == 0.5 and v71 % 2 == 1 then v71 + 1 else v71

        if v68 < 0 then
            v69 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v68)
        v69 = buffer.readu32(v1, 0)
    end

    local v73 = p24[2]
    local v74

    if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
        local v75 = math.abs(v73) * 7.1362384635298E+44
        local v76 = math.floor(v75)
        local v77 = v75 - v76

        v74 = if v77 > 0.5 or v77 == 0.5 and v76 % 2 == 1 then v76 + 1 else v76

        if v73 < 0 then
            v74 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v73)
        v74 = buffer.readu32(v1, 0)
    end

    local v78 = p24[3]
    local v79

    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
        local v80 = math.abs(v78) * 7.1362384635298E+44
        local v81 = math.floor(v80)
        local v82 = v80 - v81

        v79 = if v82 > 0.5 or v82 == 0.5 and v81 % 2 == 1 then v81 + 1 else v81

        if v78 < 0 then
            v79 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v78)
        v79 = buffer.readu32(v1, 0)
    end

    local v83 = p24[4]
    local v84

    if v83 ~= 0 and v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
        local v85 = math.abs(v83) * 7.1362384635298E+44
        local v86 = math.floor(v85)
        local v87 = v85 - v86

        v84 = if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86

        if v83 < 0 then
            v84 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v83)
        v84 = buffer.readu32(v1, 0)
    end

    return {
        v69,
        v74,
        v79,
        v84
    }
end

function t1.SkeletonLineTests.publish(p25, p26) -- line: 185
    -- upvalues: to_bits4 (copy)
    local function fields(p27) -- line: 186
        -- upvalues: to_bits4 (copy)
        return {
            position = to_bits4(p27.position),
            normal = to_bits4(p27.normal),
            surface = p27.surface,
            valid = p27.collision_time >= 0 and 1 or 0
        }
    end

    local hips = p25.hips

    p26.hips_line_test_1488 = {
        position = to_bits4(hips.position),
        normal = to_bits4(hips.normal),
        surface = hips.surface,
        valid = hips.collision_time >= 0 and 1 or 0
    }

    local v88 = p25.feet[1]

    p26.left_line_test_1536 = {
        position = to_bits4(v88.position),
        normal = to_bits4(v88.normal),
        surface = v88.surface,
        valid = v88.collision_time >= 0 and 1 or 0
    }

    local v89 = p25.feet[2]

    p26.right_line_test_1584 = {
        position = to_bits4(v89.position),
        normal = to_bits4(v89.normal),
        surface = v89.surface,
        valid = v89.collision_time >= 0 and 1 or 0
    }
end

function t1.query(p28, p29) -- line: 207
    -- upvalues: v1 (copy), SkeletonBody (copy), query_trajectory_transient (ref), part_translations_into (copy), t3 (copy), t4 (copy), t5 (copy), t6 (copy), t7 (copy), t9 (copy), t10 (copy)
    local v90 = t3
    local v91 = t4
    local v92 = t5

    if not part_translations_into(p29, 23, t3, 15, t4, 19, t5) then
        v90 = SkeletonBody.part_translation(p29, 23)
        v91 = SkeletonBody.part_translation(p29, 15)
        v92 = SkeletonBody.part_translation(p29, 19)
    end

    local v93 = query_trajectory_transient(p28, v90, t6)
    local v94 = v91[1] + t7[1]
    local v95

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        local v96 = math.abs(v94) * 7.1362384635298E+44
        local v97 = math.floor(v96)
        local v98 = v96 - v97

        v95 = (if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97) * 1.401298464324817E-45

        if v94 < 0 then
            v95 = -v95
        end
    else
        buffer.writef32(v1, 0, v94)
        v95 = buffer.readf32(v1, 0)
    end

    t10[1] = v95

    local v99 = v91[2] + t7[2]
    local v100

    if v99 ~= 0 and v99 > -1.1754943508222875E-38 and v99 < 1.1754943508222875E-38 then
        local v101 = math.abs(v99) * 7.1362384635298E+44
        local v102 = math.floor(v101)
        local v103 = v101 - v102

        v100 = (if v103 > 0.5 or v103 == 0.5 and v102 % 2 == 1 then v102 + 1 else v102) * 1.401298464324817E-45

        if v99 < 0 then
            v100 = -v100
        end
    else
        buffer.writef32(v1, 0, v99)
        v100 = buffer.readf32(v1, 0)
    end

    t10[2] = v100

    local v104 = v91[3] + t7[3]
    local v105

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        local v106 = math.abs(v104) * 7.1362384635298E+44
        local v107 = math.floor(v106)
        local v108 = v106 - v107

        v105 = (if v108 > 0.5 or v108 == 0.5 and v107 % 2 == 1 then v107 + 1 else v107) * 1.401298464324817E-45

        if v104 < 0 then
            v105 = -v105
        end
    else
        buffer.writef32(v1, 0, v104)
        v105 = buffer.readf32(v1, 0)
    end

    t10[3] = v105

    local v109 = v91[4] + t7[4]
    local v110

    if v109 ~= 0 and v109 > -1.1754943508222875E-38 and v109 < 1.1754943508222875E-38 then
        local v111 = math.abs(v109) * 7.1362384635298E+44
        local v112 = math.floor(v111)
        local v113 = v111 - v112

        v110 = (if v113 > 0.5 or v113 == 0.5 and v112 % 2 == 1 then v112 + 1 else v112) * 1.401298464324817E-45

        if v109 < 0 then
            v110 = -v110
        end
    else
        buffer.writef32(v1, 0, v109)
        v110 = buffer.readf32(v1, 0)
    end

    t10[4] = v110

    local v114 = query_trajectory_transient(p28, t10, t9)
    local v115 = v92[1] + t7[1]
    local v116

    if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
        local v117 = math.abs(v115) * 7.1362384635298E+44
        local v118 = math.floor(v117)
        local v119 = v117 - v118

        v116 = (if v119 > 0.5 or v119 == 0.5 and v118 % 2 == 1 then v118 + 1 else v118) * 1.401298464324817E-45

        if v115 < 0 then
            v116 = -v116
        end
    else
        buffer.writef32(v1, 0, v115)
        v116 = buffer.readf32(v1, 0)
    end

    t10[1] = v116

    local v120 = v92[2] + t7[2]
    local v121

    if v120 ~= 0 and v120 > -1.1754943508222875E-38 and v120 < 1.1754943508222875E-38 then
        local v122 = math.abs(v120) * 7.1362384635298E+44
        local v123 = math.floor(v122)
        local v124 = v122 - v123

        v121 = (if v124 > 0.5 or v124 == 0.5 and v123 % 2 == 1 then v123 + 1 else v123) * 1.401298464324817E-45

        if v120 < 0 then
            v121 = -v121
        end
    else
        buffer.writef32(v1, 0, v120)
        v121 = buffer.readf32(v1, 0)
    end

    t10[2] = v121

    local v125 = v92[3] + t7[3]
    local v126

    if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
        local v127 = math.abs(v125) * 7.1362384635298E+44
        local v128 = math.floor(v127)
        local v129 = v127 - v128

        v126 = (if v129 > 0.5 or v129 == 0.5 and v128 % 2 == 1 then v128 + 1 else v128) * 1.401298464324817E-45

        if v125 < 0 then
            v126 = -v126
        end
    else
        buffer.writef32(v1, 0, v125)
        v126 = buffer.readf32(v1, 0)
    end

    t10[3] = v126

    local v130 = v92[4] + t7[4]
    local v131

    if v130 ~= 0 and v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
        local v132 = math.abs(v130) * 7.1362384635298E+44
        local v133 = math.floor(v132)
        local v134 = v132 - v133

        v131 = (if v134 > 0.5 or v134 == 0.5 and v133 % 2 == 1 then v133 + 1 else v133) * 1.401298464324817E-45

        if v130 < 0 then
            v131 = -v131
        end
    else
        buffer.writef32(v1, 0, v130)
        v131 = buffer.readf32(v1, 0)
    end

    t10[4] = v131

    return {
        hips = v93,
        feet = {
            v114,
            (query_trajectory_transient(p28, t10, t9))
        }
    }
end

function t1.query_reference(p30, p31) -- line: 240
    -- upvalues: rt (copy), v1 (copy), SkeletonBody (copy), t1 (copy)
    local v135 = SkeletonBody.part_transforms(p31)
    local v136 = t1.query_trajectory_reference(p30, rt.copy(v135[24][4]), { 0, -100, 0, 0 })
    local t16 = {
        0, 0.33000001311302185, 0, 0
    }
    local t17 = {
        0, -1.5, 0, 0
    }
    local v137 = t17[1] - t16[1]
    local v138

    if v137 ~= 0 and v137 > -1.1754943508222875E-38 and v137 < 1.1754943508222875E-38 then
        local v139 = math.abs(v137) * 7.1362384635298E+44
        local v140 = math.floor(v139)
        local v141 = v139 - v140

        v138 = (if v141 > 0.5 or v141 == 0.5 and v140 % 2 == 1 then v140 + 1 else v140) * 1.401298464324817E-45

        if v137 < 0 then
            v138 = -v138
        end
    else
        buffer.writef32(v1, 0, v137)
        v138 = buffer.readf32(v1, 0)
    end

    local v142 = t17[2] - t16[2]
    local v143

    if v142 ~= 0 and v142 > -1.1754943508222875E-38 and v142 < 1.1754943508222875E-38 then
        local v144 = math.abs(v142) * 7.1362384635298E+44
        local v145 = math.floor(v144)
        local v146 = v144 - v145

        v143 = (if v146 > 0.5 or v146 == 0.5 and v145 % 2 == 1 then v145 + 1 else v145) * 1.401298464324817E-45

        if v142 < 0 then
            v143 = -v143
        end
    else
        buffer.writef32(v1, 0, v142)
        v143 = buffer.readf32(v1, 0)
    end

    local v147 = t17[3] - t16[3]
    local v148

    if v147 ~= 0 and v147 > -1.1754943508222875E-38 and v147 < 1.1754943508222875E-38 then
        local v149 = math.abs(v147) * 7.1362384635298E+44
        local v150 = math.floor(v149)
        local v151 = v149 - v150

        v148 = (if v151 > 0.5 or v151 == 0.5 and v150 % 2 == 1 then v150 + 1 else v150) * 1.401298464324817E-45

        if v147 < 0 then
            v148 = -v148
        end
    else
        buffer.writef32(v1, 0, v147)
        v148 = buffer.readf32(v1, 0)
    end

    local v152 = t17[4] - t16[4]
    local v153

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        local v154 = math.abs(v152) * 7.1362384635298E+44
        local v155 = math.floor(v154)
        local v156 = v154 - v155

        v153 = (if v156 > 0.5 or v156 == 0.5 and v155 % 2 == 1 then v155 + 1 else v155) * 1.401298464324817E-45

        if v152 < 0 then
            v153 = -v153
        end
    else
        buffer.writef32(v1, 0, v152)
        v153 = buffer.readf32(v1, 0)
    end

    local t18 = {
        v138,
        v143,
        v148,
        v153
    }
    local t19 = {
        t1.SkeletonLineHit.pending_result(),
        t1.SkeletonLineHit.pending_result()
    }
    local t20 = {
        15, 19
    }

    for i = 0, 1 do
        local v157 = v135[t20[i + 1] + 1][4]
        local v158 = v157[1] + t16[1]
        local v159

        if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
            local v160 = math.abs(v158) * 7.1362384635298E+44
            local v161 = math.floor(v160)
            local v162 = v160 - v161

            v159 = (if v162 > 0.5 or v162 == 0.5 and v161 % 2 == 1 then v161 + 1 else v161) * 1.401298464324817E-45

            if v158 < 0 then
                v159 = -v159
            end
        else
            buffer.writef32(v1, 0, v158)
            v159 = buffer.readf32(v1, 0)
        end

        local v163 = v157[2] + t16[2]
        local v164

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            local v165 = math.abs(v163) * 7.1362384635298E+44
            local v166 = math.floor(v165)
            local v167 = v165 - v166

            v164 = (if v167 > 0.5 or v167 == 0.5 and v166 % 2 == 1 then v166 + 1 else v166) * 1.401298464324817E-45

            if v163 < 0 then
                v164 = -v164
            end
        else
            buffer.writef32(v1, 0, v163)
            v164 = buffer.readf32(v1, 0)
        end

        local v168 = v157[3] + t16[3]
        local v169

        if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
            local v170 = math.abs(v168) * 7.1362384635298E+44
            local v171 = math.floor(v170)
            local v172 = v170 - v171

            v169 = (if v172 > 0.5 or v172 == 0.5 and v171 % 2 == 1 then v171 + 1 else v171) * 1.401298464324817E-45

            if v168 < 0 then
                v169 = -v169
            end
        else
            buffer.writef32(v1, 0, v168)
            v169 = buffer.readf32(v1, 0)
        end

        local v173 = v157[4] + t16[4]
        local v174

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            local v175 = math.abs(v173) * 7.1362384635298E+44
            local v176 = math.floor(v175)
            local v177 = v175 - v176

            v174 = (if v177 > 0.5 or v177 == 0.5 and v176 % 2 == 1 then v176 + 1 else v176) * 1.401298464324817E-45

            if v173 < 0 then
                v174 = -v174
            end
        else
            buffer.writef32(v1, 0, v173)
            v174 = buffer.readf32(v1, 0)
        end

        local t21 = {
            v159,
            v164,
            v169,
            v174
        }

        t19[i + 1] = t1.query_trajectory_reference(p30, t21, rt.copy(t18))
    end

    return {
        hips = v136,
        feet = t19
    }
end

local t22 = {
    position = nil,
    velocity = nil,
    duration = 1,
    radius = 0.029999999329447746,
    start_error = 0,
    end_error = 0,
    gravity = { 0, 0, 0, 0 }
}
local v178, v179
local t23 = {
    0, 0, 0, 0
}
local v180 = Vector3.new(0, 0, 0)
local v181 = Vector3.new(0, 0, 0)
local v182 = Vector3.new(0, 0, 0)
local v183 = Vector3.new(0, 0, 0)
local v184 = Vector3.new(0, 0, 0)
local t24 = {
    0, 0, 0
}
local t25 = {
    fraction = 0,
    position = v183,
    normal = v184,
    volume_parameter = t24
}

local function trajectory_line(p32, p33, p34) -- line: 325
    -- upvalues: rt (copy), triangle_segment_transient (copy), line_candidate_indices (copy), line_vertices (copy), line_vertices_fill (copy), t2 (copy), v178 (ref), v179 (ref), t23 (copy), v180 (copy), v181 (copy), v182 (copy), v183 (copy), v184 (copy), t24 (copy), t25 (copy)
    local v185 = v178
    local v186 = p32[1]
    local v187 = p32[2]
    local v188 = p32[3]
    local v189 = p33[1]
    local v190 = p33[2]
    local v191 = p33[3]

    v180.x = v186
    v180.y = v187
    v180.z = v188
    v181.x = v189
    v181.y = v190
    v181.z = v191

    local v192 = v189 - v186
    local v193 = v190 - v187
    local v194 = v191 - v188

    v182.x = v192
    v182.y = v193
    v182.z = v194

    local v195 = rt.F32_MAX
    local triangles = v185.triangles
    local v196 = line_vertices(v185)
    local n1 = -1
    local n2 = 0
    local n3 = 0
    local n4 = 0

    for i = 1, line_candidate_indices(v185, v180, v181, p34, t2) do
        local v198 = t2[i]
        local v199 = if v196 == nil then triangles[v198 + 1].triangle.vertices else v196[v198] or line_vertices_fill(v196, v198)

        v183.x = 0
        v183.y = 0
        v183.z = 0
        v184.x = 0
        v184.y = 0
        v184.z = 0
        t24[1] = 0
        t24[2] = 0
        t24[3] = 0
        t25.position = v183
        t25.normal = v184
        t25.fraction = 0
        t25.volume_parameter = t24

        local v200 = v195
        local v201 = n1
        local v202 = n2
        local v203 = n3
        local v204 = n4

        if triangle_segment_transient(t25, v180, v182, v199, p34, 0) then
            local fraction = t25.fraction

            if -fraction >= 0 then
                fraction = 0
            end

            v200 = if 1 - fraction >= 0 then fraction else 1

            if v200 < v195 then
                local position = t25.position

                v201 = v198
                v202 = position.x
                v203 = position.y
                v204 = position.z
            else
                v200 = v195
            end
        end

        n4 = v204
        n1 = v201
        v195 = v200
        n2 = v202
        n3 = v203
    end

    if n1 < 0 then
        return nil
    end

    local v205 = triangles[n1 + 1]
    local normal = v205.triangle.feature.normal
    local v206 = v179

    v206.position = { n2, n3, n4, 0 }
    v206.normal = {
        normal.x,
        normal.y,
        normal.z,
        0
    }
    v206.surface = v205.tag
    t23[1] = n2
    t23[2] = n3
    t23[3] = n4
    t23[4] = 0

    return t23
end

local function trajectory_line_r3(p35, p36, p37) -- line: 391
    -- upvalues: rt (copy), BoardWorld (copy), triangle_segment_transient (copy), v178 (ref), v179 (ref), t23 (copy), v180 (copy), v181 (copy), v182 (copy), v183 (copy), v184 (copy), t24 (copy), t25 (copy)
    local v207 = v178
    local v208 = p35[1]
    local v209 = p35[2]
    local v210 = p35[3]
    local v211 = p36[1]
    local v212 = p36[2]
    local v213 = p36[3]

    v180.x = v208
    v180.y = v209
    v180.z = v210
    v181.x = v211
    v181.y = v212
    v181.z = v213

    local v214 = v211 - v208
    local v215 = v212 - v209
    local v216 = v213 - v210

    v182.x = v214
    v182.y = v215
    v182.z = v216

    local v217 = false
    local v218 = rt.F32_MAX
    local v219 = 0
    local v220 = 0
    local v221 = 0
    local v222 = 0
    local v223 = 0
    local v224 = 0
    local v225 = 0

    for _, v226 in BoardWorld.line_candidates(v207, v180, v181, p37) do
        local v227 = v226[2]

        v183.x = 0
        v183.y = 0
        v183.z = 0
        v184.x = 0
        v184.y = 0
        v184.z = 0
        t24[1] = 0
        t24[2] = 0
        t24[3] = 0
        t25.position = v183
        t25.normal = v184
        t25.fraction = 0
        t25.volume_parameter = t24

        if triangle_segment_transient(t25, v180, v182, v227.triangle.vertices, p37, 0) then
            local v228 = if -t25.fraction >= 0 then 0 else t25.fraction

            if not (1 - v228 >= 0) then
                v228 = 1
            end

            if v228 < v218 then
                local position = t25.position
                local normal = v227.triangle.feature.normal

                v217 = true
                v218 = v228
                v219 = position.x
                v220 = position.y
                v221 = position.z
                v222 = normal.x
                v223 = normal.y
                v224 = normal.z
                v225 = v227.tag
            end
        end
    end

    if not v217 then
        return nil
    end

    local v229 = v179

    v229.position = { v219, v220, v221, 0 }
    v229.normal = { v222, v223, v224, 0 }
    v229.surface = v225
    t23[1] = v219
    t23[2] = v220
    t23[3] = v221
    t23[4] = 0

    return t23
end

function query_trajectory_transient(p38, p39, p40) -- line: 450
    -- upvalues: rt (copy), TrajectoryQuery (copy), t1 (copy), v13 (ref), t22 (copy), v178 (ref), v179 (ref), trajectory_line (copy), trajectory_line_r3 (copy)
    if p38.external ~= nil then
        return t1.query_trajectory_reference(p38, rt.copy(p39), rt.copy(p40))
    end

    t22.position = p39
    t22.velocity = p40

    local v230 = t1.SkeletonLineHit.pending_result()

    v178 = p38
    v179 = v230
    v230.collision_time = TrajectoryQuery.collision_time_transient(t22, if v13 then trajectory_line_r3 else trajectory_line)
    v178 = nil
    v179 = nil
    t22.position = nil
    t22.velocity = nil
    v230.hit = v230.collision_time >= 0

    return v230
end

t1.query_trajectory_transient = query_trajectory_transient

function t1.query_trajectory(p41, p42, p43) -- line: 472
    -- upvalues: query_trajectory_transient (ref)
    return query_trajectory_transient(p41, p42, p43)
end

function t1.query_trajectory_reference(p44, p45, p46) -- line: 480
    -- upvalues: rt (copy), TrajectoryQuery (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), t1 (copy), vector (ref), lanes (ref)
    local t26 = {
        duration = 1,
        radius = 0.029999999329447746,
        start_error = 0,
        end_error = 0,
        position = p45,
        velocity = p46,
        gravity = { 0, 0, 0, 0 }
    }
    local v232 = t1.SkeletonLineHit.pending_result()

    v232.collision_time = TrajectoryQuery.collision_time(t26, function(p47, p48, p49) -- line: 496
        -- upvalues: p44 (copy), v232 (copy), rt (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), vector (ref), lanes (ref)
        local v233 = vector(p47)
        local v234 = Vector3.new(p48[1] - p47[1], p48[2] - p47[2], p48[3] - p47[3])
        local v235 = rt.F32_MAX
        local v236

        for _, v237 in BoardWorld.line_candidates(p44, v233, vector(p48), p49) do
            local v238 = v237[2]
            local t27 = {
                fraction = 0,
                position = Vector3.new(0, 0, 0),
                normal = Vector3.new(0, 0, 0),
                volume_parameter = { 0, 0, 0 }
            }

            if triangle_segment(t27, v233, v234, v238.triangle.vertices, p49, 0) then
                local v239 = if -t27.fraction >= 0 then 0 else t27.fraction

                if not (1 - v239 >= 0) then
                    v239 = 1
                end

                if v239 < v235 then
                    local v240 = lanes(t27.position)

                    v232.position = v240
                    v232.normal = lanes(v238.triangle.feature.normal)
                    v232.surface = v238.tag
                    v235 = v239
                    v236 = rt.copy(v240)
                end
            end
        end

        local v241 = BoardWorld.external_line(p44, v233, vector(p48), p49)

        if v241 ~= nil then
            local geometry = v241.hit.geometry

            if rt.clamp(geometry.fraction, 0, 1) < v235 then
                local v242 = lanes(geometry.position)

                v232.position = v242
                v232.normal = lanes(geometry.normal)
                v232.surface = v241.hit.tag
                v236 = rt.copy(v242)
            end
        end

        return v236
    end)
    v232.hit = v232.collision_time >= 0

    return v232
end

function t1.vector(p50) -- line: 551
    -- upvalues: Vector3 (copy)
    return Vector3.new(p50[1], p50[2], p50[3])
end

vector = t1.vector

function t1.lanes(p51) -- line: 556
    return {
        p51.x,
        p51.y,
        p51.z,
        0
    }
end

lanes = t1.lanes

return t1
