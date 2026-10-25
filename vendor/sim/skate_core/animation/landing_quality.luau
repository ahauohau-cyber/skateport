-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v1 = import("skate_core/physics/native_arithmetic")
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {},
    Input = {},
    Output = {}
}

function t1.Output.default() -- line: 36
    return {
        landing_adjust_80 = 0,
        sideways_speed_84 = 0,
        forward_speed_88 = 0,
        spin_92 = 0,
        landing_type_96 = 0,
        landing_data_167 = false
    }
end

function t1.Output.eq(p1, p2) -- line: 48
    if p1.landing_adjust_80 == p2.landing_adjust_80 and p1.sideways_speed_84 == p2.sideways_speed_84 and p1.forward_speed_88 == p2.forward_speed_88 and p1.spin_92 == p2.spin_92 and p1.landing_type_96 == p2.landing_type_96 then
        return p1.landing_data_167 == p2.landing_data_167
    end

    return false
end

local dot, scale, planar, cross, length, reciprocal, upper_one

function t1.Output.update(p3, p4, p5) -- line: 67
    -- upvalues: rt (copy), PointGraph (copy), dot (ref), scale (ref), planar (ref), cross (ref), length (ref), reciprocal (ref), upper_one (ref)
    local v2 = false
    local v3 = false
    local v4 = false
    local v5 = false
    local v6 = false
    local v7 = false
    local v8 = false

    if p4.previous_filtered_state == 1 then
        v8 = true
    else
        v2 = true
    end

    if v2 then
        if p4.filtered_state == 1 then
            v3 = true
        else
            v8 = true
        end
    end

    v2 = false

    local v9, v10, v11, v12, v13, v14

    if v3 then
        v9 = planar(p4.deck_velocity, p4.ground_normal)
        v10 = planar(p4.reckoning_forward, p4.ground_normal)
        v11 = length(v9)
        v12 = length(v10)
        v13 = math.abs((dot(v9, v10)))
        v14 = math.abs((dot(cross(v10, p4.ground_normal), p4.deck_velocity)))

        if v12 * v11 < 9.999999747378752E-06 then
            v4 = true
        else
            v2 = true
        end
    end

    v3 = false

    local v17, v18, v19, v20

    if v2 then
        v17 = scale(v9, reciprocal(v11))
        v18 = scale(v10, reciprocal(v12))
        v19 = cross(v18, v17)[2]

        if p4.flipped then
            v3 = true
        else
            v20 = v19
            v5 = true
        end
    end

    v2 = false

    if v3 then
        v20 = -v19
        v5 = true
    end

    v3 = false

    local v21, v22, v23, v24, v25, v26, v27

    if v5 then
        v21 = -p4.air_spin

        local v28 = (math.abs(v21) - 0.1) * 0.14492753

        v22 = PointGraph.evaluate(p5.twist_spin, upper_one(v28))

        local v29 = (v14 - 0.1) * 0.1010101

        v23 = PointGraph.evaluate(p5.side_speed, upper_one(v29))

        if v11 >= 2 then
            v3 = true
        else
            v26 = v13
            v25 = v14
            v27 = 0
            v24 = 0
            v8 = false
        end
    end

    v5 = false

    if v3 then
        if p4.flipped then
            v2 = true
        else
            v5 = true
        end
    end

    v3 = false

    local v30

    if v5 then
        v30 = v18
        v3 = true
    end

    v5 = false

    if v2 then
        v30 = scale(v18, -1)
        v3 = true
    end

    v2 = false

    if v3 then
        if dot(v30, v17) >= 0 then
            v5 = true
        else
            v2 = true
        end
    end

    v3 = false

    local v31

    if v2 then
        v31 = false
        v3 = true
    end

    v2 = false

    if v5 then
        v31 = true
        v3 = true
    end

    v5 = false

    if v3 then
        if math.abs(v21) <= 0.1 then
            v2 = true
        else
            v5 = true
        end
    end

    v3 = false

    local v32

    if v5 then
        v32 = v21 * v20

        if v31 then
            v3 = true
        else
            v6 = true
        end
    end

    v5 = false

    if v3 then
        if v32 <= 0 then
            v5 = true
        else
            v6 = true
        end
    end

    v3 = false

    if v6 then
        if v31 then
            v7 = true
        else
            v3 = true
        end
    end

    if v3 then
        if v32 > 0 then
            v5 = true
        else
            v7 = true
        end
    end

    v3 = false

    local v33

    if v7 then
        v33 = 1
        v3 = true
    end

    v7 = false

    if v5 then
        v33 = 2
        v3 = true
    end

    v5 = false

    if v3 then
        if v22 - v23 >= -0 then
            v5 = true
        else
            v7 = true
        end
    end

    v3 = false

    local v34, v35

    if v7 then
        v35 = v33
        v34 = v23
        v3 = true
    end

    v7 = false

    if v5 then
        v35 = v33
        v34 = v22
        v3 = true
    end

    v5 = false

    if v2 then
        v35 = 1
        v34 = v23
        v3 = true
    end

    if v3 then
        if v21 >= -0 then
            v7 = true
        else
            v5 = true
        end
    end

    v3 = false

    local v36

    if v5 then
        v36 = -v34
        v3 = true
    end

    v5 = false

    if v7 then
        v36 = v34
        v3 = true
    end

    v7 = false

    if v3 then
        if math.abs(v20) < 0.2 then
            v7 = true
        else
            v26 = v13
            v25 = v14
            v27 = v35
            v24 = v36
            v8 = false
        end
    end

    v3 = false

    if v7 then
        if v35 == 2 then
            v3 = true
        else
            v5 = true
        end
    end

    v7 = false

    if v3 then
        if math.abs(v36) > 0.3 then
            v26 = v13
            v25 = v14
            v27 = v35
            v24 = v36
            v8 = false
        else
            v5 = true
        end
    end

    v3 = false

    if v5 then
        if math.abs(v20) >= 0.05 then
            v7 = true
        else
            v3 = true
        end
    end

    v5 = false

    local v37

    if v3 then
        v37 = 0
        v5 = true
    end

    if v7 then
        v37 = 3
        v5 = true
    end

    if v5 then
        v26 = v13
        v25 = v14
        v27 = v37
        v24 = 0
        v8 = false
    end

    if v4 then
        v26 = 0
        v25 = 0
        v27 = 0
        v24 = 0
        v8 = false
    end

    if not v8 then
        rt.assign(p3, {
            landing_data_167 = true,
            landing_adjust_80 = v24,
            sideways_speed_84 = v25,
            forward_speed_88 = v26,
            spin_92 = v24,
            landing_type_96 = v27
        })
    end
end

function t1.dot(p6, p7) -- line: 141
    -- upvalues: v1 (copy)
    return v1.dot3(p6, p7)
end

dot = t1.dot

function t1.scale(p8, p9) -- line: 146
    return {
        p8[1] * p9,
        p8[2] * p9,
        p8[3] * p9,
        p8[4] * p9
    }
end

scale = t1.scale

function t1.planar(p10, p11) -- line: 151
    -- upvalues: dot (ref), scale (ref)
    local v38 = scale(p11, dot(p11, p10))

    return {
        p10[1] - v38[1],
        p10[2] - v38[2],
        p10[3] - v38[3],
        p10[4] - v38[4]
    }
end

planar = t1.planar

function t1.cross(p12, p13) -- line: 157
    return {
        -p12[3] * p13[2] + p12[2] * p13[3],
        -p12[1] * p13[3] + p12[3] * p13[1],
        -p12[2] * p13[1] + p12[1] * p13[2],
        0
    }
end

cross = t1.cross

function t1.length(p14) -- line: 167
    -- upvalues: inverse_length_squared (copy), dot (ref)
    local v39 = dot(p14, p14)
    local v40 = v39 * inverse_length_squared(v39, 2)

    if v39 == 0 then
        return 0
    end

    return v40
end

length = t1.length

function t1.reciprocal(p15) -- line: 178
    -- upvalues: v1 (copy)
    local v41 = v1.reciprocal_estimate(p15)
    local v42 = v41 * (-v41 * p15 + 1) + v41

    return v42 * (-v42 * p15 + 1) + v42
end

reciprocal = t1.reciprocal

function t1.upper_one(p16) -- line: 187
    if 1 - p16 >= -0 then
        return p16
    end

    return 1
end

upper_one = t1.upper_one

return t1
