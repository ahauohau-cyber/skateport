-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {}

function t1.add(p1, p2) -- line: 14
    -- upvalues: Vector3 (copy)
    return Vector3.new(p1.x + p2.x, p1.y + p2.y, p1.z + p2.z)
end

function t1.sub(p3, p4) -- line: 19
    -- upvalues: Vector3 (copy)
    return Vector3.new(p3.x - p4.x, p3.y - p4.y, p3.z - p4.z)
end

function t1.scale(p5, p6) -- line: 24
    -- upvalues: Vector3 (copy)
    return Vector3.new(p5.x * p6, p5.y * p6, p5.z * p6)
end

function t1.madd(p7, p8, p9) -- line: 29
    -- upvalues: Vector3 (copy)
    return Vector3.new(p7.x * p8 + p9.x, p7.y * p8 + p9.y, p7.z * p8 + p9.z)
end

function t1.point(p10, p11) -- line: 34
    -- upvalues: t1 (copy)
    return t1.madd(p10.forward, p11.z, t1.madd(p10.up, p11.y, t1.madd(p10.right, p11.x, p10.position)))
end

function t1.bounds(p12, p13) -- line: 39
    -- upvalues: Vector3 (copy), t1 (copy)
    local v1 = t1.point(p12, t1.scale(t1.add(p13.max, p13.min), 0.5))
    local v2 = t1.scale(t1.sub(p13.max, p13.min), 0.5)

    local function abs(p14) -- line: 42
        -- upvalues: Vector3 (copy)
        return Vector3.new(math.abs(p14.x), math.abs(p14.y), (math.abs(p14.z)))
    end

    local madd = t1.madd
    local forward = p12.forward
    local v7 = Vector3.new(math.abs(forward.x), math.abs(forward.y), (math.abs(forward.z)))
    local z2 = v2.z
    local madd2 = t1.madd
    local up = p12.up
    local v10 = Vector3.new(math.abs(up.x), math.abs(up.y), (math.abs(up.z)))
    local y3 = v2.y
    local scale = t1.scale
    local right = p12.right
    local v13 = madd(v7, z2, madd2(v10, y3, scale(Vector3.new(math.abs(right.x), math.abs(right.y), (math.abs(right.z))), v2.x)))

    return {
        min = t1.sub(v1, v13),
        max = t1.add(v1, v13)
    }
end

function t1.overlaps(p15, p16) -- line: 53
    if p15.min.x <= p16.max.x and p15.max.x >= p16.min.x and p15.min.y <= p16.max.y and p15.max.y >= p16.min.y and p15.min.z <= p16.max.z then
        return p15.max.z >= p16.min.z
    end

    return false
end

function t1.matches(p17, p18) -- line: 63
    if p17 == -1 or p18 == -1 then
        return true
    end

    return p17 == p18
end

function t1.face(p19) -- line: 69
    -- upvalues: Vector3 (copy), t1 (copy)
    local v14 = p19[1]
    local v15 = p19[2]
    local v16 = p19[3]
    local v17 = t1.sub(v15, v14)
    local v18 = t1.sub(v16, v14)
    local v19 = Vector3.new(-v17.z * v18.y + v17.y * v18.z, -v17.x * v18.z + v17.z * v18.x, -v17.y * v18.x + v17.x * v18.y)
    local v20 = v19.z * v19.z + (v19.y * v19.y + v19.x * v19.x)
    local v21 = 1 / math.sqrt(v20)
    local v22 = v21 * 0.5 * (-v20 * (v21 * v21) + 1) + v21
    local v23 = v22 * 0.5 * (-v20 * (v22 * v22) + 1) + v22

    return t1.scale(v19, v23)
end

return t1
