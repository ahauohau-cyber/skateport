-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local Vector3 = import("skate_core/math").Vector3
local t1 = {
    QuaternionRows = {}
}

function t1.quaternion_rows(p1, p2) -- line: 23
    -- upvalues: Vector3 (copy)
    local v2 = p1.x * p2.x
    local v3 = p1.x * p2.y
    local v4 = p1.x * p2.z
    local v5 = p1.x * p2.w
    local v6 = p1.y * p2.x
    local v7 = p1.y * p2.y
    local v8 = p1.y * p2.z
    local v9 = p1.y * p2.w
    local v10 = p1.z * p2.x
    local v11 = p1.z * p2.y
    local v12 = p1.z * p2.z
    local v13 = p1.z * p2.w
    local v14 = p1.w * p2.x
    local v15 = p1.w * p2.y
    local v16 = p1.w * p2.z
    local v17 = p1.w * p2.w

    return {
        axes = {
            Vector3.new(v17 + v2 - v7 - v12, v6 + v3 + v16 + v13, v4 + v10 - v15 - v9),
            Vector3.new(v6 + v3 - v16 - v13, v17 + v7 - v12 - v2, v8 + v11 + v14 + v5),
            Vector3.new(v4 + v10 + v9 + v15, v11 + v8 - v14 - v5, v17 + v12 - v2 - v7)
        },
        relative = {
            x = v14 - v5 + v11 - v8,
            y = v15 - v9 + v4 - v10,
            z = v16 - v13 + v6 - v3,
            w = v17 + v12 + v7 + v2
        }
    }
end

function t1.compose(p3, p4) -- line: 56
    -- upvalues: Vector3 (copy), t1 (copy)
    local v18 = t1.cross(Vector3.new(p3.x, p3.y, p3.z), Vector3.new(p4.x, p4.y, p4.z))

    return {
        x = p3.x * p4.w + (p4.x * p3.w + v18.x),
        y = p3.y * p4.w + (p4.y * p3.w + v18.y),
        z = p3.z * p4.w + (p4.z * p3.w + v18.z),
        w = p3.w * p4.w - (p3.x * p4.x + p3.y * p4.y + p3.z * p4.z)
    }
end

function t1.basis(p5) -- line: 70
    local v19 = p5.x * 1.4142135381698608
    local v20 = p5.y * 1.4142135381698608
    local v21 = p5.z * 1.4142135381698608
    local v22 = p5.w * 1.4142135381698608
    local v23 = -v19 * v19 + 0.5
    local v24 = -v20 * v20 + 0.5
    local v25 = -v21 * v21 + 0.5
    local v26 = v19 * v20
    local v27 = v20 * v21
    local v28 = v21 * v19
    local v29 = v22 * v21
    local v30 = v22 * v19
    local v31 = v22 * v20

    return {
        columns = {
            {
                v24 + v25,
                v26 + v29,
                v28 - v31
            },
            {
                v26 - v29,
                v25 + v23,
                v27 + v30
            },
            {
                v28 + v31,
                v27 - v30,
                v23 + v24
            }
        }
    }
end

function t1.transform_direction(p6, p7) -- line: 94
    -- upvalues: Vector3 (copy)
    local columns = p6.columns

    return Vector3.new(columns[3][1] * p7.z + (columns[2][1] * p7.y + columns[1][1] * p7.x), columns[3][2] * p7.z + (columns[2][2] * p7.y + columns[1][2] * p7.x), columns[3][3] * p7.z + (columns[2][3] * p7.y + columns[1][3] * p7.x))
end

function t1.cross(p8, p9) -- line: 103
    -- upvalues: Vector3 (copy)
    return Vector3.new(-p8.z * p9.y + p8.y * p9.z, -p8.x * p9.z + p8.z * p9.x, -p8.y * p9.x + p8.x * p9.y)
end

function t1.point_rate(p10, p11, p12) -- line: 112
    -- upvalues: Vector3 (copy)
    return Vector3.new(p12.z * p11.y + (-p12.y * p11.z + p10.x), p12.x * p11.z + (-p12.z * p11.x + p10.y), p12.y * p11.x + (-p12.x * p11.y + p10.z))
end

function t1.multiply_add(p13, p14, p15) -- line: 120
    -- upvalues: Vector3 (copy)
    return Vector3.new(p13.x * p14 + p15.x, p13.y * p14 + p15.y, p13.z * p14 + p15.z)
end

function t1.reciprocal(p16) -- line: 124
    -- upvalues: v1 (copy)
    local v32 = v1.reciprocal_estimate(p16)
    local v33 = v32 * (-v32 * p16 + 1) + v32

    return v33 * (-v33 * p16 + 1) + v33
end

function t1.reciprocal_sqrt(p17) -- line: 133
    -- upvalues: v1 (copy)
    local v34 = v1.reciprocal_square_root_estimate(p17)
    local v35 = v34 * v34
    local v36 = v34 * 0.5 * (-p17 * v35 + 1) + v34
    local v37 = v36 * v36

    return v36 * 0.5 * (-p17 * v37 + 1) + v36
end

function t1.multiply_inertia(p18, p19) -- line: 145
    -- upvalues: Vector3 (copy), t1 (copy)
    return t1.inertia_tail(p18, p19, Vector3.new(p18.full.x * p19.x, p18.full.y * p19.x, p18.full.z * p19.x))
end

function t1.multiply_inertia_from_zero(p20, p21) -- line: 150
    -- upvalues: Vector3 (copy), t1 (copy)
    return t1.inertia_tail(p20, p21, Vector3.new(p20.full.x * p21.x + 0, p20.full.y * p21.x + 0, p20.full.z * p21.x + 0))
end

function t1.inertia_tail(p22, p23, p24) -- line: 158
    -- upvalues: Vector3 (copy)
    return Vector3.new(p22.full.z * p23.z + (p22.full.y * p23.y + p24.x), p22.split.z * p23.z + (p22.split.y * p23.y + p24.y), p22.split.x * p23.z + (p22.split.z * p23.y + p24.z))
end

return t1
