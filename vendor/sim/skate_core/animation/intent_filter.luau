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

local apply_filter = require(sim.import)("skate_core/input/graph_intents").apply_filter
local t1 = {
    Settings = {}
}

function t1.Settings.eq(p3, p4) -- line: 41
    if p3.filters[1] ~= p4.filters[1] or p3.filters[2] ~= p4.filters[2] or p3.filters[3] ~= p4.filters[3] or p3.filters[4] ~= p4.filters[4] then
        return false
    end

    if p3.starting_value == p4.starting_value and p3.default_value == p4.default_value and p3.scale == p4.scale and p3.ramp_time == p4.ramp_time and p3.blend_rising == p4.blend_rising and p3.blend_falling == p4.blend_falling and p3.blend_out == p4.blend_out and p3.clamp_velocity == p4.clamp_velocity then
        return p3.clamp_acceleration == p4.clamp_acceleration
    end

    return false
end

t1.State = {}

function t1.State.default() -- line: 61
    return {
        elapsed = 0,
        previous_delta = 0,
        value = 0
    }
end

function t1.State.eq(p5, p6) -- line: 66
    if p5.elapsed == p6.elapsed and p5.previous_delta == p6.previous_delta then
        return p5.value == p6.value
    end

    return false
end

local limit_delta, ramp

function t1.State.begin(p7, p8) -- line: 74
    p7.elapsed = 0
    p7.previous_delta = 0
    p7.value = p8.starting_value

    return p7.value
end

function t1.State.update(p9, p10, p11, p12, p13) -- line: 83
    -- upvalues: apply_filter (copy), limit_delta (ref), ramp (ref)
    p9.elapsed += p12

    local v8 = p10.scale * (if p11 == nil then p10.default_value else p11)
    local t2 = {
        true,
        true,
        p13[1],
        p13[2]
    }

    for i = 0, 3 do
        local v9 = p10.filters[i + 1]

        if t2[i + 1] and v9 <= 7 then
            v8 = apply_filter(v8, v9)
        end
    end

    local v10 = if v8 < p9.value then p10.blend_falling else p10.blend_rising

    if p11 ~= nil then
        if p10.ramp_time ~= nil then
            local ramp_time = p10.ramp_time

            v10 = ramp(p9.elapsed, ramp_time) * v10
        end
    elseif p10.blend_out ~= nil then
        v10 = p10.blend_out
    end

    local v11 = v10 * v8
    local v12 = (1 - v10) * p9.value + v11 - p9.value

    if p10.clamp_acceleration ~= nil then
        local clamp_acceleration = p10.clamp_acceleration

        v12 = limit_delta(v12, p9.previous_delta - clamp_acceleration, p9.previous_delta + clamp_acceleration)
    end

    if p10.clamp_velocity ~= nil then
        local clamp_velocity = p10.clamp_velocity

        v12 = limit_delta(v12, -clamp_velocity, clamp_velocity)
    end

    p9.previous_delta = v12
    p9.value = v12 + p9.value

    return p9.value
end

function t1.limit_delta(p14, p15, p16) -- line: 126
    local v13 = if p15 - p14 >= 0 then p15 else p14

    if p16 - v13 >= 0 then
        return v13
    end

    return p16
end

limit_delta = t1.limit_delta

function t1.ramp(p17, p18) -- line: 137
    -- upvalues: rt (copy), v1 (copy)
    local t3 = {
        0,
        p18
    }
    local n1 = 0
    local n2 = 2

    while n2 ~= 0 do
        local v14 = rt.idiv(n2, 2)
        local v15 = n1 + v14
        local to_i32 = rt.to_i32
        local v16 = t3[v15 + 1]
        local v17

        if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
            local v18 = math.abs(v16) * 7.1362384635298E+44
            local v19 = math.floor(v18)
            local v20 = v18 - v19
            local v21 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

            v17 = if v16 < 0 then v21 + 2147483648 else v21
        else
            buffer.writef32(v1, 0, v16)
            v17 = buffer.readu32(v1, 0)
        end

        local v22 = to_i32(v17)
        local to_i32_2 = rt.to_i32
        local v23

        if p17 ~= 0 and p17 > -1.1754943508222875E-38 and p17 < 1.1754943508222875E-38 then
            local v24 = math.abs(p17) * 7.1362384635298E+44
            local v25 = math.floor(v24)
            local v26 = v24 - v25
            local v27 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

            v23 = if p17 < 0 then v27 + 2147483648 else v27
        else
            buffer.writef32(v1, 0, p17)
            v23 = buffer.readu32(v1, 0)
        end

        if v22 < to_i32_2(v23) then
            n1 = v15 + 1
            n2 -= v14 + 1
        else
            n2 = v14
        end
    end

    if n1 == 0 then
        return 0
    end

    if n1 == 2 then
        return 1
    end

    return 1 / (p18 - 0) * (p17 - 0) + 0
end

ramp = t1.ramp

return t1
