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

local import = require(sim.import)
local v9 = import("skate_core/animation/output/attributes")
local v10 = import("skate_core/animation/skeleton_input/name")
local AttributeName = v9.AttributeName
local encode = v10.encode
local t1 = {
    State = {}
}

function t1.State.default() -- line: 41
    return {
        frames = 0
    }
end

function t1.State.begin(p4, p5, p6) -- line: 46
    -- upvalues: rt (copy), v1 (copy)
    local v11 = (p5 - p6) * 59.999996
    local v12

    if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
        local v13 = math.abs(v11) * 7.1362384635298E+44
        local v14 = math.floor(v13)
        local v15 = v13 - v14

        v12 = (if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14) * 1.401298464324817E-45

        if v11 < 0 then
            v12 = -v12
        end
    else
        buffer.writef32(v1, 0, v11)
        v12 = buffer.readf32(v1, 0)
    end

    if not (v12 == v12 and v12 ~= 1e999 and v12 ~= (-1e999)) or v12 >= 2147483648 then
        error(("AirDismounting invalid animation timing: length=%* time=%*"):format(p5, p6), 0)
    end

    p4.frames = rt.f_to_i32(rt.fmax(v12, 1))
end

function t1.State.request(p7, p8) -- line: 61
    -- upvalues: AttributeName (copy), encode (copy)
    local airdismountrevert = encode("airdismountrevert")

    for _, v16 in p8 do
        if AttributeName.eq(v16.name, airdismountrevert) then
            return p7.frames
        end
    end

    return nil
end

return t1
