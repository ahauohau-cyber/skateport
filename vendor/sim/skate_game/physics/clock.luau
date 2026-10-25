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
    NORMAL_STEP = 0.01666666753590107
}
local timer_period

t1.SimulationClock = {}

function t1.SimulationClock.default() -- line: 43
    -- upvalues: timer_period (ref)
    return {
        ticks_until_reset = 0,
        timer_period = timer_period(60)
    }
end

function t1.SimulationClock.apply(p4, p5) -- line: 51
    -- upvalues: rt (copy), v1 (copy), t1 (copy), timer_period (ref)
    local trunc = rt.trunc
    local v9 = 1 / p5.timestep
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

    local v14 = v10 + 0.5
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

    local v19 = trunc(v15)

    if v19 ~= v19 or v19 == 1e999 or v19 == (-1e999) or v19 < 1 or v19 > 2147483648 then
        error(string.format("Invalid simulation-rate request: %s", (tostring(p5.timestep))), 0)
    end

    local v20 = rt.f_to_i32(v19)

    if rt.idiv(1E+07, v20) == 0 then
        error("Simulation-rate request has a zero timer period", 0)
    end

    p4.timer_period = timer_period(v20)

    if p5.timestep == t1.NORMAL_STEP then
        p4.ticks_until_reset = 0
    elseif rt.to_i32(p5.ticks) > 0 then
        p4.ticks_until_reset = rt.wrapping_add_u32(p5.ticks, 1)
    else
        p4.ticks_until_reset = 180
    end
end

function t1.SimulationClock.finish_tick(p6) -- line: 73
    -- upvalues: rt (copy), timer_period (ref)
    p6.ticks_until_reset = rt.wrapping_sub_u32(p6.ticks_until_reset, 1)

    if p6.ticks_until_reset == 0 then
        p6.timer_period = timer_period(60)
    end
end

function t1.SimulationClock.period(p7) -- line: 83
    return p7.timer_period
end

function timer_period(p8) -- line: 88
    -- upvalues: rt (copy)
    return rt.idiv(1E+07, p8) * 100
end

t1.timer_period = timer_period

return t1
