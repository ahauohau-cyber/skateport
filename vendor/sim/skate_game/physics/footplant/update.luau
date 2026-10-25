-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/air/reckoning")
local v3 = import("skate_core/air/trajectory/grind")
local v4 = import("skate_core/air/trajectory")
local v5 = import("skate_core/math")
local v6 = import("skate_game/physics/footplant/math")
local Trajectory = v4.Trajectory
local Vector3 = v5.Vector3
local STEP, dot, cross, add = v6.STEP, v6.dot, v6.cross, v6.add
local sub, scale, madd, reciprocal = v6.sub, v6.scale, v6.madd, v6.reciprocal
local length, normalize, point, clamp01 = v6.length, v6.normalize, v6.point, v6.clamp01
local t1 = {}

local function footplant() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function air_trajectory() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function ledge() -- line: 49
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector/ledge")
end

local function from_bits4(p2) -- line: 53
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v8,
        v10,
        v12,
        (buffer.readf32(v1, 0))
    }
end

t1.FootplantFrame = {}
t1.Footplant = {}

function t1.Footplant.update_candidate(p3, p4, p5) -- line: 71
    -- upvalues: rt (copy), STEP (copy), add (copy), sub (copy), madd (copy), normalize (copy), point (copy)
    p3.candidate = false

    local t2 = {
        0,
        p3.settings.deck_bounds_y_offset,
        0, 0
    }
    local v14 = add(p3.settings.deck_bounds, t2)
    local v15 = sub(t2, p3.settings.deck_bounds)
    local pose = p5.body.record.pose
    local t3 = {
        rt.copy(pose[16][4]),
        rt.copy(pose[20][4])
    }
    local t4 = {
        point(p5.toolkit.inverse_effective, t3[1]),
        point(p5.toolkit.inverse_effective, t3[2])
    }

    local function outside(p6) -- line: 83
        -- upvalues: v14 (copy), v15 (copy)
        if v15[1] > p6[1] or p6[1] > v14[1] or v15[2] > p6[2] or p6[2] > v14[2] then
            return true
        end

        return v15[3] > p6[3] or p6[3] > v14[3]
    end

    p3.physical_com = madd(p4.trajectory.velocity, STEP, p5.animated.board_frames.centre_of_mass)
    p3.animation_com = madd(p4.trajectory.velocity, STEP, point(p5.animated.roots.animation_to_world, p5.animated.record.centre_of_mass))

    local v16 = t4[1]
    local v17 = 1

    if v15[1] > v16[1]
        or v16[1] > v14[1]
        or v15[2] > v16[2]
        or v16[2] > v14[2]
        or v15[3] > v16[3]
        or v16[3] > v14[3] then
        v17 = 0
    else
        local v18 = t4[2]

        if not (v15[1] > v18[1]
            or v18[1] > v14[1]
            or v15[2] > v18[2]
            or v18[2] > v14[2]
            or v15[3] > v18[3]
            or v18[3] > v14[3]) then
            return
        end
    end

    local v19 = if v17 == 0 then 15 else 19

    p3.selected_toe = v19
    p3.candidate = true
    p3.selected_world = point(p5.animated.roots.animation_to_world, p5.animated.record.pose[v19 + 1][4])
    p3.selected_record = rt.copy(t3[v17 + 1])
    p3.leg_direction = normalize(sub(p3.selected_record, p3.physical_com))
end

function t1.Footplant.update_launch(p7, p8) -- line: 114
    -- upvalues: rt (copy), v2 (copy), sub (copy), scale (copy), madd (copy), normalize (copy)
    local clamp_vector_within_max_angle = v2.clamp_vector_within_max_angle

    if not p7.hit then
        p7.contact_time = p8.remaining_collision_time
    end

    local v21 = sub(normalize((madd(p8.trajectory.acceleration, p7.contact_time, p8.trajectory.velocity))), p8.landing_normal)
    local v22 = scale(p7.current_up, -1)
    local v23 = normalize(clamp_vector_within_max_angle(v21, rt.copy(v22), 0.6108652334660292))

    clamp_vector_within_max_angle(sub(p7.adjusted_contact, p7.physical_com), rt.copy(v22), 0.6108652334660292)
    p7.launch_direction = normalize(v23)
    p7.launch_valid = true
    p7.request = {
        duration = -1,
        position = madd(p7.launch_direction, p7.settings.leg_length_on_landing, p7.physical_com),
        velocity = rt.copy(p8.trajectory.velocity),
        acceleration = { 0, -9.800000190734863, 0, 0 }
    }
end

function t1.Footplant.consume_and_submit(p9, p10, p11, p12, p13) -- line: 139
    -- upvalues: rt (copy), import (copy), STEP (copy), madd (copy), clamp01 (copy), t1 (copy), from_bits4 (copy)
    p9.hit = false

    if p9.enabled and p9.result.contact_time >= 0 then
        p9.contact_time = clamp01(p9.result.contact_time)
        p9.contact = rt.copy(p9.result.contact_position)
        p9.surface = p9.result.surface
        p9.hit = true
        t1.Footplant.nearby_edge(p9, p11)
        p9.adjusted_contact = madd(p10.landing_normal, p9.settings.foot_volume_y_offset, p9.contact)

        if p9.contact_active then
            if p9.active_elapsed + p9.contact_time < 0 then
                p9.contact_active = false
                t1.Footplant.clear_contact(p9)
                p9.active_elapsed = 0
            end
        elseif p9.candidate and p9.contact_time > 0.10999999940395355 and p9.contact_time < 0.3 then
            p9.contact_active = true
            p9.active_elapsed = 0
        else
            t1.Footplant.clear_contact(p9)
        end

        if p9.contact_active then
            local v24 = bit32.band(p11.processed.flags_2480, 8388608) ~= 0

            p9.requested = p9.requested or v24
            p9.active_elapsed += STEP
            import("skate_game/physics/footplant").Footplant.update_pose(p9, p10, p11.animated, p12, p13)
        end
    end

    p9.current_up = from_bits4(p11.processed.vectors_544_560_592_608[1])

    local t5 = {
        duration = 1,
        position = rt.copy(p9.request.position),
        velocity = rt.copy(p9.request.velocity),
        acceleration = rt.copy(p11.gravity)
    }

    p9.result = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.query(p11.world, {
        radius = 0.03999999910593033,
        start_error = 1,
        end_error = 1,
        trajectory = rt.copy(t5)
    })
    p9.completed_trajectory = t5
    p9.enabled = true
end

function t1.Footplant.clear_contact(p14) -- line: 186
    p14.surface = 0
    p14.hit = false
    p14.contact_time = 0
    p14.contact = { 0, 0, 0, 0 }
end

function t1.Footplant.nearby_edge(p15, p16) -- line: 195
    -- upvalues: rt (copy), import (copy), v3 (copy), Trajectory (copy), Vector3 (copy), dot (copy), cross (copy), sub (copy), scale (copy), madd (copy), reciprocal (copy), length (copy), normalize (copy)
    local filter_edges = import("skate_core/player/offboard/air_selector/ledge").filter_edges

    local function xyz(p17) -- line: 197
        -- upvalues: Vector3 (copy)
        return Vector3.new(p17[1], p17[2], p17[3])
    end

    local function lanes(p18) -- line: 200
        return {
            p18.x,
            p18.y,
            p18.z,
            0
        }
    end

    local t6 = {}

    for _, v25 in p16.edges do
        local v26 = true

        for i = 0, 2 do
            if not (rt.fmin(v25.start[i + 1], v25["end"][i + 1]) <= p15.contact[i + 1] + 2 and rt.fmax(v25.start[i + 1], v25["end"][i + 1]) >= p15.contact[i + 1] - 2) then
                v26 = false
                break
            end
        end

        if v26 then
            local start = v25.start
            local t7 = {}

            t7.start = Vector3.new(start[1], start[2], start[3])

            local v27 = v25["end"]

            t7["end"] = Vector3.new(v27[1], v27[2], v27[3])
            table.insert(t6, t7)
        end
    end

    local v28 = p15.contact[2]
    local n1 = 0.25

    for _, v29 in filter_edges(t6, rt.copy(p16.toolkit.deck[4])) do
        local start = v29.start
        local t8 = {
            start.x,
            start.y,
            start.z,
            0
        }
        local v30 = v29["end"]
        local v31 = sub({
            v30.x,
            v30.y,
            v30.z,
            0
        }, t8)
        local v32 = cross(cross(v31, { 0, 1, 0, 0 }), v31)
        local v33 = if length(v32) > 9.999999974752427E-07 then normalize(v32) else { 0, 1, 0, 0 }
        local v34 = v3.descending_plane_time(p15.completed_trajectory, t8, v33)

        if v34 ~= nil then
            local v35 = Trajectory.position_at(p15.completed_trajectory, v34)
            local v36 = length(v31)

            if v36 > 1.52587890625E-05 then
                v31 = scale(v31, reciprocal(v36))
            end

            local v37 = madd(v31, rt.fmax(rt.fmin(dot(v31, sub(v35, t8)), v36), 0), t8)
            local v38 = length(sub(v35, v37))

            if v38 < n1 and v37[2] - v28 > -0.029999999329447746 then
                n1 = v38
                p15.contact_time = v34
                p15.current_up = rt.copy(v33)
                p15.contact = v37
                p15.surface = 0
                p15.hit = true
            end
        end
    end
end

return t1
