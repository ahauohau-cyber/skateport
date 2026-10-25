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

local Scorable = require(sim.import)("skate_core/scoring").Scorable
local t1 = {
    delay_ticks = function(p3, p4) -- delay_ticks | line: 39
        -- upvalues: rt (copy), v1 (copy)
        local v9 = p3 + p4
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

        local v14 = v10 * 60
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

        if v15 ~= v15 then
            return 0
        end

        local v19 = rt.trunc(v15)

        if v19 >= 9223372036854776000 then
            return 4294967295
        end

        if v19 <= -9223372036854776000 then
            return 0
        end

        return v19 % 4294967296
    end,
    Carrier = {}
}
local Carrier = t1.Carrier

function t1.Carrier.new(p5, p6, p7, p8, p9, p10, p11, p12) -- line: 64
    -- upvalues: rt (copy)
    return {
        reward = 0,
        announced = false,
        completed = false,
        unannounced = false,
        scorable = rt.copy(p5),
        points = p6,
        factor = p7,
        announcement_threshold = p8 * p7,
        start_tick = p9,
        delay_ticks = p10,
        switch = p11,
        fakie = p12
    }
end

function t1.Carrier.credit(p13, p14) -- line: 90
    local v20 = p13.points * p13.factor

    if p13.unannounced then
        v20 *= p14
    end

    p13.reward += v20
end

function t1.Carrier.announce(p15, p16, p17) -- line: 100
    -- upvalues: rt (copy), Scorable (copy), Carrier (copy)
    if p15.announced or not Scorable.valid(p15.scorable) or rt.wrapping_sub_u32(p16, p15.start_tick) < p15.delay_ticks then
        return false
    end

    p15.announced = true
    Carrier.credit(p15, p17)

    return true
end

function t1.Carrier.complete(p18, p19) -- line: 115
    -- upvalues: Scorable (copy), Carrier (copy)
    if not Scorable.valid(p18.scorable) then
        return false
    end

    if not p18.announced then
        p18.unannounced = true
        Carrier.credit(p18, p19)
    end

    p18.completed = true

    return true
end

function t1.Carrier.convert_to(p20, p21, p22) -- line: 130
    -- upvalues: Carrier (copy)
    p20.completed = true
    p21.announced = true
    Carrier.credit(p21, p22)
end

return t1
