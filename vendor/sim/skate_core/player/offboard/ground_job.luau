-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/reciprocal_sqrt")
local v3 = import("skate_core/trigonometry")
local t1 = {
    STEP = 0.01666666753590107
}
local STEP = t1.STEP

t1.ContactSnapshot = {}
t1.Input = {}
t1.Prepared = {}

local function madd(p1, p2, p3) -- line: 55
    return {
        p1[1] * p2 + p3[1],
        p1[2] * p2 + p3[2],
        p1[3] * p2 + p3[3],
        p1[4] * p2 + p3[4]
    }
end

local function cross(p4, p5) -- line: 64
    return {
        -p4[3] * p5[2] + p4[2] * p5[3],
        -p4[1] * p5[3] + p4[3] * p5[1],
        -p4[2] * p5[1] + p4[1] * p5[2],
        -p4[4] * p5[4] + p4[4] * p5[4]
    }
end

local function normalize(p6) -- line: 73
    -- upvalues: v1 (copy), v2 (copy)
    local v4 = v1.dot3(p6, p6)
    local v5 = v2.estimate(v4)
    local v6 = v5 * 0.5 * (-v4 * (v5 * v5) + 1) + v5
    local v7 = v6 * 0.5 * (-v4 * (v6 * v6) + 1) + v6

    return {
        p6[1] * v7,
        p6[2] * v7,
        p6[3] * v7,
        p6[4] * v7
    }
end

local function xyz(p7) -- line: 82
    -- upvalues: Vector3 (copy)
    return Vector3.new(p7[1], p7[2], p7[3])
end

local function query_frame(p8) -- line: 87
    -- upvalues: Vector3 (copy)
    local v8 = p8[1]
    local t2 = {}

    t2.right = Vector3.new(v8[1], v8[2], v8[3])

    local v9 = p8[2]

    t2.up = Vector3.new(v9[1], v9[2], v9[3])

    local v10 = p8[3]

    t2.forward = Vector3.new(v10[1], v10[2], v10[3])

    local v11 = p8[4]

    t2.position = Vector3.new(v11[1], v11[2], v11[3])

    return t2
end

local function native_frame(p9) -- line: 92
    return {
        {
            p9.right.x,
            p9.right.y,
            p9.right.z,
            0
        },
        {
            p9.up.x,
            p9.up.y,
            p9.up.z,
            0
        },
        {
            p9.forward.x,
            p9.forward.y,
            p9.forward.z,
            0
        },
        {
            p9.position.x,
            p9.position.y,
            p9.position.z,
            0
        }
    }
end

function t1.prepare(p10, p11, p12, p13) -- line: 108
    -- upvalues: rt (copy), Vector3 (copy), STEP (copy), query_frame (copy), native_frame (copy)
    local v12 = p11 + STEP
    local v13 = true

    if p12.contact.readiness > 0 then
        rt.assign(p10, p12.contact.prefix)
        v13 = bit32.band(p10.flags_176, 48) == 48
    elseif p12.previous_state ~= 501 then
        local third_line_position = p12.third_line_position

        if third_line_position ~= nil then
            p10.flags_176 = 1
            p10.position = rt.copy(third_line_position)
            p10.normal = rt.copy(p12.frame[2])
        end
    end

    local v14 = rt.to_i32(p12.frames_since_teleport) < 20

    if v14 then
        p10.flags_176 = bit32.band(p10.flags_176, 4294967287)
    end

    local v15 = rt.copy(p10)
    local t3 = {
        frame_80 = query_frame(p12.frame)
    }
    local position = p10.position

    t3.contact_position_192 = Vector3.new(position[1], position[2], position[3])
    t3.contact_flags_368 = p10.flags_176
    t3.reach_364 = p10.distance_172

    local normal = v15.normal

    t3.previous_input_up_416 = Vector3.new(normal[1], normal[2], normal[3])

    local v16 = p13(t3)

    if not (v13 or v16.state_753) and bit32.band(p10.flags_176, 8) == 0 then
        v12 = 0
    end

    local t4 = {
        p12.processed_velocity[1] * STEP + p12.processed_position[1],
        p12.processed_velocity[2] * STEP + p12.processed_position[2],
        p12.processed_velocity[3] * STEP + p12.processed_position[3],
        p12.processed_velocity[4] * STEP + p12.processed_position[4]
    }

    return {
        job = {
            contact_position = rt.copy(v15.position),
            contact_normal = {
                v16.input_up_416.x,
                v16.input_up_416.y,
                v16.input_up_416.z,
                v15.normal[4]
            },
            support_frame = rt.copy(v15.support_frame),
            target_position = rt.copy(v15.target_position),
            target_normal = rt.copy(v15.target_normal),
            edge_position = rt.copy(v15.edge_position),
            edge_normal = rt.copy(v15.edge_normal),
            flags = v15.flags_176,
            support_id = v15.support_180,
            collision_displacements = rt.copy(p12.collision_displacements),
            animation_motion = rt.copy(p12.animation_motion),
            animation_velocity = rt.copy(p12.animation_velocity),
            desired_direction = rt.copy(p12.controls.state_656),
            animation_position = t4,
            requested_duration = p12.requested_duration,
            mirrored = bit32.band(p12.flags_2476, 4) ~= 0,
            requested_phase = p12.requested_phase,
            override_duration = p12.override_duration,
            animation_directed = bit32.band(p12.flags_2488, 134217728) ~= 0,
            movement = p12.controls.state_708,
            steering = p12.controls.state_712,
            sprint_pressed = bit32.band(p12.flags_2484, 131072) ~= 0,
            suppress_lean = bit32.band(p12.flags_2480, 128) ~= 0,
            suppress_minimum = v14,
            target_frame_present = v16.state_752,
            edge_active = v16.state_753,
            target_frame = native_frame(v16.frame_768),
            ignore_obstacle = bit32.band(p12.flags_2472, 268435456) ~= 0
        },
        geometry = v16
    }, v12
end

function t1.sync_frames(p14, p15, p16) -- line: 190
    -- upvalues: rt (copy), v1 (copy), v3 (copy), STEP (copy), madd (copy), cross (copy), normalize (copy)
    p14.flags_144_to_150[4] = p16.sliding
    p14.frame_80 = rt.copy(p16.physical_frame)

    if bit32.band(p15.flags_176, 1) ~= 0 then
        local t6 = {
            p15.position[1] - p14.frame_80[4][1],
            p15.position[2] - p14.frame_80[4][2],
            p15.position[3] - p14.frame_80[4][3],
            p15.position[4] - p14.frame_80[4][4]
        }
        local v17 = v1.dot3(t6, p14.frame_80[2])

        if not (v17 <= 0) then
            p14.frame_80[4] = madd(p14.frame_80[2], v17, p14.frame_80[4])
        end
    end

    local v18 = rt.copy(p16.animation_frame)

    if p14.flags_144_to_150[7] then
        p14.duration_180 -= STEP

        if not (p14.duration_180 > 0) then
            p14.duration_180 = 0
            p14.flags_144_to_150[7] = false
        end

        p14.angle_172 *= 0.8999999761581421

        local v19 = -p14.angular_velocity_176 * p14.duration_180 + p14.angle_172
        local v20, v21 = v3.sin_cos(v19)
        local v22 = madd({ v20, 0, v21, 0 }, v18[3][3], (madd({ 0, 1, 0, 0 }, v18[3][2], {
            v21 * v18[3][1],
            0 * v18[3][1],
            -v20 * v18[3][1],
            0 * v18[3][1]
        })))
        local v23 = normalize((cross(v18[2], v22)))

        v18[1] = v23
        v18[2] = normalize((cross(v22, v23)))
        v18[3] = v22
    end

    return v18
end

t1.madd = madd
t1.cross = cross
t1.normalize = normalize
t1.xyz = xyz
t1.query_frame = query_frame
t1.native_frame = native_frame

return t1
