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
local v9 = import("skate_core/animation/foot_ik/math")
local cross, length, normalize = v9.cross, v9.length, v9.normalize
local inverse_rigid = import("skate_core/animation/foot_ik/transforms").inverse_rigid
local v10 = import("skate_core/animation/foot_ik/two_bone")
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local v11 = import("skate_core/physics/skeleton_animation_record")
local compose_affine, transform_point = v11.compose_affine, v11.transform_point
local orthonormalize = import("skate_core/physics/skeleton_root").orthonormalize
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local t1 = {
    Geometry = {}
}

function t1.Geometry.new(p3, p4) -- line: 56
    -- upvalues: rt (copy), v9 (copy)
    for i = 0, 23 do
        local v12 = p3[i + 1]
        local v13 = table.create(24, false)

        v13[i + 1] = true

        while v12 ~= nil do
            if v12 >= 24 or v13[v12 + 1] then
                error(("Invalid physical ancestor chain for IK part %*"):format(i), 0)
            end

            v13[v12 + 1] = true
            v12 = p3[v12 + 1]
        end
    end

    local v14 = table.create(24)

    for i = 0, 23 do
        v14[i + 1] = v9.inverse_affine(p4[i + 1])
    end

    return {
        parents = rt.copy(p3),
        inverse_part_frames = v14
    }
end

function t1.Geometry.validate_limbs(p5, p6) -- line: 81
    for i = 0, 3 do
        local v15 = p6[i + 1]
        local v16 = if v15.parent_part == nil then v15.part else v15.parent_part
        local v17 = v15.part >= 24 or v16 >= 24

        if not v17 then
            local v18 = p5.parents[v16 + 1]

            v17 = (if v18 == nil then nil else p5.parents[v18 + 1]) == nil
        end

        if v17 then
            error(("IK part %* has no two-bone physical ancestor chain"):format(v16), 0)
        end
    end
end

local function subtract(p7, p8) -- line: 107
    return {
        p7[1] - p8[1],
        p7[2] - p8[2],
        p7[3] - p8[3],
        p7[4] - p8[4]
    }
end

local function add_translation(p9, p10) -- line: 111
    p9[4][1] += p10[1]
    p9[4][2] += p10[2]
    p9[4][3] += p10[3]
    p9[4][4] += p10[4]
end

local function normalize_safe(p11) -- line: 117
    -- upvalues: length (copy), normalize (copy)
    local v19 = length(p11)
    local v20 = normalize(p11)

    if v19 > 9.999999974752427E-07 then
        return v20
    end

    return { 0, 0, 0, 0 }
end

local function line_frame(p12, p13, p14) -- line: 129
    -- upvalues: rt (copy), cross (copy), length (copy), normalize (copy), dot3 (copy)
    local t2 = {
        p13[1] - p12[1],
        p13[2] - p12[2],
        p13[3] - p12[3],
        p13[4] - p12[4]
    }
    local v21 = cross(t2, p14)
    local v22 = cross(v21, t2)
    local v23 = length(v21)
    local v24 = normalize(v21)

    if not (v23 > 9.999999974752427E-07) then
        v24 = { 0, 0, 0, 0 }
    end

    local v25 = length(v22)
    local v26 = normalize(v22)

    if not (v25 > 9.999999974752427E-07) then
        v26 = { 0, 0, 0, 0 }
    end

    local v27 = length(t2)
    local v28 = normalize(t2)

    if not (v27 > 9.999999974752427E-07) then
        v28 = { 0, 0, 0, 0 }
    end

    return if dot3(v26, v26) * dot3(v24, v24) * dot3(v28, v28) > 1.52587890625E-05 then {
        v24,
        v28,
        v26,
        rt.copy(p12)
    } else nil
end

local function normalize_safe_lanes(p15, p16, p17, p18) -- line: 148
    -- upvalues: v1 (copy), inverse_length_squared (copy)
    local v29 = p15 * p15 + p16 * p16 + p17 * p17
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = (if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32) * 1.401298464324817E-45

        if v29 < 0 then
            v30 = -v30
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readf32(v1, 0)
    end

    local v34 = v30 * inverse_length_squared(v30, 2)

    if v30 == 0 then
        v34 = 0
    end

    local v35 = inverse_length_squared(v29, 2)

    if v34 > 9.999999974752427E-07 then
        return p15 * v35, p16 * v35, p17 * v35, p18 * v35
    end

    return 0, 0, 0, 0
end

local function line_frame_axes(p19, p20, p21) -- line: 165
    -- upvalues: normalize_safe_lanes (copy)
    local v36 = p20[1] - p19[1]
    local v37 = p20[2] - p19[2]
    local v38 = p20[3] - p19[3]
    local v39 = p20[4] - p19[4]
    local v40 = p21[1]
    local v41 = p21[2]
    local v42 = p21[3]
    local v43 = p21[4]
    local v44 = -v38 * v41 + v37 * v42
    local v45 = -v36 * v42 + v38 * v40
    local v46 = -v37 * v40 + v36 * v41
    local v47 = -v39 * v43 + v39 * v43
    local v48 = -v46 * v37 + v45 * v38
    local v49 = -v44 * v38 + v46 * v36
    local v50 = -v45 * v36 + v44 * v37
    local v51 = -v47 * v39 + v47 * v39
    local v52, v53, v54, v55 = normalize_safe_lanes(v44, v45, v46, v47)
    local v56, v57, v58, v59 = normalize_safe_lanes(v48, v49, v50, v51)
    local v60, v61, v62, v63 = normalize_safe_lanes(v36, v37, v38, v39)

    if (v56 * v56 + v57 * v57 + v58 * v58) * (v52 * v52 + v53 * v53 + v54 * v54) * (v60 * v60 + v61 * v61 + v62 * v62) > 1.52587890625E-05 then
        return true, v52, v53, v54, v55, v60, v61, v62, v63, v56, v57, v58, v59
    end

    return false, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
end

local function line_mapping(p22, p23, p24, p25, p26, p27) -- line: 201
    -- upvalues: line_frame_axes (copy)
    local v64, v65, v66, v67, _, v68, v69, v70, _, v71, v72, v73 = line_frame_axes(p22, p23, p24)

    if not v64 then
        return nil
    end

    local v74, v75, v76, v77, v78, v79, v80, v81, v82, v83, v84, v85, v86 = line_frame_axes(p25, p26, p27)

    if not v74 then
        return nil
    end

    local v87 = 0 - p22[1]
    local v88 = 0 - p22[2]
    local v89 = 0 - p22[3]
    local v90 = v87 * v65 + (v88 * v66 + v89 * v67)
    local v91 = v87 * v68 + (v88 * v69 + v89 * v70)
    local v92 = v87 * v71 + (v88 * v72 + v89 * v73)

    return {
        {
            v71 * v83 + (v68 * v79 + v65 * v75),
            v71 * v84 + (v68 * v80 + v65 * v76),
            v71 * v85 + (v68 * v81 + v65 * v77),
            v71 * v86 + (v68 * v82 + v65 * v78)
        },
        {
            v72 * v83 + (v69 * v79 + v66 * v75),
            v72 * v84 + (v69 * v80 + v66 * v76),
            v72 * v85 + (v69 * v81 + v66 * v77),
            v72 * v86 + (v69 * v82 + v66 * v78)
        },
        {
            v73 * v83 + (v70 * v79 + v67 * v75),
            v73 * v84 + (v70 * v80 + v67 * v76),
            v73 * v85 + (v70 * v81 + v67 * v77),
            v73 * v86 + (v70 * v82 + v67 * v78)
        },
        {
            v83 * v92 + (v79 * v91 + (v75 * v90 + p25[1])),
            v84 * v92 + (v80 * v91 + (v76 * v90 + p25[2])),
            v85 * v92 + (v81 * v91 + (v77 * v90 + p25[3])),
            v86 * v92 + (v82 * v91 + (v78 * v90 + p25[4]))
        }
    }
end

local function v93(p28, p29, p30, p31, p32, p33) -- line: 246
    -- upvalues: inverse_rigid (copy), compose_affine (copy), line_frame (copy)
    local v94 = line_frame(p28, p29, p30)

    if v94 == nil then
        return nil
    end

    local v95 = line_frame(p31, p32, p33)

    if v95 == nil then
        return nil
    end

    return compose_affine(v95, inverse_rigid(v94))
end

local function clamp_point(p34, p35, p36) -- line: 260
    -- upvalues: rt (copy), length (copy)
    local t3 = {
        p34[1] - p35[1],
        p34[2] - p35[2],
        p34[3] - p35[3],
        p34[4] - p35[4]
    }
    local v96 = length(t3)

    if v96 <= p36 then
        return rt.copy(p34)
    end

    local v97 = p36 / v96

    return {
        t3[1] * v97 + p35[1],
        t3[2] * v97 + p35[2],
        t3[3] * v97 + p35[3],
        t3[4] * v97 + p35[4]
    }
end

local function solve_drives(p37, p38, p39, p40, p41, p42, p43) -- line: 288
    -- upvalues: cross (copy), length (copy), normalize (copy), v10 (copy), compose_affine (copy), orthonormalize (copy), line_mapping (copy), clamp_point (copy)
    local v98 = p40.parents[p37 + 1]

    if v98 == nil then
        return nil
    end

    local v99 = p40.parents[v98 + 1]

    if v99 == nil then
        return nil
    end

    local v100 = p41[v99 + 1][4]
    local v101 = p41[v98 + 1][4]
    local v102 = p41[p37 + 1][4]
    local t4 = {
        v102[1] + p38[1],
        v102[2] + p38[2],
        v102[3] + p38[3],
        v102[4] + p38[4]
    }
    local v103 = clamp_point(t4, v100, p39)
    local t5 = {
        0, 0, 0, 0
    }

    if v10.solve(v100, v101, v102, t5, v103, p43, true, 2) == "Invalid" then
        return nil
    end

    local t6 = {
        v103[1] - t4[1],
        v103[2] - t4[2],
        v103[3] - t4[3],
        v103[4] - t4[4]
    }
    local v104 = cross({
        v100[1] - v101[1],
        v100[2] - v101[2],
        v100[3] - v101[3],
        v100[4] - v101[4]
    }, {
        v102[1] - v101[1],
        v102[2] - v101[2],
        v102[3] - v101[3],
        v102[4] - v101[4]
    })
    local v105 = cross({
        v100[1] - t5[1],
        v100[2] - t5[2],
        v100[3] - t5[3],
        v100[4] - t5[4]
    }, {
        v103[1] - t5[1],
        v103[2] - t5[2],
        v103[3] - t5[3],
        v103[4] - t5[4]
    })
    local t7 = {
        v104[1] + v105[1],
        v104[2] + v105[2],
        v104[3] + v105[3],
        v104[4] + v105[4]
    }
    local v106 = length(t7)
    local v107 = normalize(t7)

    if not (v106 > 9.999999974752427E-07) then
        v107 = { 0, 0, 0, 0 }
    end

    local v108 = line_mapping(v101, v102, v107, t5, v103, v107)

    if v108 == nil then
        return nil
    end

    local v109 = line_mapping(v100, v101, v107, v100, t5, v107)

    if v109 == nil then
        return nil
    end

    p42[v99 + 1] = orthonormalize(compose_affine(v109, p42[v99 + 1]))
    p42[v98 + 1] = orthonormalize(compose_affine(v108, p42[v98 + 1]))

    return t6
end

local function v110(p44, p45, p46, p47, p48, p49, p50) -- line: 331
    -- upvalues: rt (copy), cross (copy), length (copy), normalize (copy), v10 (copy), compose_affine (copy), orthonormalize (copy), v93 (copy), clamp_point (copy)
    local v111 = p47.parents[p44 + 1]

    if v111 == nil then
        return nil
    end

    local v112 = p47.parents[v111 + 1]

    if v112 == nil then
        return nil
    end

    local v113 = rt.copy(p48[v112 + 1][4])
    local v114 = rt.copy(p48[v111 + 1][4])
    local v115 = rt.copy(p48[p44 + 1][4])
    local t8 = {
        v115[1] + p45[1],
        v115[2] + p45[2],
        v115[3] + p45[3],
        v115[4] + p45[4]
    }
    local v116 = clamp_point(t8, v113, p46)
    local t9 = {
        0, 0, 0, 0
    }

    if v10.solve(v113, v114, v115, t9, v116, p50, true, 2) == "Invalid" then
        return nil
    end

    local t10 = {
        v116[1] - t8[1],
        v116[2] - t8[2],
        v116[3] - t8[3],
        v116[4] - t8[4]
    }
    local v117 = cross({
        v113[1] - v114[1],
        v113[2] - v114[2],
        v113[3] - v114[3],
        v113[4] - v114[4]
    }, {
        v115[1] - v114[1],
        v115[2] - v114[2],
        v115[3] - v114[3],
        v115[4] - v114[4]
    })
    local v118 = cross({
        v113[1] - t9[1],
        v113[2] - t9[2],
        v113[3] - t9[3],
        v113[4] - t9[4]
    }, {
        v116[1] - t9[1],
        v116[2] - t9[2],
        v116[3] - t9[3],
        v116[4] - t9[4]
    })
    local t11 = {
        v117[1] + v118[1],
        v117[2] + v118[2],
        v117[3] + v118[3],
        v117[4] + v118[4]
    }
    local v119 = length(t11)
    local v120 = normalize(t11)

    if not (v119 > 9.999999974752427E-07) then
        v120 = { 0, 0, 0, 0 }
    end

    local v121 = v93(v114, v115, v120, t9, v116, v120)

    if v121 == nil then
        return nil
    end

    local v122 = v93(v113, v114, v120, v113, t9, v120)

    if v122 == nil then
        return nil
    end

    p49[v112 + 1] = orthonormalize(compose_affine(v122, p49[v112 + 1]))
    p49[v111 + 1] = orthonormalize(compose_affine(v121, p49[v111 + 1]))

    return t10
end

function t1.update(p51, p52, p53, p54, p55, p56, p57, p58) -- line: 381
    -- upvalues: compose_affine (copy), transform_point (copy), solve_drives (copy)
    local t12 = {
        false,
        false,
        false,
        false
    }

    for i = 0, 3 do
        if p51[i + 1].mode ~= "Disabled" then
            local v123 = p53[i + 1]
            local v124 = compose_affine(p57, p52[i + 1].world)
            local v125 = if v123.parent_part == nil then nil else compose_affine(p57, p52[i + 1].parent_world)
            local v126 = if v123.parent_part == nil then v123.part else v123.parent_part
            local v128 = transform_point(if v125 == nil then v124 else v125, p54.inverse_part_frames[v126 + 1][4])
            local v129 = p55[v126 + 1][4]
            local v131 = solve_drives(v126, {
                v128[1] - v129[1],
                v128[2] - v129[2],
                v128[3] - v129[3],
                v128[4] - v129[4]
            }, if i < 2 then 0.800000011920929 else 1, p54, p55, p56, p58)

            if v131 ~= nil then
                p56[v123.part + 1] = v124
                v124[4][1] += v131[1]
                v124[4][2] += v131[2]
                v124[4][3] += v131[3]
                v124[4][4] += v131[4]

                local world = p52[i + 1].world

                world[4][1] += v131[1]
                world[4][2] += v131[2]
                world[4][3] += v131[3]
                world[4][4] += v131[4]

                local parent_part = v123.parent_part

                if parent_part ~= nil then
                    if v125 == nil then
                        error("called `Option::unwrap()` on a `None` value", 0)
                    end

                    p56[parent_part + 1] = v125
                    v125[4][1] += v131[1]
                    v125[4][2] += v131[2]
                    v125[4][3] += v131[3]
                    v125[4][4] += v131[4]

                    local parent_world = p52[i + 1].parent_world

                    parent_world[4][1] += v131[1]
                    parent_world[4][2] += v131[2]
                    parent_world[4][3] += v131[3]
                    parent_world[4][4] += v131[4]
                end

                t12[i + 1] = true
            end
        end
    end

    return t12
end

function t1.update_reference(p59, p60, p61, p62, p63, p64, p65, p66) -- line: 446
    -- upvalues: rt (copy), compose_affine (copy), transform_point (copy), v110 (copy)
    local t14 = {
        false,
        false,
        false,
        false
    }

    for i = 0, 3 do
        if p59[i + 1].mode ~= "Disabled" then
            local v132 = rt.copy(p61[i + 1])
            local v133 = compose_affine(p65, p60[i + 1].world)
            local v134 = if v132.parent_part == nil then nil else compose_affine(p65, p60[i + 1].parent_world)
            local v135 = if v132.parent_part == nil then v132.part else v132.parent_part
            local v137 = transform_point(if v134 == nil then v133 else v134, p62.inverse_part_frames[v135 + 1][4])
            local v138 = p63[v135 + 1][4]
            local v140 = v110(v135, {
                v137[1] - v138[1],
                v137[2] - v138[2],
                v137[3] - v138[3],
                v137[4] - v138[4]
            }, if i < 2 then 0.800000011920929 else 1, p62, p63, p64, p66)

            if v140 ~= nil then
                p64[v132.part + 1] = rt.copy(v133)

                local v141 = p64[v132.part + 1]

                v141[4][1] += v140[1]
                v141[4][2] += v140[2]
                v141[4][3] += v140[3]
                v141[4][4] += v140[4]

                local world = p60[i + 1].world

                world[4][1] += v140[1]
                world[4][2] += v140[2]
                world[4][3] += v140[3]
                world[4][4] += v140[4]

                local parent_part = v132.parent_part

                if parent_part ~= nil then
                    if v134 == nil then
                        error("called `Option::unwrap()` on a `None` value", 0)
                    end

                    p64[parent_part + 1] = rt.copy(v134)

                    local v142 = p64[parent_part + 1]

                    v142[4][1] += v140[1]
                    v142[4][2] += v140[2]
                    v142[4][3] += v140[3]
                    v142[4][4] += v140[4]

                    local parent_world = p60[i + 1].parent_world

                    parent_world[4][1] += v140[1]
                    parent_world[4][2] += v140[2]
                    parent_world[4][3] += v140[3]
                    parent_world[4][4] += v140[4]
                end

                t14[i + 1] = true
            end
        end
    end

    return t14
end

t1.solve_drives_reference = v110
t1.line_mapping_reference = v93
t1.solve_drives = solve_drives
t1.clamp_point = clamp_point
t1.line_mapping = line_mapping
t1.line_frame = line_frame
t1.normalize_safe = normalize_safe
t1.subtract = subtract
t1.add_translation = add_translation

return t1
