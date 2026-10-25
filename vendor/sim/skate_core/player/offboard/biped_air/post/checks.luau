-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout")
local Requests, regional_force = v1.Requests, v1.regional_force
local dot = import("skate_core/player/offboard/biped_air/height").dot
local t1 = {
    Thresholds = {},
    Settings = {}
}

function t1.collision(p1, p2, p3, p4) -- line: 24
    -- upvalues: Requests (copy), regional_force (copy), dot (copy)
    if p3.check_squash and p4.maximum_pose_error > p2.squash then
        Requests.request(p1, 18, 0)

        return
    end

    local v2 = dot(p4.pose_error, p4.pose_error) <= p2.displacement * p2.displacement
    local v3

    if v2 then
        v3 = regional_force(p4, p2.body_contact, p2.arm_contact)
    else
        Requests.request(p1, 1, 0)
    end

    if (not v2 or v3) and v2 then
        Requests.request(p1, 0, 0)
    end
end

function t1.skeleton_air(p5, p6, p7, p8) -- line: 38
    -- upvalues: t1 (copy)
    t1.collision(p5, p6.skeleton_air, p7, p8)
end

function t1.offboard_air(p9, p10, p11, p12, p13) -- line: 43
    -- upvalues: dot (copy), t1 (copy)
    p9.mode = 4

    if dot(p13, p13) > p10.offboard_min_speed * p10.offboard_min_speed then
        t1.collision(p9, p10.offboard_air, p11, p12)
    end
end

return t1
