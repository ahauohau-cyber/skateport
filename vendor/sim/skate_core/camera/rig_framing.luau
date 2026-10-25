-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/rig_tracking")
local v2 = import("skate_core/camera/direction")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/physics/reciprocal_sqrt")
local AngularRigTracking = v1.AngularRigTracking
local direction_to_angles = v2.direction_to_angles
local t1 = {
    RigFraming = {}
}

function t1.RigFraming.update_reference(p1, p2, p3, p4, p5, p6) -- line: 25
    -- upvalues: rt (copy), v3 (copy), v4 (copy), AngularRigTracking (copy), direction_to_angles (copy)
    if bit32.band(p3.flags_517, 64) == 0 then
        return
    end

    local v5 = rt.copy(p5.position)
    local flags = p5.flags
    local v6 = v5

    if bit32.band(flags, 128) == 0 then
        v6 = {}
        v6[1] = p5.velocity[1] * p2 + v5[1]
        v6[2] = p5.velocity[2] * p2 + v5[2]
        v6[3] = p5.velocity[3] * p2 + v5[3]
        v6[4] = p5.velocity[4] * p2 + v5[4]
    end

    local v7 = rt.copy(p4)

    v7[2] = p1.reference_height

    local t2 = {}

    t2[1] = v6[1] - v7[1] - p1.offset[1]
    t2[2] = v6[2] - v7[2] - p1.offset[2]
    t2[3] = v6[3] - v7[3] - p1.offset[3]
    t2[4] = v6[4] - v7[4] - p1.offset[4]

    local v8 = v3.dot(t2, t2)
    local v9 = v4.estimate(v8)
    local v10 = v9 * 0.5 * (-v8 * (v9 * v9) + 1) + v9
    local v11 = v10 * 0.5 * (-v8 * (v10 * v10) + 1) + v10
    local v12 = if v8 == 0 then 0 else v8 * v11
    local t3 = {}

    t3[1] = if p6[1] < v12 then t2[1] * v11 else 0
    t3[2] = if p6[2] < v12 then t2[2] * v11 else 0
    t3[3] = if p6[3] < v12 then t2[3] * v11 else 0
    t3[4] = if p6[4] < v12 then t2[4] * v11 else 0

    local v13 = direction_to_angles(t3)

    p3.heading_target = -v13[2] - p3.heading_offset
    p3.elevation_target = v13[1] - p1.elevation_offset - p1.additional_elevation
    p1.distance = v12
    p1.anchor[2] = p1.reference_height
    AngularRigTracking.reset_heading(p3, false)
    AngularRigTracking.reset_elevation(p3, false)
end

local PERF = import("skate_core/camera/tracker").PERF
local direction_to_angles_lanes = v2.direction_to_angles_lanes

function t1.RigFraming.update(p7, p8, p9, p10, p11, p12) -- line: 80
    -- upvalues: AngularRigTracking (copy), t1 (copy), PERF (copy), direction_to_angles_lanes (copy)
    if PERF.reference then
        return t1.RigFraming.update_reference(p7, p8, p9, p10, p11, p12)
    end

    if bit32.band(p9.flags_517, 64) == 0 then
        return
    end

    local position = p11.position
    local v14 = position[1]
    local v15 = position[2]
    local v16 = position[3]

    if bit32.band(p11.flags, 128) == 0 then
        local velocity = p11.velocity

        v14 = velocity[1] * p8 + v14
        v15 = velocity[2] * p8 + v15
        v16 = velocity[3] * p8 + v16
    end

    local offset, reference_height = p7.offset, p7.reference_height
    local v17 = v14 - p10[1] - offset[1]
    local v18 = v15 - reference_height - offset[2]
    local v19 = v16 - p10[3] - offset[3]
    local v20 = v17 * v17 + v18 * v18 + v19 * v19
    local v21 = 1 / math.sqrt(v20)
    local v22 = v21 * 0.5 * (-v20 * (v21 * v21) + 1) + v21
    local v23 = v22 * 0.5 * (-v20 * (v22 * v22) + 1) + v22
    local v24 = if v20 == 0 then 0 else v20 * v23
    local v28, v29 = direction_to_angles_lanes(if p12[1] < v24 then v17 * v23 else 0, if p12[2] < v24 then v18 * v23 else 0, if p12[3] < v24 then v19 * v23 else 0)

    p9.heading_target = -v29 - p9.heading_offset
    p9.elevation_target = v28 - p7.elevation_offset - p7.additional_elevation
    p7.distance = v24
    p7.anchor[2] = reference_height
    AngularRigTracking.reset_heading(p9, false)
    AngularRigTracking.reset_elevation(p9, false)
end

t1.RigModeSubject = {}
t1.RigMode = {}

function t1.RigMode.update(p13, p14) -- line: 132
    local n1 = 0

    if p14.flag_568(p14) == 0 then
        if p14.flag_596(p14) ~= 0 or p14.flag_680(p14) ~= 0 then
            n1 = 2
        else
            if p14.flag_540(p14) == 0 then
                return
            end

            n1 = 1
        end
    end

    if n1 == p13.current then
        return
    end

    p13.previous = p13.current
    p13.current = n1
    p13.elapsed = 0
end

return t1
