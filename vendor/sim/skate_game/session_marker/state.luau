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

local t1 = {
    Hold = {}
}

function t1.Hold.default() -- line: 42
    return {
        elapsed = 0,
        fired = false,
        tail = 0
    }
end

t1.Step = {}

function t1.Step.default() -- line: 50
    return {
        progress = 0,
        relocate = false
    }
end

function t1.Step.eq(p4, p5) -- line: 55
    if p4.progress == p5.progress then
        return p4.relocate == p5.relocate
    end

    return false
end

function t1.Hold.cancel(p6) -- line: 60
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p6, t1.Hold.default())
end

function t1.Hold.update(p7, p8, p9, p10, p11) -- line: 65
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v9 = t1.Step.default()

    if p8 then
        if not p7.fired and p9 then
            local v11 = p7.elapsed + 0.01666666753590107
            local v10

            if v11 == 0 then
                buffer.writef32(v1, 0, v11)
                v10 = buffer.readf32(v1, 0)
            elseif v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
                local v12 = math.abs(v11) * 7.1362384635298E+44
                local v13 = math.floor(v12)
                local v14 = v12 - v13

                if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then
                    v13 += 1
                end

                v10 = v13 * 1.401298464324817E-45

                if v11 < 0 then
                    v10 = -v10
                end
            else
                buffer.writef32(v1, 0, v11)
                v10 = buffer.readf32(v1, 0)
            end

            p7.elapsed = v10

            if p10 > 0.5 and p10 == p10 and p10 ~= 1e999 and p10 ~= (-1e999) then
                local v15 = t1.duration(p10)

                if p11 and v15 < p7.elapsed then
                    p7.fired = true
                    p7.tail = 3
                    v9.relocate = true
                end

                local clamp = rt.clamp
                local v16 = p7.elapsed / v15
                local v17

                if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
                    local v18 = math.abs(v16) * 7.1362384635298E+44
                    local v19 = math.floor(v18)
                    local v20 = v18 - v19

                    v17 = (if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19) * 1.401298464324817E-45

                    if v16 < 0 then
                        v17 = -v17
                    end
                else
                    buffer.writef32(v1, 0, v16)
                    v17 = buffer.readf32(v1, 0)
                end

                v9.progress = clamp(v17, 0, 1)
            end
        end
    else
        p7.elapsed = 0
        p7.fired = false
    end

    if p7.tail > 0 then
        v9.progress = 1
        p7.tail -= 1
    end

    return v9
end

function t1.duration(p12) -- line: 92
    -- upvalues: v1 (copy)
    if p12 <= 100 then
        buffer.writef32(v1, 0, 0.2)

        return (buffer.readf32(v1, 0))
    end

    if p12 >= 1000 then
        return 1
    end

    local v21 = p12 * 0.0008888888987712562 + 0.1111111119389534

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v22 = math.floor(v23)
        local v24 = v23 - v22

        if v24 > 0.5 or v24 == 0.5 and v22 % 2 == 1 then
            v22 += 1
        end

        local v25 = v22 * 1.401298464324817E-45

        if v21 < 0 then
            return -v25
        end

        return v25
    end

    buffer.writef32(v1, 0, v21)

    return (buffer.readf32(v1, 0))
end

return t1
