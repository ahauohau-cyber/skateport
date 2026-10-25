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

require(sim.import)

return {
    AngleError = {},
    normalize = function(p4) -- normalize | line: 40
        -- upvalues: rt (copy), v1 (copy)
        if p4 >= -3.1415927410125732 and p4 < 3.1415927410125732 then
            return p4
        end

        local v9 = p4 * 0.15915493667125702
        local v10

        if v9 ~= 0 and v9 > -1.1754943508222875E-38 and v9 < 1.1754943508222875E-38 then
            local v11 = math.abs(v9) * 7.1362384635298E+44
            local v12 = math.floor(v11)
            local v13 = v11 - v12

            v10 = (if v13 > 0.5 or v13 == 0.5 and v12 % 2 == 1 then v12 + 1 else v12) * 1.401298464324817E-45

            if v9 < 0 then
                v10 = -v10
            end
        else
            buffer.writef32(v1, 0, v9)
            v10 = buffer.readf32(v1, 0)
        end

        if v10 ~= v10 or v10 == 1e999 or v10 == (-1e999) or v10 < -2147483648 or v10 > 2147483647 then
            error("IntegerConversionUnavailable", 0)
        end

        local v14 = rt.f_to_i32(v10) * 6.2831854820251465 + -p4
        local v15

        if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
            local v16 = math.abs(v14) * 7.1362384635298E+44
            local v17 = math.floor(v16)
            local v18 = v16 - v17

            v15 = (if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17) * 1.401298464324817E-45

            if v14 < 0 then
                v15 = -v15
            end
        else
            buffer.writef32(v1, 0, v14)
            v15 = buffer.readf32(v1, 0)
        end

        local v19 = -v15

        if v19 >= 3.1415927410125732 then
            local v20 = v19 - 6.2831854820251465

            if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
                local v22 = math.abs(v20) * 7.1362384635298E+44
                local v21 = math.floor(v22)
                local v23 = v22 - v21

                if v23 > 0.5 or v23 == 0.5 and v21 % 2 == 1 then
                    v21 += 1
                end

                local v24 = v21 * 1.401298464324817E-45

                if v20 < 0 then
                    return -v24
                end

                return v24
            end

            buffer.writef32(v1, 0, v20)

            return (buffer.readf32(v1, 0))
        end

        if not (v19 < -3.1415927410125732) then
            return v19
        end

        local v25 = v19 + 6.2831854820251465

        if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
            local v27 = math.abs(v25) * 7.1362384635298E+44
            local v26 = math.floor(v27)
            local v28 = v27 - v26

            if v28 > 0.5 or v28 == 0.5 and v26 % 2 == 1 then
                v26 += 1
            end

            local v29 = v26 * 1.401298464324817E-45

            if v25 < 0 then
                return -v29
            end

            return v29
        end

        buffer.writef32(v1, 0, v25)

        return (buffer.readf32(v1, 0))
    end
}
