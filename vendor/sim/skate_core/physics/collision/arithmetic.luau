-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3

import("skate_core/physics/native_arithmetic")

local v1 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {
    dot = function(p1, p2) -- dot | line: 14
        return p1.x * p2.x + p1.y * p2.y + p1.z * p2.z
    end
}

function t1.cross(p3, p4) -- line: 17
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p3.z * p4.y + p3.y * p4.z, -p3.x * p4.z + p3.z * p4.x, -p3.y * p4.x + p3.x * p4.y)
end

function t1.scale(p5, p6) -- line: 20
    -- upvalues: Vector3 (copy)
    return Vector3.new(p5.x * p6, p5.y * p6, p5.z * p6)
end

function t1.neg(p7) -- line: 23
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p7.x, -p7.y, -p7.z)
end

function t1.sub(p8, p9) -- line: 26
    -- upvalues: Vector3 (copy)
    return Vector3.new(p8.x - p9.x, p8.y - p9.y, p8.z - p9.z)
end

function t1.madd(p10, p11, p12) -- line: 29
    -- upvalues: Vector3 (copy)
    return Vector3.new(p10.x * p11 + p12.x, p10.y * p11 + p12.y, p10.z * p11 + p12.z)
end

function t1.inverse_length_squared(p13, p14) -- line: 32
    -- upvalues: v1 (copy)
    local v2 = v1.estimate(p13)

    for _ = 0, p14 - 1 do
        v2 = v2 * 0.5 * (-p13 * (v2 * v2) + 1) + v2
    end

    return v2
end

function t1.normalize(p15, p16) -- line: 39
    -- upvalues: t1 (copy)
    return t1.scale(p15, t1.inverse_length_squared(t1.dot(p15, p15), p16))
end

function t1.dot_xyz(p17, p18, p19, p20, p21, p22) -- line: 47
    return p17 * p20 + p18 * p21 + p19 * p22
end

function t1.cross_xyz(p23, p24, p25, p26, p27, p28) -- line: 50
    return -p25 * p27 + p24 * p28, -p23 * p28 + p25 * p26, -p24 * p26 + p23 * p27
end

function t1.madd_xyz(p29, p30, p31, p32, p33, p34, p35) -- line: 53
    return p29 * p32 + p33, p30 * p32 + p34, p31 * p32 + p35
end

function t1.normalize_xyz(p36, p37, p38, p39) -- line: 56
    local v3 = p36 * p36 + p37 * p37 + p38 * p38
    local v4 = 1 / math.sqrt(v3)

    for _ = 0, p39 - 1 do
        v4 = v4 * 0.5 * (-v3 * (v4 * v4) + 1) + v4
    end

    return p36 * v4, p37 * v4, p38 * v4
end

function t1.cross_into(p40, p41, p42) -- line: 64
    local v5 = -p41.z * p42.y + p41.y * p42.z
    local v6 = -p41.x * p42.z + p41.z * p42.x
    local v7 = -p41.y * p42.x + p41.x * p42.y

    p40.x = v5
    p40.y = v6
    p40.z = v7

    return p40
end

function t1.scale_into(p43, p44, p45) -- line: 69
    local v8 = p44.x * p45
    local v9 = p44.y * p45
    local v10 = p44.z * p45

    p43.x = v8
    p43.y = v9
    p43.z = v10

    return p43
end

function t1.neg_into(p46, p47) -- line: 74
    local v11 = -p47.x
    local v12 = -p47.y
    local v13 = -p47.z

    p46.x = v11
    p46.y = v12
    p46.z = v13

    return p46
end

function t1.sub_into(p48, p49, p50) -- line: 79
    local v14 = p49.x - p50.x
    local v15 = p49.y - p50.y
    local v16 = p49.z - p50.z

    p48.x = v14
    p48.y = v15
    p48.z = v16

    return p48
end

function t1.madd_into(p51, p52, p53, p54) -- line: 84
    local v17 = p52.x * p53 + p54.x
    local v18 = p52.y * p53 + p54.y
    local v19 = p52.z * p53 + p54.z

    p51.x = v17
    p51.y = v18
    p51.z = v19

    return p51
end

function t1.normalize_into(p55, p56, p57) -- line: 89
    local x, y, z = p56.x, p56.y, p56.z
    local v20 = x * x + y * y + z * z
    local v21 = 1 / math.sqrt(v20)

    for _ = 0, p57 - 1 do
        v21 = v21 * 0.5 * (-v20 * (v21 * v21) + 1) + v21
    end

    local v22 = x * v21
    local v23 = y * v21
    local v24 = z * v21

    p55.x = v22
    p55.y = v23
    p55.z = v24

    return p55
end

return t1
