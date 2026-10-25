-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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
local v8 = import("skate_core/physics/solver/contact")
local v9 = import("skate_core/physics/solver/drive")
local v10 = import("skate_core/physics/solver/joint")
local t1 = {
    Constraint = {}
}

t1.Contact = t1.Constraint
t1.Joint = t1.Constraint
t1.Drive = t1.Constraint
t1.Reaction = {}

function t1.solve(p3, p4, p5, p6, p7) -- line: 49
    -- upvalues: v8 (copy), v9 (copy), v10 (copy), t1 (copy)
    t1.validate(p3, #p6)
    t1.validate(p4, #p6)
    t1.validate(p5, #p6)

    local mirror = v8.mirror
    local v11 = table.create(#p6)

    for v12, v13 in ipairs(p6) do
        v11[v12] = mirror(v13)
    end

    local v14 = table.create(#p3)

    for v15, v16 in ipairs(p3) do
        v14[v15] = mirror(v16.words)
    end

    local v17 = table.create(#p4)

    for v18, v19 in ipairs(p4) do
        v17[v18] = mirror(v19.words)
    end

    local v20 = table.create(#p5)

    for v21, v22 in ipairs(p5) do
        v20[v21] = mirror(v22.words)
    end

    for _ = 0, p7 - 1 do
        t1.pass_mirrored(p3, v14, p6, v11, 64, v8.solve_mirrored)
        t1.pass_mirrored(p4, v17, p6, v11, 96, v10.solve_mirrored)
        t1.pass_mirrored(p5, v20, p6, v11, 96, v9.solve_mirrored)
    end

    local store = v8.store

    for v23, v24 in ipairs(p3) do
        store(v24.words, v14[v23], 21, 24)
    end

    for v25, v26 in ipairs(p4) do
        store(v26.words, v17[v25], 9, 16)
    end

    for v27, v28 in ipairs(p5) do
        store(v28.words, v20[v27], 9, 16)
    end

    for v29, v30 in ipairs(p6) do
        store(v30, v11[v29], 1, 16)
    end
end

function t1.pass_mirrored(p8, p9, p10, p11, p12, p13) -- line: 97
    for v31, v32 in ipairs(p8) do
        local v33 = v32.reaction_a + 1
        local v34 = v32.reaction_b + 1
        local words = v32.words
        local v35 = p10[v33]
        local v36 = p10[v34]

        if #words ~= p12 then
            error("assertion `left == right` failed\n  left: " .. #words .. "\n right: " .. p12, 0)
        end

        if #v35 ~= 16 then
            error("assertion `left == right` failed\n  left: " .. #v35 .. "\n right: 16", 0)
        end

        if #v36 ~= 16 then
            error("assertion `left == right` failed\n  left: " .. #v36 .. "\n right: 16", 0)
        end

        p13(words, p9[v31], v35, p11[v33], v36, p11[v34])
    end
end

local v37 = buffer.create(8)

local function pooled_mirror(p14, p15, p16) -- line: 122
    -- upvalues: v37 (copy)
    local v38 = #p16
    local v39 = p14[p15]

    if v39 == nil then
        v39 = table.create(v38)
        p14[p15] = v39
    end

    for i = 1, v38 do
        buffer.writeu32(v37, 0, p16[i])
        v39[i] = buffer.readf32(v37, 0)
    end

    return v39
end

local t2 = {}
local t3 = {}
local t4 = {}
local t5 = {}

local function pass_xyz(p17, p18, p19, p20, p21, p22) -- line: 137
    for v41, v42 in ipairs(p17) do
        local v43 = v42.reaction_a + 1
        local v44 = v42.reaction_b + 1
        local words = v42.words
        local v45 = p19[v43]
        local v46 = p19[v44]

        if #words ~= p21 then
            error("assertion `left == right` failed\n  left: " .. #words .. "\n right: " .. p21, 0)
        end

        if #v45 ~= 16 then
            error("assertion `left == right` failed\n  left: " .. #v45 .. "\n right: 16", 0)
        end

        if #v46 ~= 16 then
            error("assertion `left == right` failed\n  left: " .. #v46 .. "\n right: 16", 0)
        end

        p22(p18[v41], p20[v43], p20[v44])
    end
end

local v47 = false

function t1.set_pass_r3(p23) -- line: 156
    -- upvalues: v47 (ref)
    local v48 = v47

    v47 = p23

    return v48
end

local t6 = {}
local t7 = {}
local t8 = {}
local t9 = {}
local t10 = {}
local t11 = {}

function t1.solve_xyz(p24, p25, p26, p27, p28) -- line: 162
    -- upvalues: v8 (copy), v9 (copy), v10 (copy), t1 (copy), pooled_mirror (copy), t2 (copy), t3 (copy), t4 (copy), t5 (copy), pass_xyz (copy), v47 (ref), t6 (copy), t7 (copy), t8 (copy), t9 (copy), t10 (copy), t11 (copy)
    t1.validate(p24, #p27)
    t1.validate(p25, #p27)
    t1.validate(p26, #p27)

    for v49, v50 in ipairs(p27) do
        pooled_mirror(t5, v49, v50)
    end

    for v51, v52 in ipairs(p24) do
        pooled_mirror(t2, v51, v52.words)
    end

    for v53, v54 in ipairs(p25) do
        pooled_mirror(t3, v53, v54.words)
    end

    for v55, v56 in ipairs(p26) do
        pooled_mirror(t4, v55, v56.words)
    end

    local v57

    if v47 then
        local v58 = p28 - 1

        v57 = false

        for _ = 0, v58 do
            pass_xyz(p24, t2, p27, t5, 64, v8.solve_mirrored_xyz)
            pass_xyz(p25, t3, p27, t5, 96, v10.solve_mirrored_xyz)
            v57 = true
            pass_xyz(p26, t4, p27, t5, 96, v9.solve_mirrored_xyz)
        end
    elseif p28 >= 1 then
        local solve_mirrored_xyz = v8.solve_mirrored_xyz
        local solve_mirrored_xyz2 = v10.solve_mirrored_xyz
        local solve_mirrored_xyz3 = v9.solve_mirrored_xyz

        pass_xyz(p24, t2, p27, t5, 64, solve_mirrored_xyz)
        pass_xyz(p25, t3, p27, t5, 96, solve_mirrored_xyz2)
        pass_xyz(p26, t4, p27, t5, 96, solve_mirrored_xyz3)

        if p28 >= 2 then
            local n1 = 0

            for v59, v60 in ipairs(p24) do
                n1 = v59

                local v61 = t5[v60.reaction_a + 1]
                local v62 = t5[v60.reaction_b + 1]

                t6[v59] = v61
                t7[v59] = v62
            end

            local n2 = 0

            for v63, v64 in ipairs(p25) do
                n2 = v63

                local v65 = t5[v64.reaction_a + 1]
                local v66 = t5[v64.reaction_b + 1]

                t8[v63] = v65
                t9[v63] = v66
            end

            local n3 = 0

            for v67, v68 in ipairs(p26) do
                n3 = v67

                local v69 = t5[v68.reaction_a + 1]
                local v70 = t5[v68.reaction_b + 1]

                t10[v67] = v69
                t11[v67] = v70
            end

            for _ = 1, p28 - 1 do
                for i = 1, n1 do
                    solve_mirrored_xyz(t2[i], t6[i], t7[i])
                end

                for j = 1, n2 do
                    solve_mirrored_xyz2(t3[j], t8[j], t9[j])
                end

                for k = 1, n3 do
                    solve_mirrored_xyz3(t4[k], t10[k], t11[k])
                end
            end

            table.clear(t6)
            table.clear(t7)
            table.clear(t8)
            table.clear(t9)
            table.clear(t10)
            table.clear(t11)
        end

        v57 = true
    else
        v57 = false
    end

    if not v57 then
        return
    end

    local store = v8.store

    for v71, v72 in ipairs(p24) do
        store(v72.words, t2[v71], 21, 24)
    end

    for v73, v74 in ipairs(p25) do
        store(v74.words, t3[v73], 9, 16)
    end

    for v75, v76 in ipairs(p26) do
        store(v76.words, t4[v75], 9, 16)
    end

    for v77, v78 in ipairs(p27) do
        local v79 = t5[v77]

        store(v78, v79, 1, 3)
        store(v78, v79, 5, 7)
        store(v78, v79, 9, 11)
        store(v78, v79, 13, 15)
    end
end

t1.drive_rows = {}
t1.reaction_rows = {}

local v90, v91 = (function() -- lanes_probe | line: 319
    -- upvalues: v1 (copy)
    local v80 = buffer.create(8)
    local n4 = 0
    local n5 = 0

    for v81, v82 in {
            1E-40, -1E-40, 1.401298464324817E-45, -1.401298464324817E-45, 2.1019476964872256E-45, 3.5032461608120427E-45, 7.006493722922549E-46, 7.006490920325621E-46,
            3E-45, 7.006492321624085E-46, 8.816207631167156E-39, -3.918314110909508E-39, 1.1754942106924411E-38, 1.1754943157898259E-38, 1.1754943497275231E-38, 5E-324
        } do
        local v84 = vector.create(v82, -v82, v82)
        local v85

        if v82 == 0 then
            buffer.writef32(v1, 0, v82)
            v85 = buffer.readu32(v1, 0)
        elseif v82 > -1.1754943508222875E-38 and v82 < 1.1754943508222875E-38 then
            local v86 = math.abs(v82) * 7.1362384635298E+44

            v85 = math.floor(v86)

            local v87 = v86 - v85

            if v87 > 0.5 or v87 == 0.5 and v85 % 2 == 1 then
                v85 += 1
            end

            if v82 < 0 then
                v85 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v82)
            v85 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v80, 0, v85)

        local v88 = buffer.readf32(v80, 0)

        for i = 1, 3 do
            local v89 = if i == 1 then v84.x elseif i == 2 then -v84.y else v84.z

            if v89 == v88 then
                n5 += 1
            else
                if v89 ~= 0 then
                    return false, (("refused: probe %* lane %* is %*, neither 0 nor %*"):format(v81, i, v89, v88))
                end

                n4 += 1
            end
        end
    end

    if n4 == 0 then
        return true, "subnormal lanes kept (IEEE)"
    end

    return true, (("subnormal lanes flushed to zero (%* of %*)"):format(n4, n4 + n5))
end)()
local v92 = v90

function t1.set_lanes_first(p29) -- line: 363
    -- upvalues: v90 (copy), v92 (ref)
    local v93 = v92

    v92 = p29 and v90

    return v93
end

function t1.lanes_probe() -- line: 369
    -- upvalues: v90 (copy), v91 (copy)
    return v90, v91
end

function t1.lanes_first() -- line: 373
    -- upvalues: v92 (ref)
    return v92
end

t1.contact_rows = t2

local drive_rows, reaction_rows = t1.drive_rows, t1.reaction_rows
local t12 = {}
local t13 = {}
local t14 = {}
local t15 = {}
local t16 = {}
local t17 = {}
local t18 = {}
local t19 = {}
local n6 = 0
local n7 = 0

function t1.last_kernels() -- line: 397
    -- upvalues: v8 (copy), v9 (copy), v10 (copy), t12 (copy), n7 (ref)
    local t20 = {
        contact = 0,
        contact_b0 = 0,
        joint = 0,
        drive = 0,
        drive_angular = 0,
        drive_inert = 0
    }

    for i = 1, n7 do
        local v95 = t12[i]

        t20[if v95 == v8.solve_w3 then "contact"
            elseif v95 == v8.solve_w3_b0 then "contact_b0"
            elseif v95 == v10.solve_w3 then "joint"
            elseif v95 == v9.solve_w3 then "drive"
            elseif v95 == v9.solve_w3_angular then "drive_angular"
            else "drive_inert"] += 1
    end

    return t20
end

local function contact_extras(p30) -- line: 413
    local v96 = p30[29] + p30[30] + p30[31] + p30[33] + p30[34] + p30[35] + p30[36] + p30[37] + p30[38] + p30[39] + p30[40] + p30[41] + p30[42] + p30[43] + p30[45] + p30[46] + p30[47] + p30[49] + p30[50] + p30[51] + p30[53] + p30[54] + p30[55] + p30[57] + p30[58] + p30[59] + p30[61] + p30[62] + p30[63]

    p30[65] = v96 - v96 == 0 and 1 or 0
end

t1.contact_extras = contact_extras

local function contact_b_inert(p31) -- line: 424
    if p31[40] ~= 0 then
        return false
    end

    local v97 = p31[16]
    local v98 = p31[20]

    if p31[37] == 0 and p31[38] == 0 and p31[39] == 0 and p31[49] == 0 and p31[50] == 0 and p31[51] == 0 and p31[61] == 0 and p31[62] == 0 and p31[63] == 0 and v97 >= -1 and v97 <= 1 and v98 >= -1 and v98 <= 1 then
        local v99 = p31[5] + p31[6] + p31[7] + p31[21] + p31[22] + p31[23] + p31[24] + p31[29] + p31[30] + p31[31] + p31[41] + p31[42] + p31[43] + p31[53] + p31[54] + p31[55]

        return v99 - v99 == 0
    end

    return false
end

t1.contact_b_inert = contact_b_inert

local function joint_extras(p32) -- line: 452
    local v100 = -p32[85]
    local v101 = -p32[86]
    local v102 = -p32[87]

    p32[97] = v100
    p32[98] = v101
    p32[99] = v102

    local v103 = -p32[89]
    local v104 = -p32[90]
    local v105 = -p32[91]

    p32[100] = v103
    p32[101] = v104
    p32[102] = v105

    local v106 = -p32[93]
    local v107 = -p32[94]
    local v108 = -p32[95]

    p32[103] = v106
    p32[104] = v107
    p32[105] = v108

    local v109 = p32[61] + p32[62] + p32[63] + p32[65] + p32[66] + p32[67] + p32[69] + p32[70] + p32[71]

    p32[106] = v109 - v109 == 0 and 1 or 0
end

t1.joint_extras = joint_extras

local function drive_kernel(p33) -- line: 462
    -- upvalues: v9 (copy)
    if p33[28] ~= 0
        or p33[32] ~= 0
        or p33[44] ~= 0
        or p33[9] ~= 0
        or p33[10] ~= 0
        or p33[11] ~= 0 then
        return v9.solve_w3
    end

    local v110 = p33[1] + p33[2] + p33[3] + p33[5] + p33[6] + p33[7] + p33[49] + p33[50] + p33[51] + p33[53] + p33[54] + p33[55] + p33[57] + p33[58] + p33[59] + p33[76] + p33[88]

    if v110 - v110 == 0 then
        p33[9] = 0
        p33[10] = 0
        p33[11] = 0

        if p33[36] == 0 and p33[40] == 0 and p33[48] == 0 and p33[13] == 0 and p33[14] == 0 and p33[15] == 0 then
            local v111 = p33[61] + p33[62] + p33[63] + p33[65] + p33[66] + p33[67] + p33[69] + p33[70] + p33[71] + p33[73] + p33[74] + p33[75] + p33[77] + p33[78] + p33[79] + p33[81] + p33[82] + p33[83] + p33[85] + p33[86] + p33[87] + p33[89] + p33[90] + p33[91] + p33[93] + p33[94] + p33[95]

            if v111 - v111 == 0 then
                p33[13] = 0
                p33[14] = 0
                p33[15] = 0

                return v9.solve_w3_inert
            end
        end

        return v9.solve_w3_angular
    end

    return v9.solve_w3
end

t1.drive_kernel = drive_kernel

local function reaction_plus_zero(p34) -- line: 486
    -- upvalues: reaction_rows (copy), t19 (copy), n6 (ref)
    local v112 = t19[p34]

    if v112 == n6 then
        return true
    end

    if v112 == -n6 then
        return false
    end

    local v114 = reaction_rows[p34]
    local v115 = v114[1]
    local v116 = v114[2]
    local v117 = v114[3]
    local v118 = v114[5]
    local v119 = v114[6]
    local v120 = v114[7]
    local v121 = v114[9]
    local v122 = v114[10]
    local v123 = v114[11]
    local v124 = v114[13]
    local v125 = v114[14]
    local v126 = v114[15]
    local v113 = v115 == 0 and v116 == 0 and v117 == 0 and v118 == 0 and v119 == 0 and v120 == 0 and v121 == 0 and v122 == 0 and v123 == 0 and v124 == 0 and v125 == 0 and v126 == 0 and 1 / v115 > 0 and 1 / v116 > 0 and 1 / v117 > 0 and 1 / v118 > 0 and 1 / v119 > 0 and 1 / v120 > 0 and 1 / v121 > 0 and 1 / v122 > 0 and 1 / v123 > 0 and 1 / v124 > 0 and 1 / v125 > 0 and 1 / v126 > 0

    t19[p34] = if v113 then n6 else -n6

    return v113
end

local function pair_error(p35, p36) -- line: 524
    error("assertion `left != right` failed\n  left: " .. p35 .. "\n right: " .. p36, 0)
end

local function validate_pairs(p37, p38, p39, p40) -- line: 529
    for i = 1, p37 do
        local v128 = p38[i]
        local v129 = p39[i]

        if v128 == v129 then
            error("assertion `left != right` failed\n  left: " .. v128 .. "\n right: " .. v129, 0)
        end

        if not (v128 < p40 and v129 < p40) then
            error("assertion failed: c.reaction_a < count && c.reaction_b < count", 0)
        end
    end
end

local t21 = {}
local n8 = 0

function t1.last_prepared_joints() -- line: 562
    -- upvalues: n8 (ref)
    return n8
end

function t1.solve_rows(p41, p42, p43, p44, p45, p46, p47, p48, p49, p50, p51, p52, p53, p54, p55, p56) -- line: 565
    -- upvalues: v8 (copy), v9 (copy), v10 (copy), pooled_mirror (copy), t2 (copy), t3 (copy), v92 (ref), drive_rows (copy), reaction_rows (copy), t12 (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy), t17 (copy), t18 (copy), n6 (ref), n7 (ref), contact_extras (copy), contact_b_inert (copy), joint_extras (copy), drive_kernel (copy), reaction_plus_zero (copy), validate_pairs (copy), t21 (copy), n8 (ref)
    validate_pairs(p41, p44, p45, p53)
    validate_pairs(p46, p48, p49, p53)
    validate_pairs(p50, p51, p52, p53)

    for i = p42 + 1, p41 do
        pooled_mirror(t2, i, p43[i])
    end

    local n9 = 0

    if p56 ~= nil then
        for i = 1, p46 do
            local v130 = p56[i]

            if v130 then
                t21[i] = v130
                n9 += 1
            else
                t21[i] = pooled_mirror(t3, i, p47[i])
            end
        end
    else
        for i = 1, p46 do
            n9 = 0
            t21[i] = pooled_mirror(t3, i, p47[i])
        end
    end

    n8 = n9

    if p54 >= 1 then
        for i = 1, p41 do
            local v131 = #p43[i]

            if v131 ~= 64 then
                error("assertion `left == right` failed\n  left: " .. v131 .. "\n right: 64", 0)
            end
        end

        for i = 1, p46 do
            local v132 = #p47[i]

            if v132 ~= 96 then
                error("assertion `left == right` failed\n  left: " .. v132 .. "\n right: 96", 0)
            end
        end

        n6 += 1

        local v133 = n6

        for i = 1, p46 do
            t18[p48[i] + 1] = v133
            t18[p49[i] + 1] = v133
        end

        for i = 1, p50 do
            t18[p51[i] + 1] = v133
            t18[p52[i] + 1] = v133
        end

        for i = 1, p41 do
            local v134 = t2[i]

            contact_extras(v134)
            t18[p44[i] + 1] = v133

            local v135 = contact_b_inert(v134)

            t17[i] = v135

            if not v135 then
                t18[p45[i] + 1] = v133
            end
        end

        local v136 = v92 and p55 == nil
        local solve_w3, solve_w3_b0 = v8.solve_w3, v8.solve_w3_b0
        local v137, v138

        if v136 then
            v138 = v8.solve_b3
            v137 = v8.solve_b3_b0
        else
            v137 = solve_w3_b0
            v138 = solve_w3
        end

        local n10 = 0

        for i = 1, p41 do
            local v139 = p45[i] + 1

            n10 += 1

            if t17[i] and t18[v139] ~= v133 and reaction_plus_zero(v139) then
                t12[n10] = solve_w3_b0
                t13[n10] = v137
            else
                t12[n10] = solve_w3
                t13[n10] = v138
            end

            t14[n10] = t2[i]
            t15[n10] = reaction_rows[p44[i] + 1]
            t16[n10] = reaction_rows[v139]
        end

        local solve_w3_2 = v10.solve_w3
        local v140 = if v136 then v10.solve_b3 else solve_w3_2

        for i = 1, p46 do
            local v141 = t21[i]

            joint_extras(v141)
            n10 += 1
            t12[n10] = solve_w3_2
            t13[n10] = v140
            t14[n10] = v141
            t15[n10] = reaction_rows[p48[i] + 1]
            t16[n10] = reaction_rows[p49[i] + 1]
        end

        local solve_w3_3, solve_w3_angular, solve_w3_inert = v9.solve_w3, v9.solve_w3_angular, v9.solve_w3_inert
        local v142, v143

        if v136 then
            v142 = v9.solve_b3
            v143 = v9.solve_b3_angular
            solve_w3_inert = v9.solve_b3_inert
        else
            v143 = solve_w3_angular
            v142 = solve_w3_3
        end

        for i = 1, p50 do
            local v144 = drive_rows[i]

            n10 += 1

            local v145 = drive_kernel(v144)

            t12[n10] = v145
            t13[n10] = if v145 == solve_w3_3 then v142 elseif v145 == solve_w3_angular then v143 else solve_w3_inert
            t14[n10] = v144
            t15[n10] = reaction_rows[p51[i] + 1]
            t16[n10] = reaction_rows[p52[i] + 1]
        end

        n7 = n10

        if p55 ~= nil then
            p55(n10, t12, t14, t15, t16, p41, p44, p45, p46, p48, p49, p50, p51, p52, p53, p54, reaction_rows)
        else
            for i = 1, n10 do
                t13[i](t14[i], t15[i], t16[i])
            end

            for _ = 1, p54 - 1 do
                for i = 1, n10 do
                    t13[i](t14[i], t15[i], t16[i])
                end
            end
        end

        local store = v8.store

        for i = 1, p41 do
            store(p43[i], t2[i], 21, 24)
        end

        for i = 1, p46 do
            store(p47[i], t21[i], 9, 16)
        end

        return true
    end

    n7 = 0

    return false
end

function t1.solve_reference(p57, p58, p59, p60, p61) -- line: 726
    -- upvalues: v8 (copy), v9 (copy), v10 (copy), t1 (copy)
    t1.validate(p57, #p60)
    t1.validate(p58, #p60)
    t1.validate(p59, #p60)

    for _ = 0, p61 - 1 do
        t1.pass(p57, p60, v8.solve_reference)
        t1.pass(p58, p60, v10.solve_reference)
        t1.pass(p59, p60, v9.solve_reference)
    end
end

function t1.validate(p62, p63) -- line: 737
    for _, v147 in ipairs(p62) do
        if v147.reaction_a == v147.reaction_b then
            error("assertion `left != right` failed\n  left: " .. v147.reaction_a .. "\n right: " .. v147.reaction_b, 0)
        end

        if not (v147.reaction_a < p63) or not (v147.reaction_b < p63) then
            error("assertion failed: c.reaction_a < count && c.reaction_b < count", 0)
        end
    end
end

function t1.pass(p64, p65, p66) -- line: 754
    for _, v148 in ipairs(p64) do
        local v149 = p65[v148.reaction_a + 1]
        local v150 = p65[v148.reaction_b + 1]

        p66(v148.words, v149, v150)
    end
end

return t1
