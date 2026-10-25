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
local v9 = import("skate_core/player/offboard/air_selector/math")
local Trajectory = import("skate_core/air/trajectory").Trajectory
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared

local function air_selector() -- line: 31
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector")
end

local dot, length, madd, reciprocal = v9.dot, v9.length, v9.madd, v9.reciprocal
local scale, sub, flatten, shift = v9.scale, v9.sub, v9.flatten, v9.shift
local adjust = v9.adjust
local t1 = {
    Selector = {}
}

function t1.Selector.adjust_animation(p3, p4, p5, p6, p7) -- line: 46
    -- upvalues: rt (copy), v1 (copy), import (copy), Trajectory (copy), inverse_length_squared (copy), dot (copy), length (copy), madd (copy), reciprocal (copy), scale (copy), sub (copy), flatten (copy), shift (copy), adjust (copy)
    local DT = import("skate_core/player/offboard/air_selector").DT

    p3.sampling.adjustment_8336 = scale(p6[3], p5[3])
    p3.correction_8304 = scale(madd(p6[2], p5[2] - p7, p3.sampling.adjustment_8336), -1)
    p3.correction_8304[2] -= 0.08

    local selection = p3.sampling.selection
    local v10 = sub(sub(selection.position_6176, p3.correction_8304), Trajectory.position_at(selection.trajectory_8144, selection.landing_frame_8480 * DT))

    shift(selection.trajectory_8144, p4 * DT)
    adjust(selection.trajectory_8144, rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(selection.landing_frame_8480), rt.to_u32(p4))), v10, 0.5)
    shift(selection.trajectory_8144, rt.to_i32(rt.wrapping_sub_u32(0, rt.to_u32(p4))) * DT)

    local v11 = rt.copy(selection.trajectory_8144)
    local v12 = Trajectory.position_at(v11, selection.landing_frame_8480 * DT)
    local v13 = false
    local v14 = false
    local v15 = false
    local v16 = false
    local v17 = false
    local v18 = false
    local v19 = false
    local v20 = false

    if p3.launch.up_48[2] < 0.8 then
        v13 = true
    else
        v20 = true
    end

    if v13 then
        if dot(p3.launch.up_48, flatten(v11.velocity)) <= 0 then
            v14 = true
        else
            v20 = true
        end
    end

    v13 = false

    if v14 then
        if selection.normal_6144[2] > 0.9 then
            v13 = true
        else
            v20 = true
        end
    end

    v14 = false

    if v13 then
        if v12[2] - v11.position[2] > -0.2 then
            v14 = true
        else
            v20 = true
        end
    end

    v13 = false

    local v21

    if v14 then
        v21 = 2 * length(sub(v11.position, v12)) * reciprocal(9.800000190734863)

        if v21 == 0 then
            v15 = true
        else
            v13 = true
        end
    end

    v14 = false

    if v13 then
        if v21 < 1E-44 then
            v14 = true
        else
            v16 = true
        end
    end

    v13 = false

    if v14 then
        if v21 > -1E-44 then
            v13 = true
        else
            v16 = true
        end
    end

    v14 = false

    if v13 then
        if v21 == 0 then
            v17 = true
        else
            v14 = true
        end
    end

    v13 = false

    if v14 then
        if v21 > -1.1754943508222875E-38 then
            v13 = true
        else
            v17 = true
        end
    end

    v14 = false

    if v13 then
        if v21 < 1.1754943508222875E-38 then
            v14 = true
        else
            v17 = true
        end
    end

    v13 = false

    local v22

    if v17 then
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readf32(v1, 0)
        v13 = true
    end

    v17 = false

    local v23, v24

    if v14 then
        local v25 = math.abs(v21) * 7.1362384635298E+44

        v23 = math.floor(v25)
        v24 = v25 - v23

        if v24 > 0.5 then
            v18 = true
        else
            v17 = true
        end
    end

    v14 = false

    local v26

    if v17 then
        if v24 == 0.5 then
            v14 = true
        else
            v26 = v23
            v19 = true
        end
    end

    if v14 then
        if v23 % 2 == 1 then
            v18 = true
        else
            v26 = v23
            v19 = true
        end
    end

    v14 = false

    if v18 then
        v26 = v23 + 1
        v19 = true
    end

    v18 = false

    local v27

    if v19 then
        v27 = v26 * 1.401298464324817E-45

        if v21 < 0 then
            v18 = true
        else
            v14 = true
        end
    end

    if v14 then
        v22 = v27
        v13 = true
    end

    if v18 then
        v22 = -v27
        v13 = true
    end

    if v13 then
        if v22 == 0 then
            v15 = true
        else
            v16 = true
        end
    end

    local v28

    if v16 then
        v28 = v21 * inverse_length_squared(v21, 2)
        v20 = false
    end

    if v15 then
        v28 = 0
        v20 = false
    end

    if not v20 then
        local v29 = v28 * 0.66 + selection.landing_frame_8480 * 0.0056666667

        if v29 > 0.2 then
            local t2 = {
                0, -9.800000190734863, 0, 0
            }

            selection.trajectory_8144.velocity = sub(scale(sub(v12, v11.position), reciprocal(v29)), scale(scale(t2, 0.5), v29))
            selection.trajectory_8144.acceleration = rt.copy(t2)
            selection.trajectory_8144.duration = -1
            selection.landing_frame_8480 = rt.f_to_i32(v29 * 59.999996)
            selection.scalar_8392 = selection.landing_frame_8480 * DT
        end
    end
end

return t1
