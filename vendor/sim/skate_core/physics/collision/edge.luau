-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/collision/arithmetic")
local dot, cross, scale, neg = v1.dot, v1.cross, v1.scale, v1.neg
local sub, normalize = v1.sub, v1.normalize
local t1 = {}

function t1.edge_cos_test_reference(p1, p2, p3, p4, p5, p6) -- line: 19
    -- upvalues: dot (copy), cross (copy), scale (copy), neg (copy), sub (copy), normalize (copy)
    if dot(p3, cross(p1, p2)) < 0 then
        return true
    end

    if not (p5 or p6) then
        return false
    end

    return p4 <= dot(normalize(sub(p3, scale(p1, dot(p3, p1))), 2), if p5 then p2 else neg(p2))
end

function t1.edge_cos_test_xyz(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18) -- line: 40
    local v4 = -p9 * p11 + p8 * p12
    local v5 = -p7 * p12 + p9 * p10
    local v6 = -p8 * p10 + p7 * p11

    if p13 * v4 + p14 * v5 + p15 * v6 < 0 then
        return true
    end

    if not (p17 or p18) then
        return false
    end

    local v7 = p13 * p7 + p14 * p8 + p15 * p9
    local v8 = p13 - p7 * v7
    local v9 = p14 - p8 * v7
    local v10 = p15 - p9 * v7
    local v11 = v8 * v8 + v9 * v9 + v10 * v10
    local v12 = 1 / math.sqrt(v11)
    local v13 = v12 * 0.5 * (-v11 * (v12 * v12) + 1) + v12
    local v14 = v13 * 0.5 * (-v11 * (v13 * v13) + 1) + v13
    local v15 = v8 * v14
    local v16 = v9 * v14
    local v17 = v10 * v14

    if p17 then
        return p16 <= v15 * p10 + v16 * p11 + v17 * p12
    end

    return p16 <= v15 * -p10 + v16 * -p11 + v17 * -p12
end

local edge_cos_test_xyz = t1.edge_cos_test_xyz

function t1.edge_cos_test(p19, p20, p21, p22, p23, p24) -- line: 77
    -- upvalues: edge_cos_test_xyz (copy)
    return edge_cos_test_xyz(p19.x, p19.y, p19.z, p20.x, p20.y, p20.z, p21.x, p21.y, p21.z, p22, p23, p24)
end

return t1
