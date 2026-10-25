-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout")

local function ground_lifecycle() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/ground_lifecycle")
end

local Requests = v1.Requests

return {
    CollisionSettings = {},
    CollisionInput = {},
    check_collision = function(p1, p2, p3) -- check_collision | line: 42
        -- upvalues: import (copy), v1 (copy), Requests (copy)
        local dot = import("skate_core/player/offboard/ground_lifecycle").dot

        p1.mode = 4

        if dot(p3.skeleton_velocity_16336, p3.skeleton_velocity_16336) <= p2.minimum_speed * p2.minimum_speed then
            return
        end

        local v2 = if bit32.band(p3.shared.flags_2480, 128) == 0 then 1 else p2.special_scalar
        local v3 = 1

        if p3.contact_flag_4072 then
            if p3.contact_force_4056 > p2.vehicle_contact then
                Requests.request(p1, 7, 0)
            end

            v3 = p2.vehicle_scalar
        end

        if v2 - v3 >= 0 then
            v2 = v3
        end

        if p3.shared.maximum_pose_error > v2 * p2.maximum_squash then
            Requests.request(p1, 18, 0)
        else
            local v4 = p2.maximum_displacement * v2

            if dot(p3.shared.pose_error, p3.shared.pose_error) > v4 * v4 then
                Requests.request(p1, 1, 0)
            elseif v1.regional_force(p3.shared, p2.maximum_body_contact * v2, p2.maximum_arm_contact * v3) then
                Requests.request(p1, 0, 0)
            end
        end
    end
}
