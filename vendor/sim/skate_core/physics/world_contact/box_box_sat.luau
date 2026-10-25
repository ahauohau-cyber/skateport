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
local v9 = import("skate_core/physics/world_contact/prism_math")
local estimate = v8.estimate
local load, dot, scale, cross = v9.load, v9.dot, v9.scale, v9.cross

return {
    box_box = function(p4, p5) -- box_box | line: 46
        -- upvalues: rt (copy), v1 (copy), estimate (copy), load (copy), dot (copy), scale (copy), cross (copy)
        local v10 = rt.filled(16, { 0, 0, 0, 0 })

        v10[1] = load(p4, 12)
        v10[4] = load(p5, 12)
        v10[2] = load(p4, 8)
        v10[5] = load(p5, 8)
        v10[3] = load(p4, 4)
        v10[6] = load(p5, 4)

        for i = 0, 2 do
            for j = 0, 2 do
                local v11 = cross(load(p4, i * 4 + 16), load(p5, j * 4 + 16))

                v10[i * 3 + 6 + j + 1] = scale(v11, estimate(dot(v11, v11)))
            end
        end

        v10[16] = rt.copy(v10[15])

        local v12 = load(p4, 4)

        buffer.writeu32(v1, 0, p4[29])

        local v14 = scale(v12, (buffer.readf32(v1, 0)))
        local v15 = load(p4, 8)

        buffer.writeu32(v1, 0, p4[30])

        local v17 = scale(v15, (buffer.readf32(v1, 0)))
        local v18 = load(p4, 12)

        buffer.writeu32(v1, 0, p4[31])

        local t2 = {
            v14,
            v17,
            scale(v18, (buffer.readf32(v1, 0)))
        }
        local v20 = load(p5, 4)

        buffer.writeu32(v1, 0, p5[29])

        local v22 = scale(v20, (buffer.readf32(v1, 0)))
        local v23 = load(p5, 8)

        buffer.writeu32(v1, 0, p5[30])

        local v25 = scale(v23, (buffer.readf32(v1, 0)))
        local v26 = load(p5, 12)

        buffer.writeu32(v1, 0, p5[31])

        local t3 = {
            v22,
            v25,
            scale(v26, (buffer.readf32(v1, 0)))
        }
        local v28 = 0
        local v29 = rt.copy(v10[1])
        local v30 = 1

        for i = 0, 15 do
            local v31 = v10[i + 1]
            local v32 = dot(load(p4, 0), v31)
            local v33 = dot(load(p5, 0), v31)
            local t4 = {
                math.abs((dot(t2[1], v31))),
                math.abs((dot(t2[2], v31))),
                (math.abs((dot(t2[3], v31))))
            }
            local t5 = {
                math.abs((dot(t3[1], v31))),
                math.abs((dot(t3[2], v31))),
                (math.abs((dot(t3[3], v31))))
            }
            local v44 = t4[1] + t4[2] + t4[3]
            local v45 = t5[1] + t5[2] + t5[3]
            local v46 = v32 - v44 - (v33 + v45)
            local v47 = v33 - v45 - (v32 + v44)
            local n1 = 1

            if v47 < v46 then
                n1 = -1
            else
                v46 = v47
            end

            if i == 0 or v28 < v46 then
                v28 = v46
                v29 = rt.copy(v31)
                v30 = n1
            end
        end

        local v48 = scale(v29, v30)
        local filled = rt.filled
        local v49

        if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
            local v50 = math.abs(v28) * 7.1362384635298E+44
            local v51 = math.floor(v50)
            local v52 = v50 - v51

            v49 = if v52 > 0.5 or v52 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51

            if v28 < 0 then
                v49 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v28)
            v49 = buffer.readu32(v1, 0)
        end

        local v53 = filled(4, v49)
        local v54 = v48[1]
        local v55

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            local v56 = math.abs(v54) * 7.1362384635298E+44
            local v57 = math.floor(v56)
            local v58 = v56 - v57

            v55 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v54 < 0 then
                v55 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v55 = buffer.readu32(v1, 0)
        end

        local v59 = v48[2]
        local v60

        if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
            local v61 = math.abs(v59) * 7.1362384635298E+44
            local v62 = math.floor(v61)
            local v63 = v61 - v62

            v60 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

            if v59 < 0 then
                v60 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v59)
            v60 = buffer.readu32(v1, 0)
        end

        local v64 = v48[3]
        local v65

        if v64 ~= 0 and v64 > -1.1754943508222875E-38 and v64 < 1.1754943508222875E-38 then
            local v66 = math.abs(v64) * 7.1362384635298E+44
            local v67 = math.floor(v66)
            local v68 = v66 - v67

            v65 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

            if v64 < 0 then
                v65 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v64)
            v65 = buffer.readu32(v1, 0)
        end

        local v69 = v48[4]
        local v70

        if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
            local v71 = math.abs(v69) * 7.1362384635298E+44
            local v72 = math.floor(v71)
            local v73 = v71 - v72

            v70 = if v73 > 0.5 or v73 == 0.5 and v72 % 2 == 1 then v72 + 1 else v72

            if v69 < 0 then
                v70 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v69)
            v70 = buffer.readu32(v1, 0)
        end

        return v53, {
            v55,
            v60,
            v65,
            v70
        }
    end
}
