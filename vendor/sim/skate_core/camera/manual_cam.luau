-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local GameplayActions = require(sim.import)("skate_core/input/gameplay_map").GameplayActions
local t1 = {
    ManualCamSettings = {}
}

function t1.ManualCamSettings.default() -- line: 25
    return {
        deadzone = 0.01,
        move_speed = 8,
        look_speed = 1.75,
        vertical_speed = 6,
        fast_multiplier = 3
    }
end

t1.ManualCamMatrix = {}
t1.ManualCam = {}

function t1.ManualCam.default() -- line: 41
    return {
        active = false,
        speed_multiplier = 1,
        matrix = {
            right = { 1, 0, 0 },
            up = { 0, 1, 0 },
            at = { 0, 0, 1 },
            position = { 0, 0, 0 }
        }
    }
end

function t1.ManualCam.manual_cam_active(p1) -- line: 55
    return p1.active
end

function t1.ManualCam.set_manual_cam_mode(p2, p3, p4) -- line: 61
    -- upvalues: t1 (copy)
    if p3 then
        if not p2.active and p4 ~= nil then
            p2.matrix = t1.matrix_from_frame(p4)
            p2.speed_multiplier = 1
            p2.active = true
        end
    elseif p2.active then
        p2.active = false
    end
end

function t1.ManualCam.get_matrix(p5, p6) -- line: 77
    -- upvalues: rt (copy), t1 (copy)
    if p5.active then
        return t1.ManualCam.to_camera_frame(p5, p6)
    end

    return rt.copy(p6)
end

function t1.ManualCam.spawn_matrix(p7) -- line: 85
    local matrix = p7.matrix

    return {
        {
            matrix.right[1],
            matrix.right[2],
            matrix.right[3],
            0
        },
        {
            matrix.up[1],
            matrix.up[2],
            matrix.up[3],
            0
        },
        {
            matrix.at[1],
            matrix.at[2],
            matrix.at[3],
            0
        },
        {
            matrix.position[1],
            matrix.position[2],
            matrix.position[3],
            1
        }
    }
end

function t1.ManualCam.to_camera_frame(p8, p9) -- line: 95
    -- upvalues: rt (copy)
    return {
        discontinuity = false,
        basis = {
            columns = {
                rt.copy(p8.matrix.right),
                rt.copy(p8.matrix.up),
                (rt.copy(p8.matrix.at))
            }
        },
        position = {
            p8.matrix.position[1],
            p8.matrix.position[2],
            p8.matrix.position[3],
            0
        },
        previous_basis = rt.copy(p9.previous_basis),
        previous_position = rt.copy(p9.previous_position),
        linear_velocity = { 0, 0, 0, 0 },
        angular_velocity = { 0, 0, 0, 0 },
        shake_translation = { 0, 0, 0, 0 },
        field_of_view_degrees = p9.field_of_view_degrees,
        opacity = p9.opacity,
        blur = p9.blur
    }
end

function t1.ManualCam.update_manual_cam(p10, p11, p12, p13) -- line: 118
    -- upvalues: rt (copy), GameplayActions (copy), t1 (copy)
    local v1, v2, v3, v4

    if not p10.active or p13 <= 0 then
        return
    else
        v1 = GameplayActions.values(p11)
        v2 = t1.cubic(v1[1], p12.deadzone)
        v3 = t1.cubic(v1[2], p12.deadzone)
        v4 = v1[3] > 0.5
    end

    local v6 = t1.cubic(-v1[4], p12.deadzone)
    local v7 = t1.cubic(-v1[5], p12.deadzone)
    local v8 = v1[8] - v1[7]
    local v9 = if v4 then p12.fast_multiplier else 1

    p10.speed_multiplier = t1.smooth_speed(p10.speed_multiplier, v9, p13)

    local v10 = p12.move_speed * p10.speed_multiplier * p13
    local v11 = rt.copy(p10.matrix.right)
    local v12 = rt.copy(p10.matrix.at)
    local v13 = rt.copy(p10.matrix.position)

    if math.abs(v3) > 0 then
        v13 = t1.add(v13, t1.scale(v12, v3 * v10))
    end

    if math.abs(v2) > 0 then
        local v14 = t1.normalize(t1.cross(v12, { 0, 1, 0 }))

        v13 = t1.add(v13, t1.scale(v14, v2 * v10))
    end

    if math.abs(v8) > 0 then
        v13[2] += v8 * p12.vertical_speed * p13
    end

    local v15 = p12.look_speed * p13

    if math.abs(v6) > 0 then
        local v16 = t1.rotate_axis({ 0, 1, 0 }, v6 * v15)

        v11 = t1.mul_mat_vec(v16, v11)
        v12 = t1.mul_mat_vec(v16, v12)
    end

    if math.abs(v7) > 0 then
        local v17 = t1.rotate_axis(v11, v7 * v15)

        v12 = t1.mul_mat_vec(v17, v12)
    end

    local v18 = t1.normalize(v12)
    local v19 = t1.normalize(t1.cross({ 0, 1, 0 }, v18))

    if t1.length(v19) < 1E-04 then
        v19 = t1.normalize(p10.matrix.right)
    end

    local v20 = t1.normalize(t1.cross(v18, v19))

    p10.matrix = {
        right = t1.normalize(t1.cross(v20, v18)),
        up = v20,
        at = v18,
        position = v13
    }
end

function t1.matrix_from_frame(p14) -- line: 171
    -- upvalues: rt (copy)
    local v21 = p14.basis.columns[1]
    local v22 = p14.basis.columns[2]
    local v23 = p14.basis.columns[3]

    return {
        right = rt.copy(v21),
        up = rt.copy(v22),
        at = rt.copy(v23),
        position = {
            p14.position[1],
            p14.position[2],
            p14.position[3]
        }
    }
end

function t1.cubic(p15, p16) -- line: 181
    local v24 = p15 * p15 * p15

    if p16 < math.abs(v24) then
        return v24
    end

    return 0
end

function t1.smooth_speed(p17, p18, p19) -- line: 186
    -- upvalues: rt (copy)
    local v25 = rt.clamp(p19 * 0.1 * 60, 0, 1)

    return p17 + (p18 - p17) * v25
end

function t1.add(p20, p21) -- line: 192
    return {
        p20[1] + p21[1],
        p20[2] + p21[2],
        p20[3] + p21[3]
    }
end

function t1.scale(p22, p23) -- line: 196
    return {
        p22[1] * p23,
        p22[2] * p23,
        p22[3] * p23
    }
end

function t1.dot(p24, p25) -- line: 200
    return p24[1] * p25[1] + p24[2] * p25[2] + p24[3] * p25[3]
end

function t1.cross(p26, p27) -- line: 204
    return {
        p26[2] * p27[3] - p26[3] * p27[2],
        p26[3] * p27[1] - p26[1] * p27[3],
        p26[1] * p27[2] - p26[2] * p27[1]
    }
end

function t1.length(p28) -- line: 212
    -- upvalues: t1 (copy)
    return (math.sqrt((t1.dot(p28, p28))))
end

function t1.normalize(p29) -- line: 216
    -- upvalues: rt (copy), t1 (copy)
    local v27 = t1.length(p29)

    if v27 > 1E-06 then
        return t1.scale(p29, 1 / v27)
    end

    return rt.copy(p29)
end

function t1.rotate_axis(p30, p31) -- line: 225
    -- upvalues: t1 (copy)
    local v28 = t1.normalize(p30)
    local v29 = v28[1]
    local v30 = v28[2]
    local v31 = v28[3]
    local v32 = math.sin(p31)
    local v33 = math.cos(p31)
    local v34 = 1 - v33

    return {
        {
            v34 * v29 * v29 + v33,
            v34 * v29 * v30 - v32 * v31,
            v34 * v29 * v31 + v32 * v30
        },
        {
            v34 * v29 * v30 + v32 * v31,
            v34 * v30 * v30 + v33,
            v34 * v30 * v31 - v32 * v29
        },
        {
            v34 * v29 * v31 - v32 * v30,
            v34 * v30 * v31 + v32 * v29,
            v34 * v31 * v31 + v33
        }
    }
end

function t1.mul_mat_vec(p32, p33) -- line: 237
    return {
        p32[1][1] * p33[1] + p32[1][2] * p33[2] + p32[1][3] * p33[3],
        p32[2][1] * p33[1] + p32[2][2] * p33[2] + p32[2][3] * p33[3],
        p32[3][1] * p33[1] + p32[3][2] * p33[2] + p32[3][3] * p33[3]
    }
end

return t1
