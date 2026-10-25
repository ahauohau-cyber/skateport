-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Vector3 = {}
}

function t1.Vector3.new(p1, p2, p3) -- line: 14
    return {
        x = p1,
        y = p2,
        z = p3
    }
end

t1.Vector3.ZERO = t1.Vector3.new(0, 0, 0)

function t1.Vector3.default() -- line: 20
    -- upvalues: rt (copy), t1 (copy)
    return rt.copy(t1.Vector3.ZERO)
end

function t1.Vector3.eq(p4, p5) -- line: 25
    if p4.x == p5.x and p4.y == p5.y then
        return p4.z == p5.z
    end

    return false
end

function t1.Vector3.set(p6, p7, p8, p9) -- line: 47
    p6.x = p7
    p6.y = p8
    p6.z = p9

    return p6
end

function t1.Vector3.copy_into(p10, p11) -- line: 51
    local x, y, z = p11.x, p11.y, p11.z

    p10.x = x
    p10.y = y
    p10.z = z

    return p10
end

function t1.Vector3.unpack(p12) -- line: 55
    return p12.x, p12.y, p12.z
end

function t1.Vector3.add_into(p13, p14, p15) -- line: 58
    local v1 = p14.x + p15.x
    local v2 = p14.y + p15.y
    local v3 = p14.z + p15.z

    p13.x = v1
    p13.y = v2
    p13.z = v3

    return p13
end

function t1.Vector3.sub_into(p16, p17, p18) -- line: 63
    local v4 = p17.x - p18.x
    local v5 = p17.y - p18.y
    local v6 = p17.z - p18.z

    p16.x = v4
    p16.y = v5
    p16.z = v6

    return p16
end

function t1.Vector3.scale_into(p19, p20, p21) -- line: 68
    local v7 = p20.x * p21
    local v8 = p20.y * p21
    local v9 = p20.z * p21

    p19.x = v7
    p19.y = v8
    p19.z = v9

    return p19
end

function t1.Vector3.neg_into(p22, p23) -- line: 73
    local v10 = -p23.x
    local v11 = -p23.y
    local v12 = -p23.z

    p22.x = v10
    p22.y = v11
    p22.z = v12

    return p22
end

function t1.Vector3.madd_into(p24, p25, p26, p27) -- line: 78
    local v13 = p25.x * p26 + p27.x
    local v14 = p25.y * p26 + p27.y
    local v15 = p25.z * p26 + p27.z

    p24.x = v13
    p24.y = v14
    p24.z = v15

    return p24
end

function t1.Vector3.cross_into(p28, p29, p30) -- line: 83
    local v16 = -p29.z * p30.y + p29.y * p30.z
    local v17 = -p29.x * p30.z + p29.z * p30.x
    local v18 = -p29.y * p30.x + p29.x * p30.y

    p28.x = v16
    p28.y = v17
    p28.z = v18

    return p28
end

function t1.Vector3.dot(p31, p32) -- line: 88
    return p31.x * p32.x + p31.y * p32.y + p31.z * p32.z
end

function t1.Vector3.dot_xyz(p33, p34, p35, p36, p37, p38) -- line: 91
    return p33 * p36 + p34 * p37 + p35 * p38
end

function t1.Vector3.cross_xyz(p39, p40, p41, p42, p43, p44) -- line: 94
    return -p41 * p43 + p40 * p44, -p39 * p44 + p41 * p42, -p40 * p42 + p39 * p43
end

function t1.Vector3.madd_xyz(p45, p46, p47, p48, p49, p50, p51) -- line: 97
    return p45 * p48 + p49, p46 * p48 + p50, p47 * p48 + p51
end

t1.Basis3 = {}

function t1.Basis3.eq(p52, p53) -- line: 105
    for i = 0, 2 do
        if p52.columns[i + 1][1] ~= p53.columns[i + 1][1] or p52.columns[i + 1][2] ~= p53.columns[i + 1][2] or p52.columns[i + 1][3] ~= p53.columns[i + 1][3] then
            return false
        end
    end

    return true
end

return t1
