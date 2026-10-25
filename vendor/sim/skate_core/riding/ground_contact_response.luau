-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_motion_output")
local v3 = import("skate_core/physics/force_queue")
local v4 = import("skate_core/point_graph")
local Vector3 = v1.Vector3
local dot = v2.dot
local QueuedPointForce = v3.QueuedPointForce
local PointGraph = v4.PointGraph
local t1 = {
    WallRideSettings = {},
    WallRidePhysical = {}
}

function t1.wall_ride_response(p1, p2, p3, p4) -- line: 48
    -- upvalues: rt (copy), Vector3 (copy), dot (copy), QueuedPointForce (copy), PointGraph (copy), t1 (copy)
    local v5 = QueuedPointForce.default()

    v5.tag = 16

    local t2 = {
        active_2731 = false,
        scalar_2704 = 0,
        animated_board_2708 = false,
        tag_16_force = v5,
        vector_2688 = rt.copy(p4)
    }
    local scalar_2756, v6, v7

    if p3.flag_8084 then
        if math.abs(p2.board_normal[2]) < 0.5 and dot(t1.xyz(p2.up), t1.xyz(p2.board_normal)) > 0.71 then
            t2.active_2731 = true

            local v9 = PointGraph.evaluate(p1.anti_gravity_vs_time, p3.scalar_2752)

            t2.tag_16_force.force_world = Vector3.new(0, -(v9 * p2.board_mass * p2.gravity), 0)
            scalar_2756 = p3.scalar_2756
            v6 = scalar_2756 < 0 and scalar_2756 > -1 or p2.speed < 3 and scalar_2756 > 0.1
            v7 = false
        else
            v7 = true
        end
    else
        v7 = true
    end

    if v7 or not (v6 or p3.scalar_2752 > 0.01 and p2.contact_count > 0) and not (p3.scalar_2752 > p1.foot_force_time) then
        return t2
    end

    local v10 = dot(t1.xyz(p3.vector_8064), t1.xyz(p2.board_normal))
    local v12 = math.abs(p3.vector_8048[2] - p3.vector_8032[2])
    local v13 = p2.velocity[2] * p1.velocity_time_to_consider + v12

    if not (v10 < p1.max_dot_floor_wall) or not v6 and not (v13 < p1.auto_jump_height) and not (p1.max_time < scalar_2756) then
        return t2
    end

    t2.animated_board_2708 = true

    local v14 = dot(t1.xyz(p2.board_normal), t1.xyz(p2.velocity))
    local t3 = {
        p2.velocity[1] - p2.board_normal[1] * v14,
        p2.velocity[2] - p2.board_normal[2] * v14,
        p2.velocity[3] - p2.board_normal[3] * v14,
        p2.velocity[4] - p2.board_normal[4] * v14
    }

    if t3[2] < 0 and t3[2] > -6 then
        t3[2] *= p1.auto_jump_y_down_scalar
    end

    t2.vector_2688 = {
        p2.board_normal[1] * p1.auto_jump_force + t3[1],
        p2.board_normal[2] * p1.auto_jump_force + t3[2],
        p2.board_normal[3] * p1.auto_jump_force + t3[3],
        p2.board_normal[4] * p1.auto_jump_force + t3[4]
    }

    return t2
end

function t1.xyz(p5) -- line: 113
    -- upvalues: Vector3 (copy)
    return Vector3.new(p5[1], p5[2], p5[3])
end

return t1
