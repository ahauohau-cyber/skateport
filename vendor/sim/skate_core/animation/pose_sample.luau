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

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local blend_sample = require(sim.import)("skate_core/animation/pose_blend").blend_sample
local t1 = {
    FrameSelection = {}
}

function t1.FrameSelection.eq(p4, p5) -- line: 40
    if p4.first == p5.first and p4.second == p5.second then
        return p4.coefficient == p5.coefficient
    end

    return false
end

function t1.select_frames(p6, p7, p8, p9, p10) -- line: 47
    -- upvalues: rt (copy), v1 (copy)
    local v9 = false
    local v10 = false
    local v11 = false
    local v12 = false
    local v13 = false

    if p8 == 0 then
    else
        v9 = true
    end

    local v14

    if v9 then
        if p6 == p6 then
            v10 = true
        else
            v14 = false
            v11 = true
        end
    end

    v9 = false

    if v10 then
        if p6 == 1e999 then
            v14 = false
            v11 = true
        else
            v9 = true
        end
    end

    v10 = false

    if v9 then
        if p6 == (-1e999) then
            v12 = true
        else
            v10 = true
        end
    end

    v9 = false

    if v10 then
        v14 = true
        v11 = true
    end

    v10 = false

    if v12 then
        v14 = false
        v11 = true
    end

    v12 = false

    if v11 then
        if v14 then
            v12 = true
        else
            v13 = false
        end
    end

    v11 = false

    if v12 then
        if p6 < 0 then
            v13 = false
        else
            v11 = true
        end
    end

    v12 = false

    local v15

    if v11 then
        if p7 == p7 then
            v12 = true
        else
            v15 = false
            v10 = true
        end
    end

    v11 = false

    if v12 then
        if p7 == 1e999 then
            v15 = false
            v10 = true
        else
            v11 = true
        end
    end

    v12 = false

    if v11 then
        if p7 == (-1e999) then
            v9 = true
        else
            v12 = true
        end
    end

    if v12 then
        v15 = true
        v10 = true
    end

    if v9 then
        v15 = false
        v10 = true
    end

    v9 = false

    if v10 then
        if v15 then
            v9 = true
        else
            v13 = false
        end
    end

    if v9 then
        v13 = not (p7 <= 0)
    end

    if not v13 then
        error("Invalid stock animation sampling input", 0)
    end

    local v16 = p8 - 1
    local v17 = p6 * p7
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = (if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20) * 1.401298464324817E-45

        if v17 < 0 then
            v18 = -v18
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readf32(v1, 0)
    end

    if not (v18 - v16 >= 0) then
        v16 = v18
    end

    local v22 = if p9 then 0 else p10
    local f_to_usize = rt.f_to_usize
    local v23 = v16 + v22
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = (if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26) * 1.401298464324817E-45

        if v23 < 0 then
            v24 = -v24
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readf32(v1, 0)
    end

    local v28 = f_to_usize(v24)

    if p8 <= v28 then
        error("Stock frame selection exceeds decoded samples", 0)
    end

    local v29 = if p9 then math.min(v28 + 1, p8 - 1) else v28
    local f_to_int = rt.f_to_int
    local v32 = v16 - v28
    local v33

    if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
        local v34 = math.abs(v32) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

        if v32 < 0 then
            v33 = -v33
        end
    else
        buffer.writef32(v1, 0, v32)
        v33 = buffer.readf32(v1, 0)
    end

    local v37 = v33 * 65535
    local v38

    if v37 == 0 or not (v37 > -1.1754943508222875E-38) or not (v37 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v37)
        v38 = buffer.readf32(v1, 0)

        return {
            first = v28,
            second = v29,
            coefficient = f_to_int(v38, 0, 65535) * 1.5259021893143654E-05
        }
    end

    local v39 = math.abs(v37) * 7.1362384635298E+44
    local v40 = math.floor(v39)
    local v41 = v39 - v40

    v38 = (if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40) * 1.401298464324817E-45

    if v37 < 0 then
        v38 = -v38
    end

    return {
        first = v28,
        second = v29,
        coefficient = f_to_int(v38, 0, 65535) * 1.5259021893143654E-05
    }
end

function t1.sample_key(p11, p12, p13) -- line: 77
    -- upvalues: rt (copy), blend_sample (copy)
    if p13.first == p13.second then
        return rt.copy(p11)
    end

    return blend_sample(p11, p12, p13.coefficient)
end

function t1.sample_key_vbr(p14, p15, p16) -- line: 91
    -- upvalues: rt (copy), t1 (copy)
    local v42 = rt.idiv(p16.first, 8) ~= rt.idiv(p16.second, 8) and (rt.irem(p16.first, 8) == 7 or rt.irem(p16.second, 8) == 0)

    return t1.sample_key(if v42 then p15 else p14, p15, p16)
end

return t1
