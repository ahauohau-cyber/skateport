-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout/common")
local Requests = import("skate_core/player/wipeout/requests").Requests
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {}

function t1.check_collision(p1, p2, p3, p4) -- line: 17
    -- upvalues: v1 (copy), Requests (copy), dot3 (copy)
    if p3.check_squash and p4.maximum_pose_error > p2.air.max_squash then
        Requests.request(p1, 18, 0)
    elseif dot3(p4.pose_error, p4.pose_error) > p2.air.max_displacement * p2.air.max_displacement then
        Requests.request(p1, 1, 0)
    elseif v1.force(p4, p2.air.max_contact, p2.air.max_arm_contact) then
        Requests.request(p1, 0, 0)
    end
end

function t1.check(p5, p6, p7, p8, p9) -- line: 27
    -- upvalues: v1 (copy), Requests (copy), dot3 (copy), t1 (copy)
    if p5.mode ~= 2 then
        p5.mode = 2
        p5.contact_frames = 0
    end

    if p8.board_contact then
        p5.contact_frames = 4
    end

    if p5.contact_frames > 0 then
        p5.contact_frames -= 1
    end

    if p5.cooldown > 0 then
        p5.cooldown -= p8.timestep
    else
        v1.vehicle(p5, p6, p8)

        local air = p6.air
        local flags_2476 = p8.flags_2476
        local v2, v3

        if bit32.band(flags_2476, 67108864) ~= 0 then
            v3 = air.body_flip_scalar
            v2 = air.body_flip_acc_scalar
        else
            v3 = 1
            v2 = 1
        end

        local flags_2472 = p8.flags_2472
        local v4, v5

        if bit32.band(flags_2472, 32768) ~= 0 and p8.jump_fix_frames > air.ignore_danger_frames then
            v4 = air.xz_trick
            v5 = air.y_trick
        elseif p8.wheel_contact then
            v4 = p7.ground_xz * v2
            v5 = p6.ground.y_acceleration
        else
            v4 = air.xz_acceleration * v2
            v5 = air.y_acceleration
        end

        if bit32.band(p8.board_material_flags, 536870912) ~= 0 then
            v4 *= air.light_dmo_scalar
        end

        v1.closing(p5, p8, v4, v5)

        local v6 = air.max_displacement * v3

        if p7.check_squash and p8.maximum_pose_error > air.max_squash * v3 then
            Requests.request(p5, 18, 0)
        elseif dot3(p8.pose_error, p8.pose_error) > v6 * v6 then
            Requests.request(p5, 1, 0)
        elseif v1.force(p8, air.max_contact * v3, air.max_arm_contact) then
            Requests.request(p5, 0, 0)
        end

        if p8.flip_active and p8.flip_requested_speed == 0 and p8.system_up_y < 0 then
            Requests.request(p5, 4, 0)
        end

        t1.bad_landing(p5, p6, p7, p8, p9)
        v1.leaning(p5, p6, p8)

        if bit32.band(p8.flags_2476, 67108864) ~= 0 and p8.compliant then
            Requests.request(p5, 21, 0)
        end

        if bit32.band(p8.flags_2472, 64) ~= 0 and (p8.compliant or p8.board_contact) then
            Requests.request(p5, 21, 0)
        end
    end
end

function t1.bad_landing(p10, p11, p12, p13, p14) -- line: 81
    -- upvalues: v1 (copy), Requests (copy), dot3 (copy), PointGraph (copy)
    if not (p12.check_bad_landing and p13.board_contact) then
        return
    end

    local v7 = if p14 then p13.com_velocity else p13.deck_velocity
    local board_contact_normal = p13.board_contact_normal

    if p13.grind_selected then
        if -dot3(if p13.grind_normal_valid then p13.grind_normal else board_contact_normal, v7) > p11.air.max_grind_speed * p12.bad_landing_scale then
            Requests.request(p10, 8, 0)
        end
    else
        local v9 = -dot3(board_contact_normal, v7)
        local t2 = {
            board_contact_normal[1] * v9 + v7[1],
            board_contact_normal[2] * v9 + v7[2],
            board_contact_normal[3] * v9 + v7[3],
            board_contact_normal[4] * v9 + v7[4]
        }

        if PointGraph.evaluate(p11.air.max_landing_angle, v1.length(t2)) * p12.bad_landing_scale < math.abs(p13.landing_angle) then
            Requests.request(p10, 5, 0)
        end

        if (if bit32.band(p13.board_material_flags, 2147483648) == 0 then p11.air.max_landing_speed else p11.air.max_stairs_speed) * p12.bad_landing_scale < v9 then
            Requests.request(p10, 6, v9)
        end
    end
end

return t1
