-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {
    RetailForceAccumulator = {}
}

function t1.accumulate_point_force(p1, p2, p3, p4, p5, p6) -- line: 27
    -- upvalues: rt (copy)
    local v1 = rt.copy(p1)
    local x, y, z = p2.x, p2.y, p2.z
    local x2, y2, z2 = p3.x, p3.y, p3.z
    local force_acceleration = v1.force_acceleration

    force_acceleration.x += x * p5
    force_acceleration.y += y * p5
    force_acceleration.z += z * p5

    local columns = p4.columns
    local v2 = columns[1]
    local v3 = columns[2]
    local v4 = columns[3]
    local v5 = v4[1] * z2 + (v3[1] * y2 + v2[1] * x2)
    local v6 = v4[2] * z2 + (v3[2] * y2 + v2[2] * x2)
    local v7 = v4[3] * z2 + (v3[3] * y2 + v2[3] * x2)
    local v8 = -v7 * y + v6 * z
    local v9 = -v5 * z + v7 * x
    local v10 = -v6 * x + v5 * y
    local columns2 = p6.columns
    local v11 = columns2[1]
    local v12 = columns2[2]
    local v13 = columns2[3]
    local torque_acceleration = v1.torque_acceleration

    torque_acceleration.x += v13[1] * v10 + (v12[1] * v9 + v11[1] * v8)
    torque_acceleration.y += v13[2] * v10 + (v12[2] * v9 + v11[2] * v8)
    torque_acceleration.z += v13[3] * v10 + (v12[3] * v9 + v11[3] * v8)
    v1.cool_down = 0

    return v1
end

function t1.accumulate_point_force_reference(p7, p8, p9, p10, p11, p12) -- line: 71
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v14 = rt.copy(p7)

    v14.force_acceleration.x += p8.x * p11
    v14.force_acceleration.y += p8.y * p11
    v14.force_acceleration.z += p8.z * p11

    local v15 = t1.multiply_basis(p10, p9)
    local v16 = Vector3.new(-v15.z * p8.y + v15.y * p8.z, -v15.x * p8.z + v15.z * p8.x, -v15.y * p8.x + v15.x * p8.y)
    local v17 = t1.multiply_basis(p12, v16)

    v14.torque_acceleration.x += v17.x
    v14.torque_acceleration.y += v17.y
    v14.torque_acceleration.z += v17.z
    v14.cool_down = 0

    return v14
end

function t1.multiply_basis(p13, p14) -- line: 101
    -- upvalues: Vector3 (copy)
    local columns = p13.columns
    local v18 = columns[1]
    local v19 = columns[2]
    local v20 = columns[3]
    local x, y, z = p14.x, p14.y, p14.z

    return Vector3.new(v20[1] * z + (v19[1] * y + v18[1] * x), v20[2] * z + (v19[2] * y + v18[2] * x), v20[3] * z + (v19[3] * y + v18[3] * x))
end

function t1.multiply_basis_reference(p15, p16) -- line: 115
    -- upvalues: Vector3 (copy)
    local function lane(p17) -- line: 117
        -- upvalues: p15 (copy), p16 (copy)
        return p15.columns[3][p17 + 1] * p16.z + (p15.columns[2][p17 + 1] * p16.y + p15.columns[1][p17 + 1] * p16.x)
    end

    return Vector3.new(p15.columns[3][1] * p16.z + (p15.columns[2][1] * p16.y + p15.columns[1][1] * p16.x), p15.columns[3][2] * p16.z + (p15.columns[2][2] * p16.y + p15.columns[1][2] * p16.x), p15.columns[3][3] * p16.z + (p15.columns[2][3] * p16.y + p15.columns[1][3] * p16.x))
end

return t1
