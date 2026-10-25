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

local import = require(sim.import)
local v8 = import("skate_core/player/wipeout_state/math")
local v9 = import("skate_core/player/wipeout_state/torque")
local t1 = {
    UP = { 0, 1, 0, 0 }
}
local UP = t1.UP

function t1.update(p4, p5, p6, p7, p8) -- line: 42
    -- upvalues: v1 (copy), v8 (copy), v9 (copy), UP (copy)
    local t2 = {
        0, 0, 0, 0
    }
    local v10 = v8.normalize_or(v8.sub(p5.record.pose[12][4], p5.record.pose[24][4]), t2)

    p4.angular_velocity = v9.angular_velocity(p5.record, p5.definition.animation_masses.fractional)

    if p8 then
        return false
    end

    local v11 = v8.normalize_or(p4.velocity, t2)
    local v12 = v8.normalize_or(v8.cross(UP, v10), t2)

    v12[2] = 0

    local v13 = v8.normalize_or(v12, t2)
    local v14 = v8.cross(UP, v11)

    if v8.dot(v14, v13) < 0 then
        v13 = v8.scale(v13, -1)
    end

    local v15 = v8.normalize_or(v14, t2)
    local v16 = v8.sub(v10, v8.scale(v15, v8.dot(v15, v10)))
    local v17 = v8.normalize_or(v16, t2)
    local v18 = v8.scale(v8.cross(v10, v17), 0.5)
    local v19 = p5.record.pose[24][2]

    if math.abs(p7[1]) < 0.5 and v19[2] < 0 then
        local v21 = v8.sub(v19, v8.scale(v15, v8.dot(v15, v19)))
        local v22 = v8.normalize_or(v21, t2)

        v18 = v8.madd(v8.cross(v19, v22), 0.5, v18)
    end

    local v23 = v8.scale(v13, 0.13962633907794952 * p7[2])
    local v24 = v10[1]
    local v25

    if v24 ~= 0 and v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
        local v26 = math.abs(v24) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if v24 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v24)
        v25 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v25, 2147483648)))

    local v30 = buffer.readf32(v1, 0)
    local v31 = v10[2]
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

    buffer.writeu32(v1, 0, (bit32.bxor(v32, 2147483648)))

    local v37 = buffer.readf32(v1, 0)
    local v38 = v10[3]
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

    buffer.writeu32(v1, 0, (bit32.bxor(v39, 2147483648)))

    local v44 = buffer.readf32(v1, 0)
    local v45 = v10[4]
    local v46

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        local v47 = math.abs(v45) * 7.1362384635298E+44
        local v48 = math.floor(v47)
        local v49 = v47 - v48

        v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

        if v45 < 0 then
            v46 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v45)
        v46 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v46, 2147483648)))

    local t3 = {
        v30,
        v37,
        v44,
        (buffer.readf32(v1, 0))
    }
    local v52 = v8.add(v8.madd(t3, 0.13962633907794952 * p7[1], v23), v18)
    local v53 = v8.scale(v52, 59.999996185302734)
    local v54 = v8.scale(v8.scale(v8.sub(v53, p4.angular_velocity), 2.4000000953674316), 0.01666666753590107)

    v9.apply(p5, p6, v8.limit_length(v54, 0.5))

    return true
end

return t1
