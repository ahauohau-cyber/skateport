-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/angle_tracker")
local v2 = import("skate_core/camera/manager_incline")
local v3 = import("skate_core/input/angle")
local v4 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {
    CameraFrame = {}
}

function t1.CameraFrame.new() -- line: 24
    -- upvalues: rt (copy)
    local t2 = {
        columns = {
            { 1, 0, 0 },
            { 0, 1, 0 },
            { 0, 0, 1 }
        }
    }

    return {
        discontinuity = false,
        field_of_view_degrees = 0,
        opacity = 1,
        blur = 1,
        basis = t2,
        position = { 0, 0, 0, 0 },
        previous_basis = rt.copy(t2),
        previous_position = { 0, 0, 0, 0 },
        linear_velocity = { 0, 0, 0, 0 },
        angular_velocity = { 0, 0, 0, 0 },
        shake_translation = { 0, 0, 0, 0 }
    }
end

function t1.CameraFrame.motion_reference(p1, p2, p3, p4) -- line: 41
    -- upvalues: v1 (copy), t1 (copy)
    local v5 = if p2 == 0 then 1 else 1 / p2
    local t3 = {}

    t3[1] = (p4[1] - p1.position[1]) * v5
    t3[2] = (p4[2] - p1.position[2]) * v5
    t3[3] = (p4[3] - p1.position[3]) * v5
    t3[4] = (p4[4] - p1.position[4]) * v5
    p1.linear_velocity = t3

    local v6 = t1.angles(p1.basis)
    local v7 = t1.angles(p3)
    local t4 = {}

    for i = 0, 3 do
        if i == 3 then
            t4[i + 1] = 0
        else
            t4[i + 1] = v1.normalize_angle(v7[i + 1] - v6[i + 1]) * v5
        end
    end

    p1.angular_velocity = t4
end

function t1.lens_field_of_view(p5, p6) -- line: 61
    -- upvalues: v3 (copy), t1 (copy)
    local v8 = v3.atan(35 / (p5 * 2)) * 114.59156036376953

    return t1.square_root(v8 * v8 / (p6 + 1))
end

function t1.angles(p7) -- line: 67
    -- upvalues: v2 (copy), t1 (copy)
    local v9 = p7.columns[1]
    local v10 = p7.columns[2]
    local v11 = p7.columns[3]
    local v12 = t1.square_root(v9[1] * v9[1] + v9[2] * v9[2])
    local v13 = v2.atan_ratio(-v9[3], v12)

    if v12 > 0.0010000000474974513 then
        return {
            v2.atan_ratio(v10[3], v11[3]),
            v13,
            v2.atan_ratio(v9[2], v9[1])
        }
    end

    return {
        v2.atan_ratio(-v11[2], v10[2]),
        v13,
        0
    }
end

function t1.square_root(p8) -- line: 82
    -- upvalues: v4 (copy)
    local v14 = v4.estimate(p8)
    local v15 = v14 * 0.5 * (-p8 * (v14 * v14) + 1) + v14
    local v16 = v15 * 0.5 * (-p8 * (v15 * v15) + 1) + v15

    if p8 == 0 then
        return 0
    end

    return p8 * v16
end

local PERF = import("skate_core/camera/tracker").PERF
local atan_ratio = v2.atan_ratio
local normalize_angle = v1.normalize_angle

local function angles_lanes(p9) -- line: 102
    -- upvalues: t1 (copy), atan_ratio (copy)
    local columns = p9.columns
    local v17 = columns[1]
    local v18 = columns[2]
    local v19 = columns[3]
    local v20 = t1.square_root(v17[1] * v17[1] + v17[2] * v17[2])
    local v21 = atan_ratio(-v17[3], v20)

    if v20 > 0.0010000000474974513 then
        return atan_ratio(v18[3], v19[3]), v21, atan_ratio(v17[2], v17[1])
    end

    return atan_ratio(-v19[2], v18[2]), v21, 0
end

t1.angles_lanes = angles_lanes

function t1.CameraFrame.motion(p10, p11, p12, p13) -- line: 115
    -- upvalues: t1 (copy), PERF (copy), normalize_angle (copy), angles_lanes (copy)
    if PERF.reference then
        return t1.CameraFrame.motion_reference(p10, p11, p12, p13)
    end

    local v22 = if p11 == 0 then 1 else 1 / p11
    local position, linear_velocity = p10.position, p10.linear_velocity
    local v23 = (p13[1] - position[1]) * v22
    local v24 = (p13[2] - position[2]) * v22
    local v25 = (p13[3] - position[3]) * v22
    local v26 = (p13[4] - position[4]) * v22

    linear_velocity[1] = v23
    linear_velocity[2] = v24
    linear_velocity[3] = v25
    linear_velocity[4] = v26

    local v27, v28, v29 = angles_lanes(p10.basis)
    local v30, v31, v32 = angles_lanes(p12)
    local v33 = normalize_angle(v30 - v27) * v22
    local v34 = normalize_angle(v31 - v28) * v22
    local v35 = normalize_angle(v32 - v29) * v22
    local angular_velocity = p10.angular_velocity

    angular_velocity[1] = v33
    angular_velocity[2] = v34
    angular_velocity[3] = v35
    angular_velocity[4] = 0
end

return t1
