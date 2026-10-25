-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/solver/contact_data")
local ContactRows, Reaction = v1.ContactRows, v1.Reaction
local t1 = {}

function t1.solve_reference(p1, p2, p3) -- line: 22
    -- upvalues: rt (copy), ContactRows (copy), Reaction (copy)
    local v2 = ContactRows.read(p1)
    local v3 = Reaction.read(p2)
    local v4 = Reaction.read(p3)
    local v5 = Reaction.point_position(v3, v2.arm_a)
    local v6 = Reaction.point_position(v4, v2.arm_b)
    local v7 = Reaction.point_velocity(v3, v2.arm_a)
    local v8 = Reaction.point_velocity(v4, v2.arm_b)
    local t2 = {
        v6[1] - v5[1],
        v6[2] - v5[2],
        v6[3] - v5[3],
        v6[4] - v5[4]
    }
    local t3 = {
        v8[1] - v7[1] + t2[1],
        v8[2] - v7[2] + t2[2],
        v8[3] - v7[3] + t2[3],
        v8[4] - v7[4] + t2[4]
    }
    local v9 = rt.from_fn(4, function(p4) -- line: 45
        -- upvalues: v2 (copy), t2 (copy), t3 (copy)
        local v10 = if p4 == 3 then t2 else t3
        local v11 = v2.accumulated[p4 + 1] + v2.target[p4 + 1]
        local v12 = v10[1]
        local v13 = if p4 == 3 then 0 else p4
        local v14 = v2.correction_columns[1][v13 + 1] * v12 + v11
        local v15 = v10[2]
        local v16 = if p4 == 3 then 0 else p4
        local v17 = v2.correction_columns[2][v16 + 1] * v15 + v14
        local v18 = v10[3]
        local v19 = if p4 == 3 then 0 else p4

        return v2.correction_columns[3][v19 + 1] * v18 + v17
    end)
    local v20 = rt.from_fn(4, function(p5) -- line: 64
        -- upvalues: v2 (copy), v9 (copy), rt (copy)
        local v21 = if p5 == 1 or p5 == 2 then v2.accumulated[1] else 0
        local v22 = if p5 == 0 or p5 == 3 then rt.F32_MAX else 0
        local v23 = -v2.static_friction * v21 + 0
        local v24 = v2.static_friction * v21 + v22
        local v25 = -v2.dynamic_friction * v21 + 0
        local v26 = v2.dynamic_friction * v21 + v22

        if v23 <= v9[p5 + 1] then
            v25 = v9[p5 + 1]
        end

        if v9[p5 + 1] <= v24 then
            return v25
        end

        return v26
    end)
    local t4 = {
        v20[1] - v2.accumulated[1],
        v20[2] - v2.accumulated[2],
        v20[3] - v2.accumulated[3],
        v20[4] - v2.accumulated[4]
    }

    ContactRows.publish_impulses(v2, p1, v20)
    Reaction.apply_contact(v3, v2, t4, true)
    Reaction.apply_contact(v4, v2, t4, false)
    Reaction.write(v3, p2)
    Reaction.write(v4, p3)
end

local v27 = buffer.create(8)

local function fb(p6) -- line: 110
    -- upvalues: v27 (copy)
    buffer.writeu32(v27, 0, p6)

    return (buffer.readf32(v27, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p7) -- line: 115
    -- upvalues: v27 (copy), to_bits (copy)
    if p7 ~= 0 and p7 > -1.1754943508222875E-38 and p7 < 1.1754943508222875E-38 then
        return to_bits(p7)
    end

    buffer.writef32(v27, 0, p7)

    return (buffer.readu32(v27, 0))
end

local F32_MAX = rt.F32_MAX

local function put(_, p9, p10, p11) -- line: 132
    -- upvalues: v27 (copy), to_bits (copy)
    if p11 ~= 0 and p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(p11))
    else
        buffer.writef32(v27, 0, p11)
    end

    p9[p10] = buffer.readf32(v27, 0)
end

local function mirror(p12) -- line: 141
    -- upvalues: v27 (copy)
    local v28 = #p12
    local v29 = table.create(v28)

    for i = 1, v28 do
        buffer.writeu32(v27, 0, p12[i])
        v29[i] = buffer.readf32(v27, 0)
    end

    return v29
end

t1.mirror = mirror

local function store(p13, p14, p15, p16) -- line: 153
    -- upvalues: v27 (copy), to_bits (copy)
    for i = p15, p16 do
        local v31 = p14[i]

        if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
            p13[i] = to_bits(v31)
        else
            buffer.writef32(v27, 0, v31)
            p13[i] = buffer.readu32(v27, 0)
        end
    end
end

t1.store = store

local function limit_lane(p17, p18, p19, p20, p21) -- line: 162
    local v32 = -p20 * p18 + 0
    local v33 = p20 * p18 + p19
    local v34 = -p21 * p18 + 0
    local v35 = p21 * p18 + p19

    if v32 <= p17 then
        v34 = p17
    end

    if p17 <= v33 then
        return v34
    end

    return v35
end

function t1.solve_mirrored(_, p23, _, p25, _, p27) -- line: 181
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy)
    local v36 = p25[1]
    local v37 = p25[2]
    local v38 = p25[3]
    local v39 = p25[4]
    local v40 = p25[5]
    local v41 = p25[6]
    local v42 = p25[7]
    local v43 = p25[8]
    local v44 = p25[9]
    local v45 = p25[10]
    local v46 = p25[11]
    local v47 = p25[12]
    local v48 = p25[13]
    local v49 = p25[14]
    local v50 = p25[15]
    local v51 = p25[16]
    local v52 = p27[1]
    local v53 = p27[2]
    local v54 = p27[3]
    local v55 = p27[4]
    local v56 = p27[5]
    local v57 = p27[6]
    local v58 = p27[7]
    local v59 = p27[8]
    local v60 = p27[9]
    local v61 = p27[10]
    local v62 = p27[11]
    local v63 = p27[12]
    local v64 = p27[13]
    local v65 = p27[14]
    local v66 = p27[15]
    local v67 = p27[16]
    local v68 = p23[1]
    local v69 = p23[2]
    local v70 = p23[3]
    local v71 = p23[4]
    local v72 = p23[5]
    local v73 = p23[6]
    local v74 = p23[7]
    local v75 = p23[8]
    local v76 = -v50 * v69 + (v49 * v70 + v40)
    local v77 = -v48 * v70 + (v50 * v68 + v41)
    local v78 = -v49 * v68 + (v48 * v69 + v42)
    local v79 = -v51 * v71 + (v51 * v71 + v43)

    v79 = -v66 * v73 + (v65 * v74 + v56)

    local v80 = -v64 * v74 + (v66 * v72 + v57)
    local v81 = -v65 * v72 + (v64 * v73 + v58)
    local v82 = -v67 * v75 + (v67 * v75 + v59)

    v82 = -v46 * v69 + (v45 * v70 + v36)

    local v83 = -v44 * v70 + (v46 * v68 + v37)

    v70 = -v45 * v68 + (v44 * v69 + v38)
    v69 = -v47 * v71 + (v47 * v71 + v39)
    v71 = -v62 * v73 + (v61 * v74 + v52)
    v69 = -v60 * v74 + (v62 * v72 + v53)
    v74 = -v61 * v72 + (v60 * v73 + v54)
    v73 = -v63 * v75 + (v63 * v75 + v55)

    local v84 = v79 - v76
    local v85 = v80 - v77
    local v86 = v81 - v78
    local v87 = v71 - v82 + v84
    local v88 = v69 - v83 + v85
    local v89 = v74 - v70 + v86
    local v90 = p23[21]
    local v91 = p23[22]
    local v92 = p23[23]
    local v93 = p23[24]

    v83 = p23[17] * v89 + (p23[13] * v88 + (p23[9] * v87 + (v90 + p23[25])))
    v82 = p23[18] * v89 + (p23[14] * v88 + (p23[10] * v87 + (v91 + p23[26])))
    v81 = p23[19] * v89 + (p23[15] * v88 + (p23[11] * v87 + (v92 + p23[27])))
    v89 = p23[17] * v86 + (p23[13] * v85 + (p23[9] * v84 + (v93 + p23[28])))
    v88 = p23[16]
    v87 = p23[20]
    v85 = -v88 * 0 + 0
    v84 = v88 * 0 + F32_MAX
    v80 = -v87 * 0 + 0
    v79 = v87 * 0 + F32_MAX

    if v85 <= v83 then
        v80 = v83
    end

    if not (v83 <= v84) then
        v80 = v79
    end

    v78 = -v88 * v90 + 0
    v77 = v88 * v90 + 0
    v76 = -v87 * v90 + 0
    v75 = v87 * v90 + 0

    if v78 <= v82 then
        v76 = v82
    end

    if not (v82 <= v77) then
        v76 = v75
    end

    v74 = -v88 * v90 + 0
    v73 = v88 * v90 + 0
    v72 = -v87 * v90 + 0
    v71 = v87 * v90 + 0

    if v74 <= v81 then
        v72 = v81
    end

    if not (v81 <= v73) then
        v72 = v71
    end

    v70 = -v88 * 0 + 0
    v69 = v88 * 0 + F32_MAX
    v68 = -v87 * 0 + 0

    local v94 = v87 * 0 + F32_MAX

    if v70 <= v89 then
        v68 = v89
    end

    if not (v89 <= v69) then
        v68 = v94
    end

    local v95 = v80 - v90

    v94 = v76 - v91

    local v96 = v72 - v92
    local v97 = v68 - v93

    if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v80))
    else
        buffer.writef32(v27, 0, v80)
    end

    p23[21] = buffer.readf32(v27, 0)

    if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v76))
    else
        buffer.writef32(v27, 0, v76)
    end

    p23[22] = buffer.readf32(v27, 0)

    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v72))
    else
        buffer.writef32(v27, 0, v72)
    end

    p23[23] = buffer.readf32(v27, 0)

    if v68 ~= 0 and v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v68))
    else
        buffer.writef32(v27, 0, v68)
    end

    p23[24] = buffer.readf32(v27, 0)
    v93 = p23[36]
    v92 = p23[40]
    v91 = p23[29]
    v90 = p23[53] * v96 + (p23[41] * v94 + (v91 * v95 + 0))
    v89 = v91 * v97 + 0
    v91 = p23[33]

    local v98 = p23[57] * v96 + (p23[45] * v94 + (v91 * v95 + v44))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[9] = buffer.readf32(v27, 0)
    v98 = v91 * v97 + v48

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[13] = buffer.readf32(v27, 0)
    v98 = v90 * v93 + v36

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[1] = buffer.readf32(v27, 0)
    v98 = v89 * v93 + v40

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[5] = buffer.readf32(v27, 0)
    v91 = p23[37]
    v98 = -p23[61] * v96 + (-p23[49] * v94 + (-v91 * v95 + v60))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[9] = buffer.readf32(v27, 0)
    v98 = -v91 * v97 + v64

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[13] = buffer.readf32(v27, 0)
    v98 = -v90 * v92 + v52

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[1] = buffer.readf32(v27, 0)
    v98 = -v89 * v92 + v56

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[5] = buffer.readf32(v27, 0)
    v88 = p23[30]
    v87 = p23[54] * v96 + (p23[42] * v94 + (v88 * v95 + 0))
    v86 = v88 * v97 + 0
    v88 = p23[34]
    v98 = p23[58] * v96 + (p23[46] * v94 + (v88 * v95 + v45))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[10] = buffer.readf32(v27, 0)
    v98 = v88 * v97 + v49

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[14] = buffer.readf32(v27, 0)
    v98 = v87 * v93 + v37

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[2] = buffer.readf32(v27, 0)
    v98 = v86 * v93 + v41

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[6] = buffer.readf32(v27, 0)
    v88 = p23[38]
    v98 = -p23[62] * v96 + (-p23[50] * v94 + (-v88 * v95 + v61))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[10] = buffer.readf32(v27, 0)
    v98 = -v88 * v97 + v65

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[14] = buffer.readf32(v27, 0)
    v98 = -v87 * v92 + v53

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[2] = buffer.readf32(v27, 0)
    v98 = -v86 * v92 + v57

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[6] = buffer.readf32(v27, 0)
    v83 = p23[31]
    v82 = p23[55] * v96 + (p23[43] * v94 + (v83 * v95 + 0))
    v81 = v83 * v97 + 0
    v83 = p23[35]
    v98 = p23[59] * v96 + (p23[47] * v94 + (v83 * v95 + v46))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[11] = buffer.readf32(v27, 0)
    v98 = v83 * v97 + v50

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[15] = buffer.readf32(v27, 0)
    v98 = v82 * v93 + v38

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[3] = buffer.readf32(v27, 0)
    v98 = v81 * v93 + v42

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[7] = buffer.readf32(v27, 0)
    v83 = p23[39]
    v98 = -p23[63] * v96 + (-p23[51] * v94 + (-v83 * v95 + v62))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[11] = buffer.readf32(v27, 0)
    v98 = -v83 * v97 + v66

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[15] = buffer.readf32(v27, 0)
    v98 = -v82 * v92 + v54

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[3] = buffer.readf32(v27, 0)
    v98 = -v81 * v92 + v58

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[7] = buffer.readf32(v27, 0)
    v66 = p23[32]
    v65 = p23[56] * v96 + (p23[44] * v94 + (v66 * v95 + 0))
    v64 = v66 * v97 + 0
    v66 = p23[36]
    v98 = p23[60] * v96 + (p23[48] * v94 + (v66 * v95 + v47))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[12] = buffer.readf32(v27, 0)
    v98 = v66 * v97 + v51

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[16] = buffer.readf32(v27, 0)
    v98 = v65 * v93 + v39

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[4] = buffer.readf32(v27, 0)
    v98 = v64 * v93 + v43

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p25[8] = buffer.readf32(v27, 0)
    v66 = p23[40]
    v98 = -p23[64] * v96 + (-p23[52] * v94 + (-v66 * v95 + v63))

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[12] = buffer.readf32(v27, 0)
    v98 = -v66 * v97 + v67

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[16] = buffer.readf32(v27, 0)
    v98 = -v65 * v92 + v55

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[4] = buffer.readf32(v27, 0)
    v98 = -v64 * v92 + v59

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v98))
    else
        buffer.writef32(v27, 0, v98)
    end

    p27[8] = buffer.readf32(v27, 0)
end

function t1.solve_mirrored_xyz_r3(p28, p29, p30) -- line: 301
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy)
    local v99 = p29[1]
    local v100 = p29[2]
    local v101 = p29[3]
    local v102 = p29[5]
    local v103 = p29[6]
    local v104 = p29[7]
    local v105 = p29[9]
    local v106 = p29[10]
    local v107 = p29[11]
    local v108 = p29[13]
    local v109 = p29[14]
    local v110 = p29[15]
    local v111 = p30[1]
    local v112 = p30[2]
    local v113 = p30[3]
    local v114 = p30[5]
    local v115 = p30[6]
    local v116 = p30[7]
    local v117 = p30[9]
    local v118 = p30[10]
    local v119 = p30[11]
    local v120 = p30[13]
    local v121 = p30[14]
    local v122 = p30[15]
    local v123 = p28[1]
    local v124 = p28[2]
    local v125 = p28[3]
    local v126 = p28[5]
    local v127 = p28[6]
    local v128 = p28[7]
    local v129 = -v110 * v124 + (v109 * v125 + v102)
    local v130 = -v108 * v125 + (v110 * v123 + v103)
    local v131 = -v109 * v123 + (v108 * v124 + v104)
    local v132 = -v122 * v127 + (v121 * v128 + v114)
    local v133 = -v120 * v128 + (v122 * v126 + v115)
    local v134 = -v121 * v126 + (v120 * v127 + v116)
    local v135 = -v107 * v124 + (v106 * v125 + v99)
    local v136 = -v105 * v125 + (v107 * v123 + v100)

    v125 = -v106 * v123 + (v105 * v124 + v101)
    v124 = -v119 * v127 + (v118 * v128 + v111)
    v123 = -v117 * v128 + (v119 * v126 + v112)
    v128 = -v118 * v126 + (v117 * v127 + v113)

    local v137 = v132 - v129
    local v138 = v133 - v130
    local v139 = v134 - v131
    local v140 = v124 - v135 + v137
    local v141 = v123 - v136 + v138
    local v142 = v128 - v125 + v139
    local v143 = p28[21]
    local v144 = p28[22]
    local v145 = p28[23]
    local v146 = p28[24]

    v136 = p28[17] * v142 + (p28[13] * v141 + (p28[9] * v140 + (v143 + p28[25])))
    v135 = p28[18] * v142 + (p28[14] * v141 + (p28[10] * v140 + (v144 + p28[26])))
    v134 = p28[19] * v142 + (p28[15] * v141 + (p28[11] * v140 + (v145 + p28[27])))
    v142 = p28[17] * v139 + (p28[13] * v138 + (p28[9] * v137 + (v146 + p28[28])))
    v141 = p28[16]
    v140 = p28[20]
    v138 = -v141 * 0 + 0
    v137 = v141 * 0 + F32_MAX
    v133 = -v140 * 0 + 0
    v132 = v140 * 0 + F32_MAX

    if v138 <= v136 then
        v133 = v136
    end

    if not (v136 <= v137) then
        v133 = v132
    end

    v131 = -v141 * v143 + 0
    v130 = v141 * v143 + 0
    v129 = -v140 * v143 + 0
    v128 = v140 * v143 + 0

    if v131 <= v135 then
        v129 = v135
    end

    if not (v135 <= v130) then
        v129 = v128
    end

    v127 = -v141 * v143 + 0
    v126 = v141 * v143 + 0
    v125 = -v140 * v143 + 0
    v124 = v140 * v143 + 0

    if v127 <= v134 then
        v125 = v134
    end

    if not (v134 <= v126) then
        v125 = v124
    end

    v123 = -v141 * 0 + 0

    local v147 = v141 * 0 + F32_MAX
    local v148 = -v140 * 0 + 0
    local v149 = v140 * 0 + F32_MAX

    if v123 <= v142 then
        v148 = v142
    end

    if not (v142 <= v147) then
        v148 = v149
    end

    local v150 = v133 - v143

    v147 = v129 - v144

    local v151 = v125 - v145

    v149 = v148 - v146

    if v133 ~= 0 and v133 > -1.1754943508222875E-38 and v133 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v133))
    else
        buffer.writef32(v27, 0, v133)
    end

    p28[21] = buffer.readf32(v27, 0)

    if v129 ~= 0 and v129 > -1.1754943508222875E-38 and v129 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v129))
    else
        buffer.writef32(v27, 0, v129)
    end

    p28[22] = buffer.readf32(v27, 0)

    if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v125))
    else
        buffer.writef32(v27, 0, v125)
    end

    p28[23] = buffer.readf32(v27, 0)

    if v148 ~= 0 and v148 > -1.1754943508222875E-38 and v148 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v148))
    else
        buffer.writef32(v27, 0, v148)
    end

    p28[24] = buffer.readf32(v27, 0)
    v146 = p28[36]
    v145 = p28[40]
    v144 = p28[29]
    v143 = p28[53] * v151 + (p28[41] * v147 + (v144 * v150 + 0))
    v142 = v144 * v149 + 0
    v144 = p28[33]

    local v152 = p28[57] * v151 + (p28[45] * v147 + (v144 * v150 + v105))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[9] = buffer.readf32(v27, 0)
    v152 = v144 * v149 + v108

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[13] = buffer.readf32(v27, 0)
    v152 = v143 * v146 + v99

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[1] = buffer.readf32(v27, 0)
    v152 = v142 * v146 + v102

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[5] = buffer.readf32(v27, 0)
    v144 = p28[37]
    v152 = -p28[61] * v151 + (-p28[49] * v147 + (-v144 * v150 + v117))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[9] = buffer.readf32(v27, 0)
    v152 = -v144 * v149 + v120

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[13] = buffer.readf32(v27, 0)
    v152 = -v143 * v145 + v111

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[1] = buffer.readf32(v27, 0)
    v152 = -v142 * v145 + v114

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[5] = buffer.readf32(v27, 0)
    v141 = p28[30]
    v140 = p28[54] * v151 + (p28[42] * v147 + (v141 * v150 + 0))
    v139 = v141 * v149 + 0
    v141 = p28[34]
    v152 = p28[58] * v151 + (p28[46] * v147 + (v141 * v150 + v106))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[10] = buffer.readf32(v27, 0)
    v152 = v141 * v149 + v109

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[14] = buffer.readf32(v27, 0)
    v152 = v140 * v146 + v100

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[2] = buffer.readf32(v27, 0)
    v152 = v139 * v146 + v103

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[6] = buffer.readf32(v27, 0)
    v141 = p28[38]
    v152 = -p28[62] * v151 + (-p28[50] * v147 + (-v141 * v150 + v118))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[10] = buffer.readf32(v27, 0)
    v152 = -v141 * v149 + v121

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[14] = buffer.readf32(v27, 0)
    v152 = -v140 * v145 + v112

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[2] = buffer.readf32(v27, 0)
    v152 = -v139 * v145 + v115

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[6] = buffer.readf32(v27, 0)
    v136 = p28[31]
    v135 = p28[55] * v151 + (p28[43] * v147 + (v136 * v150 + 0))
    v134 = v136 * v149 + 0
    v136 = p28[35]
    v152 = p28[59] * v151 + (p28[47] * v147 + (v136 * v150 + v107))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[11] = buffer.readf32(v27, 0)
    v152 = v136 * v149 + v110

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[15] = buffer.readf32(v27, 0)
    v152 = v135 * v146 + v101

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[3] = buffer.readf32(v27, 0)
    v152 = v134 * v146 + v104

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p29[7] = buffer.readf32(v27, 0)
    v136 = p28[39]
    v152 = -p28[63] * v151 + (-p28[51] * v147 + (-v136 * v150 + v119))

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[11] = buffer.readf32(v27, 0)
    v152 = -v136 * v149 + v122

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[15] = buffer.readf32(v27, 0)
    v152 = -v135 * v145 + v113

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[3] = buffer.readf32(v27, 0)
    v152 = -v134 * v145 + v116

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v27, 0, to_bits(v152))
    else
        buffer.writef32(v27, 0, v152)
    end

    p30[7] = buffer.readf32(v27, 0)
end

local create = vector.create

local function tiny(p31) -- line: 408
    -- upvalues: v27 (copy), to_bits (copy)
    buffer.writeu32(v27, 0, to_bits(p31))

    return (buffer.readf32(v27, 0))
end

function t1.solve_mirrored_xyz(p32, p33, p34) -- line: 412
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy), create (copy)
    local v153 = p33[1]
    local v154 = p33[2]
    local v155 = p33[3]
    local v156 = p33[5]
    local v157 = p33[6]
    local v158 = p33[7]
    local v159 = p33[9]
    local v160 = p33[10]
    local v161 = p33[11]
    local v162 = p33[13]
    local v163 = p33[14]
    local v164 = p33[15]
    local v165 = p34[1]
    local v166 = p34[2]
    local v167 = p34[3]
    local v168 = p34[5]
    local v169 = p34[6]
    local v170 = p34[7]
    local v171 = p34[9]
    local v172 = p34[10]
    local v173 = p34[11]
    local v174 = p34[13]
    local v175 = p34[14]
    local v176 = p34[15]
    local v177 = p32[1]
    local v178 = p32[2]
    local v179 = p32[3]
    local v180 = p32[5]
    local v181 = p32[6]
    local v182 = p32[7]
    local v183 = -v164 * v178 + (v163 * v179 + v156)
    local v184 = -v162 * v179 + (v164 * v177 + v157)
    local v185 = -v163 * v177 + (v162 * v178 + v158)
    local v186 = -v176 * v181 + (v175 * v182 + v168)
    local v187 = -v174 * v182 + (v176 * v180 + v169)
    local v188 = -v175 * v180 + (v174 * v181 + v170)
    local v189 = -v161 * v178 + (v160 * v179 + v153)
    local v190 = -v159 * v179 + (v161 * v177 + v154)

    v179 = -v160 * v177 + (v159 * v178 + v155)
    v178 = -v173 * v181 + (v172 * v182 + v165)
    v177 = -v171 * v182 + (v173 * v180 + v166)
    v182 = -v172 * v180 + (v171 * v181 + v167)

    local v191 = v186 - v183
    local v192 = v187 - v184
    local v193 = v188 - v185
    local v194 = v178 - v189 + v191
    local v195 = v177 - v190 + v192
    local v196 = v182 - v179 + v193
    local v197 = p32[21]
    local v198 = p32[22]
    local v199 = p32[23]
    local v200 = p32[24]

    v190 = p32[17] * v196 + (p32[13] * v195 + (p32[9] * v194 + (v197 + p32[25])))
    v189 = p32[18] * v196 + (p32[14] * v195 + (p32[10] * v194 + (v198 + p32[26])))
    v188 = p32[19] * v196 + (p32[15] * v195 + (p32[11] * v194 + (v199 + p32[27])))
    v196 = p32[17] * v193 + (p32[13] * v192 + (p32[9] * v191 + (v200 + p32[28])))
    v195 = p32[16]
    v194 = p32[20]
    v192 = -v195 * 0 + 0
    v191 = v195 * 0 + F32_MAX
    v187 = -v194 * 0 + 0
    v186 = v194 * 0 + F32_MAX

    if v192 <= v190 then
        v187 = v190
    end

    if not (v190 <= v191) then
        v187 = v186
    end

    v185 = -v195 * v197 + 0
    v184 = v195 * v197 + 0
    v183 = -v194 * v197 + 0
    v182 = v194 * v197 + 0

    if v185 <= v189 then
        v183 = v189
    end

    if not (v189 <= v184) then
        v183 = v182
    end

    v181 = -v195 * v197 + 0
    v180 = v195 * v197 + 0
    v179 = -v194 * v197 + 0
    v178 = v194 * v197 + 0

    if v181 <= v188 then
        v179 = v188
    end

    if not (v188 <= v180) then
        v179 = v178
    end

    v177 = -v195 * 0 + 0

    local v201 = v195 * 0 + F32_MAX
    local v202 = -v194 * 0 + 0
    local v203 = v194 * 0 + F32_MAX

    if v177 <= v196 then
        v202 = v196
    end

    if not (v196 <= v201) then
        v202 = v203
    end

    local v204 = v187 - v197

    v201 = v183 - v198

    local v205 = v179 - v199

    v203 = v202 - v200

    local v206 = create(v187, v183, v179)
    local x, y, z = v206.x, v206.y, v206.z

    if v187 < 1.1754943508222875E-38 and v187 > -1.1754943508222875E-38 and v187 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v187))
        x = buffer.readf32(v27, 0)
    end

    if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v183))
        y = buffer.readf32(v27, 0)
    end

    if v179 < 1.1754943508222875E-38 and v179 > -1.1754943508222875E-38 and v179 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v179))
        z = buffer.readf32(v27, 0)
    end

    p32[21] = x
    p32[22] = y
    p32[23] = z
    v199 = create(v202, 0, 0).x

    if v202 < 1.1754943508222875E-38 and v202 > -1.1754943508222875E-38 and v202 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v202))
        v199 = buffer.readf32(v27, 0)
    end

    p32[24] = v199
    v198 = p32[36]
    v197 = p32[40]
    v196 = p32[29]
    v195 = p32[53] * v205 + (p32[41] * v201 + (v196 * v204 + 0))
    v194 = v196 * v203 + 0
    v196 = p32[33]
    v193 = p32[57] * v205 + (p32[45] * v201 + (v196 * v204 + v159))
    v190 = v196 * v203 + v162
    v196 = v195 * v198 + v153
    v189 = v194 * v198 + v156
    v188 = p32[37]
    v162 = -p32[61] * v205 + (-p32[49] * v201 + (-v188 * v204 + v171))
    v171 = -v188 * v203 + v174
    v188 = -v195 * v197 + v165
    v195 = -v194 * v197 + v168
    v194 = p32[30]
    v174 = p32[54] * v205 + (p32[42] * v201 + (v194 * v204 + 0))
    v168 = v194 * v203 + 0
    v194 = p32[34]
    v165 = p32[58] * v205 + (p32[46] * v201 + (v194 * v204 + v160))
    v160 = v194 * v203 + v163
    v194 = v174 * v198 + v154
    v163 = v168 * v198 + v157
    v159 = p32[38]
    v157 = -p32[62] * v205 + (-p32[50] * v201 + (-v159 * v204 + v172))
    v172 = -v159 * v203 + v175
    v175 = -v174 * v197 + v166
    v174 = -v168 * v197 + v169
    v169 = p32[31]
    v168 = p32[55] * v205 + (p32[43] * v201 + (v169 * v204 + 0))
    v166 = v169 * v203 + 0
    v169 = p32[35]
    v159 = p32[59] * v205 + (p32[47] * v201 + (v169 * v204 + v161))
    v161 = v169 * v203 + v164
    v169 = v168 * v198 + v155
    v164 = v166 * v198 + v158
    v198 = p32[39]
    v158 = -p32[63] * v205 + (-p32[51] * v201 + (-v198 * v204 + v173))
    v205 = -v198 * v203 + v176
    v203 = -v168 * v197 + v167
    v201 = -v166 * v197 + v170
    v206 = create(v193, v165, v159)
    x = v206.x
    y = v206.y
    z = v206.z

    if v193 < 1.1754943508222875E-38 and v193 > -1.1754943508222875E-38 and v193 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v193))
        x = buffer.readf32(v27, 0)
    end

    if v165 < 1.1754943508222875E-38 and v165 > -1.1754943508222875E-38 and v165 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v165))
        y = buffer.readf32(v27, 0)
    end

    if v159 < 1.1754943508222875E-38 and v159 > -1.1754943508222875E-38 and v159 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v159))
        z = buffer.readf32(v27, 0)
    end

    p33[9] = x
    p33[10] = y
    p33[11] = z
    v206 = create(v190, v160, v161)
    x = v206.x
    y = v206.y
    z = v206.z

    if v190 < 1.1754943508222875E-38 and v190 > -1.1754943508222875E-38 and v190 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v190))
        x = buffer.readf32(v27, 0)
    end

    if v160 < 1.1754943508222875E-38 and v160 > -1.1754943508222875E-38 and v160 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v160))
        y = buffer.readf32(v27, 0)
    end

    if v161 < 1.1754943508222875E-38 and v161 > -1.1754943508222875E-38 and v161 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v161))
        z = buffer.readf32(v27, 0)
    end

    p33[13] = x
    p33[14] = y
    p33[15] = z
    v206 = create(v196, v194, v169)
    x = v206.x
    y = v206.y
    z = v206.z

    if v196 < 1.1754943508222875E-38 and v196 > -1.1754943508222875E-38 and v196 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v196))
        x = buffer.readf32(v27, 0)
    end

    if v194 < 1.1754943508222875E-38 and v194 > -1.1754943508222875E-38 and v194 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v194))
        y = buffer.readf32(v27, 0)
    end

    if v169 < 1.1754943508222875E-38 and v169 > -1.1754943508222875E-38 and v169 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v169))
        z = buffer.readf32(v27, 0)
    end

    p33[1] = x
    p33[2] = y
    p33[3] = z
    v206 = create(v189, v163, v164)
    x = v206.x
    y = v206.y
    z = v206.z

    if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v189))
        x = buffer.readf32(v27, 0)
    end

    if v163 < 1.1754943508222875E-38 and v163 > -1.1754943508222875E-38 and v163 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v163))
        y = buffer.readf32(v27, 0)
    end

    if v164 < 1.1754943508222875E-38 and v164 > -1.1754943508222875E-38 and v164 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v164))
        z = buffer.readf32(v27, 0)
    end

    p33[5] = x
    p33[6] = y
    p33[7] = z
    v206 = create(v162, v157, v158)
    x = v206.x
    y = v206.y
    z = v206.z

    if v162 < 1.1754943508222875E-38 and v162 > -1.1754943508222875E-38 and v162 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v162))
        x = buffer.readf32(v27, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v157))
        y = buffer.readf32(v27, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v158))
        z = buffer.readf32(v27, 0)
    end

    p34[9] = x
    p34[10] = y
    p34[11] = z
    v206 = create(v171, v172, v205)
    x = v206.x
    y = v206.y
    z = v206.z

    if v171 < 1.1754943508222875E-38 and v171 > -1.1754943508222875E-38 and v171 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v171))
        x = buffer.readf32(v27, 0)
    end

    if v172 < 1.1754943508222875E-38 and v172 > -1.1754943508222875E-38 and v172 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v172))
        y = buffer.readf32(v27, 0)
    end

    if v205 < 1.1754943508222875E-38 and v205 > -1.1754943508222875E-38 and v205 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v205))
        z = buffer.readf32(v27, 0)
    end

    p34[13] = x
    p34[14] = y
    p34[15] = z
    v206 = create(v188, v175, v203)
    x = v206.x
    y = v206.y
    z = v206.z

    if v188 < 1.1754943508222875E-38 and v188 > -1.1754943508222875E-38 and v188 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v188))
        x = buffer.readf32(v27, 0)
    end

    if v175 < 1.1754943508222875E-38 and v175 > -1.1754943508222875E-38 and v175 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v175))
        y = buffer.readf32(v27, 0)
    end

    if v203 < 1.1754943508222875E-38 and v203 > -1.1754943508222875E-38 and v203 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v203))
        z = buffer.readf32(v27, 0)
    end

    p34[1] = x
    p34[2] = y
    p34[3] = z
    v203 = create(v195, v174, v201)
    x = v203.x
    y = v203.y
    z = v203.z

    if v195 < 1.1754943508222875E-38 and v195 > -1.1754943508222875E-38 and v195 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v195))
        x = buffer.readf32(v27, 0)
    end

    if v174 < 1.1754943508222875E-38 and v174 > -1.1754943508222875E-38 and v174 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v174))
        y = buffer.readf32(v27, 0)
    end

    if v201 < 1.1754943508222875E-38 and v201 > -1.1754943508222875E-38 and v201 ~= 0 then
        buffer.writeu32(v27, 0, to_bits(v201))
        z = buffer.readf32(v27, 0)
    end

    p34[5] = x
    p34[6] = y
    p34[7] = z
end

function t1.solve_w3(p35, p36, p37) -- line: 662
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy), create (copy)
    local v207 = p36[1]
    local v208 = p36[2]
    local v209 = p36[3]
    local v210 = p36[5]
    local v211 = p36[6]
    local v212 = p36[7]
    local v213 = p36[9]
    local v214 = p36[10]
    local v215 = p36[11]
    local v216 = p36[13]
    local v217 = p36[14]
    local v218 = p36[15]
    local v219 = p37[1]
    local v220 = p37[2]
    local v221 = p37[3]
    local v222 = p37[5]
    local v223 = p37[6]
    local v224 = p37[7]
    local v225 = p37[9]
    local v226 = p37[10]
    local v227 = p37[11]
    local v228 = p37[13]
    local v229 = p37[14]
    local v230 = p37[15]
    local v231 = p35[1]
    local v232 = p35[2]
    local v233 = p35[3]
    local v234 = p35[5]
    local v235 = p35[6]
    local v236 = p35[7]
    local v237 = -v218 * v232 + (v217 * v233 + v210)
    local v238 = -v216 * v233 + (v218 * v231 + v211)
    local v239 = -v217 * v231 + (v216 * v232 + v212)
    local v240 = -v230 * v235 + (v229 * v236 + v222)
    local v241 = -v228 * v236 + (v230 * v234 + v223)
    local v242 = -v229 * v234 + (v228 * v235 + v224)
    local v243 = -v215 * v232 + (v214 * v233 + v207)
    local v244 = -v213 * v233 + (v215 * v231 + v208)

    v233 = -v214 * v231 + (v213 * v232 + v209)
    v232 = -v227 * v235 + (v226 * v236 + v219)
    v231 = -v225 * v236 + (v227 * v234 + v220)
    v236 = -v226 * v234 + (v225 * v235 + v221)

    local v245 = v240 - v237
    local v246 = v241 - v238
    local v247 = v242 - v239
    local v248 = v232 - v243 + v245
    local v249 = v231 - v244 + v246
    local v250 = v236 - v233 + v247
    local v251 = p35[21]
    local v252 = p35[22]
    local v253 = p35[23]
    local v254 = p35[24]

    v244 = p35[17] * v250 + (p35[13] * v249 + (p35[9] * v248 + (v251 + p35[25])))
    v243 = p35[18] * v250 + (p35[14] * v249 + (p35[10] * v248 + (v252 + p35[26])))
    v242 = p35[19] * v250 + (p35[15] * v249 + (p35[11] * v248 + (v253 + p35[27])))
    v250 = p35[17] * v247 + (p35[13] * v246 + (p35[9] * v245 + (v254 + p35[28])))
    v249 = p35[16]
    v248 = p35[20]
    v246 = -v249 * 0 + 0
    v245 = v249 * 0 + F32_MAX
    v241 = -v248 * 0 + 0
    v240 = v248 * 0 + F32_MAX

    if v246 <= v244 then
        v241 = v244
    end

    if not (v244 <= v245) then
        v241 = v240
    end

    v239 = -v249 * v251 + 0
    v238 = v249 * v251 + 0
    v237 = -v248 * v251 + 0
    v236 = v248 * v251 + 0

    if v239 <= v243 then
        v237 = v243
    end

    if not (v243 <= v238) then
        v237 = v236
    end

    v235 = -v249 * v251 + 0
    v234 = v249 * v251 + 0
    v233 = -v248 * v251 + 0
    v232 = v248 * v251 + 0

    if v235 <= v242 then
        v233 = v242
    end

    if not (v242 <= v234) then
        v233 = v232
    end

    v231 = -v249 * 0 + 0

    local v255 = v249 * 0 + F32_MAX
    local v256 = -v248 * 0 + 0
    local v257 = v248 * 0 + F32_MAX

    if v231 <= v250 then
        v256 = v250
    end

    if not (v250 <= v255) then
        v256 = v257
    end

    local v258 = v241 - v251

    v255 = v237 - v252

    local v259 = v233 - v253

    v257 = v256 - v254

    if v258 == 0 and v255 == 0 and v259 == 0 and v257 == 0 and p35[65] == 1 and (v207 ~= 0 or 1 / v207 > 0) and (v208 ~= 0 or 1 / v208 > 0) and (v209 ~= 0 or 1 / v209 > 0) and (v210 ~= 0 or 1 / v210 > 0) and (v211 ~= 0 or 1 / v211 > 0) and (v212 ~= 0 or 1 / v212 > 0) and (v213 ~= 0 or 1 / v213 > 0) and (v214 ~= 0 or 1 / v214 > 0) and (v215 ~= 0 or 1 / v215 > 0) and (v216 ~= 0 or 1 / v216 > 0) and (v217 ~= 0 or 1 / v217 > 0) and (v218 ~= 0 or 1 / v218 > 0) and (v219 ~= 0 or 1 / v219 > 0) and (v220 ~= 0 or 1 / v220 > 0) and (v221 ~= 0 or 1 / v221 > 0) and (v222 ~= 0 or 1 / v222 > 0) and (v223 ~= 0 or 1 / v223 > 0) and (v224 ~= 0 or 1 / v224 > 0) and (v225 ~= 0 or 1 / v225 > 0) and (v226 ~= 0 or 1 / v226 > 0) and (v227 ~= 0 or 1 / v227 > 0) and (v228 ~= 0 or 1 / v228 > 0) and (v229 ~= 0 or 1 / v229 > 0) and (v230 ~= 0 or 1 / v230 > 0) then
        p35[21] = v241
        p35[22] = v237
        p35[23] = v233
        p35[24] = v256
    else
        local v260 = create(v241, v237, v233)
        local x, y, z = v260.x, v260.y, v260.z

        if v241 < 1.1754943508222875E-38 and v241 > -1.1754943508222875E-38 and v241 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v241))
            x = buffer.readf32(v27, 0)
        end

        if v237 < 1.1754943508222875E-38 and v237 > -1.1754943508222875E-38 and v237 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v237))
            y = buffer.readf32(v27, 0)
        end

        if v233 < 1.1754943508222875E-38 and v233 > -1.1754943508222875E-38 and v233 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v233))
            z = buffer.readf32(v27, 0)
        end

        p35[21] = x
        p35[22] = y
        p35[23] = z
        v253 = create(v256, 0, 0).x

        if v256 < 1.1754943508222875E-38 and v256 > -1.1754943508222875E-38 and v256 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v256))
            v253 = buffer.readf32(v27, 0)
        end

        p35[24] = v253
        v252 = p35[36]
        v251 = p35[40]
        v250 = p35[29]
        v249 = p35[53] * v259 + (p35[41] * v255 + (v250 * v258 + 0))
        v248 = v250 * v257 + 0
        v250 = p35[33]
        v247 = p35[57] * v259 + (p35[45] * v255 + (v250 * v258 + v213))
        v244 = v250 * v257 + v216
        v250 = v249 * v252 + v207
        v243 = v248 * v252 + v210
        v242 = p35[37]
        v216 = -p35[61] * v259 + (-p35[49] * v255 + (-v242 * v258 + v225))
        v225 = -v242 * v257 + v228
        v242 = -v249 * v251 + v219
        v249 = -v248 * v251 + v222
        v248 = p35[30]
        v228 = p35[54] * v259 + (p35[42] * v255 + (v248 * v258 + 0))
        v222 = v248 * v257 + 0
        v248 = p35[34]
        v219 = p35[58] * v259 + (p35[46] * v255 + (v248 * v258 + v214))
        v214 = v248 * v257 + v217
        v248 = v228 * v252 + v208
        v217 = v222 * v252 + v211
        v213 = p35[38]
        v211 = -p35[62] * v259 + (-p35[50] * v255 + (-v213 * v258 + v226))
        v226 = -v213 * v257 + v229
        v229 = -v228 * v251 + v220
        v228 = -v222 * v251 + v223
        v223 = p35[31]
        v222 = p35[55] * v259 + (p35[43] * v255 + (v223 * v258 + 0))
        v220 = v223 * v257 + 0
        v223 = p35[35]
        v213 = p35[59] * v259 + (p35[47] * v255 + (v223 * v258 + v215))
        v215 = v223 * v257 + v218
        v223 = v222 * v252 + v209
        v218 = v220 * v252 + v212
        v252 = p35[39]
        v212 = -p35[63] * v259 + (-p35[51] * v255 + (-v252 * v258 + v227))
        v259 = -v252 * v257 + v230
        v257 = -v222 * v251 + v221
        v255 = -v220 * v251 + v224
        v260 = create(v247, v219, v213)
        x = v260.x
        y = v260.y
        z = v260.z

        if v247 < 1.1754943508222875E-38 and v247 > -1.1754943508222875E-38 and v247 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v247))
            x = buffer.readf32(v27, 0)
        end

        if v219 < 1.1754943508222875E-38 and v219 > -1.1754943508222875E-38 and v219 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v219))
            y = buffer.readf32(v27, 0)
        end

        if v213 < 1.1754943508222875E-38 and v213 > -1.1754943508222875E-38 and v213 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v213))
            z = buffer.readf32(v27, 0)
        end

        p36[9] = x
        p36[10] = y
        p36[11] = z
        v260 = create(v244, v214, v215)
        x = v260.x
        y = v260.y
        z = v260.z

        if v244 < 1.1754943508222875E-38 and v244 > -1.1754943508222875E-38 and v244 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v244))
            x = buffer.readf32(v27, 0)
        end

        if v214 < 1.1754943508222875E-38 and v214 > -1.1754943508222875E-38 and v214 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v214))
            y = buffer.readf32(v27, 0)
        end

        if v215 < 1.1754943508222875E-38 and v215 > -1.1754943508222875E-38 and v215 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v215))
            z = buffer.readf32(v27, 0)
        end

        p36[13] = x
        p36[14] = y
        p36[15] = z
        v260 = create(v250, v248, v223)
        x = v260.x
        y = v260.y
        z = v260.z

        if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v250))
            x = buffer.readf32(v27, 0)
        end

        if v248 < 1.1754943508222875E-38 and v248 > -1.1754943508222875E-38 and v248 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v248))
            y = buffer.readf32(v27, 0)
        end

        if v223 < 1.1754943508222875E-38 and v223 > -1.1754943508222875E-38 and v223 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v223))
            z = buffer.readf32(v27, 0)
        end

        p36[1] = x
        p36[2] = y
        p36[3] = z
        v260 = create(v243, v217, v218)
        x = v260.x
        y = v260.y
        z = v260.z

        if v243 < 1.1754943508222875E-38 and v243 > -1.1754943508222875E-38 and v243 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v243))
            x = buffer.readf32(v27, 0)
        end

        if v217 < 1.1754943508222875E-38 and v217 > -1.1754943508222875E-38 and v217 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v217))
            y = buffer.readf32(v27, 0)
        end

        if v218 < 1.1754943508222875E-38 and v218 > -1.1754943508222875E-38 and v218 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v218))
            z = buffer.readf32(v27, 0)
        end

        p36[5] = x
        p36[6] = y
        p36[7] = z
        v260 = create(v216, v211, v212)
        x = v260.x
        y = v260.y
        z = v260.z

        if v216 < 1.1754943508222875E-38 and v216 > -1.1754943508222875E-38 and v216 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v216))
            x = buffer.readf32(v27, 0)
        end

        if v211 < 1.1754943508222875E-38 and v211 > -1.1754943508222875E-38 and v211 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v211))
            y = buffer.readf32(v27, 0)
        end

        if v212 < 1.1754943508222875E-38 and v212 > -1.1754943508222875E-38 and v212 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v212))
            z = buffer.readf32(v27, 0)
        end

        p37[9] = x
        p37[10] = y
        p37[11] = z
        v260 = create(v225, v226, v259)
        x = v260.x
        y = v260.y
        z = v260.z

        if v225 < 1.1754943508222875E-38 and v225 > -1.1754943508222875E-38 and v225 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v225))
            x = buffer.readf32(v27, 0)
        end

        if v226 < 1.1754943508222875E-38 and v226 > -1.1754943508222875E-38 and v226 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v226))
            y = buffer.readf32(v27, 0)
        end

        if v259 < 1.1754943508222875E-38 and v259 > -1.1754943508222875E-38 and v259 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v259))
            z = buffer.readf32(v27, 0)
        end

        p37[13] = x
        p37[14] = y
        p37[15] = z
        v260 = create(v242, v229, v257)
        x = v260.x
        y = v260.y
        z = v260.z

        if v242 < 1.1754943508222875E-38 and v242 > -1.1754943508222875E-38 and v242 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v242))
            x = buffer.readf32(v27, 0)
        end

        if v229 < 1.1754943508222875E-38 and v229 > -1.1754943508222875E-38 and v229 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v229))
            y = buffer.readf32(v27, 0)
        end

        if v257 < 1.1754943508222875E-38 and v257 > -1.1754943508222875E-38 and v257 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v257))
            z = buffer.readf32(v27, 0)
        end

        p37[1] = x
        p37[2] = y
        p37[3] = z
        v257 = create(v249, v228, v255)
        x = v257.x
        y = v257.y
        z = v257.z

        if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v249))
            x = buffer.readf32(v27, 0)
        end

        if v228 < 1.1754943508222875E-38 and v228 > -1.1754943508222875E-38 and v228 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v228))
            y = buffer.readf32(v27, 0)
        end

        if v255 < 1.1754943508222875E-38 and v255 > -1.1754943508222875E-38 and v255 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v255))
            z = buffer.readf32(v27, 0)
        end

        p37[5] = x
        p37[6] = y
        p37[7] = z
    end
end

function t1.solve_b3(p38, p39, p40) -- line: 920
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy), create (copy)
    local v261 = p39[1]
    local v262 = p39[2]
    local v263 = p39[3]
    local v264 = p39[5]
    local v265 = p39[6]
    local v266 = p39[7]
    local v267 = p39[9]
    local v268 = p39[10]
    local v269 = p39[11]
    local v270 = p39[13]
    local v271 = p39[14]
    local v272 = p39[15]
    local v273 = p40[1]
    local v274 = p40[2]
    local v275 = p40[3]
    local v276 = p40[5]
    local v277 = p40[6]
    local v278 = p40[7]
    local v279 = p40[9]
    local v280 = p40[10]
    local v281 = p40[11]
    local v282 = p40[13]
    local v283 = p40[14]
    local v284 = p40[15]
    local v285 = p38[1]
    local v286 = p38[2]
    local v287 = p38[3]
    local v288 = p38[5]
    local v289 = p38[6]
    local v290 = p38[7]
    local v291 = -v272 * v286 + (v271 * v287 + v264)
    local v292 = -v270 * v287 + (v272 * v285 + v265)
    local v293 = -v271 * v285 + (v270 * v286 + v266)
    local v294 = -v284 * v289 + (v283 * v290 + v276)
    local v295 = -v282 * v290 + (v284 * v288 + v277)
    local v296 = -v283 * v288 + (v282 * v289 + v278)
    local v297 = -v269 * v286 + (v268 * v287 + v261)
    local v298 = -v267 * v287 + (v269 * v285 + v262)

    v287 = -v268 * v285 + (v267 * v286 + v263)
    v286 = -v281 * v289 + (v280 * v290 + v273)
    v285 = -v279 * v290 + (v281 * v288 + v274)
    v290 = -v280 * v288 + (v279 * v289 + v275)

    local v299 = v294 - v291
    local v300 = v295 - v292
    local v301 = v296 - v293
    local v302 = v286 - v297 + v299
    local v303 = v285 - v298 + v300
    local v304 = v290 - v287 + v301
    local v305 = p38[21]
    local v306 = p38[22]
    local v307 = p38[23]
    local v308 = p38[24]

    v298 = p38[17] * v304 + (p38[13] * v303 + (p38[9] * v302 + (v305 + p38[25])))
    v297 = p38[18] * v304 + (p38[14] * v303 + (p38[10] * v302 + (v306 + p38[26])))
    v296 = p38[19] * v304 + (p38[15] * v303 + (p38[11] * v302 + (v307 + p38[27])))
    v304 = p38[17] * v301 + (p38[13] * v300 + (p38[9] * v299 + (v308 + p38[28])))
    v303 = p38[16]
    v302 = p38[20]
    v300 = -v303 * 0 + 0
    v299 = v303 * 0 + F32_MAX
    v295 = -v302 * 0 + 0
    v294 = v302 * 0 + F32_MAX

    if v300 <= v298 then
        v295 = v298
    end

    if not (v298 <= v299) then
        v295 = v294
    end

    v293 = -v303 * v305 + 0
    v292 = v303 * v305 + 0
    v291 = -v302 * v305 + 0
    v290 = v302 * v305 + 0

    if v293 <= v297 then
        v291 = v297
    end

    if not (v297 <= v292) then
        v291 = v290
    end

    v289 = -v303 * v305 + 0
    v288 = v303 * v305 + 0
    v287 = -v302 * v305 + 0
    v286 = v302 * v305 + 0

    if v289 <= v296 then
        v287 = v296
    end

    if not (v296 <= v288) then
        v287 = v286
    end

    v285 = -v303 * 0 + 0

    local v309 = v303 * 0 + F32_MAX
    local v310 = -v302 * 0 + 0
    local v311 = v302 * 0 + F32_MAX

    if v285 <= v304 then
        v310 = v304
    end

    if not (v304 <= v309) then
        v310 = v311
    end

    local v312 = v295 - v305

    v309 = v291 - v306

    local v313 = v287 - v307

    v311 = v310 - v308

    if v312 == 0 and v309 == 0 and v313 == 0 and v311 == 0 and p38[65] == 1 and (v261 ~= 0 or 1 / v261 > 0) and (v262 ~= 0 or 1 / v262 > 0) and (v263 ~= 0 or 1 / v263 > 0) and (v264 ~= 0 or 1 / v264 > 0) and (v265 ~= 0 or 1 / v265 > 0) and (v266 ~= 0 or 1 / v266 > 0) and (v267 ~= 0 or 1 / v267 > 0) and (v268 ~= 0 or 1 / v268 > 0) and (v269 ~= 0 or 1 / v269 > 0) and (v270 ~= 0 or 1 / v270 > 0) and (v271 ~= 0 or 1 / v271 > 0) and (v272 ~= 0 or 1 / v272 > 0) and (v273 ~= 0 or 1 / v273 > 0) and (v274 ~= 0 or 1 / v274 > 0) and (v275 ~= 0 or 1 / v275 > 0) and (v276 ~= 0 or 1 / v276 > 0) and (v277 ~= 0 or 1 / v277 > 0) and (v278 ~= 0 or 1 / v278 > 0) and (v279 ~= 0 or 1 / v279 > 0) and (v280 ~= 0 or 1 / v280 > 0) and (v281 ~= 0 or 1 / v281 > 0) and (v282 ~= 0 or 1 / v282 > 0) and (v283 ~= 0 or 1 / v283 > 0) and (v284 ~= 0 or 1 / v284 > 0) then
        p38[21] = v295
        p38[22] = v291
        p38[23] = v287
        p38[24] = v310
    else
        local v314 = create(v295, v291, v287)
        local x, y, z = v314.x, v314.y, v314.z
        local v315 = x
        local v316 = y
        local v317 = z

        if x == 0 or y == 0 or z == 0 then
            if v295 < 1.1754943508222875E-38 and v295 > -1.1754943508222875E-38 and v295 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v295))
                v315 = buffer.readf32(v27, 0)
            end

            if v291 < 1.1754943508222875E-38 and v291 > -1.1754943508222875E-38 and v291 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v291))
                v316 = buffer.readf32(v27, 0)
            end

            if v287 < 1.1754943508222875E-38 and v287 > -1.1754943508222875E-38 and v287 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v287))
                v317 = buffer.readf32(v27, 0)
            end
        end

        p38[21] = v315
        p38[22] = v316
        p38[23] = v317
        v307 = create(v310, 0, 0).x

        if v307 == 0 and v310 < 1.1754943508222875E-38 and v310 > -1.1754943508222875E-38 and v310 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v310))
            v307 = buffer.readf32(v27, 0)
        end

        p38[24] = v307
        v306 = p38[36]
        v305 = p38[40]
        v304 = p38[29]
        v303 = p38[53] * v313 + (p38[41] * v309 + (v304 * v312 + 0))
        v302 = v304 * v311 + 0
        v304 = p38[33]
        v301 = p38[57] * v313 + (p38[45] * v309 + (v304 * v312 + v267))
        v298 = v304 * v311 + v270
        v304 = v303 * v306 + v261
        v297 = v302 * v306 + v264
        v296 = p38[37]
        v270 = -p38[61] * v313 + (-p38[49] * v309 + (-v296 * v312 + v279))
        v279 = -v296 * v311 + v282
        v296 = -v303 * v305 + v273
        v303 = -v302 * v305 + v276
        v302 = p38[30]
        v282 = p38[54] * v313 + (p38[42] * v309 + (v302 * v312 + 0))
        v276 = v302 * v311 + 0
        v302 = p38[34]
        v273 = p38[58] * v313 + (p38[46] * v309 + (v302 * v312 + v268))
        v268 = v302 * v311 + v271
        v302 = v282 * v306 + v262
        v271 = v276 * v306 + v265
        v267 = p38[38]
        v265 = -p38[62] * v313 + (-p38[50] * v309 + (-v267 * v312 + v280))
        v280 = -v267 * v311 + v283
        v283 = -v282 * v305 + v274
        v282 = -v276 * v305 + v277
        v277 = p38[31]
        v276 = p38[55] * v313 + (p38[43] * v309 + (v277 * v312 + 0))
        v274 = v277 * v311 + 0
        v277 = p38[35]
        v267 = p38[59] * v313 + (p38[47] * v309 + (v277 * v312 + v269))
        v269 = v277 * v311 + v272
        v277 = v276 * v306 + v263
        v272 = v274 * v306 + v266
        v306 = p38[39]
        v266 = -p38[63] * v313 + (-p38[51] * v309 + (-v306 * v312 + v281))
        v313 = -v306 * v311 + v284
        v311 = -v276 * v305 + v275
        v309 = -v274 * v305 + v278
        x = create(v301, v273, v267)
        v315 = x.x
        v316 = x.y
        v317 = x.z

        local v318 = v315
        local v319 = v316
        local v320 = v317

        if v315 == 0 or v316 == 0 or v317 == 0 then
            if v301 < 1.1754943508222875E-38 and v301 > -1.1754943508222875E-38 and v301 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v301))
                v318 = buffer.readf32(v27, 0)
            end

            if v273 < 1.1754943508222875E-38 and v273 > -1.1754943508222875E-38 and v273 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v273))
                v319 = buffer.readf32(v27, 0)
            end

            if v267 < 1.1754943508222875E-38 and v267 > -1.1754943508222875E-38 and v267 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v267))
                v320 = buffer.readf32(v27, 0)
            end
        end

        p39[9] = v318
        p39[10] = v319
        p39[11] = v320
        v315 = create(v298, v268, v269)
        v318 = v315.x
        v319 = v315.y
        v320 = v315.z

        local v321 = v318
        local v322 = v319
        local v323 = v320

        if v318 == 0 or v319 == 0 or v320 == 0 then
            if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v298))
                v321 = buffer.readf32(v27, 0)
            end

            if v268 < 1.1754943508222875E-38 and v268 > -1.1754943508222875E-38 and v268 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v268))
                v322 = buffer.readf32(v27, 0)
            end

            if v269 < 1.1754943508222875E-38 and v269 > -1.1754943508222875E-38 and v269 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v269))
                v323 = buffer.readf32(v27, 0)
            end
        end

        p39[13] = v321
        p39[14] = v322
        p39[15] = v323
        v318 = create(v304, v302, v277)
        v321 = v318.x
        v322 = v318.y
        v323 = v318.z

        local v324 = v321
        local v325 = v322
        local v326 = v323

        if v321 == 0 or v322 == 0 or v323 == 0 then
            if v304 < 1.1754943508222875E-38 and v304 > -1.1754943508222875E-38 and v304 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v304))
                v324 = buffer.readf32(v27, 0)
            end

            if v302 < 1.1754943508222875E-38 and v302 > -1.1754943508222875E-38 and v302 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v302))
                v325 = buffer.readf32(v27, 0)
            end

            if v277 < 1.1754943508222875E-38 and v277 > -1.1754943508222875E-38 and v277 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v277))
                v326 = buffer.readf32(v27, 0)
            end
        end

        p39[1] = v324
        p39[2] = v325
        p39[3] = v326
        v321 = create(v297, v271, v272)
        v324 = v321.x
        v325 = v321.y
        v326 = v321.z

        local v327 = v324
        local v328 = v325
        local v329 = v326

        if v324 == 0 or v325 == 0 or v326 == 0 then
            if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v297))
                v327 = buffer.readf32(v27, 0)
            end

            if v271 < 1.1754943508222875E-38 and v271 > -1.1754943508222875E-38 and v271 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v271))
                v328 = buffer.readf32(v27, 0)
            end

            if v272 < 1.1754943508222875E-38 and v272 > -1.1754943508222875E-38 and v272 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v272))
                v329 = buffer.readf32(v27, 0)
            end
        end

        p39[5] = v327
        p39[6] = v328
        p39[7] = v329
        v324 = create(v270, v265, v266)
        v327 = v324.x
        v328 = v324.y
        v329 = v324.z

        local v330 = v327
        local v331 = v328
        local v332 = v329

        if v327 == 0 or v328 == 0 or v329 == 0 then
            if v270 < 1.1754943508222875E-38 and v270 > -1.1754943508222875E-38 and v270 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v270))
                v330 = buffer.readf32(v27, 0)
            end

            if v265 < 1.1754943508222875E-38 and v265 > -1.1754943508222875E-38 and v265 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v265))
                v331 = buffer.readf32(v27, 0)
            end

            if v266 < 1.1754943508222875E-38 and v266 > -1.1754943508222875E-38 and v266 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v266))
                v332 = buffer.readf32(v27, 0)
            end
        end

        p40[9] = v330
        p40[10] = v331
        p40[11] = v332
        v327 = create(v279, v280, v313)
        v330 = v327.x
        v331 = v327.y
        v332 = v327.z

        local v333 = v330
        local v334 = v331
        local v335 = v332

        if v330 == 0 or v331 == 0 or v332 == 0 then
            if v279 < 1.1754943508222875E-38 and v279 > -1.1754943508222875E-38 and v279 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v279))
                v333 = buffer.readf32(v27, 0)
            end

            if v280 < 1.1754943508222875E-38 and v280 > -1.1754943508222875E-38 and v280 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v280))
                v334 = buffer.readf32(v27, 0)
            end

            if v313 < 1.1754943508222875E-38 and v313 > -1.1754943508222875E-38 and v313 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v313))
                v335 = buffer.readf32(v27, 0)
            end
        end

        p40[13] = v333
        p40[14] = v334
        p40[15] = v335
        v330 = create(v296, v283, v311)
        v333 = v330.x
        v334 = v330.y
        v335 = v330.z

        local v336 = v333
        local v337 = v334
        local v338 = v335

        if v333 == 0 or v334 == 0 or v335 == 0 then
            if v296 < 1.1754943508222875E-38 and v296 > -1.1754943508222875E-38 and v296 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v296))
                v336 = buffer.readf32(v27, 0)
            end

            if v283 < 1.1754943508222875E-38 and v283 > -1.1754943508222875E-38 and v283 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v283))
                v337 = buffer.readf32(v27, 0)
            end

            if v311 < 1.1754943508222875E-38 and v311 > -1.1754943508222875E-38 and v311 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v311))
                v338 = buffer.readf32(v27, 0)
            end
        end

        p40[1] = v336
        p40[2] = v337
        p40[3] = v338
        v311 = create(v303, v282, v309)
        v336 = v311.x
        v337 = v311.y
        v338 = v311.z

        local v339 = v336
        local v340 = v337
        local v341 = v338

        if v336 == 0 or v337 == 0 or v338 == 0 then
            if v303 < 1.1754943508222875E-38 and v303 > -1.1754943508222875E-38 and v303 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v303))
                v339 = buffer.readf32(v27, 0)
            end

            if v282 < 1.1754943508222875E-38 and v282 > -1.1754943508222875E-38 and v282 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v282))
                v340 = buffer.readf32(v27, 0)
            end

            if v309 < 1.1754943508222875E-38 and v309 > -1.1754943508222875E-38 and v309 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v309))
                v341 = buffer.readf32(v27, 0)
            end
        end

        p40[5] = v339
        p40[6] = v340
        p40[7] = v341
    end
end

function t1.solve_w3_b0(p41, p42) -- line: 1198
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy), create (copy)
    local v342 = p42[1]
    local v343 = p42[2]
    local v344 = p42[3]
    local v345 = p42[5]
    local v346 = p42[6]
    local v347 = p42[7]
    local v348 = p42[9]
    local v349 = p42[10]
    local v350 = p42[11]
    local v351 = p42[13]
    local v352 = p42[14]
    local v353 = p42[15]
    local v354 = p41[1]
    local v355 = p41[2]
    local v356 = p41[3]
    local v357 = -v353 * v355 + (v352 * v356 + v345)
    local v358 = -v351 * v356 + (v353 * v354 + v346)
    local v359 = -v352 * v354 + (v351 * v355 + v347)
    local v360 = -v350 * v355 + (v349 * v356 + v342)
    local v361 = -v348 * v356 + (v350 * v354 + v343)
    local v362 = -v349 * v354 + (v348 * v355 + v344)
    local v363 = 0 - v357
    local v364 = 0 - v358
    local v365 = 0 - v359
    local v366 = 0 - v360 + v363
    local v367 = 0 - v361 + v364
    local v368 = 0 - v362 + v365
    local v369 = p41[21]
    local v370 = p41[22]
    local v371 = p41[23]
    local v372 = p41[24]
    local v373 = p41[17] * v368 + (p41[13] * v367 + (p41[9] * v366 + (v369 + p41[25])))
    local v374 = p41[18] * v368 + (p41[14] * v367 + (p41[10] * v366 + (v370 + p41[26])))
    local v375 = p41[19] * v368 + (p41[15] * v367 + (p41[11] * v366 + (v371 + p41[27])))
    local v376 = p41[17] * v365 + (p41[13] * v364 + (p41[9] * v363 + (v372 + p41[28])))
    local v377 = p41[16]
    local v378 = p41[20]
    local v379 = -v377 * 0 + 0
    local v380 = v377 * 0 + F32_MAX
    local v381 = -v378 * 0 + 0
    local v382 = v378 * 0 + F32_MAX

    if v379 <= v373 then
        v381 = v373
    end

    if not (v373 <= v380) then
        v381 = v382
    end

    local v383 = -v377 * v369 + 0
    local v384 = v377 * v369 + 0
    local v385 = -v378 * v369 + 0
    local v386 = v378 * v369 + 0

    if v383 <= v374 then
        v385 = v374
    end

    if not (v374 <= v384) then
        v385 = v386
    end

    local v387 = -v377 * v369 + 0
    local v388 = v377 * v369 + 0
    local v389 = -v378 * v369 + 0
    local v390 = v378 * v369 + 0

    if v387 <= v375 then
        v389 = v375
    end

    if not (v375 <= v388) then
        v389 = v390
    end

    local v391 = -v377 * 0 + 0
    local v392 = v377 * 0 + F32_MAX
    local v393 = -v378 * 0 + 0
    local v394 = v378 * 0 + F32_MAX

    if v391 <= v376 then
        v393 = v376
    end

    if not (v376 <= v392) then
        v393 = v394
    end

    local v395 = v381 - v369
    local v396 = v385 - v370
    local v397 = v389 - v371
    local v398 = v393 - v372

    if v395 == 0 and v396 == 0 and v397 == 0 and v398 == 0 and p41[65] == 1 and (v342 ~= 0 or 1 / v342 > 0) and (v343 ~= 0 or 1 / v343 > 0) and (v344 ~= 0 or 1 / v344 > 0) and (v345 ~= 0 or 1 / v345 > 0) and (v346 ~= 0 or 1 / v346 > 0) and (v347 ~= 0 or 1 / v347 > 0) and (v348 ~= 0 or 1 / v348 > 0) and (v349 ~= 0 or 1 / v349 > 0) and (v350 ~= 0 or 1 / v350 > 0) and (v351 ~= 0 or 1 / v351 > 0) and (v352 ~= 0 or 1 / v352 > 0) and (v353 ~= 0 or 1 / v353 > 0) then
        p41[21] = v381
        p41[22] = v385
        p41[23] = v389
        p41[24] = v393
    else
        local v399 = create(v381, v385, v389)
        local x, y, z = v399.x, v399.y, v399.z

        if v381 < 1.1754943508222875E-38 and v381 > -1.1754943508222875E-38 and v381 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v381))
            x = buffer.readf32(v27, 0)
        end

        if v385 < 1.1754943508222875E-38 and v385 > -1.1754943508222875E-38 and v385 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v385))
            y = buffer.readf32(v27, 0)
        end

        if v389 < 1.1754943508222875E-38 and v389 > -1.1754943508222875E-38 and v389 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v389))
            z = buffer.readf32(v27, 0)
        end

        p41[21] = x
        p41[22] = y
        p41[23] = z

        local x2 = create(v393, 0, 0).x

        if v393 < 1.1754943508222875E-38 and v393 > -1.1754943508222875E-38 and v393 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v393))
            x2 = buffer.readf32(v27, 0)
        end

        p41[24] = x2

        local v400 = p41[36]
        local v401 = p41[29]
        local v402 = p41[53] * v397 + (p41[41] * v396 + (v401 * v395 + 0))
        local v403 = v401 * v398 + 0
        local v404 = p41[33]
        local v405 = p41[57] * v397 + (p41[45] * v396 + (v404 * v395 + v348))
        local v406 = v404 * v398 + v351
        local v407 = v402 * v400 + v342
        local v408 = v403 * v400 + v345
        local v409 = p41[30]
        local v410 = p41[54] * v397 + (p41[42] * v396 + (v409 * v395 + 0))
        local v411 = v409 * v398 + 0
        local v412 = p41[34]
        local v413 = p41[58] * v397 + (p41[46] * v396 + (v412 * v395 + v349))
        local v414 = v412 * v398 + v352
        local v415 = v410 * v400 + v343
        local v416 = v411 * v400 + v346
        local v417 = p41[31]
        local v418 = p41[55] * v397 + (p41[43] * v396 + (v417 * v395 + 0))
        local v419 = v417 * v398 + 0
        local v420 = p41[35]
        local v421 = p41[59] * v397 + (p41[47] * v396 + (v420 * v395 + v350))
        local v422 = v420 * v398 + v353
        local v423 = v418 * v400 + v344
        local v424 = v419 * v400 + v347
        local v425 = create(v405, v413, v421)
        local x3, y2, z2 = v425.x, v425.y, v425.z

        if v405 < 1.1754943508222875E-38 and v405 > -1.1754943508222875E-38 and v405 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v405))
            x3 = buffer.readf32(v27, 0)
        end

        if v413 < 1.1754943508222875E-38 and v413 > -1.1754943508222875E-38 and v413 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v413))
            y2 = buffer.readf32(v27, 0)
        end

        if v421 < 1.1754943508222875E-38 and v421 > -1.1754943508222875E-38 and v421 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v421))
            z2 = buffer.readf32(v27, 0)
        end

        p42[9] = x3
        p42[10] = y2
        p42[11] = z2

        local v426 = create(v406, v414, v422)
        local x4, y3, z3 = v426.x, v426.y, v426.z

        if v406 < 1.1754943508222875E-38 and v406 > -1.1754943508222875E-38 and v406 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v406))
            x4 = buffer.readf32(v27, 0)
        end

        if v414 < 1.1754943508222875E-38 and v414 > -1.1754943508222875E-38 and v414 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v414))
            y3 = buffer.readf32(v27, 0)
        end

        if v422 < 1.1754943508222875E-38 and v422 > -1.1754943508222875E-38 and v422 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v422))
            z3 = buffer.readf32(v27, 0)
        end

        p42[13] = x4
        p42[14] = y3
        p42[15] = z3

        local v427 = create(v407, v415, v423)
        local x5, y4, z4 = v427.x, v427.y, v427.z

        if v407 < 1.1754943508222875E-38 and v407 > -1.1754943508222875E-38 and v407 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v407))
            x5 = buffer.readf32(v27, 0)
        end

        if v415 < 1.1754943508222875E-38 and v415 > -1.1754943508222875E-38 and v415 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v415))
            y4 = buffer.readf32(v27, 0)
        end

        if v423 < 1.1754943508222875E-38 and v423 > -1.1754943508222875E-38 and v423 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v423))
            z4 = buffer.readf32(v27, 0)
        end

        p42[1] = x5
        p42[2] = y4
        p42[3] = z4

        local v428 = create(v408, v416, v424)
        local x6, y5, z5 = v428.x, v428.y, v428.z

        if v408 < 1.1754943508222875E-38 and v408 > -1.1754943508222875E-38 and v408 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v408))
            x6 = buffer.readf32(v27, 0)
        end

        if v416 < 1.1754943508222875E-38 and v416 > -1.1754943508222875E-38 and v416 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v416))
            y5 = buffer.readf32(v27, 0)
        end

        if v424 < 1.1754943508222875E-38 and v424 > -1.1754943508222875E-38 and v424 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v424))
            z5 = buffer.readf32(v27, 0)
        end

        p42[5] = x6
        p42[6] = y5
        p42[7] = z5
    end
end

function t1.solve_b3_b0(p43, p44) -- line: 1361
    -- upvalues: v27 (copy), to_bits (copy), F32_MAX (copy), create (copy)
    local v429 = p44[1]
    local v430 = p44[2]
    local v431 = p44[3]
    local v432 = p44[5]
    local v433 = p44[6]
    local v434 = p44[7]
    local v435 = p44[9]
    local v436 = p44[10]
    local v437 = p44[11]
    local v438 = p44[13]
    local v439 = p44[14]
    local v440 = p44[15]
    local v441 = p43[1]
    local v442 = p43[2]
    local v443 = p43[3]
    local v444 = -v440 * v442 + (v439 * v443 + v432)
    local v445 = -v438 * v443 + (v440 * v441 + v433)
    local v446 = -v439 * v441 + (v438 * v442 + v434)
    local v447 = -v437 * v442 + (v436 * v443 + v429)
    local v448 = -v435 * v443 + (v437 * v441 + v430)

    v443 = -v436 * v441 + (v435 * v442 + v431)

    local v449 = 0 - v444
    local v450 = 0 - v445
    local v451 = 0 - v446
    local v452 = 0 - v447 + v449
    local v453 = 0 - v448 + v450
    local v454 = 0 - v443 + v451
    local v455 = p43[21]
    local v456 = p43[22]
    local v457 = p43[23]
    local v458 = p43[24]

    v448 = p43[17] * v454 + (p43[13] * v453 + (p43[9] * v452 + (v455 + p43[25])))
    v447 = p43[18] * v454 + (p43[14] * v453 + (p43[10] * v452 + (v456 + p43[26])))
    v446 = p43[19] * v454 + (p43[15] * v453 + (p43[11] * v452 + (v457 + p43[27])))
    v454 = p43[17] * v451 + (p43[13] * v450 + (p43[9] * v449 + (v458 + p43[28])))
    v453 = p43[16]
    v452 = p43[20]
    v450 = -v453 * 0 + 0
    v449 = v453 * 0 + F32_MAX
    v445 = -v452 * 0 + 0
    v444 = v452 * 0 + F32_MAX

    if v450 <= v448 then
        v445 = v448
    end

    if not (v448 <= v449) then
        v445 = v444
    end

    v443 = -v453 * v455 + 0
    v442 = v453 * v455 + 0
    v441 = -v452 * v455 + 0

    local v459 = v452 * v455 + 0

    if v443 <= v447 then
        v441 = v447
    end

    if not (v447 <= v442) then
        v441 = v459
    end

    v459 = -v453 * v455 + 0

    local v460 = v453 * v455 + 0
    local v461 = -v452 * v455 + 0
    local v462 = v452 * v455 + 0

    if v459 <= v446 then
        v461 = v446
    end

    if not (v446 <= v460) then
        v461 = v462
    end

    v460 = -v453 * 0 + 0

    local v463 = v453 * 0 + F32_MAX
    local v464 = -v452 * 0 + 0
    local x = v452 * 0 + F32_MAX

    if v460 <= v454 then
        v464 = v454
    end

    if not (v454 <= v463) then
        v464 = x
    end

    v459 = v445 - v455
    v460 = v441 - v456
    v463 = v461 - v457
    v462 = v464 - v458

    if v459 == 0 and v460 == 0 and v463 == 0 and v462 == 0 and p43[65] == 1 and (v429 ~= 0 or 1 / v429 > 0) and (v430 ~= 0 or 1 / v430 > 0) and (v431 ~= 0 or 1 / v431 > 0) and (v432 ~= 0 or 1 / v432 > 0) and (v433 ~= 0 or 1 / v433 > 0) and (v434 ~= 0 or 1 / v434 > 0) and (v435 ~= 0 or 1 / v435 > 0) and (v436 ~= 0 or 1 / v436 > 0) and (v437 ~= 0 or 1 / v437 > 0) and (v438 ~= 0 or 1 / v438 > 0) and (v439 ~= 0 or 1 / v439 > 0) and (v440 ~= 0 or 1 / v440 > 0) then
        p43[21] = v445
        p43[22] = v441
        p43[23] = v461
        p43[24] = v464
    else
        local v465 = create(v445, v441, v461)

        x = v465.x

        local y, z = v465.y, v465.z
        local v466 = x
        local v467 = y
        local v468 = z

        if x == 0 or y == 0 or z == 0 then
            if v445 < 1.1754943508222875E-38 and v445 > -1.1754943508222875E-38 and v445 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v445))
                v466 = buffer.readf32(v27, 0)
            end

            if v441 < 1.1754943508222875E-38 and v441 > -1.1754943508222875E-38 and v441 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v441))
                v467 = buffer.readf32(v27, 0)
            end

            if v461 < 1.1754943508222875E-38 and v461 > -1.1754943508222875E-38 and v461 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v461))
                v468 = buffer.readf32(v27, 0)
            end
        end

        p43[21] = v466
        p43[22] = v467
        p43[23] = v468
        v457 = create(v464, 0, 0).x

        if v457 == 0 and v464 < 1.1754943508222875E-38 and v464 > -1.1754943508222875E-38 and v464 ~= 0 then
            buffer.writeu32(v27, 0, to_bits(v464))
            v457 = buffer.readf32(v27, 0)
        end

        p43[24] = v457
        v456 = p43[36]
        v455 = p43[29]
        v454 = p43[53] * v463 + (p43[41] * v460 + (v455 * v459 + 0))
        v453 = v455 * v462 + 0
        v455 = p43[33]
        v452 = p43[57] * v463 + (p43[45] * v460 + (v455 * v459 + v435))
        v451 = v455 * v462 + v438
        v455 = v454 * v456 + v429
        v454 = v453 * v456 + v432
        v453 = p43[30]
        v448 = p43[54] * v463 + (p43[42] * v460 + (v453 * v459 + 0))
        v447 = v453 * v462 + 0
        v453 = p43[34]
        v446 = p43[58] * v463 + (p43[46] * v460 + (v453 * v459 + v436))
        v438 = v453 * v462 + v439
        v453 = v448 * v456 + v430
        v448 = v447 * v456 + v433
        v447 = p43[31]
        v439 = p43[55] * v463 + (p43[43] * v460 + (v447 * v459 + 0))
        v436 = v447 * v462 + 0
        v447 = p43[35]
        v435 = p43[59] * v463 + (p43[47] * v460 + (v447 * v459 + v437))
        v463 = v447 * v462 + v440
        v462 = v439 * v456 + v431
        v460 = v436 * v456 + v434
        x = create(v452, v446, v435)
        v466 = x.x
        v467 = x.y
        v468 = x.z

        local v469 = v466
        local v470 = v467
        local v471 = v468

        if v466 == 0 or v467 == 0 or v468 == 0 then
            if v452 < 1.1754943508222875E-38 and v452 > -1.1754943508222875E-38 and v452 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v452))
                v469 = buffer.readf32(v27, 0)
            end

            if v446 < 1.1754943508222875E-38 and v446 > -1.1754943508222875E-38 and v446 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v446))
                v470 = buffer.readf32(v27, 0)
            end

            if v435 < 1.1754943508222875E-38 and v435 > -1.1754943508222875E-38 and v435 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v435))
                v471 = buffer.readf32(v27, 0)
            end
        end

        p44[9] = v469
        p44[10] = v470
        p44[11] = v471
        v466 = create(v451, v438, v463)
        v469 = v466.x
        v470 = v466.y
        v471 = v466.z

        local v472 = v469
        local v473 = v470
        local v474 = v471

        if v469 == 0 or v470 == 0 or v471 == 0 then
            if v451 < 1.1754943508222875E-38 and v451 > -1.1754943508222875E-38 and v451 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v451))
                v472 = buffer.readf32(v27, 0)
            end

            if v438 < 1.1754943508222875E-38 and v438 > -1.1754943508222875E-38 and v438 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v438))
                v473 = buffer.readf32(v27, 0)
            end

            if v463 < 1.1754943508222875E-38 and v463 > -1.1754943508222875E-38 and v463 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v463))
                v474 = buffer.readf32(v27, 0)
            end
        end

        p44[13] = v472
        p44[14] = v473
        p44[15] = v474
        v469 = create(v455, v453, v462)
        v472 = v469.x
        v473 = v469.y
        v474 = v469.z

        local v475 = v472
        local v476 = v473
        local v477 = v474

        if v472 == 0 or v473 == 0 or v474 == 0 then
            if v455 < 1.1754943508222875E-38 and v455 > -1.1754943508222875E-38 and v455 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v455))
                v475 = buffer.readf32(v27, 0)
            end

            if v453 < 1.1754943508222875E-38 and v453 > -1.1754943508222875E-38 and v453 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v453))
                v476 = buffer.readf32(v27, 0)
            end

            if v462 < 1.1754943508222875E-38 and v462 > -1.1754943508222875E-38 and v462 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v462))
                v477 = buffer.readf32(v27, 0)
            end
        end

        p44[1] = v475
        p44[2] = v476
        p44[3] = v477
        v462 = create(v454, v448, v460)
        v475 = v462.x
        v476 = v462.y
        v477 = v462.z

        local v478 = v475
        local v479 = v476
        local v480 = v477

        if v475 == 0 or v476 == 0 or v477 == 0 then
            if v454 < 1.1754943508222875E-38 and v454 > -1.1754943508222875E-38 and v454 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v454))
                v478 = buffer.readf32(v27, 0)
            end

            if v448 < 1.1754943508222875E-38 and v448 > -1.1754943508222875E-38 and v448 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v448))
                v479 = buffer.readf32(v27, 0)
            end

            if v460 < 1.1754943508222875E-38 and v460 > -1.1754943508222875E-38 and v460 ~= 0 then
                buffer.writeu32(v27, 0, to_bits(v460))
                v480 = buffer.readf32(v27, 0)
            end
        end

        p44[5] = v478
        p44[6] = v479
        p44[7] = v480
    end
end

function t1.solve(p45, p46, p47) -- line: 1536
    -- upvalues: t1 (copy), mirror (copy), store (copy)
    if #p45 ~= 64 then
        error("assertion `left == right` failed\n  left: " .. #p45 .. "\n right: 64", 0)
    end

    if #p46 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p46 .. "\n right: 16", 0)
    end

    if #p47 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p47 .. "\n right: 16", 0)
    end

    local v481 = mirror(p45)
    local v482 = mirror(p46)
    local v483 = mirror(p47)

    t1.solve_mirrored(p45, v481, p46, v482, p47, v483)
    store(p45, v481, 21, 24)
    store(p46, v482, 1, 16)
    store(p47, v483, 1, 16)
end

return t1
