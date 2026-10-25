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
local v8 = import("skate_core/physics/reciprocal_sqrt")
local v9 = import("skate_core/physics/native_arithmetic")
local t1 = {
    DynamicUpdateResult = {}
}

function t1.dynamic_update_packed(p4, p5, p6, p7) -- line: 50
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v10 = rt.filled(4, p6.time_step)
    local v11 = t1.madd(t1.madd(t1.load(p4, 36), v10, t1.load(p4, 8)), v10, t1.load(p7, 0))
    local v12 = t1.madd(t1.madd(t1.load(p4, 40), v10, t1.load(p4, 12)), v10, t1.load(p7, 8))
    local v13 = t1.add(t1.add(t1.load(p4, 4), t1.load(p7, 4)), v11)

    t1.store_xyz(p4, 4, v13)

    local v14 = t1.add(v12, t1.load(p7, 12))
    local v15 = t1.orientation(t1.load(p4, 0), v14)
    local v16 = v15[1]
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    p4[1] = v17

    local v21 = v15[2]
    local v22

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v21 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readu32(v1, 0)
    end

    p4[2] = v22

    local v26 = v15[3]
    local v27

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v28 = math.abs(v26) * 7.1362384635298E+44
        local v29 = math.floor(v28)
        local v30 = v28 - v29

        v27 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

        if v26 < 0 then
            v27 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readu32(v1, 0)
    end

    p4[3] = v27

    local v31 = v15[4]
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    p4[4] = v32

    local v36 = t1.quaternion_basis(v15)
    local t2 = {
        16, 20, 24
    }

    t1.store_xyz(p4, t2[1], v36[1])
    t1.store_xyz(p4, t2[2], v36[2])
    t1.store_xyz(p4, t2[3], v36[3])

    local v37 = rt.slice(p5, 0, 3)
    local v38, v39 = t1.inverse_inertia(v36, v37)

    t1.store_xyz(p4, 28, v38)
    t1.store_xyz(p4, 32, v39)

    local function rate(p8) -- line: 71
        -- upvalues: p6 (copy), v1 (copy)
        local frequency = p6.frequency

        buffer.writeu32(v1, 0, p8)

        local v40 = frequency - buffer.readf32(v1, 0)

        if v40 > 0 then
            return v40
        end

        return 0
    end

    local cap, mul = t1.cap, t1.mul
    local filled = rt.filled
    local v41 = p5[10]
    local frequency = p6.frequency

    buffer.writeu32(v1, 0, v41)

    local v42 = frequency - buffer.readf32(v1, 0)

    if not (v42 > 0) then
        v42 = 0
    end

    local v43 = mul(v12, filled(4, v42))

    buffer.writeu32(v1, 0, p5[8])

    local v45, v46 = cap(v43, (buffer.readf32(v1, 0)))
    local cap2, mul2 = t1.cap, t1.mul
    local filled2 = rt.filled
    local v47 = p5[9]
    local frequency2 = p6.frequency

    buffer.writeu32(v1, 0, v47)

    local v48 = frequency2 - buffer.readf32(v1, 0)

    if not (v48 > 0) then
        v48 = 0
    end

    local v49 = mul2(v11, filled2(4, v48))

    buffer.writeu32(v1, 0, p5[7])

    local v51, v52 = cap2(v49, (buffer.readf32(v1, 0)))

    buffer.writeu32(v1, 0, p5[6])

    local v54 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[32])

    local v56 = v54 * buffer.readf32(v1, 0) * v46 + v52

    if v56 < p6.minimum_energy then
        buffer.writeu32(v1, 0, p4[40])
        p4[44] = math.min(if buffer.readf32(v1, 0) < v56 then p4[44] else rt.wrapping_add_u32(p4[44], 1), p6.cool_down)
    else
        p4[44] = 0
    end

    local v59

    if v56 ~= 0 and v56 > -1.1754943508222875E-38 and v56 < 1.1754943508222875E-38 then
        local v60 = math.abs(v56) * 7.1362384635298E+44
        local v61 = math.floor(v60)
        local v62 = v60 - v61

        v59 = if v62 > 0.5 or v62 == 0.5 and v61 % 2 == 1 then v61 + 1 else v61

        if v56 < 0 then
            v59 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v56)
        v59 = buffer.readu32(v1, 0)
    end

    p4[40] = v59
    t1.store_xyz(p4, 8, v51)
    t1.store_xyz(p4, 12, v45)

    for i = 1, #p7 do
        p7[i] = 0
    end

    local gravity_acceleration = p6.gravity_acceleration

    t1.store_xyz(p4, 36, {
        gravity_acceleration.x,
        gravity_acceleration.y,
        gravity_acceleration.z,
        0
    })
    t1.store_xyz(p4, 40, table.create(4, 0))

    return {
        orientation_displacement = rt.slice(v14, 0, 3),
        linear_speed_squared = v52,
        angular_speed_squared = v46
    }
end

function t1.orientation(p9, p10) -- line: 115
    -- upvalues: rt (copy), t1 (copy)
    local v63 = t1.perm(t1.nmsub(t1.perm(p10, { 1, 2, 0, 3 }), p9, t1.mul(p10, t1.perm(p9, { 1, 2, 0, 3 }))), { 1, 2, 0, 3 })
    local v64 = t1.mul(t1.madd(p10, rt.filled(4, p9[4]), v63), table.create(4, 0.5))

    v64[4] = t1.dot(p10, p9, false) * -0.5

    local v65 = t1.add(p9, v64)

    return t1.mul(v65, rt.filled(4, t1.refined_rsqrt(t1.dot(v65, v65, true))))
end

function t1.quaternion_basis(p11) -- line: 127
    -- upvalues: rt (copy), t1 (copy)
    local v66 = t1.mul(p11, rt.filled(4, 1.4142135381698608))
    local v67 = t1.nmsub(v66, v66, table.create(4, 0.5))
    local v68 = t1.add(v67, t1.perm(v67, { 1, 2, 0, 0 }))
    local v69 = t1.mul(v66, t1.perm(v66, { 1, 2, 0, 0 }))
    local v70 = t1.mul(rt.filled(4, v66[4]), t1.perm(v66, { 2, 0, 1, 0 }))
    local v71 = t1.add(v69, v70)
    local v72 = t1.sub(v69, v70)

    return {
        {
            v68[2],
            v71[1],
            v72[3],
            0
        },
        {
            v72[1],
            v68[3],
            v71[2],
            0
        },
        {
            v71[3],
            v72[2],
            v68[1],
            0
        }
    }
end

function t1.inverse_inertia(p12, p13) -- line: 145
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v73 = p12[1]
    local v74 = p12[2]
    local v75 = p12[3]
    local mul = t1.mul
    local filled = rt.filled

    buffer.writeu32(v1, 0, p13[1])

    local v77 = mul(v73, filled(4, (buffer.readf32(v1, 0))))
    local mul2 = t1.mul
    local filled2 = rt.filled

    buffer.writeu32(v1, 0, p13[2])

    local v79 = mul2(v74, filled2(4, (buffer.readf32(v1, 0))))
    local mul3 = t1.mul
    local filled3 = rt.filled

    buffer.writeu32(v1, 0, p13[3])

    local v81 = mul3(v75, filled3(4, (buffer.readf32(v1, 0))))
    local v82 = t1.madd(v81, rt.filled(4, v75[1]), t1.madd(v77, rt.filled(4, v73[1]), t1.mul(v79, rt.filled(4, v74[1]))))

    local function p(p14) -- line: 151
        -- upvalues: t1 (copy)
        return t1.perm(p14, { 2, 1, 1, 3 })
    end

    local function s(p15) -- line: 154
        -- upvalues: t1 (copy)
        return t1.perm(p15, { 2, 1, 2, 3 })
    end

    return v82, (t1.madd(t1.perm(v75, { 2, 1, 1, 3 }), t1.perm(v81, { 2, 1, 2, 3 }), t1.madd(t1.perm(v73, { 2, 1, 1, 3 }), t1.perm(v77, { 2, 1, 2, 3 }), t1.mul(t1.perm(v74, { 2, 1, 1, 3 }), s(v79)))))
end

function t1.cap(p16, p17) -- line: 162
    -- upvalues: rt (copy), t1 (copy)
    local v83 = t1.dot(p16, p16, false)
    local v84 = p17 * p17

    if v84 < v83 then
        local v85 = v84 / v83
        local v86 = v85 * t1.refined_rsqrt(v85)

        if v85 == 0 then
            v86 = 0
        end

        return t1.mul(p16, rt.filled(4, v86)), v84
    end

    return p16, v83
end

function t1.refined_rsqrt(p18) -- line: 177
    -- upvalues: v8 (copy)
    local v87 = v8.estimate(p18)
    local v88 = v87 * v87
    local v89 = v87 * 0.5 * (-p18 * v88 + 1) + v87
    local v90 = v89 * v89

    return v89 * 0.5 * (-p18 * v90 + 1) + v89
end

function t1.dot(p19, p20, p21) -- line: 188
    -- upvalues: v9 (copy)
    if p21 then
        return v9.dot4(p19, p20)
    end

    return v9.dot3(p19, p20)
end

function t1.load(p22, p23) -- line: 196
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p22[p23 + 0 + 1])

    local v92 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p22[p23 + 1 + 1])

    local v94 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p22[p23 + 2 + 1])

    local v96 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p22[p23 + 3 + 1])

    return {
        v92,
        v94,
        v96,
        (buffer.readf32(v1, 0))
    }
end

function t1.store_xyz(p24, p25, p26) -- line: 205
    -- upvalues: v1 (copy)
    local v98 = p25 + 0 + 1
    local v99 = p26[1]
    local v100

    if v99 ~= 0 and v99 > -1.1754943508222875E-38 and v99 < 1.1754943508222875E-38 then
        local v101 = math.abs(v99) * 7.1362384635298E+44
        local v102 = math.floor(v101)
        local v103 = v101 - v102

        v100 = if v103 > 0.5 or v103 == 0.5 and v102 % 2 == 1 then v102 + 1 else v102

        if v99 < 0 then
            v100 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v99)
        v100 = buffer.readu32(v1, 0)
    end

    p24[v98] = v100

    local v104 = p25 + 1 + 1
    local v105 = p26[2]
    local v106

    if v105 ~= 0 and v105 > -1.1754943508222875E-38 and v105 < 1.1754943508222875E-38 then
        local v107 = math.abs(v105) * 7.1362384635298E+44
        local v108 = math.floor(v107)
        local v109 = v107 - v108

        v106 = if v109 > 0.5 or v109 == 0.5 and v108 % 2 == 1 then v108 + 1 else v108

        if v105 < 0 then
            v106 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v105)
        v106 = buffer.readu32(v1, 0)
    end

    p24[v104] = v106

    local v110 = p25 + 2 + 1
    local v111 = p26[3]
    local v112

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        local v113 = math.abs(v111) * 7.1362384635298E+44
        local v114 = math.floor(v113)
        local v115 = v113 - v114

        v112 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

        if v111 < 0 then
            v112 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v111)
        v112 = buffer.readu32(v1, 0)
    end

    p24[v110] = v112
end

function t1.perm(p27, p28) -- line: 212
    local t3 = {}

    for v116, v117 in ipairs(p28) do
        t3[v116] = p27[v117 + 1]
    end

    return t3
end

function t1.mul(p29, p30) -- line: 220
    return {
        p29[1] * p30[1],
        p29[2] * p30[2],
        p29[3] * p30[3],
        p29[4] * p30[4]
    }
end

function t1.add(p31, p32) -- line: 224
    return {
        p31[1] + p32[1],
        p31[2] + p32[2],
        p31[3] + p32[3],
        p31[4] + p32[4]
    }
end

function t1.sub(p33, p34) -- line: 228
    return {
        p33[1] - p34[1],
        p33[2] - p34[2],
        p33[3] - p34[3],
        p33[4] - p34[4]
    }
end

function t1.madd(p35, p36, p37) -- line: 232
    return {
        p35[1] * p36[1] + p37[1],
        p35[2] * p36[2] + p37[2],
        p35[3] * p36[3] + p37[3],
        p35[4] * p36[4] + p37[4]
    }
end

function t1.nmsub(p38, p39, p40) -- line: 241
    return {
        -p38[1] * p39[1] + p40[1],
        -p38[2] * p39[2] + p40[2],
        -p38[3] * p39[3] + p40[3],
        -p38[4] * p39[4] + p40[4]
    }
end

return t1
