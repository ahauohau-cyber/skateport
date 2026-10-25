-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/native_arithmetic")
local t1 = {}

function t1.add(p1, p2) -- line: 13
    -- upvalues: Vector3 (copy)
    return Vector3.new(p1.x + p2.x, p1.y + p2.y, p1.z + p2.z)
end

function t1.sub(p3, p4) -- line: 17
    -- upvalues: Vector3 (copy)
    return Vector3.new(p3.x - p4.x, p3.y - p4.y, p3.z - p4.z)
end

function t1.scale(p5, p6) -- line: 21
    -- upvalues: Vector3 (copy)
    return Vector3.new(p5.x * p6, p5.y * p6, p5.z * p6)
end

function t1.madd(p7, p8, p9) -- line: 25
    -- upvalues: Vector3 (copy)
    return Vector3.new(p7.x * p8 + p9.x, p7.y * p8 + p9.y, p7.z * p8 + p9.z)
end

function t1.dot(p10, p11) -- line: 29
    return p10.x * p11.x + p10.y * p11.y + p10.z * p11.z
end

function t1.cross(p12, p13) -- line: 33
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p12.z * p13.y + p12.y * p13.z, -p12.x * p13.z + p12.z * p13.x, -p12.y * p13.x + p12.x * p13.y)
end

function t1.horizontal(p14) -- line: 37
    -- upvalues: Vector3 (copy)
    return Vector3.new(p14.x, 0, p14.z)
end

function t1.abs(p15) -- line: 41
    -- upvalues: Vector3 (copy)
    return Vector3.new(math.abs(p15.x), math.abs(p15.y), (math.abs(p15.z)))
end

function t1.inverse_root(p16) -- line: 46
    -- upvalues: v1 (copy)
    local v4 = v1.reciprocal_square_root_estimate(p16)
    local v5 = v4 * 0.5 * (-p16 * (v4 * v4) + 1) + v4

    return v5 * 0.5 * (-p16 * (v5 * v5) + 1) + v5
end

function t1.length(p17) -- line: 54
    -- upvalues: t1 (copy)
    local v6 = t1.dot(p17, p17)
    local v7 = v6 * t1.inverse_root(v6)

    if v6 == 0 then
        return 0
    end

    return v7
end

function t1.reciprocal(p18) -- line: 64
    -- upvalues: v1 (copy)
    local v8 = v1.reciprocal_estimate(p18)
    local v9 = v8 * (-p18 * v8 + 1) + v8

    return v9 * (-p18 * v9 + 1) + v9
end

function t1.safe_unit(p19, p20) -- line: 73
    -- upvalues: rt (copy), t1 (copy)
    local v10 = t1.dot(p19, p19)
    local v11 = t1.inverse_root(v10)

    if (if v10 == 0 then 0 else v10 * v11) > 9.999999974752427E-07 then
        return t1.scale(p19, v11)
    end

    return rt.copy(p20)
end

return t1
