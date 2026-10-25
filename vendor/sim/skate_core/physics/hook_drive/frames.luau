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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local v8 = require(sim.import)("skate_core/physics/reciprocal_sqrt")
local t1 = {
    add = function(p4, p5) -- add | line: 38
        return {
            p4[1] + p5[1],
            p4[2] + p5[2],
            p4[3] + p5[3],
            p4[4] + p5[4]
        }
    end,
    sub = function(p6, p7) -- sub | line: 41
        return {
            p6[1] - p7[1],
            p6[2] - p7[2],
            p6[3] - p7[3],
            p6[4] - p7[4]
        }
    end,
    mul = function(p8, p9) -- mul | line: 44
        return {
            p8[1] * p9[1],
            p8[2] * p9[2],
            p8[3] * p9[3],
            p8[4] * p9[4]
        }
    end
}

function t1.rsqrt(p10) -- line: 47
    -- upvalues: v8 (copy)
    local v9 = v8.estimate(p10)
    local v10 = v9 * v9
    local v11 = v9 * 0.5 * (-p10 * v10 + 1) + v9
    local v12 = v11 * v11

    return v11 * 0.5 * (-p10 * v12 + 1) + v11
end

function t1.set_child_angular_frame(p11, p12) -- line: 57
    -- upvalues: t1 (copy)
    local v13 = t1.convert(p12)

    p11[1] = v13[1]
    p11[2] = v13[2]
    p11[3] = v13[3]
    p11[4] = v13[4]
end

function t1.set_parent_angular_frame(p13, p14) -- line: 64
    -- upvalues: t1 (copy)
    local v14 = t1.convert(p14)

    p13[9] = v14[1]
    p13[10] = v14[2]
    p13[11] = v14[3]
    p13[12] = v14[4]
end

function t1.convert(p15) -- line: 70
    -- upvalues: v1 (copy), t1 (copy)
    local quaternion = t1.quaternion

    buffer.writeu32(v1, 0, p15[1])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[2])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[3])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[4])

    local t2 = {
        v16,
        v18,
        v20,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p15[5])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[6])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[7])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[8])

    local t3 = {
        v23,
        v25,
        v27,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p15[9])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[10])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[11])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p15[12])

    local v36 = quaternion({
        t2,
        t3,
        {
            v30,
            v32,
            v34,
            (buffer.readf32(v1, 0))
        }
    })
    local v37 = table.create(4)
    local v38 = v36[1]
    local v39

    if v38 ~= 0 and v38 > -1.1754943508222875E-38 and v38 < 1.1754943508222875E-38 then
        local v40 = math.abs(v38) * 7.1362384635298E+44
        local v41 = math.floor(v40)
        local v42 = v40 - v41

        v39 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

        if v38 < 0 then
            v39 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v38)
        v39 = buffer.readu32(v1, 0)
    end

    v37[1] = v39

    local v43 = v36[2]
    local v44

    if v43 ~= 0 and v43 > -1.1754943508222875E-38 and v43 < 1.1754943508222875E-38 then
        local v45 = math.abs(v43) * 7.1362384635298E+44
        local v46 = math.floor(v45)
        local v47 = v45 - v46

        v44 = if v47 > 0.5 or v47 == 0.5 and v46 % 2 == 1 then v46 + 1 else v46

        if v43 < 0 then
            v44 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v43)
        v44 = buffer.readu32(v1, 0)
    end

    v37[2] = v44

    local v48 = v36[3]
    local v49

    if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
        local v50 = math.abs(v48) * 7.1362384635298E+44
        local v51 = math.floor(v50)
        local v52 = v50 - v51

        v49 = if v52 > 0.5 or v52 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51

        if v48 < 0 then
            v49 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v48)
        v49 = buffer.readu32(v1, 0)
    end

    v37[3] = v49

    local v53 = v36[4]
    local v54

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        local v55 = math.abs(v53) * 7.1362384635298E+44
        local v56 = math.floor(v55)
        local v57 = v55 - v56

        v54 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

        if v53 < 0 then
            v54 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v54 = buffer.readu32(v1, 0)
    end

    v37[4] = v54

    return v37
end

function t1.quaternion(p16) -- line: 82
    -- upvalues: t1 (copy)
    local v58 = p16[1]
    local v59 = p16[2]
    local v60 = p16[3]
    local t4 = {
        v58[1],
        v58[1],
        -v58[1],
        -v58[1]
    }
    local t5 = {
        v59[2],
        -v59[2],
        v59[2],
        -v59[2]
    }
    local t6 = {
        v60[3],
        -v60[3],
        -v60[3],
        v60[3]
    }
    local v61 = t1.add(t4, t5)
    local v62 = t1.add(v61, t1.add(t6, table.create(4, 1)))
    local v63 = table.create(4)

    v63[1] = t1.rsqrt(v62[1])
    v63[2] = t1.rsqrt(v62[2])
    v63[3] = t1.rsqrt(v62[3])
    v63[4] = t1.rsqrt(v62[4])

    local v64 = t1.mul(v62, v63)
    local v65 = t1.mul(table.create(4, 0.5), v63)
    local t7 = {
        v59[3],
        v60[1],
        v58[2],
        0.5
    }
    local t8 = {
        v60[2],
        v58[3],
        v59[1],
        0
    }
    local v66 = t1.sub(t7, t8)
    local v67 = t1.add(t7, t8)
    local v68 = t1.mul({
        v67[3],
        v66[4],
        v67[1],
        v66[2]
    }, {
        v65[3],
        v64[3],
        v65[3],
        v65[3]
    })
    local v69 = t1.mul({
        v67[2],
        v67[1],
        v66[4],
        v66[3]
    }, {
        v65[4],
        v65[4],
        v64[4],
        v65[4]
    })
    local v70 = t1.mul({
        v66[4],
        v67[3],
        v67[2],
        v66[1]
    }, {
        v64[2],
        v65[2],
        v65[2],
        v65[2]
    })
    local v71 = t1.mul(v66, {
        v65[1],
        v65[1],
        v65[1],
        v64[1]
    })

    if not (v59[2] > v60[3]) then
        v68 = v69
    end

    if v58[1] > v59[2] and v58[1] > v60[3] then
        v68 = v70
    end

    if v61[1] + v60[3] > 0 then
        return v71
    end

    return v68
end

return t1
