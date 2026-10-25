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

local import = require(sim.import)
local v9 = import("skate_core/physics/reciprocal_sqrt")
local v10 = import("skate_core/point_graph")
local v11 = import("skate_core/trigonometry")
local v12 = import("skate_core/riding/vector")
local estimate = v9.estimate
local PointGraph = v10.PointGraph
local acos = v11.acos
local t1 = {
    HeadingSettings = {},
    HeadingInput = {}
}

function t1.calculate(p3, p4, p5) -- line: 90
    -- upvalues: v1 (copy), PointGraph (copy), acos (copy), t1 (copy)
    if p4.balance ~= 0 and p4.manual_turn ~= 0 then
        local flags_2472 = p4.flags_2472
        local v13 = if bit32.band(flags_2472, 134217728) == 0 then bit32.band(p4.flags_2472, 67108864) ~= 0 and p4.balance > 0 else p4.balance < 0 or bit32.band(p4.flags_2472, 67108864) ~= 0 and p4.balance > 0
        local v14 = if v13 then p4.manual_turn * p3.manual_wrong_wheel_scalar else p4.manual_turn
        local v15 = PointGraph.evaluate(p3.manual_response, p4.manual_curve_input) * 0.01745329238474369
        local v16 = (1 - p3.manual_damping) * p5 + v15 * p3.manual_damping
        local v17 = p4.timestep * v16 * v14
        local normal = p4.normal

        return {
            normal[1] * v17,
            normal[2] * v17,
            normal[3] * v17,
            normal[4] * v17
        }, v16
    end

    local transform = p4.transform
    local v18 = transform[1]
    local v19 = transform[2]
    local v20 = transform[3]
    local v21 = v18[1]
    local v22 = v20[1]
    local v23 = v18[2]
    local v24 = v19[2]
    local v25 = v20[2]
    local v26 = v18[3]
    local v27 = v20[3]
    local v29 = acos((t1.clamp(v24, -1, 1))) * 0.6366197466850281

    if v29 > 1.2 then
        v29 = 0
    end

    local v30 = v26 * 0 + (v23 * -1 + v21 * 0)
    local v31 = v27 * 0 + (v25 * -1 + v22 * 0)
    local v32 = v30 * v30 + 0 + v31 * v31
    local v33

    if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
        local v34 = math.abs(v32) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

        if v32 < 0 then
            v33 = -v33
        end
    else
        buffer.writef32(v1, 0, v32)
        v33 = buffer.readf32(v1, 0)
    end

    local v37 = 1 / math.sqrt(v33)
    local v38 = -v33 * (v37 * v37) + 1
    local v39 = v37 * 0.5 * v38 + v37
    local v40 = -v33 * (v39 * v39) + 1
    local v41 = v39 * 0.5 * v40 + v39
    local v42 = if v33 == 0 then 0 else v33 * v41
    local v43 = PointGraph.evaluate(p3.inclination_response, v29)
    local normal_threshold = p3.normal_threshold
    local v44 = (if normal_threshold[1] < v42 then v30 * v41 else 0) * v43
    local v45 = (if normal_threshold[3] < v42 then v31 * v41 else 0) * v43
    local velocity = p4.velocity
    local v46 = velocity[1]
    local v47 = velocity[2]
    local v48 = velocity[3]
    local v49 = v26 * v48 + (v23 * v47 + v21 * v46)
    local v50 = v27 * v48 + (v25 * v47 + v22 * v46)
    local v51 = -v49 * v45 + v50 * v44
    local v52 = t1.clamp(math.abs(p4.signed_speed), 0, p3.speed_max)
    local v53 = v51 * p3.heading_strength * PointGraph.evaluate(p3.speed_response, v52 / p3.speed_max)
    local normal, angular_velocity = p4.normal, p4.angular_velocity
    local v54 = (angular_velocity[1] * normal[1] + angular_velocity[2] * normal[2] + angular_velocity[3] * normal[3]) * -p4.turn_2712

    if not (v54 >= 0) then
        v54 = 0
    end

    local v55 = PointGraph.evaluate(p3.angular_response, v54) * p4.scalar_2740 * p3.turn_strength * p4.turn_2712

    if not (v53 * v55 < 0 or math.abs(v55) > math.abs(v53)) then
        v55 = v53
    end

    return {
        normal[1] * v55,
        normal[2] * v55,
        normal[3] * v55,
        normal[4] * v55
    }, 0
end

function t1.calculate_reference(p6, p7, p8) -- line: 167
    -- upvalues: rt (copy), v1 (copy), estimate (copy), PointGraph (copy), acos (copy), t1 (copy)
    if p7.balance ~= 0 and p7.manual_turn ~= 0 then
        local flags_2472 = p7.flags_2472
        local v56 = if bit32.band(flags_2472, 134217728) == 0 then bit32.band(p7.flags_2472, 67108864) ~= 0 and p7.balance > 0 else p7.balance < 0 or bit32.band(p7.flags_2472, 67108864) ~= 0 and p7.balance > 0
        local v57 = if v56 then p7.manual_turn * p6.manual_wrong_wheel_scalar else p7.manual_turn
        local v58 = PointGraph.evaluate(p6.manual_response, p7.manual_curve_input) * 0.01745329238474369
        local v59 = (1 - p6.manual_damping) * p8 + v58 * p6.manual_damping
        local v60 = p7.timestep * v59 * v57

        return {
            p7.normal[1] * v60,
            p7.normal[2] * v60,
            p7.normal[3] * v60,
            p7.normal[4] * v60
        }, v59
    end

    local v61 = rt.copy(p7.transform)
    local t2 = {
        {
            v61[1][1],
            v61[2][1],
            v61[3][1],
            0
        },
        {
            v61[1][2],
            v61[2][2],
            v61[3][2],
            0
        },
        {
            v61[1][3],
            v61[2][3],
            v61[3][3],
            0
        }
    }
    local v63 = acos((t1.clamp(t2[2][2], -1, 1))) * 0.6366197466850281

    if v63 > 1.2 then
        v63 = 0
    end

    local v64 = rt.from_fn(4, function(p9) -- line: 201
        -- upvalues: t2 (copy)
        local v65 = t2[1][p9 + 1] * 0
        local v66 = t2[2][p9 + 1] * -1 + v65

        return t2[3][p9 + 1] * 0 + v66
    end)

    v64[2] = 0

    local v67 = t1.dot3(v64, v64)
    local v68

    if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
        local v69 = math.abs(v67) * 7.1362384635298E+44
        local v70 = math.floor(v69)
        local v71 = v69 - v70

        v68 = (if v71 > 0.5 or v71 == 0.5 and v70 % 2 == 1 then v70 + 1 else v70) * 1.401298464324817E-45

        if v67 < 0 then
            v68 = -v68
        end
    else
        buffer.writef32(v1, 0, v67)
        v68 = buffer.readf32(v1, 0)
    end

    local v72 = estimate(v68)
    local v73 = -v68 * (v72 * v72) + 1
    local v74 = v72 * 0.5 * v73 + v72
    local v75 = -v68 * (v74 * v74) + 1
    local v76 = v74 * 0.5 * v75 + v74
    local v77 = if v68 == 0 then 0 else v68 * v76
    local v78 = PointGraph.evaluate(p6.inclination_response, v63)

    for i = 0, 3 do
        local v79 = if p6.normal_threshold[i + 1] < v77 then v64[i + 1] * v76 else 0

        v64[i + 1] = v79 * v78
    end

    local v80 = rt.from_fn(4, function(p10) -- line: 229
        -- upvalues: p7 (copy), t2 (copy)
        local v81 = t2[1][p10 + 1] * p7.velocity[1]
        local v82 = t2[2][p10 + 1] * p7.velocity[2] + v81

        return t2[3][p10 + 1] * p7.velocity[3] + v82
    end)

    v80[2] = 0

    local v83 = -v80[1] * v64[3] + v80[3] * v64[1]
    local v84 = t1.clamp(math.abs(p7.signed_speed), 0, p6.speed_max)
    local v85 = v83 * p6.heading_strength * PointGraph.evaluate(p6.speed_response, v84 / p6.speed_max)
    local v86 = t1.dot3(p7.angular_velocity, p7.normal) * -p7.turn_2712

    if not (v86 >= 0) then
        v86 = 0
    end

    local v87 = PointGraph.evaluate(p6.angular_response, v86) * p7.scalar_2740 * p6.turn_strength * p7.turn_2712

    if not (v85 * v87 < 0 or math.abs(v87) > math.abs(v85)) then
        v87 = v85
    end

    return {
        p7.normal[1] * v87,
        p7.normal[2] * v87,
        p7.normal[3] * v87,
        p7.normal[4] * v87
    }, 0
end

function t1.clamp(p11, p12, p13) -- line: 261
    local v88 = if p12 - p11 >= 0 then p12 else p11

    if p13 - v88 >= 0 then
        return v88
    end

    return p13
end

function t1.dot3(p14, p15) -- line: 275
    -- upvalues: v12 (copy)
    return v12.dot3(p14, p15)
end

return t1
