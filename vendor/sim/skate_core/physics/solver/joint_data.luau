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

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {}

function t1.read_column(p4, p5) -- line: 42
    -- upvalues: rt (copy), v1 (copy)
    buffer.writeu32(v1, 0, p4[rt.idiv(p5, 4) + 0 + 1])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[rt.idiv(p5, 4) + 1 + 1])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[rt.idiv(p5, 4) + 2 + 1])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[rt.idiv(p5, 4) + 3 + 1])

    return {
        v9,
        v11,
        v13,
        (buffer.readf32(v1, 0))
    }
end

function t1.write_column(p6, p7, p8) -- line: 51
    -- upvalues: rt (copy), v1 (copy)
    local v15 = rt.idiv(p7, 4)
    local v16 = v15 + 0 + 1
    local v17 = p8[1]
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20

        if v17 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readu32(v1, 0)
    end

    p6[v16] = v18

    local v22 = v15 + 1 + 1
    local v23 = p8[2]
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

    p6[v22] = v24

    local v28 = v15 + 2 + 1
    local v29 = p8[3]
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if v29 < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readu32(v1, 0)
    end

    p6[v28] = v30

    local v34 = v15 + 3 + 1
    local v35 = p8[4]
    local v36

    if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
        local v37 = math.abs(v35) * 7.1362384635298E+44
        local v38 = math.floor(v37)
        local v39 = v37 - v38

        v36 = if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38

        if v35 < 0 then
            v36 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v35)
        v36 = buffer.readu32(v1, 0)
    end

    p6[v34] = v36
end

function t1.xyz(p9) -- line: 58
    -- upvalues: Vector3 (copy)
    return Vector3.new(p9[1], p9[2], p9[3])
end

t1.ConstraintGeometry = {}

function t1.ConstraintGeometry.decode(p10) -- line: 69
    -- upvalues: t1 (copy)
    if #p10 ~= 96 then
        error("assertion `left == right` failed\n  left: " .. #p10 .. "\n right: 96", 0)
    end

    return {
        arm_a = t1.xyz(t1.read_column(p10, 0)),
        arm_b = t1.xyz(t1.read_column(p10, 16)),
        linear_projection = {
            t1.read_column(p10, 64),
            t1.read_column(p10, 96),
            t1.read_column(p10, 128)
        },
        angular_projection = {
            t1.read_column(p10, 80),
            t1.read_column(p10, 112),
            t1.read_column(p10, 144)
        },
        linear_axes = {
            t1.read_column(p10, 192),
            t1.read_column(p10, 208),
            t1.read_column(p10, 224)
        },
        angular_axes = {
            t1.read_column(p10, 240),
            t1.read_column(p10, 256),
            t1.read_column(p10, 272)
        },
        inverse_inertia_a = {
            t1.read_column(p10, 288),
            t1.read_column(p10, 304),
            t1.read_column(p10, 320)
        },
        inverse_inertia_b = {
            t1.read_column(p10, 336),
            t1.read_column(p10, 352),
            t1.read_column(p10, 368)
        }
    }
end

function t1.ConstraintGeometry.relative_corrections(p11, p12, p13) -- line: 112
    -- upvalues: Vector3 (copy), t1 (copy)
    local v40 = t1.point_correction(p12, p11.arm_a)
    local v41 = t1.point_correction(p13, p11.arm_b)

    return Vector3.new(v41.x - v40.x, v41.y - v40.y, v41.z - v40.z), Vector3.new(p13.angular[1] - p12.angular[1], p13.angular[2] - p12.angular[2], p13.angular[3] - p12.angular[3])
end

function t1.ConstraintGeometry.apply_impulse_changes(p14, p15, p16, p17, p18) -- line: 121
    -- upvalues: t1 (copy)
    local v42 = t1.project_correction(p14.linear_axes, p17, table.create(4, 0))
    local v43 = t1.xyz(t1.project_correction(p14.angular_axes, p18, table.create(4, 0)))
    local v44 = t1.torque_at_offset(p14.arm_a, t1.xyz(v42), v43)
    local v45 = t1.torque_at_offset(p14.arm_b, t1.xyz(v42), v43)
    local v46 = p14.inverse_inertia_a[1][4]
    local v47 = p14.inverse_inertia_b[1][4]

    for i = 0, 3 do
        local v48 = v42[i + 1]

        p15.linear[i + 1] = v48 * v46 + p15.linear[i + 1]
        p16.linear[i + 1] = -v48 * v47 + p16.linear[i + 1]
    end

    p15.angular = t1.project_correction(p14.inverse_inertia_a, v44, p15.angular)

    for i = 0, 3 do
        local v49 = -p14.inverse_inertia_b[1][i + 1] * v45.x + p16.angular[i + 1]
        local v50 = -p14.inverse_inertia_b[2][i + 1] * v45.y + v49

        p16.angular[i + 1] = -p14.inverse_inertia_b[3][i + 1] * v45.z + v50
    end
end

t1.ReactionState = {}

function t1.ReactionState.decode(p19) -- line: 147
    -- upvalues: t1 (copy)
    if #p19 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p19 .. "\n right: 16", 0)
    end

    return {
        linear = t1.read_column(p19, 0),
        angular = t1.read_column(p19, 32)
    }
end

function t1.publish_reactions(p20, p21, p22, p23) -- line: 157
    -- upvalues: t1 (copy)
    t1.write_column(p22, 0, p20.linear)
    t1.write_column(p23, 0, p21.linear)
    t1.write_column(p22, 32, p20.angular)
    t1.write_column(p23, 32, p21.angular)
end

function t1.project_correction(p24, p25, p26) -- line: 167
    -- upvalues: rt (copy)
    return rt.from_fn(4, function(p27) -- line: 168
        -- upvalues: p24 (copy), p25 (copy), p26 (copy)
        local v51 = p24[1][p27 + 1] * p25.x + p26[p27 + 1]
        local v52 = p24[2][p27 + 1] * p25.y + v51

        return p24[3][p27 + 1] * p25.z + v52
    end)
end

function t1.point_correction(p28, p29) -- line: 175
    -- upvalues: Vector3 (copy)
    local v53 = p28.angular[1]
    local v54 = p28.angular[2]
    local v55 = p28.angular[3]

    return Vector3.new(-v55 * p29.y + (v54 * p29.z + p28.linear[1]), -v53 * p29.z + (v55 * p29.x + p28.linear[2]), -v54 * p29.x + (v53 * p29.y + p28.linear[3]))
end

function t1.torque_at_offset(p30, p31, p32) -- line: 184
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p30.z * p31.y + (p30.y * p31.z + p32.x), -p30.x * p31.z + (p30.z * p31.x + p32.y), -p30.y * p31.x + (p30.x * p31.y + p32.z))
end

local v56 = buffer.create(8)

local function fb(p33) -- line: 198
    -- upvalues: v56 (copy)
    buffer.writeu32(v56, 0, p33)

    return (buffer.readf32(v56, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p34) -- line: 203
    -- upvalues: v56 (copy), to_bits (copy)
    if p34 ~= 0 and p34 > -1.1754943508222875E-38 and p34 < 1.1754943508222875E-38 then
        return to_bits(p34)
    end

    buffer.writef32(v56, 0, p34)

    return (buffer.readu32(v56, 0))
end

function t1.relative_corrections_packed(p35, p36, p37) -- line: 213
    local v57 = p36[9]
    local v58 = p36[10]
    local v59 = p36[11]
    local v60 = p37[9]
    local v61 = p37[10]
    local v62 = p37[11]
    local v63 = p35[1]
    local v64 = p35[2]
    local v65 = p35[3]
    local v66 = p35[5]
    local v67 = p35[6]
    local v68 = p35[7]
    local v69 = -v59 * v64 + (v58 * v65 + p36[1])
    local v70 = -v57 * v65 + (v59 * v63 + p36[2])
    local v71 = -v58 * v63 + (v57 * v64 + p36[3])
    local v72 = -v62 * v67 + (v61 * v68 + p37[1])
    local v73 = -v60 * v68 + (v62 * v66 + p37[2])
    local v74 = -v61 * v66 + (v60 * v67 + p37[3])

    return v72 - v69, v73 - v70, v74 - v71, v60 - v57, v61 - v58, v62 - v59
end

local function put(_, p39, p40, p41) -- line: 240
    -- upvalues: v56 (copy), to_bits (copy)
    if p41 ~= 0 and p41 > -1.1754943508222875E-38 and p41 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(p41))
    else
        buffer.writef32(v56, 0, p41)
    end

    p39[p40] = buffer.readf32(v56, 0)
end

function t1.apply_impulse_changes_packed(p42, _, p44, _, p46, p47, p48, p49, p50, p51, p52) -- line: 249
    -- upvalues: v56 (copy), to_bits (copy)
    local v75 = p42[57] * p49 + (p42[53] * p48 + (p42[49] * p47 + 0))
    local v76 = p42[58] * p49 + (p42[54] * p48 + (p42[50] * p47 + 0))
    local v77 = p42[59] * p49 + (p42[55] * p48 + (p42[51] * p47 + 0))
    local v78 = p42[60] * p49 + (p42[56] * p48 + (p42[52] * p47 + 0))
    local v79 = p42[69] * p52 + (p42[65] * p51 + (p42[61] * p50 + 0))
    local v80 = p42[70] * p52 + (p42[66] * p51 + (p42[62] * p50 + 0))
    local v81 = p42[71] * p52 + (p42[67] * p51 + (p42[63] * p50 + 0))
    local v82 = p42[1]
    local v83 = p42[2]
    local v84 = p42[3]
    local v85 = p42[5]
    local v86 = p42[6]
    local v87 = p42[7]
    local v88 = -v84 * v76 + (v83 * v77 + v79)
    local v89 = -v82 * v77 + (v84 * v75 + v80)
    local v90 = -v83 * v75 + (v82 * v76 + v81)
    local v91 = -v87 * v76 + (v86 * v77 + v79)
    local v92 = -v85 * v77 + (v87 * v75 + v80)
    local v93 = -v86 * v75 + (v85 * v76 + v81)
    local v94 = p42[76]
    local v95 = p42[88]
    local v96 = v75 * v94 + p44[1]
    local v97 = -v75 * v95 + p46[1]
    local v98 = v76 * v94 + p44[2]
    local v99 = -v76 * v95 + p46[2]
    local v100 = v77 * v94 + p44[3]
    local v101 = -v77 * v95 + p46[3]
    local v102 = v78 * v94 + p44[4]
    local v103 = -v78 * v95 + p46[4]
    local v104 = p42[81] * v90 + (p42[77] * v89 + (p42[73] * v88 + p44[9]))
    local v105 = p42[82] * v90 + (p42[78] * v89 + (p42[74] * v88 + p44[10]))
    local v106 = p42[83] * v90 + (p42[79] * v89 + (p42[75] * v88 + p44[11]))
    local v107 = p42[84] * v90 + (p42[80] * v89 + (v94 * v88 + p44[12]))
    local v108 = -p42[93] * v93 + (-p42[89] * v92 + (-p42[85] * v91 + p46[9]))
    local v109 = -p42[94] * v93 + (-p42[90] * v92 + (-p42[86] * v91 + p46[10]))
    local v110 = -p42[95] * v93 + (-p42[91] * v92 + (-p42[87] * v91 + p46[11]))
    local v111 = -p42[96] * v93 + (-p42[92] * v92 + (-v95 * v91 + p46[12]))

    if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v96))
    else
        buffer.writef32(v56, 0, v96)
    end

    p44[1] = buffer.readf32(v56, 0)

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v98))
    else
        buffer.writef32(v56, 0, v98)
    end

    p44[2] = buffer.readf32(v56, 0)

    if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v100))
    else
        buffer.writef32(v56, 0, v100)
    end

    p44[3] = buffer.readf32(v56, 0)

    if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v102))
    else
        buffer.writef32(v56, 0, v102)
    end

    p44[4] = buffer.readf32(v56, 0)

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v97))
    else
        buffer.writef32(v56, 0, v97)
    end

    p46[1] = buffer.readf32(v56, 0)

    if v99 ~= 0 and v99 > -1.1754943508222875E-38 and v99 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v99))
    else
        buffer.writef32(v56, 0, v99)
    end

    p46[2] = buffer.readf32(v56, 0)

    if v101 ~= 0 and v101 > -1.1754943508222875E-38 and v101 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v101))
    else
        buffer.writef32(v56, 0, v101)
    end

    p46[3] = buffer.readf32(v56, 0)

    if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v103))
    else
        buffer.writef32(v56, 0, v103)
    end

    p46[4] = buffer.readf32(v56, 0)

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v104))
    else
        buffer.writef32(v56, 0, v104)
    end

    p44[9] = buffer.readf32(v56, 0)

    if v105 ~= 0 and v105 > -1.1754943508222875E-38 and v105 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v105))
    else
        buffer.writef32(v56, 0, v105)
    end

    p44[10] = buffer.readf32(v56, 0)

    if v106 ~= 0 and v106 > -1.1754943508222875E-38 and v106 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v106))
    else
        buffer.writef32(v56, 0, v106)
    end

    p44[11] = buffer.readf32(v56, 0)

    if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v107))
    else
        buffer.writef32(v56, 0, v107)
    end

    p44[12] = buffer.readf32(v56, 0)

    if v108 ~= 0 and v108 > -1.1754943508222875E-38 and v108 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v108))
    else
        buffer.writef32(v56, 0, v108)
    end

    p46[9] = buffer.readf32(v56, 0)

    if v109 ~= 0 and v109 > -1.1754943508222875E-38 and v109 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v109))
    else
        buffer.writef32(v56, 0, v109)
    end

    p46[10] = buffer.readf32(v56, 0)

    if v110 ~= 0 and v110 > -1.1754943508222875E-38 and v110 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v110))
    else
        buffer.writef32(v56, 0, v110)
    end

    p46[11] = buffer.readf32(v56, 0)

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        buffer.writeu32(v56, 0, to_bits(v111))
    else
        buffer.writef32(v56, 0, v111)
    end

    p46[12] = buffer.readf32(v56, 0)
end

function t1.mirror(p53) -- line: 319
    -- upvalues: v56 (copy)
    local v112 = #p53
    local v113 = table.create(v112)

    for i = 1, v112 do
        buffer.writeu32(v56, 0, p53[i])
        v113[i] = buffer.readf32(v56, 0)
    end

    return v113
end

return t1
